using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class StudyService : IStudyService
{
    private readonly PACSDbContext _context;
    private readonly IMemoryCache  _cache;

    // Cache key constants
    private const string StatsKey       = "worklist:stats";
    private const string WorklistPrefix = "worklist:page:";
    private const string StudyPrefix    = "study:";

    private static readonly MemoryCacheEntryOptions ShortCache = new MemoryCacheEntryOptions()
        .SetAbsoluteExpiration(TimeSpan.FromSeconds(15))
        .SetSize(1);

    private static readonly MemoryCacheEntryOptions MediumCache = new MemoryCacheEntryOptions()
        .SetAbsoluteExpiration(TimeSpan.FromSeconds(30))
        .SetSize(1);

    private static readonly MemoryCacheEntryOptions LongCache = new MemoryCacheEntryOptions()
        .SetAbsoluteExpiration(TimeSpan.FromMinutes(2))
        .SetSize(1);

    public StudyService(PACSDbContext context, IMemoryCache cache)
    {
        _context = context;
        _cache   = cache;
    }

    public async Task<WorklistStatsDto> GetWorklistStatsAsync()
    {
        if (_cache.TryGetValue(StatsKey, out WorklistStatsDto? cached) && cached != null)
            return cached;

        var stats = await _context.Studies
            .GroupBy(_ => 1)
            .Select(g => new WorklistStatsDto
            {
                PendingCount  = g.Count(s => s.Status == "Pending"),
                PriorityCount = g.Count(s => s.IsPriority),
                ReportedCount = g.Count(s => s.Status == "Reported" || s.Status == "Final")
            })
            .FirstOrDefaultAsync() ?? new WorklistStatsDto();

        _cache.Set(StatsKey, stats, ShortCache);
        return stats;
    }

    public async Task<(List<StudyDto> Studies, int TotalCount)> GetWorklistAsync(WorklistFilterDto filter)
    {
        // Build a deterministic cache key from all filter params
        var cacheKey = $"{WorklistPrefix}{filter.Page}:{filter.PageSize}:{filter.SearchTerm}:" +
                       $"{filter.Modality}:{filter.Status}:{filter.IsPriority}:" +
                       $"{filter.StartDate:yyyyMMdd}:{filter.EndDate:yyyyMMdd}";

        if (_cache.TryGetValue(cacheKey, out (List<StudyDto>, int) hit))
            return hit;

        var query = _context.Studies
            .AsNoTracking()
            .Include(s => s.Patient)
            .Include(s => s.AssignedRadiologist)
            .AsQueryable();

        if (!string.IsNullOrEmpty(filter.SearchTerm))
            query = query.Where(s =>
                s.Patient.FirstName.Contains(filter.SearchTerm) ||
                s.Patient.LastName.Contains(filter.SearchTerm)  ||
                s.Patient.MRN.Contains(filter.SearchTerm)       ||
                s.AccessionNumber.Contains(filter.SearchTerm));

        if (!string.IsNullOrEmpty(filter.Modality))
            query = query.Where(s => s.Modality == filter.Modality);

        if (filter.StartDate.HasValue)
            query = query.Where(s => s.StudyDate >= filter.StartDate.Value);

        if (filter.EndDate.HasValue)
            query = query.Where(s => s.StudyDate <= filter.EndDate.Value);

        if (!string.IsNullOrEmpty(filter.Status))
            query = query.Where(s => s.Status == filter.Status);

        if (filter.IsPriority.HasValue)
            query = query.Where(s => s.IsPriority == filter.IsPriority.Value);

        // Count + data sequentially — DbContext is NOT thread-safe, parallel queries cause concurrency errors
        var totalCount = await query.CountAsync();
        var studies = await query
            .OrderByDescending(s => s.IsPriority)
            .ThenByDescending(s => s.StudyDate)
            .Skip((filter.Page - 1) * filter.PageSize)
            .Take(filter.PageSize)
            .Select(s => new StudyDto(
                s.StudyId,
                s.StudyInstanceUID,
                $"{s.Patient.LastName}, {s.Patient.FirstName}",
                s.Patient.MRN,
                s.StudyDate,
                s.Modality,
                s.Description,
                s.AccessionNumber,
                s.Status,
                s.IsPriority,
                s.AssignedRadiologist != null
                    ? $"{s.AssignedRadiologist.FirstName} {s.AssignedRadiologist.LastName}"
                    : null,
                s.Series.Count,
                0
            ))
            .ToListAsync();

        // Cache unfiltered/simple queries only
        if (string.IsNullOrEmpty(filter.SearchTerm))
            _cache.Set(cacheKey, (studies, totalCount), ShortCache);

        return (studies, totalCount);
    }

    public async Task<StudyDetailDto?> GetStudyDetailAsync(int studyId)
    {
        var cacheKey = $"{StudyPrefix}{studyId}";
        if (_cache.TryGetValue(cacheKey, out StudyDetailDto? cached) && cached != null)
            return cached;

        var study = await _context.Studies
            .AsNoTracking()
            .Include(s => s.Patient)
            .Include(s => s.AssignedRadiologist)
            .Include(s => s.Series).ThenInclude(sr => sr.Instances)
            .Include(s => s.Reports).ThenInclude(r => r.Radiologist)
            .FirstOrDefaultAsync(s => s.StudyId == studyId);

        if (study == null) return null;

        var dto = MapToStudyDetailDto(study);
        _cache.Set(cacheKey, dto, MediumCache);
        return dto;
    }

    public async Task<StudyDetailDto?> GetStudyByUIDAsync(string studyInstanceUID)
    {
        var cacheKey = $"{StudyPrefix}uid:{studyInstanceUID}";
        if (_cache.TryGetValue(cacheKey, out StudyDetailDto? cached) && cached != null)
            return cached;

        var study = await _context.Studies
            .AsNoTracking()
            .Include(s => s.Patient)
            .Include(s => s.AssignedRadiologist)
            .Include(s => s.Series).ThenInclude(sr => sr.Instances)
            .Include(s => s.Reports).ThenInclude(r => r.Radiologist)
            .FirstOrDefaultAsync(s => s.StudyInstanceUID == studyInstanceUID);

        if (study == null) return null;

        var dto = MapToStudyDetailDto(study);
        _cache.Set(cacheKey, dto, MediumCache);
        return dto;
    }

    public async Task<bool> AssignStudyAsync(int studyId, int radiologistId)
    {
        var study = await _context.Studies.FindAsync(studyId);
        if (study == null) return false;

        study.AssignedRadiologistId = radiologistId;
        study.Status    = "InProgress";
        study.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        InvalidateStudyCache(studyId);
        return true;
    }

    public async Task<bool> UpdateStudyStatusAsync(int studyId, string status)
    {
        var study = await _context.Studies.FindAsync(studyId);
        if (study == null) return false;

        study.Status    = status;
        study.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        InvalidateStudyCache(studyId);
        return true;
    }

    public async Task<bool> SetStudyPriorityAsync(int studyId, bool isPriority)
    {
        var study = await _context.Studies.FindAsync(studyId);
        if (study == null) return false;

        study.IsPriority = isPriority;
        study.UpdatedAt  = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        InvalidateStudyCache(studyId);
        return true;
    }

    // Invalidate all caches related to a study on any write
    private void InvalidateStudyCache(int studyId)
    {
        _cache.Remove($"{StudyPrefix}{studyId}");
        _cache.Remove(StatsKey);
        // Worklist pages will expire naturally (15s) — fast enough
    }

    private static StudyDetailDto MapToStudyDetailDto(Core.Entities.Study study)
    {
        return new StudyDetailDto(
            study.StudyId,
            study.StudyInstanceUID,
            new PatientDto(
                study.Patient.PatientId,
                study.Patient.MRN,
                study.Patient.FirstName,
                study.Patient.LastName,
                study.Patient.DateOfBirth,
                study.Patient.Gender
            ),
            study.StudyDate,
            study.Modality,
            study.Description,
            study.AccessionNumber,
            study.Status,
            study.IsPriority,
            study.AssignedRadiologist != null ? new UserDto(
                study.AssignedRadiologist.UserId,
                study.AssignedRadiologist.Username,
                study.AssignedRadiologist.Email,
                study.AssignedRadiologist.Role,
                study.AssignedRadiologist.FirstName,
                study.AssignedRadiologist.LastName
            ) : null,
            study.Series.Select(s => new SeriesDto(
                s.SeriesId,
                s.SeriesInstanceUID,
                s.Modality,
                s.BodyPart,
                s.SeriesNumber,
                s.Description,
                s.Instances.Count
            )).ToList(),
            study.Reports.Select(r => new ReportDto(
                r.ReportId,
                r.StudyId,
                $"{r.Radiologist.FirstName} {r.Radiologist.LastName}",
                r.Status,
                r.ReportText,
                r.Findings,
                r.Impression,
                r.CreatedAt,
                r.FinalizedAt
            )).ToList()
        );
    }
}
