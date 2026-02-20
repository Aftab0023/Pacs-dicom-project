namespace PACS.Core.DTOs;

public record ReportTemplateDto(
    int TemplateId,
    string Name,
    string Specialty,
    string Modality,
    string TemplateContent,
    bool IsActive
);

public record CreateTemplateRequest(
    string Name,
    string Specialty,
    string Modality,
    string TemplateContent
);

public record TemplateFieldDto(
    string FieldName,
    string FieldType,
    string Label,
    bool IsRequired,
    string? DefaultValue,
    List<string>? Options
);
