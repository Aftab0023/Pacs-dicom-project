namespace PACS.Core.Entities;

public class User
{
    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty; // Admin, Radiologist, Referrer
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }

    // Navigation
    public ICollection<Study> AssignedStudies { get; set; } = new List<Study>();
    public ICollection<Report> Reports { get; set; } = new List<Report>();
    public ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();
}
