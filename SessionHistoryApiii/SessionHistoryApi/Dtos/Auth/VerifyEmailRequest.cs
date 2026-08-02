using System.ComponentModel.DataAnnotations;

namespace SessionHistoryApi.Dtos.Auth;

public class VerifyEmailRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, StringLength(6, MinimumLength = 6)]
    public string Code { get; set; } = string.Empty;
}
