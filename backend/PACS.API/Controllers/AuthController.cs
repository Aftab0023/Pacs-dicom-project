using Microsoft.AspNetCore.Mvc;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;

namespace PACS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly IAuditService _auditService;

    public AuthController(IAuthService authService, IAuditService auditService)
    {
        _authService = authService;
        _auditService = auditService;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        var response = await _authService.LoginAsync(request);
        if (response == null)
            return Unauthorized(new { message = "Invalid credentials" });

        await _auditService.LogAsync(
            response.User.UserId,
            "Login",
            "User",
            response.User.UserId.ToString(),
            "User logged in",
            HttpContext.Connection.RemoteIpAddress?.ToString() ?? ""
        );

        return Ok(response);
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<LoginResponse>> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        var response = await _authService.RefreshTokenAsync(request.RefreshToken);
        if (response == null)
            return Unauthorized(new { message = "Invalid refresh token" });

        return Ok(response);
    }

    [HttpPost("logout")]
    public async Task<ActionResult> Logout([FromBody] RefreshTokenRequest request)
    {
        await _authService.RevokeTokenAsync(request.RefreshToken);
        return Ok(new { message = "Logged out successfully" });
    }
}
