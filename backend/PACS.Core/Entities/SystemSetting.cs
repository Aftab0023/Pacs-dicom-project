namespace PACS.Core.Entities;

public class SystemSetting
{
    public int SettingID { get; set; }
    public string SettingKey { get; set; } = string.Empty;
    public string? SettingValue { get; set; }
    public string SettingType { get; set; } = "String"; // String, Number, Boolean, JSON
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsEditable { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    
    // Navigation property
    public User? UpdatedByUser { get; set; }
}
