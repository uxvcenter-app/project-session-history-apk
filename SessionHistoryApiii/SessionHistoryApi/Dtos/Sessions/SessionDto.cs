namespace SessionHistoryApi.Dtos.Sessions;

public class SessionDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public string Time { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public List<string> Tags { get; set; } = new();
    public bool IsFavorite { get; set; }
    public string? AutoSummary { get; set; }
    public List<string> AutoKeywords { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CreateSessionRequest
{
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public string Time { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public List<string> Tags { get; set; } = new();
    // Calculés côté Flutter (ai_service.dart) et envoyés tels quels ;
    // le backend ne fait que les stocker/retourner.
    public string? AutoSummary { get; set; }
    public List<string> AutoKeywords { get; set; } = new();
}

public class UpdateSessionRequest : CreateSessionRequest
{
    public bool IsFavorite { get; set; }
}
