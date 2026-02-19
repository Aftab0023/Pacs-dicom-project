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
        _httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", credentials);
    }

    public async Task<OrthancStudyMetadata?> GetStudyMetadataAsync(string orthancStudyId)
    {
        try
        {
            var response = await _httpClient.GetFromJsonAsync<OrthancStudyMetadata>($"{_orthancUrl}/studies/{orthancStudyId}");
            return response;
        }
        catch
        {
            return null;
        }
    }

    public async Task<OrthancPatientMetadata?> GetPatientMetadataAsync(string orthancPatientId)
    {
        try
        {
            var response = await _httpClient.GetFromJsonAsync<OrthancPatientMetadata>($"{_orthancUrl}/patients/{orthancPatientId}");
            return response;
        }
        catch
        {
            return null;
        }
    }

    public async Task ProcessNewStudyAsync(string orthancStudyId)
    {
        try
        {
            _logger.LogInformation($"Starting to process study: {orthancStudyId}");
            
            var studyMetadata = await GetStudyMetadataAsync(orthancStudyId);
            if (studyMetadata == null)
            {
                _logger.LogWarning($"Could not retrieve study metadata for: {orthancStudyId}");
                return;
            }

            // Extract DICOM tags from study
            var studyInstanceUID = studyMetadata.MainDicomTags.GetValueOrDefault("StudyInstanceUID", "");
            var studyDate = studyMetadata.MainDicomTags.GetValueOrDefault("StudyDate", "");
            var studyDescription = studyMetadata.MainDicomTags.GetValueOrDefault("StudyDescription", "");
            var accessionNumber = studyMetadata.MainDicomTags.GetValueOrDefault("AccessionNumber", "");

            // Extract patient tags from study (Orthanc includes them)
            var patientName = studyMetadata.PatientMainDicomTags.GetValueOrDefault("PatientName", "");
            var patientId = studyMetadata.PatientMainDicomTags.GetValueOrDefault("PatientID", "");
            var patientBirthDate = studyMetadata.PatientMainDicomTags.GetValueOrDefault("PatientBirthDate", "");
            var patientSex = studyMetadata.PatientMainDicomTags.GetValueOrDefault("PatientSex", "");

            _logger.LogInformation($"Processing study UID: {studyInstanceUID}, Patient: {patientName}");

            // Parse patient name (DICOM format: LastName^FirstName)
            var nameParts = patientName.Split('^');
            var lastName = nameParts.Length > 0 ? nameParts[0] : "";
            var firstName = nameParts.Length > 1 ? nameParts[1] : "";

            // Check if study already exists
            var existingStudy = await _context.Studies.FirstOrDefaultAsync(s => s.StudyInstanceUID == studyInstanceUID);
            if (existingStudy != null)
            {
                _logger.LogInformation($"Study already exists: {studyInstanceUID}");
                return;
            }

            // Find or create patient
            var patient = await _context.Patients.FirstOrDefaultAsync(p => p.MRN == patientId);
            if (patient == null)
            {
                _logger.LogInformation($"Creating new patient: {patientId}");
                patient = new Patient
                {
                    MRN = patientId,
                    FirstName = firstName,
                    LastName = lastName,
                    DateOfBirth = ParseDicomDate(patientBirthDate),
                    Gender = patientSex,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Patients.Add(patient);
                await _context.SaveChangesAsync();
                _logger.LogInformation($"Patient created with ID: {patient.PatientId}");
            }

            // Create study
            _logger.LogInformation($"Creating study for patient ID: {patient.PatientId}");
            var study = new Study
            {
                StudyInstanceUID = studyInstanceUID,
                PatientId = patient.PatientId,
                StudyDate = ParseDicomDate(studyDate),
                Modality = studyMetadata.MainDicomTags.GetValueOrDefault("Modality", ""),
                Description = studyDescription,
                AccessionNumber = accessionNumber,
                OrthancStudyId = orthancStudyId,
                Status = "Pending",
                IsPriority = false,
                CreatedAt = DateTime.UtcNow
            };
            _context.Studies.Add(study);
            await _context.SaveChangesAsync();
            _logger.LogInformation($"Study created with ID: {study.StudyId}");

            // Process series
            _logger.LogInformation($"Processing {studyMetadata.Series.Count} series");
            foreach (var seriesId in studyMetadata.Series)
            {
                await ProcessSeriesAsync(seriesId, study.StudyId);
            }
            
            _logger.LogInformation($"Successfully completed processing study: {orthancStudyId}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error processing study {orthancStudyId}: {ex.Message}");
            throw;
        }
    }

    private async Task ProcessSeriesAsync(string orthancSeriesId, int studyId)
    {
        try
        {
            _logger.LogInformation($"Processing series: {orthancSeriesId}");
            
            var seriesData = await _httpClient.GetFromJsonAsync<Dictionary<string, object>>($"{_orthancUrl}/series/{orthancSeriesId}");
            if (seriesData == null)
            {
                _logger.LogWarning($"Could not retrieve series data for: {orthancSeriesId}");
                return;
            }

            var mainDicomTags = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(seriesData["MainDicomTags"].ToString() ?? "{}");
            var instances = System.Text.Json.JsonSerializer.Deserialize<List<string>>(seriesData["Instances"].ToString() ?? "[]");

            var seriesInstanceUID = mainDicomTags?.GetValueOrDefault("SeriesInstanceUID", "") ?? "";
            var seriesNumber = int.TryParse(mainDicomTags?.GetValueOrDefault("SeriesNumber", "0"), out var sn) ? sn : 0;

            var series = new Series
            {
                SeriesInstanceUID = seriesInstanceUID,
                StudyId = studyId,
                Modality = mainDicomTags?.GetValueOrDefault("Modality", "") ?? "",
                BodyPart = mainDicomTags?.GetValueOrDefault("BodyPartExamined", "") ?? "",
                SeriesNumber = seriesNumber,
                Description = mainDicomTags?.GetValueOrDefault("SeriesDescription", "") ?? "",
                CreatedAt = DateTime.UtcNow
            };
            _context.Series.Add(series);
            await _context.SaveChangesAsync();
            _logger.LogInformation($"Series created with ID: {series.SeriesId}");

            // Process instances
            if (instances != null && instances.Count > 0)
            {
                _logger.LogInformation($"Processing {instances.Count} instances");
                foreach (var instanceId in instances)
                {
                    await ProcessInstanceAsync(instanceId, series.SeriesId);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error processing series {orthancSeriesId}: {ex.Message}");
            throw;
        }
    }

    private async Task ProcessInstanceAsync(string orthancInstanceId, int seriesId)
    {
        try
        {
            var instanceData = await _httpClient.GetFromJsonAsync<Dictionary<string, object>>($"{_orthancUrl}/instances/{orthancInstanceId}");
            if (instanceData == null)
            {
                _logger.LogWarning($"Could not retrieve instance data for: {orthancInstanceId}");
                return;
            }

            var mainDicomTags = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(instanceData["MainDicomTags"].ToString() ?? "{}");

            var sopInstanceUID = mainDicomTags?.GetValueOrDefault("SOPInstanceUID", "") ?? "";
            var instanceNumber = int.TryParse(mainDicomTags?.GetValueOrDefault("InstanceNumber", "0"), out var num) ? num : 0;

            var instance = new Instance
            {
                SOPInstanceUID = sopInstanceUID,
                SeriesId = seriesId,
                InstanceNumber = instanceNumber,
                FilePath = $"/orthanc/instances/{orthancInstanceId}",
                FileSize = 0,
                CreatedAt = DateTime.UtcNow
            };
            _context.Instances.Add(instance);
            await _context.SaveChangesAsync();
            _logger.LogInformation($"Instance created: {sopInstanceUID}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error processing instance {orthancInstanceId}: {ex.Message}");
            throw;
        }
    }

    public async Task<string> GetDicomWebUrlAsync(string studyInstanceUID)
    {
        return $"{_orthancUrl}/dicom-web";
    }

    private DateTime ParseDicomDate(string dicomDate)
    {
        if (string.IsNullOrEmpty(dicomDate) || dicomDate.Length < 8)
            return DateTime.UtcNow;

        try
        {
            var year = int.Parse(dicomDate.Substring(0, 4));
            var month = int.Parse(dicomDate.Substring(4, 2));
            var day = int.Parse(dicomDate.Substring(6, 2));
            return new DateTime(year, month, day);
        }
        catch
        {
            return DateTime.UtcNow;
        }
    }
}
