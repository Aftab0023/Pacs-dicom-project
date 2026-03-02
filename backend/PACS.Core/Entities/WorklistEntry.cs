namespace PACS.Core.Entities;

public class WorklistEntry
{
    public int WorklistID { get; set; }
    public string AccessionNumber { get; set; } = string.Empty;
    public string PatientID { get; set; } = string.Empty;
    public string PatientName { get; set; } = string.Empty;
    public DateTime? PatientBirthDate { get; set; }
    public string? PatientSex { get; set; }
    public DateTime ScheduledProcedureStepStartDate { get; set; }
    public TimeSpan? ScheduledProcedureStepStartTime { get; set; }
    public string Modality { get; set; } = string.Empty;
    public string? ScheduledStationAETitle { get; set; }
    public string? ScheduledProcedureStepDescription { get; set; }
    public string? StudyInstanceUID { get; set; }
    public string? RequestedProcedureID { get; set; }
    public string? ReferringPhysicianName { get; set; }
    public string Status { get; set; } = "SCHEDULED"; // SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedDate { get; set; }
    public int? CreatedBy { get; set; }
    
    // Navigation properties
    public User? Creator { get; set; }
}
