namespace PACS.Core.Entities;

public class ReportTemplate
{
    public int TemplateId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Specialty { get; set; } = string.Empty; // CT, MRI, XR, US
    public string Modality { get; set; } = string.Empty;
    public string TemplateContent { get; set; } = string.Empty; // JSON structure
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // Navigation
    public ICollection<Report> Reports { get; set; } = new List<Report>();
}

public class ReportVersion
{
    public int VersionId { get; set; }
    public int ReportId { get; set; }
    public int VersionNumber { get; set; }
    public string ReportText { get; set; } = string.Empty;
    public string Findings { get; set; } = string.Empty;
    public string Impression { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public string ChangeReason { get; set; } = string.Empty; // Addendum, Correction, Update
    
    // Navigation
    public Report Report { get; set; } = null!;
    public User CreatedByUser { get; set; } = null!;
}
