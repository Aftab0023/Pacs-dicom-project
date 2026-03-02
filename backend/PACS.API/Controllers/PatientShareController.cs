using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;
using System.Security.Claims;

namespace PACS.API.Controllers;

[Authorize]
[ApiController]
[Route("api/viewer")]
public class PatientShareController : ControllerBase
{
    private readonly IPatientShareService _patientShareService;
    private readonly ILogger<PatientShareController> _logger;

    public PatientShareController(
        IPatientShareService patientShareService,
        ILogger<PatientShareController> logger)
    {
        _patientShareService = patientShareService;
        _logger = logger;
    }

    [HttpPost("share")]
    public async Task<ActionResult<PatientShareResponse>> CreateShare([FromBody] CreatePatientShareRequest request)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var share = await _patientShareService.CreateShareAsync(request, userId);
            return Ok(share);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating patient share");
            return StatusCode(500, new { message = "Failed to create share link" });
        }
    }

    [AllowAnonymous]
    [HttpGet("share/{shareToken}")]
    public async Task<ActionResult<PatientShareResponse>> GetShare(string shareToken)
    {
        try
        {
            var share = await _patientShareService.GetShareByTokenAsync(shareToken);
            if (share == null)
                return NotFound(new { message = "Share link not found or expired" });

            return Ok(share);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving share");
            return StatusCode(500, new { message = "Failed to retrieve share" });
        }
    }

    [HttpDelete("share/{shareToken}")]
    public async Task<ActionResult> RevokeShare(string shareToken)
    {
        try
        {
            var share = await _patientShareService.GetShareByTokenAsync(shareToken);
            if (share == null)
                return NotFound(new { message = "Share not found" });

            var success = await _patientShareService.RevokeShareAsync(share.ShareID, "Revoked by user");
            if (success)
                return Ok(new { message = "Share link revoked successfully" });

            return BadRequest(new { message = "Failed to revoke share" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error revoking share");
            return StatusCode(500, new { message = "Failed to revoke share" });
        }
    }

    [HttpPost("send-to-patient")]
    public async Task<ActionResult> SendToPatient([FromBody] SendToPatientRequest request)
    {
        try
        {
            var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            
            // Create share
            var createRequest = new CreatePatientShareRequest
            {
                StudyInstanceUID = request.StudyInstanceUID,
                PatientEmail = request.PatientEmail,
                ExpiresInHours = request.ExpiresInHours ?? 24,
                AllowDownload = false,
                RequireAuthentication = false,
                CustomMessage = request.Message
            };

            var share = await _patientShareService.CreateShareAsync(createRequest, userId);
            
            // Send notification
            await _patientShareService.SendShareNotificationAsync(share.ShareID);

            return Ok(new { message = "Study link sent to patient successfully", shareId = share.ShareID });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending to patient");
            return StatusCode(500, new { message = "Failed to send to patient" });
        }
    }

    [AllowAnonymous]
    [HttpPost("access")]
    public async Task<ActionResult<PatientShareAccessResponse>> AccessShare([FromBody] PatientShareAccessRequest request)
    {
        try
        {
            var response = await _patientShareService.ValidateAndAccessShareAsync(request);
            if (!response.IsValid)
                return BadRequest(response);

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error accessing share");
            return StatusCode(500, new { message = "Failed to access share" });
        }
    }
}

public class SendToPatientRequest
{
    public string StudyInstanceUID { get; set; } = string.Empty;
    public string PatientEmail { get; set; } = string.Empty;
    public string? Message { get; set; }
    public int? ExpiresInHours { get; set; }
}
