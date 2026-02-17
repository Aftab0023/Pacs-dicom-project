using Microsoft.EntityFrameworkCore;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class StudyService : IStudyService
{
    private readonly PACSDbContext _context;

    public StudyService(PACSDbContext context)
    {
        _context = context;
    }

    public async Task<(List<StudyDto> Studies, int TotalCount)> GetWorklistAsync(WorklistFilterDto filter)
    {
        var query = _context.Studies
            .Include(s => s.Patient)
            .Include(s => s.AssignedRadiologist)
            .Include(s => s.Series)
            .ThenInclude(sr => sr.Instances)
            .AsQueryable();

        // Apply filters
        if (!string.IsNullOrEmpty(filter.SearchTerm))
        {
            query = query.Where(s =>
                s.Patient.FirstName.Contains(filter.SearchTerm) ||
                s.Patient.LastName.Contains(filter.SearchTerm) ||
                s.Patient.MRN.Contains(filter.SearchTerm) ||
                s.AccessionNumber.Contains(filter.SearchTerm));
        }

        if (!string.IsNullOrEmpty(filter.Modality))
        {
            query = query.Where(s => s.Modality == filter.Modality);
        }

        if (filter.StartDate.HasValue)
        {
            query = query.Where(s => s.StudyDate >= filter.StartDate.Value);
        }

        if (filter.EndDate.HasValue)
        {
            query = query.Where(s => s.StudyDate <= filter.EndDate.Value);
        }

        if (!string.IsNullOrEmpty(filter.Status))
        {
            query = query.Where(s => s.Status == filter.Status);
        }

        if (filter.IsPriority.HasValue)
        {
            query = query.Where(s => s.IsPriority == filter.IsPriority.Value);
        }

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
                s.AssignedRadiologist != null ? $"{s.AssignedRadiologist.FirstName} {s.AssignedRadiologist.LastName}" : null,
                s.Series.Count,
                0  // Instance count removed to avoid SQL aggregate error
            ))
            .ToListAsync();

        return (studies, totalCount);
    }

    public async Task<StudyDetailDto?> GetStudyDetailAsync(int studyId)
    {
        var study = await _context.Studies
            .Include(s => s.Patient)
            .Include(s => s.AssignedRadiologist)
            .Include(s => s.Series)
            .ThenInclude(sr => sr.Instances)
            .Include(s => s.Reports)
            .ThenInclude(r => r.Radiologist)
            .FirstOrDefaultAsync(s => s.StudyId == studyId);

        if (study == null) return null;

        return MapToStudyDetailDto(study);
    }

    public async Task<StudyDetailDto?> GetStudyByUIDAsync(string studyInstanceUID)
    {
        var study = await _context.Studies
            .Include(s => s.Patient)
            .Include(s => s.AssignedRadiologist)
            .Include(s => s.Series)
            .ThenInclude(sr => sr.Instances)
            .Include(s => s.Reports)
            .ThenInclude(r => r.Radiologist)
            .FirstOrDefaultAsync(s => s.StudyInstanceUID == studyInstanceUID);

        if (study == null) return null;

        return MapToStudyDetailDto(study);
    }

    public async Task<bool> AssignStudyAsync(int studyId, int radiologistId)
    {
        var study = await _context.Studies.FindAsync(studyId);
        if (study == null) return false;

        study.AssignedRadiologistId = radiologistId;
        study.Status = "InProgress";
        study.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UpdateStudyStatusAsync(int studyId, string status)
    {
        var study = await _context.Studies.FindAsync(studyId);
        if (study == null) return false;

        study.Status = status;
        study.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SetStudyPriorityAsync(int studyId, bool isPriority)
    {
        var study = await _context.Studies.FindAsync(studyId);
        if (study == null) return false;

        study.IsPriority = isPriority;
        study.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    private StudyDetailDto MapToStudyDetailDto(Core.Entities.Study study)
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
