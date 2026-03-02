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
    DateTime? FinalizedAt,
    StudyDetailsDto? Study = null
);

public record StudyDetailsDto(
    string StudyInstanceUID,
    DateTime StudyDate,
    string Modality,
    string Description,
    PatientDetailsDto Patient
);

public record PatientDetailsDto(
    string FirstName,
    string LastName,
    string MRN,
    DateTime DateOfBirth,
    string Gender
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
