namespace PACS.Core.DTOs;

public record OrthancWebhookPayload(
    string ChangeType,
    string ID,
    string Path,
    string ResourceType,
    int Seq
);

public record OrthancStudyMetadata(
    string ID,
    bool IsStable,
    DateTime LastUpdate,
    Dictionary<string, string> MainDicomTags,
    string ParentPatient,
    List<string> Series,
    string Type
);

public record OrthancPatientMetadata(
    string ID,
    Dictionary<string, string> MainDicomTags,
    List<string> Studies,
    string Type
);
