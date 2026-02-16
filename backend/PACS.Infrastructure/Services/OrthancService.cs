using System.Net.Http.Json;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using PACS.Core.DTOs;
using PACS.Core.Entities;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class OrthancService : IOrthancService
{
    private readonly HttpClient _httpClient;
    private readonly PACSDbContext _context;
    private readonly string _orthancUrl;

    public OrthancService(HttpClient httpClient, PACSDbContext context, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _context = context;
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
        var studyMetadata = await GetStudyMetadataAsync(orthancStudyId);
        if (studyMetadata == null) return;

        var patientMetadata = await GetPatientMetadataAsync(studyMetadata.ParentPatient);
        if (patientMetadata == null) return;

        // Extract DICOM tags
        var studyInstanceUID = studyMetadata.MainDicomTags.GetValueOrDefault("StudyInstanceUID", "");
        var studyDate = studyMetadata.MainDicomTags.GetValueOrDefault("StudyDate", "");
        var studyDescription = studyMetadata.MainDicomTags.GetValueOrDefault("StudyDescription", "");
        var accessionNumber = studyMetadata.MainDicomTags.GetValueOrDefault("AccessionNumber", "");

        var patientName = patientMetadata.MainDicomTags.GetValueOrDefault("PatientName", "");
        var patientId = patientMetadata.MainDicomTags.GetValueOrDefault("PatientID", "");
        var patientBirthDate = patientMetadata.MainDicomTags.GetValueOrDefault("PatientBirthDate", "");
        var patientSex = patientMetadata.MainDicomTags.GetValueOrDefault("PatientSex", "");

        // Parse patient name (DICOM format: LastName^FirstName)
        var nameParts = patientName.Split('^');
        var lastName = nameParts.Length > 0 ? nameParts[0] : "";
        var firstName = nameParts.Length > 1 ? nameParts[1] : "";

        // Check if study already exists
        var existingStudy = await _context.Studies.FirstOrDefaultAsync(s => s.StudyInstanceUID == studyInstanceUID);
        if (existingStudy != null) return;

        // Find or create patient
        var patient = await _context.Patients.FirstOrDefaultAsync(p => p.MRN == patientId);
        if (patient == null)
        {
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
        }

        // Create study
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

        // Process series
        foreach (var seriesId in studyMetadata.Series)
        {
            await ProcessSeriesAsync(seriesId, study.StudyId);
        }
    }

    private async Task ProcessSeriesAsync(string orthancSeriesId, int studyId)
    {
        try
        {
            var seriesData = await _httpClient.GetFromJsonAsync<Dictionary<string, object>>($"{_orthancUrl}/series/{orthancSeriesId}");
            if (seriesData == null) return;

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

            // Process instances
            if (instances != null)
            {
                foreach (var instanceId in instances)
                {
                    await ProcessInstanceAsync(instanceId, series.SeriesId);
                }
            }
        }
        catch { }
    }

    private async Task ProcessInstanceAsync(string orthancInstanceId, int seriesId)
    {
        try
        {
            var instanceData = await _httpClient.GetFromJsonAsync<Dictionary<string, object>>($"{_orthancUrl}/instances/{orthancInstanceId}");
            if (instanceData == null) return;

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
        }
        catch { }
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
