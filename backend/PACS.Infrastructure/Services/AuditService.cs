using PACS.Core.Entities;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class AuditService : IAuditService
{
    private readonly PACSDbContext _context;

    public AuditService(PACSDbContext context)
    {
        _context = context;
    }

    public async Task LogAsync(int? userId, string action, string entityType, string entityId, string details, string ipAddress)
    {
        var auditLog = new AuditLog
        {
            UserId = userId,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            Details = details,
            IpAddress = ipAddress,
            CreatedAt = DateTime.UtcNow
        };

        _context.AuditLogs.Add(auditLog);
        await _context.SaveChangesAsync();
    }
}
