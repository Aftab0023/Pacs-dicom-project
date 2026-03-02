using PACS.Core.DTOs;

namespace PACS.Core.Interfaces;

public interface IPatientShareService
{
    Task<PatientShareResponse> CreateShareAsync(CreatePatientShareRequest request, int createdBy);
    Task<PatientShareResponse?> GetShareAsync(int shareId);
    Task<PatientShareResponse?> GetShareByTokenAsync(string shareToken);
    Task<List<PatientShareResponse>> GetPatientSharesAsync(int patientId);
    Task<List<PatientShareResponse>> GetStudySharesAsync(string studyInstanceUID);
    Task<PatientShareAccessResponse> ValidateAndAccessShareAsync(PatientShareAccessRequest request);
    Task<bool> RevokeShareAsync(int shareId, string? reason);
    Task<bool> SendShareNotificationAsync(int shareId); // Email/SMS notification
    Task<PatientShareStatistics> GetShareStatisticsAsync(int? userId = null);
    Task DeactivateExpiredSharesAsync(); // Background job
}
