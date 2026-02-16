using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;

namespace PACS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class WorklistController : ControllerBase
{
    private readonly IStudyService _studyService;
    private readonly IAuditService _auditService;

    public WorklistController(IStudyService studyService, IAuditService auditService)
    {
        _studyService = studyService;
        _auditService = auditService;
    }

    [HttpGet]
    public async Task<ActionResult> GetWorklist([FromQuery] WorklistFilterDto filter)
    {
        var (studies, totalCount) = await _studyService.GetWorklistAsync(filter);

        return Ok(new
        {
            studies,
            totalCount,
            page = filter.Page,
            pageSize = filter.PageSize,
            totalPages = (int)Math.Ceiling(totalCount / (double)filter.PageSize)
        });
    }

    [HttpGet("{studyId}")]
    public async Task<ActionResult<StudyDetailDto>> GetStudyDetail(int studyId)
    {
        var study = await _studyService.GetStudyDetailAsync(studyId);
        if (study == null)
            return NotFound();

        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        await _auditService.LogAsync(
            userId,
            "ViewStudy",
            "Study",
            studyId.ToString(),
            "Viewed study details",
            HttpContext.Connection.RemoteIpAddress?.ToString() ?? ""
        );

        return Ok(study);
    }

    [HttpPost("{studyId}/assign")]
    [Authorize(Roles = "Admin,Radiologist")]
    public async Task<ActionResult> AssignStudy(int studyId, [FromBody] AssignStudyRequest request)
    {
        var success = await _studyService.AssignStudyAsync(studyId, request.RadiologistId);
        if (!success)
            return NotFound();

        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        await _auditService.LogAsync(
            userId,
            "AssignStudy",
            "Study",
            studyId.ToString(),
            $"Assigned to radiologist {request.RadiologistId}",
            HttpContext.Connection.RemoteIpAddress?.ToString() ?? ""
        );

        return Ok(new { message = "Study assigned successfully" });
    }

    [HttpPut("{studyId}/status")]
    [Authorize(Roles = "Admin,Radiologist")]
    public async Task<ActionResult> UpdateStatus(int studyId, [FromBody] UpdateStatusRequest request)
    {
        var success = await _studyService.UpdateStudyStatusAsync(studyId, request.Status);
        if (!success)
            return NotFound();

        return Ok(new { message = "Status updated successfully" });
    }

    [HttpPut("{studyId}/priority")]
    [Authorize(Roles = "Admin,Radiologist")]
    public async Task<ActionResult> SetPriority(int studyId, [FromBody] SetPriorityRequest request)
    {
        var success = await _studyService.SetStudyPriorityAsync(studyId, request.IsPriority);
        if (!success)
            return NotFound();

        return Ok(new { message = "Priority updated successfully" });
    }
}

public record AssignStudyRequest(int RadiologistId);
public record UpdateStatusRequest(string Status);
public record SetPriorityRequest(bool IsPriority);
