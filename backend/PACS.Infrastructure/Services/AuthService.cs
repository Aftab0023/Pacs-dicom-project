using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly PACSDbContext _context;
    private readonly IConfiguration _configuration;

    public AuthService(PACSDbContext context, IConfiguration configuration)
    {
        _context = context;
        _configuration = configuration;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive);
        if (user == null) return null;

        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return null;

        user.LastLoginAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        var userDto = new UserDto(
            user.UserId,
            user.Username,
            user.Email,
            user.Role,
            user.FirstName,
            user.LastName
        );

        var token = GenerateJwtToken(userDto);
        var refreshToken = Guid.NewGuid().ToString();

        return new LoginResponse(token, refreshToken, userDto);
    }

    public async Task<LoginResponse?> RefreshTokenAsync(string refreshToken)
    {
        // In production, store refresh tokens in database
        // For now, return null
        return null;
    }

    public async Task<bool> RevokeTokenAsync(string refreshToken)
    {
        // In production, revoke refresh token from database
        return true;
    }

    public string GenerateJwtToken(UserDto user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"] ?? "YourSuperSecretKeyThatIsAtLeast32CharactersLong!"));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Role, user.Role)
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"] ?? "PACSSystem",
            audience: _configuration["Jwt:Audience"] ?? "PACSClient",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(8),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
