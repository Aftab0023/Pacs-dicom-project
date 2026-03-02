namespace PACS.Core.Entities;

public class PatientShare
{
    public int ShareID { get; set; }
    public string StudyInstanceUID { get; set; } = string.Empty;
    public int? PatientID { get; set; }
    public string ShareToken { get; set; } = string.Empty;
    public string? PatientEmail { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool IsActive { get; set; } = true;
    public bool AllowDownload { get; set; } = false;
    public bool RequireAuthentication { get; set; } = false;
    public string? CustomMessage { get; set; }
    public int CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RevokedAt { get; set; }
    public string? RevokeReason { get; set; }
    
    // Navigation properties
    public Patient? Patient { get; set; }
    public User CreatedByUser { get; set; } = null!;
    public ICollection<PatientShareAccess> AccessLogs { get; set; } = new List<PatientShareAccess>();
}

public class PatientShareAccess
{
    public int AccessID { get; set; }
    public int ShareID { get; set; }
    public DateTime AccessedAt { get; set; } = DateTime.UtcNow;
    public string? IPAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? Location { get; set; }
    public string Action { get; set; } = string.Empty; // VIEW, DOWNLOAD, PRINT
    
    // Navigation properties
    public PatientShare Share { get; set; } = null!;
}
