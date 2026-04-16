using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
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
    private readonly ISystemSettingsService _settingsService;
    private readonly IMemoryCache _cache;

    private static readonly MemoryCacheEntryOptions ReportCache = new MemoryCacheEntryOptions()
        .SetAbsoluteExpiration(TimeSpan.FromMinutes(2))
        .SetSize(1);

    public ReportService(PACSDbContext context, ISystemSettingsService settingsService, IMemoryCache cache)
    {
        _context         = context;
        _settingsService = settingsService;
        _cache           = cache;
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public async Task<ReportDto?> GetReportAsync(int reportId)
    {
        var key = $"report:{reportId}";
        if (_cache.TryGetValue(key, out ReportDto? cached) && cached != null)
            return cached;

        var report = await _context.Reports
            .AsNoTracking()
            .Include(r => r.Radiologist)
            .Include(r => r.Study).ThenInclude(s => s.Patient)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

        if (report == null) return null;
        var dto = MapToDto(report);
        _cache.Set(key, dto, ReportCache);
        return dto;
    }

    public async Task<List<ReportDto>> GetStudyReportsAsync(int studyId)
    {
        var key = $"report:study:{studyId}";
        if (_cache.TryGetValue(key, out List<ReportDto>? cached) && cached != null)
            return cached;

        var reports = await _context.Reports
            .AsNoTracking()
            .Include(r => r.Radiologist)
            .Include(r => r.Study).ThenInclude(s => s.Patient)
            .Where(r => r.StudyId == studyId)
            .ToListAsync();

        var dtos = reports.Select(MapToDto).ToList();
        _cache.Set(key, dtos, ReportCache);
        return dtos;
    }

    public async Task<ReportDto> CreateReportAsync(int radiologistId, CreateReportRequest request)
    {
        var report = new Report
        {
            StudyId       = request.StudyId,
            RadiologistId = radiologistId,
            Status        = "Draft",
            ReportText    = request.ReportText,
            Findings      = request.Findings,
            Impression    = request.Impression,
            CreatedAt     = DateTime.UtcNow
        };

        _context.Reports.Add(report);
        await _context.SaveChangesAsync();

        var study = await _context.Studies.FindAsync(request.StudyId);
        if (study != null)
        {
            study.Status    = "InProgress";
            study.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        _cache.Remove($"report:study:{request.StudyId}");
        return (await GetReportAsync(report.ReportId))!;
    }

    public async Task<ReportDto?> UpdateReportAsync(int reportId, int radiologistId, UpdateReportRequest request)
    {
        var report = await _context.Reports.FindAsync(reportId);
        if (report == null || report.RadiologistId != radiologistId || report.Status == "Final")
            return null;

        report.ReportText  = request.ReportText;
        report.Findings    = request.Findings;
        report.Impression  = request.Impression;
        await _context.SaveChangesAsync();

        _cache.Remove($"report:{reportId}");
        _cache.Remove($"report:study:{report.StudyId}");
        return await GetReportAsync(reportId);
    }

    public async Task<bool> FinalizeReportAsync(int reportId, int radiologistId, FinalizeReportRequest request)
    {
        var report = await _context.Reports
            .Include(r => r.Study)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

        if (report == null || report.RadiologistId != radiologistId || report.Status == "Final")
            return false;

        report.Status           = "Final";
        report.FinalizedAt      = DateTime.UtcNow;
        report.DigitalSignature = request.DigitalSignature;
        report.Study.Status     = "Reported";
        report.Study.UpdatedAt  = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        _cache.Remove($"report:{reportId}");
        _cache.Remove($"report:study:{report.StudyId}");
        return true;
    }

    public async Task<byte[]?> GenerateReportPdfAsync(int reportId)
    {
        var report = await _context.Reports
            .Include(r => r.Study).ThenInclude(s => s.Patient)
            .Include(r => r.Radiologist)
            .FirstOrDefaultAsync(r => r.ReportId == reportId);

        if (report == null) return null;

        // Get system settings for report customization
        var settings = await _settingsService.GetReportSettingsAsync();

        // Generate professional PDF using QuestPDF
        var pdfBytes = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(2, Unit.Centimetre);
                page.PageColor(Colors.White);
                page.DefaultTextStyle(x => x.FontSize(11).FontFamily("Arial"));

                // Header
                page.Header().Element(c => ComposeHeader(c, settings, report));

                // Content
                page.Content().Element(c => ComposeContent(c, report));

                // Footer
                page.Footer().Element(c => ComposeFooter(c, settings, report));
            });
        }).GeneratePdf();

        return pdfBytes;
    }

    private void ComposeHeader(IContainer container, ReportSettingsResponse settings, Report report)
    {
        container.Column(column =>
        {
            column.Spacing(5);

            // Institution name and logo
            column.Item().Row(row =>
            {
                row.RelativeItem().Column(col =>
                {
                    col.Item().Text(text =>
                    {
                        text.Span(settings.InstitutionName).FontSize(18).Bold().FontColor(Colors.Blue.Darken2);
                    });
                    
                    col.Item().Text(text =>
                    {
                        text.Span(settings.DepartmentName).FontSize(12).FontColor(Colors.Grey.Darken1);
                    });
                    
                    if (!string.IsNullOrEmpty(settings.InstitutionAddress))
                    {
                        col.Item().Text(text =>
                        {
                            text.Span(settings.InstitutionAddress).FontSize(9).FontColor(Colors.Grey.Medium);
                        });
                    }
                    
                    if (!string.IsNullOrEmpty(settings.InstitutionPhone))
                    {
                        col.Item().Text(text =>
                        {
                            text.Span($"Phone: {settings.InstitutionPhone}").FontSize(9).FontColor(Colors.Grey.Medium);
                        });
                    }
                });

                // Logo placeholder (if URL provided)
                if (!string.IsNullOrEmpty(settings.LogoUrl))
                {
                    row.ConstantItem(80).Height(60).Border(1).BorderColor(Colors.Grey.Lighten2);
                }
            });

            // Report title
            column.Item().PaddingTop(10).PaddingBottom(5)
                .AlignCenter()
                .Text(text =>
                {
                    text.Span(settings.ReportTitle).FontSize(16).Bold().FontColor(Colors.Blue.Darken3);
                });

            // Divider
            column.Item().LineHorizontal(2).LineColor(Colors.Blue.Medium);
        });
    }

    private void ComposeContent(IContainer container, Report report)
    {
        container.PaddingVertical(10).Column(column =>
        {
            column.Spacing(10);

            // Patient Information Section
            column.Item().Element(c => ComposeSection(c, "PATIENT INFORMATION", container =>
            {
                container.Column(col =>
                {
                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Text(text =>
                        {
                            text.Span($"Name: {report.Study.Patient.FirstName} {report.Study.Patient.LastName}").Bold();
                        });
                        row.RelativeItem().Text(text =>
                        {
                            text.Span($"MRN: {report.Study.Patient.MRN}");
                        });
                    });
                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Text(text =>
                        {
                            text.Span($"DOB: {report.Study.Patient.DateOfBirth:yyyy-MM-dd}");
                        });
                        row.RelativeItem().Text(text =>
                        {
                            text.Span($"Gender: {report.Study.Patient.Gender}");
                        });
                    });
                });
            }));

            // Study Information Section
            column.Item().Element(c => ComposeSection(c, "STUDY INFORMATION", container =>
            {
                container.Column(col =>
                {
                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Text(text =>
                        {
                            text.Span($"Study Date: {report.Study.StudyDate:yyyy-MM-dd HH:mm}");
                        });
                        row.RelativeItem().Text(text =>
                        {
                            text.Span($"Modality: {report.Study.Modality}").Bold();
                        });
                    });
                    col.Item().Text(text =>
                    {
                        text.Span($"Description: {report.Study.Description}");
                    });
                    col.Item().Text(text =>
                    {
                        text.Span($"Study UID: {report.Study.StudyInstanceUID}").FontSize(8).FontColor(Colors.Grey.Medium);
                    });
                });
            }));

            // Clinical History (if available)
            if (!string.IsNullOrEmpty(report.ReportText))
            {
                column.Item().Element(c => ComposeSection(c, "CLINICAL HISTORY", container =>
                {
                    container.Text(text =>
                    {
                        text.Span(report.ReportText).FontSize(10);
                    });
                }));
            }

            // Findings Section
            column.Item().Element(c => ComposeSection(c, "FINDINGS", container =>
            {
                container.Text(text =>
                {
                    text.Span(report.Findings ?? "No findings documented.").FontSize(10);
                });
            }));

            // Impression Section
            column.Item().Element(c => ComposeSection(c, "IMPRESSION", container =>
            {
                container.Text(text =>
                {
                    text.Span(report.Impression ?? "No impression documented.").FontSize(10).Bold();
                });
            }));

            // Signature Section
            column.Item().PaddingTop(20).Element(c => ComposeSignature(c, report));
        });
    }

    private void ComposeSection(IContainer container, string title, Action<IContainer> content)
    {
        container.Column(column =>
        {
            column.Item().Background(Colors.Blue.Lighten4).Padding(5)
                .Text(text =>
                {
                    text.Span(title).FontSize(11).Bold().FontColor(Colors.Blue.Darken3);
                });
            
            column.Item().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10)
                .Element(content);
        });
    }

    private void ComposeSignature(IContainer container, Report report)
    {
        var settings = _settingsService.GetReportSettingsAsync().Result;
        
        container.Column(column =>
        {
            column.Spacing(5);
            
            column.Item().BorderTop(1).BorderColor(Colors.Grey.Medium).PaddingTop(10);
            
            column.Item().Row(row =>
            {
                row.RelativeItem().Column(col =>
                {
                    col.Item().Text(text =>
                    {
                        text.Span($"{settings.DigitalSignatureText}:").FontSize(10).FontColor(Colors.Grey.Darken1);
                    });
                    
                    col.Item().Text(text =>
                    {
                        text.Span($"Dr. {report.Radiologist.FirstName} {report.Radiologist.LastName}").FontSize(11).Bold();
                    });
                    
                    if (report.Status == "Final" && report.FinalizedAt.HasValue)
                    {
                        col.Item().Text(text =>
                        {
                            text.Span($"Finalized: {report.FinalizedAt.Value:yyyy-MM-dd HH:mm} UTC").FontSize(9).FontColor(Colors.Grey.Medium);
                        });
                        
                        if (!string.IsNullOrEmpty(report.DigitalSignature))
                        {
                            col.Item().Text(text =>
                            {
                                text.Span($"Signature: {report.DigitalSignature}").FontSize(8).FontColor(Colors.Grey.Medium).Italic();
                            });
                        }
                    }
                    else
                    {
                        col.Item().Text(text =>
                        {
                            text.Span("Status: DRAFT - NOT FINALIZED").FontSize(10).FontColor(Colors.Red.Medium).Bold();
                        });
                    }
                });

                row.ConstantItem(150).AlignRight().Column(col =>
                {
                    col.Item().Text(text =>
                    {
                        text.Span($"Report ID: {report.ReportId}").FontSize(9).FontColor(Colors.Grey.Medium);
                    });
                    
                    col.Item().Text(text =>
                    {
                        text.Span($"Created: {report.CreatedAt:yyyy-MM-dd}").FontSize(9).FontColor(Colors.Grey.Medium);
                    });
                });
            });
        });
    }

    private void ComposeFooter(IContainer container, ReportSettingsResponse settings, Report report)
    {
        container.Column(column =>
        {
            column.Item().LineHorizontal(1).LineColor(Colors.Grey.Lighten1);
            
            column.Item().PaddingTop(5).Row(row =>
            {
                row.RelativeItem().Text(text =>
                {
                    text.Span(settings.FooterText).FontSize(8).FontColor(Colors.Grey.Medium).Italic();
                });
                
                row.ConstantItem(100).AlignRight().Text(text =>
                {
                    text.Span("Page ").FontSize(8).FontColor(Colors.Grey.Medium);
                    text.CurrentPageNumber().FontSize(8).FontColor(Colors.Grey.Medium);
                    text.Span(" of ").FontSize(8).FontColor(Colors.Grey.Medium);
                    text.TotalPages().FontSize(8).FontColor(Colors.Grey.Medium);
                });
            });

            // Watermark if enabled
            if (settings.ShowWatermark && !string.IsNullOrEmpty(settings.WatermarkText))
            {
                column.Item().AlignCenter().Text(text => 
                {
                    text.Span(settings.WatermarkText).FontSize(60).FontColor(Colors.Grey.Lighten3).Bold();
                });
            }
        });
    }

    private ReportDto MapToDto(Report report)
    {
        StudyDetailsDto? studyDetails = null;
        
        if (report.Study != null)
        {
            studyDetails = new StudyDetailsDto(
                report.Study.StudyInstanceUID,
                report.Study.StudyDate,
                report.Study.Modality,
                report.Study.Description,
                new PatientDetailsDto(
                    report.Study.Patient.FirstName,
                    report.Study.Patient.LastName,
                    report.Study.Patient.MRN,
                    report.Study.Patient.DateOfBirth,
                    report.Study.Patient.Gender
                )
            );
        }

        return new ReportDto(
            report.ReportId,
            report.StudyId,
            $"{report.Radiologist.FirstName} {report.Radiologist.LastName}",
            report.Status,
            report.ReportText,
            report.Findings,
            report.Impression,
            report.CreatedAt,
            report.FinalizedAt,
            studyDetails
        );
    }
}
