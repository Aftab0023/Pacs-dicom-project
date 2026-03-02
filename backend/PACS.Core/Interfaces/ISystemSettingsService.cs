using PACS.Core.DTOs;

namespace PACS.Core.Interfaces;

public interface ISystemSettingsService
{
    Task<List<SystemSettingResponse>> GetAllSettingsAsync();
    Task<List<SystemSettingResponse>> GetSettingsByCategoryAsync(string category);
    Task<SystemSettingResponse?> GetSettingAsync(string key);
    Task<string?> GetSettingValueAsync(string key);
    Task<T?> GetSettingValueAsync<T>(string key);
    Task<bool> UpdateSettingAsync(string key, string value, int updatedBy);
    Task<bool> BulkUpdateSettingsAsync(Dictionary<string, string> settings, int updatedBy);
    Task<ReportSettingsResponse> GetReportSettingsAsync();
}
