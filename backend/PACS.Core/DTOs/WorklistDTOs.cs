namespace PACS.Core.DTOs;

public class CreateWorklistEntryRequest
{
    public string AccessionNumber { get; set; } = string.Empty;
    public string PatientID { get; set; } = string.Empty;
    public string PatientName { get; set; } = string.Empty;
    public DateTime? PatientBirthDate { get; set; }
    public string? PatientSex { get; set; }
    public DateTime ScheduledProcedureStepStartDate { get; set; }
    public TimeSpan? ScheduledProcedureStepStartTime { get; set; }
    public string Modality { get; set; } = string.Empty;
    public string? ScheduledStationAETitle { get; set; }
    public string? ScheduledProcedureStepDescription { get; set; }
    public string? RequestedProcedureID { get; set; }
    public string? ReferringPhysicianName { get; set; }
}

public class UpdateWorklistEntryRequest
{
    public string? PatientName { get; set; }
    public DateTime? PatientBirthDate { get; set; }
    public string? PatientSex { get; set; }
    public DateTime? ScheduledProcedureStepStartDate { get; set; }
    public TimeSpan? ScheduledProcedureStepStartTime { get; set; }
    public string? Modality { get; set; }
    public string? ScheduledStationAETitle { get; set; }
    public string? ScheduledProcedureStepDescription { get; set; }
    public string? ReferringPhysicianName { get; set; }
}

public class UpdateWorklistStatusRequest
{
    public string Status { get; set; } = string.Empty; // SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
}

public class WorklistEntryResponse
{
    public int WorklistID { get; set; }
    public string AccessionNumber { get; set; } = string.Empty;
    public string PatientID { get; set; } = string.Empty;
    public string PatientName { get; set; } = string.Empty;
    public DateTime? PatientBirthDate { get; set; }
    public string? PatientSex { get; set; }
    public DateTime ScheduledProcedureStepStartDate { get; set; }
    public TimeSpan? ScheduledProcedureStepStartTime { get; set; }
    public string Modality { get; set; } = string.Empty;
    public string? ScheduledStationAETitle { get; set; }
    public string? ScheduledProcedureStepDescription { get; set; }
    public string? StudyInstanceUID { get; set; }
    public string? RequestedProcedureID { get; set; }
    public string? ReferringPhysicianName { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public DateTime? CompletedDate { get; set; }
}

public class WorklistQueryRequest
{
    public string? Modality { get; set; }
    public string? Status { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? PatientID { get; set; }
    public string? PatientName { get; set; }
    public string? AccessionNumber { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}
