namespace PACS.Core.DTOs;

public record StudyDto(
    int StudyId,
    string StudyInstanceUID,
    string PatientName,
    string MRN,
    DateTime StudyDate,
    string Modality,
    string Description,
    string AccessionNumber,
    string Status,
    bool IsPriority,
    string? AssignedRadiologist,
    int SeriesCount,
    int InstanceCount
);

public record StudyDetailDto(
    int StudyId,
    string StudyInstanceUID,
    PatientDto Patient,
    DateTime StudyDate,
    string Modality,
    string Description,
    string AccessionNumber,
    string Status,
    bool IsPriority,
    UserDto? AssignedRadiologist,
    List<SeriesDto> Series,
    List<ReportDto> Reports
);

public record PatientDto(
    int PatientId,
    string MRN,
    string FirstName,
    string LastName,
    DateTime DateOfBirth,
    string Gender
);

public record SeriesDto(
    int SeriesId,
    string SeriesInstanceUID,
    string Modality,
    string BodyPart,
    int SeriesNumber,
    string Description,
    int InstanceCount
);

public record WorklistFilterDto(
    string? SearchTerm,
    string? Modality,
    DateTime? StartDate,
    DateTime? EndDate,
    string? Status,
    bool? IsPriority,
    int Page = 1,
    int PageSize = 20
);
