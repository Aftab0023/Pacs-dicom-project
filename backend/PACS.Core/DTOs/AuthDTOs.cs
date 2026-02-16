namespace PACS.Core.DTOs;

public record LoginRequest(string Email, string Password);

public record LoginResponse(
    string Token,
    string RefreshToken,
    UserDto User
);

public record RefreshTokenRequest(string RefreshToken);

public record UserDto(
    int UserId,
    string Username,
    string Email,
    string Role,
    string FirstName,
    string LastName
);
