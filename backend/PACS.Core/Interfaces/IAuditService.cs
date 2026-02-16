namespace PACS.Core.Interfaces;

public interface IAuditService
{
    Task LogAsync(int? userId, string action, string entityType, string entityId, string details, string ipAddress);
}
