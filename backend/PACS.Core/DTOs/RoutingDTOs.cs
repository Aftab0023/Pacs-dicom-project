namespace PACS.Core.DTOs;

public class CreateRoutingRuleRequest
{
    public string RuleName { get; set; } = string.Empty;
    public int Priority { get; set; } = 100;
    public bool IsActive { get; set; } = true;
    public RoutingConditions Conditions { get; set; } = new();
    public RoutingActions Actions { get; set; } = new();
}

public class UpdateRoutingRuleRequest
{
    public string? RuleName { get; set; }
    public int? Priority { get; set; }
    public bool? IsActive { get; set; }
    public RoutingConditions? Conditions { get; set; }
    public RoutingActions? Actions { get; set; }
}

public class RoutingConditions
{
    public string? Modality { get; set; }
    public List<string>? BodyPart { get; set; }
    public string? StudyDescription { get; set; }
    public string? ReferringPhysician { get; set; }
    public string? PatientLocation { get; set; }
    public TimeOfDayRange? TimeOfDay { get; set; }
    public List<string>? DaysOfWeek { get; set; }
}

public class TimeOfDayRange
{
    public string Start { get; set; } = "00:00";
    public string End { get; set; } = "23:59";
}

public class RoutingActions
{
    public string? AssignTo { get; set; } // "user:123" or "group:radiologists"
    public bool LoadBalance { get; set; } = false;
    public string Priority { get; set; } = "ROUTINE"; // STAT, URGENT, ROUTINE
    public bool Notify { get; set; } = false;
}

public class RoutingRuleResponse
{
    public int RuleID { get; set; }
    public string RuleName { get; set; } = string.Empty;
    public int Priority { get; set; }
    public bool IsActive { get; set; }
    public RoutingConditions Conditions { get; set; } = new();
    public RoutingActions Actions { get; set; } = new();
    public DateTime CreatedDate { get; set; }
    public DateTime ModifiedDate { get; set; }
}

public class EvaluateRoutingRequest
{
    public string StudyInstanceUID { get; set; } = string.Empty;
    public string? Modality { get; set; }
    public string? StudyDescription { get; set; }
    public string? PatientID { get; set; }
    public string? ReferringPhysician { get; set; }
    public string? PatientLocation { get; set; }
}

public class EvaluateRoutingResponse
{
    public bool Matched { get; set; }
    public int? MatchedRuleID { get; set; }
    public string? MatchedRuleName { get; set; }
    public int? AssignToUserID { get; set; }
    public string? AssignToUsername { get; set; }
    public string Priority { get; set; } = "ROUTINE";
    public bool NotificationRequired { get; set; }
}
