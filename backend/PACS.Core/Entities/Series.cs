namespace PACS.Core.Entities;

public class Series
{
    public int SeriesId { get; set; }
    public string SeriesInstanceUID { get; set; } = string.Empty;
    public int StudyId { get; set; }
    public string Modality { get; set; } = string.Empty;
    public string BodyPart { get; set; } = string.Empty;
    public int SeriesNumber { get; set; }
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }

    // Navigation
    public Study Study { get; set; } = null!;
    public ICollection<Instance> Instances { get; set; } = new List<Instance>();
}
