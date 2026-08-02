using System.ComponentModel.DataAnnotations;

namespace SessionHistoryApi.Dtos.Auth;

public class ResendCodeRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;
}
