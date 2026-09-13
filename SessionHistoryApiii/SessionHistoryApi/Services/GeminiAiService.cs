using System.Net.Http.Json;
using System.Text.Json;
using SessionHistoryApi.Dtos.Ai;

namespace SessionHistoryApi.Services;

public class GeminiAiService
{
    private static readonly HashSet<string> AllowedCategories = new(StringComparer.OrdinalIgnoreCase)
    {
        "development", "debug", "formation", "laboratory", "meeting",
        "work", "personal", "ideas", "others"
    };

    private readonly HttpClient _http;
    private readonly IConfiguration _config;
    private readonly ILogger<GeminiAiService> _logger;

    public GeminiAiService(HttpClient http, IConfiguration config, ILogger<GeminiAiService> logger)
    {
        _http = http;
        _config = config;
        _logger = logger;
    }

    public async Task<AnalyzeSessionResponse?> AnalyzeAsync(
        AnalyzeSessionRequest request,
        CancellationToken cancellationToken)
    {
        var apiKey = _config["Gemini:ApiKey"];
        var model = _config["Gemini:Model"] ?? "gemini-2.0-flash";
        if (string.IsNullOrWhiteSpace(apiKey)) return null;

        var prompt = "Analyse cette note de session et réponds UNIQUEMENT avec un objet JSON valide.\n"
            + "Catégorie obligatoire parmi: development, debug, formation, laboratory, meeting, work, personal, ideas, others.\n"
            + "Le résumé doit être en français, court (1 à 2 phrases), ou null si le contenu est très court.\n"
            + "Retourne exactement: {\"category\":\"...\",\"summary\":\"... ou null\",\"keywords\":[\"...\"]}\n"
            + $"Titre: {request.Title}\n"
            + $"Contenu: {request.Content}";

        var endpoint = $"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={Uri.EscapeDataString(apiKey)}";
        var payload = new
        {
            contents = new[] { new { parts = new[] { new { text = prompt } } } },
            generationConfig = new
            {
                temperature = 0.2,
                responseMimeType = "application/json"
            }
        };

        try
        {
            using var response = await _http.PostAsJsonAsync(endpoint, payload, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Gemini returned HTTP {StatusCode}", response.StatusCode);
                return null;
            }

            using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync(cancellationToken));
            var text = document.RootElement
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text")
                .GetString();
            if (string.IsNullOrWhiteSpace(text)) return null;

            var cleaned = text.Trim();
            if (cleaned.StartsWith("```", StringComparison.Ordinal))
            {
                cleaned = cleaned
                    .Replace("```json", string.Empty, StringComparison.OrdinalIgnoreCase)
                    .Replace("```", string.Empty, StringComparison.Ordinal)
                    .Trim();
            }
            var json = JsonDocument.Parse(cleaned);
            var root = json.RootElement;
            var category = root.TryGetProperty("category", out var categoryValue)
                ? categoryValue.GetString() ?? "others"
                : "others";
            if (!AllowedCategories.Contains(category)) category = "others";

            var keywords = new List<string>();
            if (root.TryGetProperty("keywords", out var keywordValues) && keywordValues.ValueKind == JsonValueKind.Array)
            {
                keywords = keywordValues.EnumerateArray()
                    .Select(value => value.GetString()?.Trim())
                    .Where(value => !string.IsNullOrWhiteSpace(value))
                    .Take(8)
                    .Cast<string>()
                    .ToList();
            }

            string? summary = null;
            if (root.TryGetProperty("summary", out var summaryValue) && summaryValue.ValueKind != JsonValueKind.Null)
            {
                summary = summaryValue.GetString()?.Trim();
            }

            return new AnalyzeSessionResponse
            {
                Category = category.ToLowerInvariant(),
                Summary = string.IsNullOrWhiteSpace(summary) ? null : summary,
                Keywords = keywords
            };
        }
        catch (Exception exception) when (exception is HttpRequestException or JsonException or KeyNotFoundException)
        {
            _logger.LogWarning(exception, "Gemini analysis failed");
            return null;
        }
    }
}
