using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;

namespace PACS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Radiologist,Admin")]
public class ReportController : ControllerBase
{
    private readonly IReportService _reportService;
    private readonly IAuditService _auditService;

    public ReportController(IReportService reportService, IAuditService auditService)
    {
        _reportService = reportService;
        _auditService = auditService;
    }

    [HttpGet("{reportId}")]
    public async Task<ActionResult<ReportDto>> GetReport(int reportId)
    {
        var report = await _reportService.GetReportAsync(reportId);
        if (report == null)
            return NotFound();

        return Ok(report);
    }

    [HttpGet("study/{studyId}")]
    public async Task<ActionResult<List<ReportDto>>> GetStudyReports(int studyId)
    {
        var reports = await _reportService.GetStudyReportsAsync(studyId);
        return Ok(reports);
    }

    [HttpPost]
    public async Task<ActionResult<ReportDto>> CreateReport([FromBody] CreateReportRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var report = await _reportService.CreateReportAsync(userId, request);

        await _auditService.LogAsync(
            userId,
            "CreateReport",
            "Report",
            report.ReportId.ToString(),
            "Created new report",
            HttpContext.Connection.RemoteIpAddress?.ToString() ?? ""
        );

        return CreatedAtAction(nameof(GetReport), new { reportId = report.ReportId }, report);
    }

    [HttpPut("{reportId}")]
    public async Task<ActionResult<ReportDto>> UpdateReport(int reportId, [FromBody] UpdateReportRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var report = await _reportService.UpdateReportAsync(reportId, userId, request);

        if (report == null)
            return NotFound();

        await _auditService.LogAsync(
            userId,
            "UpdateReport",
            "Report",
            reportId.ToString(),
            "Updated report",
            HttpContext.Connection.RemoteIpAddress?.ToString() ?? ""
        );

        return Ok(report);
    }

    [HttpPost("{reportId}/finalize")]
    public async Task<ActionResult> FinalizeReport(int reportId, [FromBody] FinalizeReportRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var success = await _reportService.FinalizeReportAsync(reportId, userId, request);

        if (!success)
            return NotFound();

        await _auditService.LogAsync(
            userId,
            "FinalizeReport",
            "Report",
            reportId.ToString(),
            "Finalized report",
            HttpContext.Connection.RemoteIpAddress?.ToString() ?? ""
        );

        return Ok(new { message = "Report finalized successfully" });
    }

    [HttpGet("{reportId}/pdf")]
    public async Task<ActionResult> DownloadPdf(int reportId)
    {
        var pdf = await _reportService.GenerateReportPdfAsync(reportId);
        if (pdf == null) return NotFound();
        return File(pdf, "application/pdf", $"report_{reportId}.txt");
    }

    
}
