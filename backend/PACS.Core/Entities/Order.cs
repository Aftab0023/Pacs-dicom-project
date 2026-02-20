namespace PACS.Core.Entities;

public class Order
{
    public int OrderId { get; set; }
    public string AccessionNumber { get; set; } = string.Empty;
    public int PatientId { get; set; }
    public string OrderingPhysician { get; set; } = string.Empty;
    public string ReferringPhysician { get; set; } = string.Empty;
    public string Modality { get; set; } = string.Empty;
    public string StudyDescription { get; set; } = string.Empty;
    public DateTime ScheduledDateTime { get; set; }
    public string Status { get; set; } = "Scheduled"; // Scheduled, InProgress, Completed, Cancelled
    public string Priority { get; set; } = "Routine"; // Routine, Urgent, STAT
    public string HL7MessageId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // Navigation
    public Patient Patient { get; set; } = null!;
    public Study? Study { get; set; }
}
