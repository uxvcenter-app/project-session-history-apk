namespace SessionHistoryApi.Models;

/// <summary>
/// Session enregistrée par un utilisateur (miroir du SessionModel Flutter),
/// utilisée pour la synchronisation avec l'app mobile.
/// </summary>
public class Session
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public string Time { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string Tags { get; set; } = string.Empty;
    public bool IsFavorite { get; set; } = false;

    public string? AutoSummary { get; set; }
    public string? AutoKeywords { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
