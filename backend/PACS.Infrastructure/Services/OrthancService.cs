using System.Net.Http.Json;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PACS.Core.DTOs;
using PACS.Core.Entities;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class OrthancService : IOrthancService
{
    private readonly HttpClient _httpClient;
    private readonly PACSDbContext _context;
    private readonly ILogger<OrthancService> _logger;
    private readonly string _orthancUrl;

    public OrthancService(HttpClient httpClient, PACSDbContext context, IConfiguration configuration, ILogger<OrthancService> logger)
    {
        _httpClient = httpClient;
        _context = context;
        _logger = logger;
        _orthancUrl = configuration["Orthanc:Url"] ?? "http://localhost:8042";

        var username = configuration["Orthanc:Username"] ?? "orthanc";
        var password = configuration["Orthanc:Password"] ?? "orthanc";
        var credentials = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{username}:{password}"));
        _httpClient.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", credentials);
    }

    public async Task<OrthancStudyMetadata?> GetStudyMetadataAsync(string orthancStudyId)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<OrthancStudyMetadata>($"{_orthancUrl}/studies/{orthancStudyId}");
        }
        catch { return null; }
    }

    public async Task<OrthancPatientMetadata?> GetPatientMetadataAsync(string orthancPatientId)
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<OrthancPatientMetadata>($"{_orthancUrl}/patients/{orthancPatientId}");
        }
        catch { return null; }
    }

    public async Task ProcessNewStudyAsync(string orthancStudyId)
    {
        try
        {
            _logger.LogInformation("Processing study: {Id}", orthancStudyId);

            var studyMetadata = await GetStudyMetadataAsync(orthancStudyId);
            if (studyMetadata == null)
            {
                _logger.LogWarning("Could not retrieve metadata for: {Id}", orthancStudyId);
                return;
            }

            var studyInstanceUID = studyMetadata.MainDicomTags.GetValueOrDefault("StudyInstanceUID", "");

            // Fast duplicate check
            if (await _context.Studies.AnyAsync(s => s.StudyInstanceUID == studyInstanceUID))
            {
                _logger.LogInformation("Study already exists: {UID}", studyInstanceUID);
                return;
            }

            var patientName    = studyMetadata.PatientMainDicomTags.GetValueOrDefault("PatientName", "");
            var patientId      = studyMetadata.PatientMainDicomTags.GetValueOrDefault("PatientID", "");
            var patientBirth   = studyMetadata.PatientMainDicomTags.GetValueOrDefault("PatientBirthDate", "");
            var patientSex     = studyMetadata.PatientMainDicomTags.GetValueOrDefault("PatientSex", "");
            var nameParts      = patientName.Split('^');
            var lastName       = nameParts.Length > 0 ? nameParts[0] : "";
            var firstName      = nameParts.Length > 1 ? nameParts[1] : "";

            // Find or create patient — single query
            var patient = await _context.Patients.FirstOrDefaultAsync(p => p.MRN == patientId);
            if (patient == null)
            {
                patient = new Patient
                {
                    MRN       = string.IsNullOrEmpty(patientId) ? Guid.NewGuid().ToString("N")[..20] : patientId,
                    FirstName = firstName,
                    LastName  = lastName,
                    DateOfBirth = ParseDicomDate(patientBirth),
                    Gender    = patientSex,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Patients.Add(patient);
                await _context.SaveChangesAsync(); // only 1 save for patient
            }

            // Create study immediately — this is what shows in the worklist
            var study = new Study
            {
                StudyInstanceUID = studyInstanceUID,
                PatientId        = patient.PatientId,
                StudyDate        = ParseDicomDate(studyMetadata.MainDicomTags.GetValueOrDefault("StudyDate", "")),
                Modality         = studyMetadata.MainDicomTags.GetValueOrDefault("Modality", ""),
                Description      = studyMetadata.MainDicomTags.GetValueOrDefault("StudyDescription", ""),
                AccessionNumber  = studyMetadata.MainDicomTags.GetValueOrDefault("AccessionNumber", ""),
                OrthancStudyId   = orthancStudyId,
                Status           = "Pending",
                IsPriority       = false,
                CreatedAt        = DateTime.UtcNow
            };
            _context.Studies.Add(study);
            await _context.SaveChangesAsync(); // study visible in worklist NOW

            _logger.LogInformation("Study {Id} saved to DB instantly, processing series in background", study.StudyId);

            // Process series/instances in background — doesn't block worklist visibility
            _ = Task.Run(() => ProcessSeriesInBackgroundAsync(studyMetadata.Series, study.StudyId, orthancStudyId));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing study {Id}", orthancStudyId);
            throw;
        }
    }

    private async Task ProcessSeriesInBackgroundAsync(List<string> seriesIds, int studyId, string orthancStudyId)
    {
        try
        {
            // Fetch all series metadata in parallel
            var seriesTasks = seriesIds.Select(id =>
                _httpClient.GetFromJsonAsync<Dictionary<string, object>>($"{_orthancUrl}/series/{id}")
            ).ToList();

            var allSeriesData = await Task.WhenAll(seriesTasks);

            var seriesList = new List<Series>();
            var instanceMap = new Dictionary<string, List<string>>(); // seriesInstanceUID -> instanceIds

            for (int i = 0; i < seriesIds.Count; i++)
            {
                var seriesData = allSeriesData[i];
                if (seriesData == null) continue;

                var tags = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(
                    seriesData["MainDicomTags"].ToString() ?? "{}");
                var instanceIds = System.Text.Json.JsonSerializer.Deserialize<List<string>>(
                    seriesData["Instances"].ToString() ?? "[]") ?? new();

                var seriesInstanceUID = tags?.GetValueOrDefault("SeriesInstanceUID", "") ?? "";
                var seriesNumber = int.TryParse(tags?.GetValueOrDefault("SeriesNumber", "0"), out var sn) ? sn : 0;

                var series = new Series
                {
                    SeriesInstanceUID = seriesInstanceUID,
                    StudyId           = studyId,
                    Modality          = tags?.GetValueOrDefault("Modality", "") ?? "",
                    BodyPart          = tags?.GetValueOrDefault("BodyPartExamined", "") ?? "",
                    SeriesNumber      = seriesNumber,
                    Description       = tags?.GetValueOrDefault("SeriesDescription", "") ?? "",
                    CreatedAt         = DateTime.UtcNow
                };
                seriesList.Add(series);
                instanceMap[seriesInstanceUID] = instanceIds;
            }

            // Bulk insert all series in one SaveChanges
            _context.Series.AddRange(seriesList);
            await _context.SaveChangesAsync();

            // Fetch all instance metadata in parallel across all series
            var allInstanceTasks = new List<Task<(int SeriesId, string SOPInstanceUID, int InstanceNumber)>>();

            foreach (var series in seriesList)
            {
                var instanceIds = instanceMap.GetValueOrDefault(series.SeriesInstanceUID, new());
                foreach (var instanceId in instanceIds)
                {
                    var capturedId = instanceId;
                    var capturedSeriesId = series.SeriesId;
                    allInstanceTasks.Add(Task.Run(async () =>
                    {
                        var data = await _httpClient.GetFromJsonAsync<Dictionary<string, object>>(
                            $"{_orthancUrl}/instances/{capturedId}");
                        var tags = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(
                            data?["MainDicomTags"].ToString() ?? "{}");
                        var sop = tags?.GetValueOrDefault("SOPInstanceUID", "") ?? "";
                        var num = int.TryParse(tags?.GetValueOrDefault("InstanceNumber", "0"), out var n) ? n : 0;
                        return (capturedSeriesId, sop, num);
                    }));
                }
            }

            var instanceResults = await Task.WhenAll(allInstanceTasks);

            // Bulk insert all instances in one SaveChanges
            var instances = instanceResults.Select(r => new Instance
            {
                SOPInstanceUID = r.SOPInstanceUID,
                SeriesId       = r.SeriesId,
                InstanceNumber = r.InstanceNumber,
                FilePath       = $"/orthanc/instances/{r.SOPInstanceUID}",
                FileSize       = 0,
                CreatedAt      = DateTime.UtcNow
            }).ToList();

            _context.Instances.AddRange(instances);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Background processing complete for study {Id}: {S} series, {I} instances",
                studyId, seriesList.Count, instances.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Background series processing failed for study {Id}", studyId);
        }
    }

    public async Task<string> GetDicomWebUrlAsync(string studyInstanceUID)
    {
        return $"{_orthancUrl}/dicom-web";
    }

    private static DateTime ParseDicomDate(string dicomDate)
    {
        if (string.IsNullOrEmpty(dicomDate) || dicomDate.Length < 8)
            return DateTime.UtcNow;
        try
        {
            return new DateTime(
                int.Parse(dicomDate[..4]),
                int.Parse(dicomDate.Substring(4, 2)),
                int.Parse(dicomDate.Substring(6, 2)));
        }
        catch { return DateTime.UtcNow; }
    }
}
