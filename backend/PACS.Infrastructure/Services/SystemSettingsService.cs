using Microsoft.EntityFrameworkCore;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;
using System.Text.Json;

namespace PACS.Infrastructure.Services;

public class SystemSettingsService : ISystemSettingsService
{
    private readonly PACSDbContext _context;

    public SystemSettingsService(PACSDbContext context)
    {
        _context = context;
    }

    public async Task<List<SystemSettingResponse>> GetAllSettingsAsync()
    {
        var settings = await _context.SystemSettings
            .Include(s => s.UpdatedByUser)
            .OrderBy(s => s.Category)
            .ThenBy(s => s.SettingKey)
            .ToListAsync();

        return settings.Select(MapToResponse).ToList();
    }

    public async Task<List<SystemSettingResponse>> GetSettingsByCategoryAsync(string category)
    {
        var settings = await _context.SystemSettings
            .Include(s => s.UpdatedByUser)
            .Where(s => s.Category == category)
            .OrderBy(s => s.SettingKey)
            .ToListAsync();

        return settings.Select(MapToResponse).ToList();
    }

    public async Task<SystemSettingResponse?> GetSettingAsync(string key)
    {
        var setting = await _context.SystemSettings
            .Include(s => s.UpdatedByUser)
            .FirstOrDefaultAsync(s => s.SettingKey == key);

        return setting != null ? MapToResponse(setting) : null;
    }

    public async Task<string?> GetSettingValueAsync(string key)
    {
        var setting = await _context.SystemSettings
            .FirstOrDefaultAsync(s => s.SettingKey == key);

        return setting?.SettingValue;
    }

    public async Task<T?> GetSettingValueAsync<T>(string key)
    {
        var value = await GetSettingValueAsync(key);
        if (value == null) return default;

        try
        {
            if (typeof(T) == typeof(string))
                return (T)(object)value;
            
            if (typeof(T) == typeof(int))
                return (T)(object)int.Parse(value);
            
            if (typeof(T) == typeof(bool))
                return (T)(object)bool.Parse(value);
            
            if (typeof(T) == typeof(decimal))
                return (T)(object)decimal.Parse(value);

            // For complex types, try JSON deserialization
            return JsonSerializer.Deserialize<T>(value);
        }
        catch
        {
            return default;
        }
    }

    public async Task<bool> UpdateSettingAsync(string key, string value, int updatedBy)
    {
        var setting = await _context.SystemSettings
            .FirstOrDefaultAsync(s => s.SettingKey == key);

        if (setting == null || !setting.IsEditable)
            return false;

        setting.SettingValue = value;
        setting.UpdatedAt = DateTime.UtcNow;
        setting.UpdatedBy = updatedBy;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> BulkUpdateSettingsAsync(Dictionary<string, string> settings, int updatedBy)
    {
        var keys = settings.Keys.ToList();
        var dbSettings = await _context.SystemSettings
            .Where(s => keys.Contains(s.SettingKey) && s.IsEditable)
            .ToListAsync();

        foreach (var setting in dbSettings)
        {
            if (settings.TryGetValue(setting.SettingKey, out var value))
            {
                setting.SettingValue = value;
                setting.UpdatedAt = DateTime.UtcNow;
                setting.UpdatedBy = updatedBy;
            }
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<ReportSettingsResponse> GetReportSettingsAsync()
    {
        var reportSettings = await _context.SystemSettings
            .Where(s => s.Category == "Report")
            .ToDictionaryAsync(s => s.SettingKey, s => s.SettingValue ?? string.Empty);

        return new ReportSettingsResponse
        {
            InstitutionName = GetValue(reportSettings, "Report.InstitutionName", "Life Relief Medical PACS"),
            ReportTitle = GetValue(reportSettings, "Report.ReportTitle", "Radiology Report"),
            DepartmentName = GetValue(reportSettings, "Report.DepartmentName", "Department of Radiology"),
            InstitutionAddress = GetValue(reportSettings, "Report.InstitutionAddress", ""),
            InstitutionPhone = GetValue(reportSettings, "Report.InstitutionPhone", ""),
            InstitutionEmail = GetValue(reportSettings, "Report.InstitutionEmail", ""),
            LogoUrl = GetValue(reportSettings, "Report.LogoUrl", ""),
            FooterText = GetValue(reportSettings, "Report.FooterText", ""),
            DigitalSignatureText = GetValue(reportSettings, "Report.DigitalSignatureText", "Electronically signed by"),
            ShowWatermark = bool.Parse(GetValue(reportSettings, "Report.ShowWatermark", "false")),
            WatermarkText = GetValue(reportSettings, "Report.WatermarkText", "CONFIDENTIAL")
        };
    }

    private string GetValue(Dictionary<string, string> dict, string key, string defaultValue)
    {
        return dict.TryGetValue(key, out var value) ? value : defaultValue;
    }

    private SystemSettingResponse MapToResponse(Core.Entities.SystemSetting setting)
    {
        return new SystemSettingResponse
        {
            SettingID = setting.SettingID,
            SettingKey = setting.SettingKey,
            SettingValue = setting.SettingValue,
            SettingType = setting.SettingType,
            Category = setting.Category,
            Description = setting.Description,
            IsEditable = setting.IsEditable,
            UpdatedAt = setting.UpdatedAt,
            UpdatedByName = setting.UpdatedByUser?.Username
        };
    }
}
