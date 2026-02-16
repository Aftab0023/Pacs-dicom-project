namespace PACS.Core.Entities;

public class Instance
{
    public int InstanceId { get; set; }
    public string SOPInstanceUID { get; set; } = string.Empty;
    public int SeriesId { get; set; }
    public int InstanceNumber { get; set; }
    public string FilePath { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public DateTime CreatedAt { get; set; }

    // Navigation
    public Series Series { get; set; } = null!;
}
