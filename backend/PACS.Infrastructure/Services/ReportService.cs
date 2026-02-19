using Microsoft.EntityFrameworkCore;
using PACS.Core.DTOs;
using PACS.Core.Entities;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace PACS.Infrastructure.Services;

public class ReportService : IReportService
{
    private readonly PACSDbContext _context;

    public ReportService(PACSDbContext context)
    {
        _context = context;
    }

    public async Task<ReportDto?> GetReportAsync(int reportId)
    {
        var report = await _context.Reports
            .Include(r => r.Radiologist)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

        return report == null ? null : MapToDto(report);
    }

    public async Task<List<ReportDto>> GetStudyReportsAsync(int studyId)
    {
        var reports = await _context.Reports
            .Include(r => r.Radiologist)
            .Where(r => r.StudyId == studyId)
            .ToListAsync();

        return reports.Select(MapToDto).ToList();
    }

    public async Task<ReportDto> CreateReportAsync(int radiologistId, CreateReportRequest request)
    {
        var report = new Report
        {
            StudyId = request.StudyId,
            RadiologistId = radiologistId,
            Status = "Draft",
            ReportText = request.ReportText,
            Findings = request.Findings,
            Impression = request.Impression,
            CreatedAt = DateTime.UtcNow
        };

        _context.Reports.Add(report);
        await _context.SaveChangesAsync();

        // Update study status
        var study = await _context.Studies.FindAsync(request.StudyId);
        if (study != null)
        {
            study.Status = "InProgress";
            study.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        return (await GetReportAsync(report.ReportId))!;
    }

    public async Task<ReportDto?> UpdateReportAsync(int reportId, int radiologistId, UpdateReportRequest request)
    {
        var report = await _context.Reports.FindAsync(reportId);
        if (report == null || report.RadiologistId != radiologistId || report.Status == "Final")
            return null;

        report.ReportText = request.ReportText;
        report.Findings = request.Findings;
        report.Impression = request.Impression;

        await _context.SaveChangesAsync();
        return await GetReportAsync(reportId);
    }

    public async Task<bool> FinalizeReportAsync(int reportId, int radiologistId, FinalizeReportRequest request)
    {
        var report = await _context.Reports
            .Include(r => r.Study)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

        if (report == null || report.RadiologistId != radiologistId || report.Status == "Final")
            return false;

        report.Status = "Final";
        report.FinalizedAt = DateTime.UtcNow;
        report.DigitalSignature = request.DigitalSignature;

        // Update study status
        report.Study.Status = "Reported";
        report.Study.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<byte[]?> GenerateReportPdfAsync(int reportId)
    {
        var report = await _context.Reports
            .Include(r => r.Study).ThenInclude(s => s.Patient)
            .Include(r => r.Radiologist)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

        if (report == null) return null;

        // NOTE: For a real PDF, you'd use: return QuestPDF.Fluent.Document.Create(...).GeneratePdf();
        // For now, let's ensure the content is formatted as a formal document
        var sb = new System.Text.StringBuilder();
        sb.AppendLine("=================================================");
        sb.AppendLine("           LIFE RELIER MEDICAL PACS              ");
        sb.AppendLine("               RADIOLOGY REPORT                  ");
        sb.AppendLine("=================================================");
        sb.AppendLine($"Patient:    {report.Study.Patient.LastName}, {report.Study.Patient.FirstName}");
        sb.AppendLine($"MRN:        {report.Study.Patient.MRN}");
        sb.AppendLine($"Study Date: {report.Study.StudyDate:yyyy-MM-dd}");
        sb.AppendLine($"Modality:   {report.Study.Modality}");
        sb.AppendLine("-------------------------------------------------");
        sb.AppendLine("FINDINGS:");
        sb.AppendLine(report.Findings);
        sb.AppendLine();
        sb.AppendLine("IMPRESSION:");
        sb.AppendLine(report.Impression);
        sb.AppendLine("-------------------------------------------------");
        sb.AppendLine($"Radiologist: {report.Radiologist.FirstName} {report.Radiologist.LastName}");
        sb.AppendLine($"Status:      {report.Status}");
        sb.AppendLine($"Digital Sig: {report.DigitalSignature ?? "NOT FINALIZED"}");
        sb.AppendLine("=================================================");

        return System.Text.Encoding.UTF8.GetBytes(sb.ToString());
    }

    private ReportDto MapToDto(Report report)
    {
        return new ReportDto(
            report.ReportId,
            report.StudyId,
            $"{report.Radiologist.FirstName} {report.Radiologist.LastName}",
            report.Status,
            report.ReportText,
            report.Findings,
            report.Impression,
            report.CreatedAt,
            report.FinalizedAt
        );
    }
}
