using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using PACS.Core.DTOs;
using PACS.Core.Entities;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class PatientShareService : IPatientShareService
{
    private readonly PACSDbContext _context;
    private readonly IConfiguration _configuration;

    public PatientShareService(PACSDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    public async Task<PatientShareResponse> CreateShareAsync(CreatePatientShareRequest request, int createdBy)
    {
        // Generate unique share token
        var shareToken = Guid.NewGuid().ToString("N");
        
        // Calculate expiration
        var expiresAt = DateTime.UtcNow.AddHours(request.ExpiresInHours);

        var share = new PatientShare
        {
            StudyInstanceUID = request.StudyInstanceUID,
            ShareToken = shareToken,
            PatientEmail = request.PatientEmail,
            ExpiresAt = expiresAt,
            AllowDownload = request.AllowDownload,
            RequireAuthentication = request.RequireAuthentication,
            CustomMessage = request.CustomMessage,
            CreatedBy = createdBy,
            CreatedAt = DateTime.UtcNow,
            IsActive = true
        };

        _context.PatientShares.Add(share);
        await _context.SaveChangesAsync();

        return MapToResponse(share);
    }

    public async Task<PatientShareResponse?> GetShareAsync(int shareId)
    {
        var share = await _context.PatientShares
            .Include(s => s.CreatedByUser)
            .FirstOrDefaultAsync(s => s.ShareID == shareId);

        return share != null ? MapToResponse(share) : null;
    }

    public async Task<PatientShareResponse?> GetShareByTokenAsync(string shareToken)
    {
        var share = await _context.PatientShares
            .Include(s => s.CreatedByUser)
            .FirstOrDefaultAsync(s => s.ShareToken == shareToken && s.IsActive);

        if (share == null || share.ExpiresAt < DateTime.UtcNow)
            return null;

        return MapToResponse(share);
    }

    public async Task<List<PatientShareResponse>> GetPatientSharesAsync(int patientId)
    {
        var shares = await _context.PatientShares
            .Include(s => s.CreatedByUser)
            .Where(s => s.PatientID == patientId)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();

        return shares.Select(MapToResponse).ToList();
    }

    public async Task<List<PatientShareResponse>> GetStudySharesAsync(string studyInstanceUID)
    {
        var shares = await _context.PatientShares
            .Include(s => s.CreatedByUser)
            .Where(s => s.StudyInstanceUID == studyInstanceUID)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();

        return shares.Select(MapToResponse).ToList();
    }

    public async Task<PatientShareAccessResponse> ValidateAndAccessShareAsync(PatientShareAccessRequest request)
    {
        var share = await _context.PatientShares
            .FirstOrDefaultAsync(s => s.ShareToken == request.ShareToken && s.IsActive);

        if (share == null)
        {
            return new PatientShareAccessResponse
            {
                IsValid = false,
                ErrorMessage = "Share link not found"
            };
        }

        if (share.ExpiresAt < DateTime.UtcNow)
        {
            return new PatientShareAccessResponse
            {
                IsValid = false,
                ErrorMessage = "Share link has expired"
            };
        }

        // Log access
        var accessLog = new PatientShareAccess
        {
            ShareID = share.ShareID,
            AccessedAt = DateTime.UtcNow,
            IPAddress = request.IPAddress,
            UserAgent = request.UserAgent
        };

        _context.PatientShareAccesses.Add(accessLog);
        await _context.SaveChangesAsync();

        return new PatientShareAccessResponse
        {
            IsValid = true,
            ShareData = new PatientShareData
            {
                StudyInstanceUID = share.StudyInstanceUID,
                PatientEmail = share.PatientEmail,
                CustomMessage = share.CustomMessage,
                AllowDownload = share.AllowDownload,
                ExpiresAt = share.ExpiresAt,
                ShareToken = share.ShareToken
            }
        };
    }

    public async Task<bool> RevokeShareAsync(int shareId, string? reason)
    {
        var share = await _context.PatientShares.FindAsync(shareId);
        if (share == null)
            return false;

        share.IsActive = false;
        share.RevokedAt = DateTime.UtcNow;
        share.RevokeReason = reason;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SendShareNotificationAsync(int shareId)
    {
        var share = await _context.PatientShares.FindAsync(shareId);
        if (share == null)
            return false;

        // TODO: Implement email sending
        // For now, just log that notification would be sent
        var baseUrl = _configuration["AppSettings:BaseUrl"] ?? "http://localhost:3000";
        var shareUrl = $"{baseUrl}/viewer/shared/{share.ShareToken}";

        // In production, send email here
        Console.WriteLine($"Would send email to {share.PatientEmail} with link: {shareUrl}");
        
        return true;
    }

    public async Task<PatientShareStatistics> GetShareStatisticsAsync(int? userId = null)
    {
        var query = _context.PatientShares.AsQueryable();
        
        if (userId.HasValue)
            query = query.Where(s => s.CreatedBy == userId.Value);

        var totalShares = await query.CountAsync();
        var activeShares = await query.CountAsync(s => s.IsActive && s.ExpiresAt > DateTime.UtcNow);
        var expiredShares = await query.CountAsync(s => s.ExpiresAt < DateTime.UtcNow);
        
        var totalAccesses = await _context.PatientShareAccesses
            .Where(a => query.Any(s => s.ShareID == a.ShareID))
            .CountAsync();

        var recentShares = await query
            .Include(s => s.CreatedByUser)
            .OrderByDescending(s => s.CreatedAt)
            .Take(10)
            .ToListAsync();

        return new PatientShareStatistics
        {
            TotalShares = totalShares,
            ActiveShares = activeShares,
            ExpiredShares = expiredShares,
            TotalAccesses = totalAccesses,
            RecentShares = recentShares.Select(MapToResponse).ToList()
        };
    }

    public async Task DeactivateExpiredSharesAsync()
    {
        var expiredShares = await _context.PatientShares
            .Where(s => s.IsActive && s.ExpiresAt < DateTime.UtcNow)
            .ToListAsync();

        foreach (var share in expiredShares)
        {
            share.IsActive = false;
            share.RevokedAt = DateTime.UtcNow;
            share.RevokeReason = "Expired";
        }

        await _context.SaveChangesAsync();
    }

    private PatientShareResponse MapToResponse(PatientShare share)
    {
        var baseUrl = _configuration["AppSettings:BaseUrl"] ?? "http://localhost:3000";
        var shareUrl = $"{baseUrl}/viewer/shared/{share.ShareToken}";

        return new PatientShareResponse
        {
            ShareID = share.ShareID,
            StudyInstanceUID = share.StudyInstanceUID,
            ShareToken = share.ShareToken,
            ShareUrl = shareUrl,
            PatientEmail = share.PatientEmail,
            ExpiresAt = share.ExpiresAt,
            IsActive = share.IsActive,
            AllowDownload = share.AllowDownload,
            RequireAuthentication = share.RequireAuthentication,
            CustomMessage = share.CustomMessage,
            CreatedBy = share.CreatedBy,
            CreatedByName = share.CreatedByUser?.Username ?? "Unknown",
            CreatedAt = share.CreatedAt,
            RevokedAt = share.RevokedAt,
            RevokeReason = share.RevokeReason
        };
    }
}
