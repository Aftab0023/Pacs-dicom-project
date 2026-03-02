using System.Text;
using FellowOakDicom;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PACS.Core.DTOs;
using PACS.Core.Entities;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class WorklistService : IWorklistService
{
    private readonly PACSDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<WorklistService> _logger;
    private readonly string _worklistPath;

    public WorklistService(PACSDbContext context, IConfiguration configuration, ILogger<WorklistService> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
        _worklistPath = configuration["Worklist:Path"] ?? "/var/lib/orthanc/worklists";
    }

    public async Task<WorklistEntryResponse> CreateWorklistEntryAsync(CreateWorklistEntryRequest request, int createdBy)
    {
        var entry = new WorklistEntry
        {
            AccessionNumber = request.AccessionNumber,
            PatientID = request.PatientID,
            PatientName = request.PatientName,
            PatientBirthDate = request.PatientBirthDate,
            PatientSex = request.PatientSex,
            ScheduledProcedureStepStartDate = request.ScheduledProcedureStepStartDate,
            ScheduledProcedureStepStartTime = request.ScheduledProcedureStepStartTime,
            Modality = request.Modality,
            ScheduledStationAETitle = request.ScheduledStationAETitle,
            ScheduledProcedureStepDescription = request.ScheduledProcedureStepDescription,
            RequestedProcedureID = request.RequestedProcedureID,
            ReferringPhysicianName = request.ReferringPhysicianName,
            Status = "SCHEDULED",
            CreatedBy = createdBy,
            CreatedDate = DateTime.UtcNow
        };

        _context.WorklistEntries.Add(entry);
        await _context.SaveChangesAsync();

        return MapToResponse(entry);
    }

    public async Task<WorklistEntryResponse?> GetWorklistEntryAsync(int worklistId)
    {
        var entry = await _context.WorklistEntries.FindAsync(worklistId);
        return entry != null ? MapToResponse(entry) : null;
    }

    public async Task<WorklistEntryResponse?> GetWorklistEntryByAccessionAsync(string accessionNumber)
    {
        var entry = await _context.WorklistEntries
            .FirstOrDefaultAsync(w => w.AccessionNumber == accessionNumber);
        return entry != null ? MapToResponse(entry) : null;
    }

    public async Task<List<WorklistEntryResponse>> QueryWorklistEntriesAsync(WorklistQueryRequest request)
    {
        var query = _context.WorklistEntries.AsQueryable();

        if (!string.IsNullOrEmpty(request.Modality))
            query = query.Where(w => w.Modality == request.Modality);

        if (!string.IsNullOrEmpty(request.Status))
            query = query.Where(w => w.Status == request.Status);

        if (request.StartDate.HasValue)
            query = query.Where(w => w.ScheduledProcedureStepStartDate >= request.StartDate.Value);

        if (request.EndDate.HasValue)
            query = query.Where(w => w.ScheduledProcedureStepStartDate <= request.EndDate.Value);

        var entries = await query.OrderBy(w => w.ScheduledProcedureStepStartDate).ToListAsync();
        return entries.Select(MapToResponse).ToList();
    }

    public async Task<WorklistEntryResponse?> UpdateWorklistEntryAsync(int worklistId, UpdateWorklistEntryRequest request)
    {
        var entry = await _context.WorklistEntries.FindAsync(worklistId);
        if (entry == null) return null;

        entry.ScheduledProcedureStepStartDate = request.ScheduledProcedureStepStartDate ?? entry.ScheduledProcedureStepStartDate;
        entry.ScheduledProcedureStepStartTime = request.ScheduledProcedureStepStartTime ?? entry.ScheduledProcedureStepStartTime;
        entry.Modality = request.Modality ?? entry.Modality;
        entry.ScheduledStationAETitle = request.ScheduledStationAETitle ?? entry.ScheduledStationAETitle;
        entry.ScheduledProcedureStepDescription = request.ScheduledProcedureStepDescription ?? entry.ScheduledProcedureStepDescription;
        entry.ReferringPhysicianName = request.ReferringPhysicianName ?? entry.ReferringPhysicianName;

        await _context.SaveChangesAsync();
        return MapToResponse(entry);
    }

    public async Task<WorklistEntryResponse?> UpdateWorklistStatusAsync(int worklistId, string status)
    {
        var entry = await _context.WorklistEntries.FindAsync(worklistId);
        if (entry == null) return null;

        entry.Status = status;
        if (status == "COMPLETED")
            entry.CompletedDate = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return MapToResponse(entry);
    }

    public async Task<bool> DeleteWorklistEntryAsync(int worklistId)
    {
        var entry = await _context.WorklistEntries.FindAsync(worklistId);
        if (entry == null) return false;

        _context.WorklistEntries.Remove(entry);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> LinkStudyToWorklistAsync(string accessionNumber, string studyInstanceUID)
    {
        var entry = await _context.WorklistEntries
            .FirstOrDefaultAsync(w => w.AccessionNumber == accessionNumber);
        
        if (entry == null) return false;

        entry.StudyInstanceUID = studyInstanceUID;
        entry.Status = "IN_PROGRESS";
        await _context.SaveChangesAsync();
        return true;
    }

    private WorklistEntryResponse MapToResponse(WorklistEntry entry)
    {
        return new WorklistEntryResponse
        {
            WorklistID = entry.WorklistID,
            AccessionNumber = entry.AccessionNumber,
            PatientID = entry.PatientID,
            PatientName = entry.PatientName,
            PatientBirthDate = entry.PatientBirthDate,
            PatientSex = entry.PatientSex,
            ScheduledProcedureStepStartDate = entry.ScheduledProcedureStepStartDate,
            ScheduledProcedureStepStartTime = entry.ScheduledProcedureStepStartTime,
            Modality = entry.Modality,
            ScheduledStationAETitle = entry.ScheduledStationAETitle,
            ScheduledProcedureStepDescription = entry.ScheduledProcedureStepDescription,
            StudyInstanceUID = entry.StudyInstanceUID,
            RequestedProcedureID = entry.RequestedProcedureID,
            ReferringPhysicianName = entry.ReferringPhysicianName,
            Status = entry.Status,
            CreatedDate = entry.CreatedDate,
            CompletedDate = entry.CompletedDate
        };
    }

    public async Task GenerateWorklistFilesAsync()
    {
        var scheduledEntries = await _context.WorklistEntries
            .Where(w => w.Status == "SCHEDULED")
            .ToListAsync();

        _logger.LogInformation($"Generating worklist files for {scheduledEntries.Count} scheduled entries");

        foreach (var entry in scheduledEntries)
        {
            await GenerateWorklistFileForEntryAsync(entry.WorklistID);
        }
    }

    private async Task<string> GenerateWorklistFileForEntryAsync(int worklistId)
    {
        var entry = await _context.WorklistEntries.FindAsync(worklistId);
        if (entry == null)
        {
            _logger.LogWarning($"Worklist entry {worklistId} not found");
            return string.Empty;
        }

        try
        {
            var filename = $"{entry.AccessionNumber}.wl";
            var filepath = Path.Combine(_worklistPath, filename);
            Directory.CreateDirectory(_worklistPath);

            var dataset = CreateDicomWorklistDataset(entry);
            var dicomFile = new DicomFile(dataset);
            await dicomFile.SaveAsync(filepath);

            _logger.LogInformation($"Generated DICOM worklist file: {filepath}");
            return filepath;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error generating worklist file for entry {worklistId}");
            return string.Empty;
        }
    }

    private DicomDataset CreateDicomWorklistDataset(WorklistEntry entry)
    {
        var dataset = new DicomDataset();

        dataset.AddOrUpdate(DicomTag.PatientName, entry.PatientName);
        dataset.AddOrUpdate(DicomTag.PatientID, entry.PatientID);
        if (entry.PatientBirthDate.HasValue)
            dataset.AddOrUpdate(DicomTag.PatientBirthDate, entry.PatientBirthDate.Value.ToString("yyyyMMdd"));
        if (!string.IsNullOrEmpty(entry.PatientSex))
            dataset.AddOrUpdate(DicomTag.PatientSex, entry.PatientSex);

        var spsSequence = new DicomSequence(DicomTag.ScheduledProcedureStepSequence);
        var spsItem = new DicomDataset();

        spsItem.AddOrUpdate(DicomTag.Modality, entry.Modality);
        spsItem.AddOrUpdate(DicomTag.ScheduledStationAETitle, entry.ScheduledStationAETitle ?? "PACS");
        spsItem.AddOrUpdate(DicomTag.ScheduledProcedureStepStartDate, entry.ScheduledProcedureStepStartDate.ToString("yyyyMMdd"));
        if (entry.ScheduledProcedureStepStartTime.HasValue)
            spsItem.AddOrUpdate(DicomTag.ScheduledProcedureStepStartTime, entry.ScheduledProcedureStepStartTime.Value.ToString("HHmmss"));
        spsItem.AddOrUpdate(DicomTag.ScheduledProcedureStepDescription, entry.ScheduledProcedureStepDescription ?? "");
        spsItem.AddOrUpdate(DicomTag.ScheduledProcedureStepID, entry.AccessionNumber);

        spsSequence.Items.Add(spsItem);
        dataset.Add(spsSequence);

        dataset.AddOrUpdate(DicomTag.RequestedProcedureID, entry.RequestedProcedureID ?? entry.AccessionNumber);
        dataset.AddOrUpdate(DicomTag.AccessionNumber, entry.AccessionNumber);
        if (!string.IsNullOrEmpty(entry.ReferringPhysicianName))
            dataset.AddOrUpdate(DicomTag.ReferringPhysicianName, entry.ReferringPhysicianName);

        if (!string.IsNullOrEmpty(entry.StudyInstanceUID))
            dataset.AddOrUpdate(DicomTag.StudyInstanceUID, entry.StudyInstanceUID);
        else
            dataset.AddOrUpdate(DicomTag.StudyInstanceUID, DicomUID.Generate().UID);

        return dataset;
    }
}
