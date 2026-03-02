using PACS.Core.Entities;

namespace PACS.Core.Interfaces;

public interface IAuditServiceEnhanced
{
    Task LogAsync(AuditEvent auditEvent);
    Task<List<AuditLogEnhanced>> QueryAuditLogsAsync(AuditLogQueryRequest request);
    Task ArchiveOldLogsAsync(int daysToKeep = 90);
}

public class AuditEvent
{
    public string EventType { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public int? UserID { get; set; }
    public string? Username { get; set; }
    public string? IPAddress { get; set; }
    public string? UserAgent { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? ResourceType { get; set; }
    public string? ResourceID { get; set; }
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public Dictionary<string, object>? AdditionalData { get; set; }
}

public class AuditLogQueryRequest
{
    public int? UserID { get; set; }
    public string? EventType { get; set; }
    public string? EventCategory { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? ResourceID { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 100;
}

// Audit Event Types
public static class AuditEventTypes
{
    // Authentication
    public const string AUTH_LOGIN_SUCCESS = "AUTH_LOGIN_SUCCESS";
    public const string AUTH_LOGIN_FAILED = "AUTH_LOGIN_FAILED";
    public const string AUTH_LOGOUT = "AUTH_LOGOUT";
    public const string AUTH_TOKEN_REFRESH = "AUTH_TOKEN_REFRESH";
    
    // Study Access
    public const string STUDY_VIEW = "STUDY_VIEW";
    public const string STUDY_DOWNLOAD = "STUDY_DOWNLOAD";
    public const string STUDY_DELETE = "STUDY_DELETE";
    public const string STUDY_SHARE = "STUDY_SHARE";
    public const string STUDY_PRINT = "STUDY_PRINT";
    public const string STUDY_EXPORT = "STUDY_EXPORT";
    
    // Report
    public const string REPORT_CREATE = "REPORT_CREATE";
    public const string REPORT_EDIT = "REPORT_EDIT";
    public const string REPORT_FINALIZE = "REPORT_FINALIZE";
    public const string REPORT_DELETE = "REPORT_DELETE";
    
    // Configuration
    public const string CONFIG_CHANGE = "CONFIG_CHANGE";
    public const string USER_CREATE = "USER_CREATE";
    public const string USER_MODIFY = "USER_MODIFY";
    public const string USER_DELETE = "USER_DELETE";
    public const string ROLE_CREATE = "ROLE_CREATE";
    public const string ROLE_MODIFY = "ROLE_MODIFY";
    public const string PERMISSION_GRANT = "PERMISSION_GRANT";
    public const string PERMISSION_REVOKE = "PERMISSION_REVOKE";
    
    // DICOM
    public const string DICOM_RECEIVE = "DICOM_RECEIVE";
    public const string DICOM_SEND = "DICOM_SEND";
    public const string DICOM_QUERY = "DICOM_QUERY";
    
    // Worklist
    public const string WORKLIST_CREATE = "WORKLIST_CREATE";
    public const string WORKLIST_MODIFY = "WORKLIST_MODIFY";
    public const string WORKLIST_DELETE = "WORKLIST_DELETE";
    public const string WORKLIST_QUERY = "WORKLIST_QUERY";
    
    // Routing
    public const string ROUTING_RULE_CREATE = "ROUTING_RULE_CREATE";
    public const string ROUTING_RULE_MODIFY = "ROUTING_RULE_MODIFY";
    public const string ROUTING_RULE_DELETE = "ROUTING_RULE_DELETE";
    public const string ROUTING_EVALUATE = "ROUTING_EVALUATE";
    public const string STUDY_ASSIGN = "STUDY_ASSIGN";
}

// Audit Event Categories
public static class AuditEventCategories
{
    public const string AUTH = "AUTH";
    public const string STUDY_ACCESS = "STUDY_ACCESS";
    public const string CONFIG = "CONFIG";
    public const string DICOM = "DICOM";
    public const string WORKLIST = "WORKLIST";
    public const string ROUTING = "ROUTING";
    public const string REPORT = "REPORT";
}
