using PACS.Core.DTOs;

namespace PACS.Core.Interfaces;

public interface IReportService
{
    Task<ReportDto?> GetReportAsync(int reportId);
    Task<List<ReportDto>> GetStudyReportsAsync(int studyId);
    Task<ReportDto> CreateReportAsync(int radiologistId, CreateReportRequest request);
    Task<ReportDto?> UpdateReportAsync(int reportId, int radiologistId, UpdateReportRequest request);
    Task<bool> FinalizeReportAsync(int reportId, int radiologistId, FinalizeReportRequest request);
    Task<byte[]?> GenerateReportPdfAsync(int reportId);
}
