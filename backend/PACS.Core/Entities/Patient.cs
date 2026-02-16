namespace PACS.Core.Entities;

public class Patient
{
    public int PatientId { get; set; }
    public string MRN { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
    public string Gender { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    // Navigation
    public ICollection<Study> Studies { get; set; } = new List<Study>();
}
