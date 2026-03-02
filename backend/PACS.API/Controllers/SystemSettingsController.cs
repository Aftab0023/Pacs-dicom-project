using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PACS.API.Authorization;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;
using System.Security.Claims;

namespace PACS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SystemSettingsController : ControllerBase
{
    private readonly ISystemSettingsService _settingsService;

    public SystemSettingsController(ISystemSettingsService settingsService)
    {
        _settingsService = settingsService;
    }

    /// <summary>
    /// Get all system settings (Admin only)
    /// </summary>
    [HttpGet]
    [RequireRole("Admin")]
    public async Task<ActionResult<List<SystemSettingResponse>>> GetAllSettings()
    {
        var settings = await _settingsService.GetAllSettingsAsync();
        return Ok(settings);
    }

    /// <summary>
    /// Get settings by category
    /// </summary>
    [HttpGet("category/{category}")]
    [RequireRole("Admin", "Radiologist")]
    public async Task<ActionResult<List<SystemSettingResponse>>> GetSettingsByCategory(string category)
    {
        var settings = await _settingsService.GetSettingsByCategoryAsync(category);
        return Ok(settings);
    }

    /// <summary>
    /// Get report settings (accessible by all authenticated users)
    /// </summary>
    [HttpGet("report")]
    public async Task<ActionResult<ReportSettingsResponse>> GetReportSettings()
    {
        var settings = await _settingsService.GetReportSettingsAsync();
        return Ok(settings);
    }

    /// <summary>
    /// Get specific setting by key
    /// </summary>
    [HttpGet("{key}")]
    [RequireRole("Admin")]
    public async Task<ActionResult<SystemSettingResponse>> GetSetting(string key)
    {
        var setting = await _settingsService.GetSettingAsync(key);
        
        if (setting == null)
            return NotFound(new { message = "Setting not found" });

        return Ok(setting);
    }

    /// <summary>
    /// Update a single setting (Admin only)
    /// </summary>
    [HttpPut("{key}")]
    [RequireRole("Admin")]
    public async Task<ActionResult> UpdateSetting(string key, [FromBody] UpdateSystemSettingRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        
        var success = await _settingsService.UpdateSettingAsync(key, request.SettingValue, userId);
        
        if (!success)
            return BadRequest(new { message = "Setting not found or not editable" });

        return Ok(new { message = "Setting updated successfully" });
    }

    /// <summary>
    /// Bulk update settings (Admin only)
    /// </summary>
    [HttpPut("bulk")]
    [RequireRole("Admin")]
    public async Task<ActionResult> BulkUpdateSettings([FromBody] BulkUpdateSettingsRequest request)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        
        var success = await _settingsService.BulkUpdateSettingsAsync(request.Settings, userId);
        
        if (!success)
            return BadRequest(new { message = "Failed to update settings" });

        return Ok(new { message = $"{request.Settings.Count} settings updated successfully" });
    }

    /// <summary>
    /// Update report settings (Admin only)
    /// </summary>
    [HttpPut("report")]
    [RequireRole("Admin")]
    public async Task<ActionResult> UpdateReportSettings([FromBody] ReportSettingsResponse settings)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        
        var settingsDict = new Dictionary<string, string>
        {
            { "Report.InstitutionName", settings.InstitutionName },
            { "Report.ReportTitle", settings.ReportTitle },
            { "Report.DepartmentName", settings.DepartmentName },
            { "Report.InstitutionAddress", settings.InstitutionAddress },
            { "Report.InstitutionPhone", settings.InstitutionPhone },
            { "Report.InstitutionEmail", settings.InstitutionEmail },
            { "Report.LogoUrl", settings.LogoUrl ?? "" },
            { "Report.FooterText", settings.FooterText },
            { "Report.DigitalSignatureText", settings.DigitalSignatureText },
            { "Report.ShowWatermark", settings.ShowWatermark.ToString().ToLower() },
            { "Report.WatermarkText", settings.WatermarkText }
        };

        var success = await _settingsService.BulkUpdateSettingsAsync(settingsDict, userId);
        
        if (!success)
            return BadRequest(new { message = "Failed to update report settings" });

        return Ok(new { message = "Report settings updated successfully" });
    }
}
