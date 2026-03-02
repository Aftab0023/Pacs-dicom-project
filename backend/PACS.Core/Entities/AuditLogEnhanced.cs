namespace PACS.Core.Entities;

public class AuditLogEnhanced
{
    public long AuditID { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string EventCategory { get; set; } = string.Empty; // AUTH, STUDY_ACCESS, CONFIG, DICOM, WORKLIST, ROUTING
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public int? UserID { get; set; }
    public string? Username { get; set; }
    public string? IPAddress { get; set; }
    public string? UserAgent { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? ResourceType { get; set; }
    public string? ResourceID { get; set; }
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public string? AdditionalData { get; set; } // JSON
    public string? Signature { get; set; } // HMAC signature
    
    // Navigation properties
    public User? User { get; set; }
}
