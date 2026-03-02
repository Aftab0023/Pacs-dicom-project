namespace PACS.Core.DTOs;

public class CreatePatientShareRequest
{
    public string StudyInstanceUID { get; set; } = string.Empty;
    public string? PatientEmail { get; set; }
    public int ExpiresInHours { get; set; } = 24;
    public bool AllowDownload { get; set; } = false;
    public bool RequireAuthentication { get; set; } = false;
    public string? CustomMessage { get; set; }
}

public class PatientShareResponse
{
    public int ShareID { get; set; }
    public string StudyInstanceUID { get; set; } = string.Empty;
    public string ShareToken { get; set; } = string.Empty;
    public string ShareUrl { get; set; } = string.Empty;
    public string? PatientEmail { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool IsActive { get; set; }
    public bool AllowDownload { get; set; }
    public bool RequireAuthentication { get; set; }
    public string? CustomMessage { get; set; }
    public int CreatedBy { get; set; }
    public string CreatedByName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public string? RevokeReason { get; set; }
}

public class PatientShareAccessRequest
{
    public string ShareToken { get; set; } = string.Empty;
    public string? IPAddress { get; set; }
    public string? UserAgent { get; set; }
}

public class PatientShareAccessResponse
{
    public bool IsValid { get; set; }
    public string? ErrorMessage { get; set; }
    public PatientShareData? ShareData { get; set; }
}

public class PatientShareData
{
    public string StudyInstanceUID { get; set; } = string.Empty;
    public string? PatientEmail { get; set; }
    public string? CustomMessage { get; set; }
    public bool AllowDownload { get; set; }
    public DateTime ExpiresAt { get; set; }
    public string ShareToken { get; set; } = string.Empty;
}

public class RevokePatientShareRequest
{
    public int ShareID { get; set; }
    public string? Reason { get; set; }
}

public class PatientShareStatistics
{
    public int TotalShares { get; set; }
    public int ActiveShares { get; set; }
    public int ExpiredShares { get; set; }
    public int TotalAccesses { get; set; }
    public List<PatientShareResponse> RecentShares { get; set; } = new();
}
