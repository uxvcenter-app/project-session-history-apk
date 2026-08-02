namespace SessionHistoryApi.Models;

/// <summary>
/// Utilisateur enregistré. Le mot de passe n'est jamais stocké en clair
/// (hash BCrypt). Un compte doit être vérifié par email (code à 6 chiffres)
/// avant de pouvoir se connecter.
/// </summary>
public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;

    public bool IsEmailVerified { get; set; } = false;
    public string? VerificationCode { get; set; }
    public DateTime? VerificationCodeExpiresAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Session> Sessions { get; set; } = new List<Session>();
}
