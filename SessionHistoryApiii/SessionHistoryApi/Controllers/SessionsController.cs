using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SessionHistoryApi.Data;
using SessionHistoryApi.Dtos.Sessions;
using SessionHistoryApi.Models;

namespace SessionHistoryApi.Controllers;

/// <summary>
/// CRUD des sessions, réservé aux utilisateurs authentifiés (JWT).
/// Chaque utilisateur ne voit et ne modifie que ses propres sessions.
/// </summary>
[ApiController]
[Authorize]
[Route("api/sessions")]
public class SessionsController : ControllerBase
{
    private readonly AppDbContext _db;

    public SessionsController(AppDbContext db)
    {
        _db = db;
    }

    private Guid CurrentUserId =>
        Guid.Parse(User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)!);

    [HttpGet]
    public async Task<ActionResult<List<SessionDto>>> GetAll()
    {
        var sessions = await _db.Sessions
            .Where(s => s.UserId == CurrentUserId)
            .OrderByDescending(s => s.Date)
            .ToListAsync();

        return Ok(sessions.Select(ToDto));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SessionDto>> GetById(Guid id)
    {
        var session = await _db.Sessions.FirstOrDefaultAsync(s => s.Id == id && s.UserId == CurrentUserId);
        if (session == null) return NotFound();
        return Ok(ToDto(session));
    }

    [HttpPost]
    public async Task<ActionResult<SessionDto>> Create(CreateSessionRequest request)
    {
        var session = new Session
        {
            UserId = CurrentUserId,
            Title = request.Title,
            Category = request.Category,
            Date = request.Date,
            Time = request.Time,
            Content = request.Content,
            Tags = string.Join(",", request.Tags),
            AutoSummary = request.AutoSummary,
            AutoKeywords = string.Join(",", request.AutoKeywords),
        };

        _db.Sessions.Add(session);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = session.Id }, ToDto(session));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<SessionDto>> Update(Guid id, UpdateSessionRequest request)
    {
        var session = await _db.Sessions.FirstOrDefaultAsync(s => s.Id == id && s.UserId == CurrentUserId);
        if (session == null) return NotFound();

        session.Title = request.Title;
        session.Category = request.Category;
        session.Date = request.Date;
        session.Time = request.Time;
        session.Content = request.Content;
        session.Tags = string.Join(",", request.Tags);
        session.AutoSummary = request.AutoSummary;
        session.AutoKeywords = string.Join(",", request.AutoKeywords);
        session.IsFavorite = request.IsFavorite;
        session.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return Ok(ToDto(session));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var session = await _db.Sessions.FirstOrDefaultAsync(s => s.Id == id && s.UserId == CurrentUserId);
        if (session == null) return NotFound();

        _db.Sessions.Remove(session);
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpGet("search")]
    public async Task<ActionResult<List<SessionDto>>> Search([FromQuery] string q)
    {
        var like = $"%{q}%";
        var sessions = await _db.Sessions
            .Where(s => s.UserId == CurrentUserId &&
                (EF.Functions.Like(s.Title, like) ||
                 EF.Functions.Like(s.Content, like) ||
                 EF.Functions.Like(s.Tags, like)))
            .OrderByDescending(s => s.Date)
            .ToListAsync();

        return Ok(sessions.Select(ToDto));
    }

    private static SessionDto ToDto(Session s) => new()
    {
        Id = s.Id,
        Title = s.Title,
        Category = s.Category,
        Date = s.Date,
        Time = s.Time,
        Content = s.Content,
        Tags = s.Tags.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList(),
        IsFavorite = s.IsFavorite,
        AutoSummary = s.AutoSummary,
        AutoKeywords = (s.AutoKeywords ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries).ToList(),
        CreatedAt = s.CreatedAt,
        UpdatedAt = s.UpdatedAt,
    };
}
