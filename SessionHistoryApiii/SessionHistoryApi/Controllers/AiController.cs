using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SessionHistoryApi.Dtos.Ai;
using SessionHistoryApi.Services;

namespace SessionHistoryApi.Controllers;

[ApiController]
[Authorize]
[Route("api/ai")]
public class AiController : ControllerBase
{
    private readonly GeminiAiService _gemini;

    public AiController(GeminiAiService gemini)
    {
        _gemini = gemini;
    }

    [HttpPost("analyze")]
    public async Task<ActionResult<AnalyzeSessionResponse>> Analyze(
        AnalyzeSessionRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Title) && string.IsNullOrWhiteSpace(request.Content))
        {
            return BadRequest(new { message = "Le titre ou le contenu est requis." });
        }

        var result = await _gemini.AnalyzeAsync(request, cancellationToken);
        if (result == null)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                message = "Le service Gemini n'est pas configuré ou est momentanément indisponible."
            });
        }

        return Ok(result);
    }
}
