namespace PACS.Core.DTOs;

public record ReportDto(
    int ReportId,
    int StudyId,
    string RadiologistName,
    string Status,
    string ReportText,
    string Findings,
    string Impression,
    DateTime CreatedAt,
    DateTime? FinalizedAt
);

public record CreateReportRequest(
    int StudyId,
    string ReportText,
    string Findings,
    string Impression
);

public record UpdateReportRequest(
    string ReportText,
    string Findings,
    string Impression
);

public record FinalizeReportRequest(
    string DigitalSignature
);
