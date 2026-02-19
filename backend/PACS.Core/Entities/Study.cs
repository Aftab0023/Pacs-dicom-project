namespace PACS.Core.Entities;

public class Study
{
    public int StudyId { get; set; }
    public string StudyInstanceUID { get; set; } = string.Empty;
    public int PatientId { get; set; }
    public DateTime StudyDate { get; set; }
    public string Modality { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string AccessionNumber { get; set; } = string.Empty;
    public string OrthancStudyId { get; set; } = string.Empty;

    // CHECK HERE: Ensure these two lines only exist once!
    public string Status { get; set; } = "Pending"; 
    public bool IsPriority { get; set; }

    public int? AssignedRadiologistId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public Patient Patient { get; set; } = null!;
    public User? AssignedRadiologist { get; set; }
    public ICollection<Series> Series { get; set; } = new List<Series>();
    public ICollection<Report> Reports { get; set; } = new List<Report>();
}