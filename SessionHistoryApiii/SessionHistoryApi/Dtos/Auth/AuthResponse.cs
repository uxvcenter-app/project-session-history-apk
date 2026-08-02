namespace SessionHistoryApi.Dtos.Auth;

public class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

public class MessageResponse
{
    public string Message { get; set; } = string.Empty;
}
