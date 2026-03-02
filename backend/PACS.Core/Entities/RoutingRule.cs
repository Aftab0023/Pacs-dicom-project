namespace PACS.Core.Entities;

public class RoutingRule
{
    public int RuleID { get; set; }
    public string RuleName { get; set; } = string.Empty;
    public int Priority { get; set; } = 100;
    public bool IsActive { get; set; } = true;
    public string Conditions { get; set; } = string.Empty; // JSON
    public string Actions { get; set; } = string.Empty; // JSON
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime ModifiedDate { get; set; } = DateTime.UtcNow;
    public int? CreatedBy { get; set; }
    
    // Navigation properties
    public User? Creator { get; set; }
    public ICollection<StudyAssignment> StudyAssignments { get; set; } = new List<StudyAssignment>();
}

public class StudyAssignment
{
    public int AssignmentID { get; set; }
    public string StudyInstanceUID { get; set; } = string.Empty;
    public int AssignedToUserID { get; set; }
    public DateTime AssignedDate { get; set; } = DateTime.UtcNow;
    public int? AssignedByRuleID { get; set; }
    public string Priority { get; set; } = "ROUTINE"; // STAT, URGENT, ROUTINE
    public string Status { get; set; } = "PENDING"; // PENDING, IN_PROGRESS, COMPLETED
    public bool NotificationSent { get; set; } = false;
    
    // Navigation properties
    public User AssignedToUser { get; set; } = null!;
    public RoutingRule? AssignedByRule { get; set; }
}
