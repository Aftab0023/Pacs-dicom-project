namespace PACS.Core.Entities;

public class Report
{
    public int ReportId { get; set; }
    public int StudyId { get; set; }
    public int RadiologistId { get; set; }
    public int? TemplateId { get; set; }
    public string Status { get; set; } = "Draft"; // Draft, Final, Addendum
    public string ReportText { get; set; } = string.Empty;
    public string Findings { get; set; } = string.Empty;
    public string Impression { get; set; } = string.Empty;
    public string Technique { get; set; } = string.Empty;
    public string ClinicalHistory { get; set; } = string.Empty;
    public string Comparison { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? FinalizedAt { get; set; }
    public string? DigitalSignature { get; set; }
    public string? SignatureHash { get; set; }
    public DateTime? SignedAt { get; set; }
    public int CurrentVersion { get; set; } = 1;

    // Navigation
    public Study Study { get; set; } = null!;
    public User Radiologist { get; set; } = null!;
    public ReportTemplate? Template { get; set; }
}
