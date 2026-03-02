namespace PACS.Core.DTOs;

public class SystemSettingResponse
{
    public int SettingID { get; set; }
    public string SettingKey { get; set; } = string.Empty;
    public string? SettingValue { get; set; }
    public string SettingType { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsEditable { get; set; }
    public DateTime UpdatedAt { get; set; }
    public string? UpdatedByName { get; set; }
}

public class UpdateSystemSettingRequest
{
    public string SettingKey { get; set; } = string.Empty;
    public string SettingValue { get; set; } = string.Empty;
}

public class BulkUpdateSettingsRequest
{
    public Dictionary<string, string> Settings { get; set; } = new();
}

public class ReportSettingsResponse
{
    public string InstitutionName { get; set; } = string.Empty;
    public string ReportTitle { get; set; } = string.Empty;
    public string DepartmentName { get; set; } = string.Empty;
    public string InstitutionAddress { get; set; } = string.Empty;
    public string InstitutionPhone { get; set; } = string.Empty;
    public string InstitutionEmail { get; set; } = string.Empty;
    public string? LogoUrl { get; set; }
    public string FooterText { get; set; } = string.Empty;
    public string DigitalSignatureText { get; set; } = string.Empty;
    public bool ShowWatermark { get; set; }
    public string WatermarkText { get; set; } = string.Empty;
}
