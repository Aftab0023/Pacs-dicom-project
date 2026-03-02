using PACS.Core.DTOs;

namespace PACS.Core.Interfaces;

public interface IRoutingService
{
    Task<RoutingRuleResponse> CreateRoutingRuleAsync(CreateRoutingRuleRequest request, int createdBy);
    Task<RoutingRuleResponse?> GetRoutingRuleAsync(int ruleId);
    Task<List<RoutingRuleResponse>> GetAllRoutingRulesAsync(bool? activeOnly = null);
    Task<RoutingRuleResponse?> UpdateRoutingRuleAsync(int ruleId, UpdateRoutingRuleRequest request);
    Task<bool> DeleteRoutingRuleAsync(int ruleId);
    Task<EvaluateRoutingResponse> EvaluateRoutingAsync(EvaluateRoutingRequest request);
    Task<bool> AssignStudyAsync(string studyInstanceUID, int assignedToUserID, int? ruleID, string priority);
}
