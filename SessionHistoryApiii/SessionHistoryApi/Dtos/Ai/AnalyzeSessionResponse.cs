namespace SessionHistoryApi.Dtos.Ai;

public class AnalyzeSessionResponse
{
    public string Category { get; set; } = "others";
    public string? Summary { get; set; }
    public List<string> Keywords { get; set; } = new();
}
