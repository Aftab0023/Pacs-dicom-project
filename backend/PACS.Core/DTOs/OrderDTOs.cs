namespace PACS.Core.DTOs;

public record OrderDto(
    int OrderId,
    string AccessionNumber,
    string PatientName,
    string MRN,
    string OrderingPhysician,
    string Modality,
    string StudyDescription,
    DateTime ScheduledDateTime,
    string Status,
    string Priority
);

public record CreateOrderRequest(
    string AccessionNumber,
    int PatientId,
    string OrderingPhysician,
    string ReferringPhysician,
    string Modality,
    string StudyDescription,
    DateTime ScheduledDateTime,
    string Priority
);

public record UpdateOrderStatusRequest(
    string Status
);

public record HL7MessageDto(
    string MessageType,
    string MessageControlId,
    string PatientId,
    string PatientName,
    DateTime MessageDateTime,
    string RawMessage
);
