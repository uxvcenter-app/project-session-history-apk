using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SessionHistoryApi.Data;
using SessionHistoryApi.Dtos.Auth;
using SessionHistoryApi.Models;
using SessionHistoryApi.Services;

namespace SessionHistoryApi.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IEmailService _emailService;
    private readonly JwtTokenService _jwtService;
    private readonly IConfiguration _config;

    public AuthController(AppDbContext db, IEmailService emailService, JwtTokenService jwtService, IConfiguration config)
    {
        _db = db;
        _emailService = emailService;
        _jwtService = jwtService;
        _config = config;
    }
/// <summary>
/// Génère un code de réinitialisation et l'envoie par email si le compte existe.
/// </summary>
[HttpPost("forgot-password")]
public async Task<ActionResult<MessageResponse>> ForgotPassword(ForgotPasswordRequest request)
{
    var email = request.Email.Trim().ToLowerInvariant();
    var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

    // On répond pareil même si l'utilisateur n'existe pas, pour ne pas
    // révéler quels emails sont enregistrés (bonne pratique sécurité).
    if (user == null)
    {
        return Ok(new MessageResponse { Message = "Si ce compte existe, un code a été envoyé." });
    }

    var code = VerificationCodeGenerator.Generate();
    var expiryMinutes = int.Parse(_config["VerificationCode:ExpiryMinutes"]!);

    user.VerificationCode = code;
    user.VerificationCodeExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes);
    await _db.SaveChangesAsync();

    await _emailService.SendVerificationCodeAsync(user.Email, user.FullName, code);

    return Ok(new MessageResponse { Message = "Si ce compte existe, un code a été envoyé." });
}

/// <summary>
/// Réinitialise le mot de passe après vérification du code reçu par email.
/// </summary>
[HttpPost("reset-password")]
public async Task<ActionResult<MessageResponse>> ResetPassword(ResetPasswordRequest request)
{
    var email = request.Email.Trim().ToLowerInvariant();
    var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

    if (user == null)
        return NotFound(new MessageResponse { Message = "Utilisateur introuvable." });

    if (user.VerificationCode != request.Code)
        return BadRequest(new MessageResponse { Message = "Code incorrect." });

    if (user.VerificationCodeExpiresAt == null || user.VerificationCodeExpiresAt < DateTime.UtcNow)
        return BadRequest(new MessageResponse { Message = "Ce code a expiré. Demandez-en un nouveau." });

    user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
    user.VerificationCode = null;
    user.VerificationCodeExpiresAt = null;
    await _db.SaveChangesAsync();

    return Ok(new MessageResponse { Message = "Mot de passe réinitialisé avec succès." });
}

    /// <summary>
    /// Inscription : crée le compte (non vérifié), génère un code à 6 chiffres
    /// et l'envoie par email. Le compte ne peut pas se connecter tant qu'il
    /// n'est pas vérifié.
    /// </summary>
    [HttpPost("register")]
    public async Task<ActionResult<MessageResponse>> Register(RegisterRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();

        if (await _db.Users.AnyAsync(u => u.Email == email))
        {
            return Conflict(new MessageResponse { Message = "Un compte existe déjà avec cet email." });
        }

        var code = VerificationCodeGenerator.Generate();
        var expiryMinutes = int.Parse(_config["VerificationCode:ExpiryMinutes"]!);

        var user = new User
        {
            FullName = request.FullName.Trim(),
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            IsEmailVerified = false,
            VerificationCode = code,
            VerificationCodeExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes),
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        await _emailService.SendVerificationCodeAsync(user.Email, user.FullName, code);

        return Ok(new MessageResponse
        {
            Message = "Compte créé. Un code de vérification a été envoyé par email."
        });
    }

    /// <summary>
    /// Vérifie le code à 6 chiffres reçu par email et active le compte.
    /// </summary>
    [HttpPost("verify-email")]
    public async Task<ActionResult<AuthResponse>> VerifyEmail(VerifyEmailRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        if (user == null)
            return NotFound(new MessageResponse { Message = "Utilisateur introuvable." });

        if (user.IsEmailVerified)
            return BadRequest(new MessageResponse { Message = "Ce compte est déjà vérifié." });

        if (user.VerificationCode != request.Code)
            return BadRequest(new MessageResponse { Message = "Code de vérification incorrect." });

        if (user.VerificationCodeExpiresAt == null || user.VerificationCodeExpiresAt < DateTime.UtcNow)
            return BadRequest(new MessageResponse { Message = "Ce code a expiré. Demandez-en un nouveau." });

        user.IsEmailVerified = true;
        user.VerificationCode = null;
        user.VerificationCodeExpiresAt = null;
        await _db.SaveChangesAsync();

        var token = _jwtService.GenerateToken(user);

        return Ok(new AuthResponse
        {
            Token = token,
            UserId = user.Id,
            FullName = user.FullName,
            Email = user.Email,
        });
    }

    /// <summary>
    /// Renvoie un nouveau code si l'utilisateur ne l'a pas reçu / a expiré.
    /// </summary>
    [HttpPost("resend-code")]
    public async Task<ActionResult<MessageResponse>> ResendCode(ResendCodeRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        if (user == null)
            return NotFound(new MessageResponse { Message = "Utilisateur introuvable." });

        if (user.IsEmailVerified)
            return BadRequest(new MessageResponse { Message = "Ce compte est déjà vérifié." });

        var code = VerificationCodeGenerator.Generate();
        var expiryMinutes = int.Parse(_config["VerificationCode:ExpiryMinutes"]!);

        user.VerificationCode = code;
        user.VerificationCodeExpiresAt = DateTime.UtcNow.AddMinutes(expiryMinutes);
        await _db.SaveChangesAsync();

        await _emailService.SendVerificationCodeAsync(user.Email, user.FullName, code);

        return Ok(new MessageResponse { Message = "Un nouveau code a été envoyé par email." });
    }

    /// <summary>
    /// Connexion : refuse tant que l'email n'est pas vérifié.
    /// </summary>
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return Unauthorized(new MessageResponse { Message = "Email ou mot de passe incorrect." });

        if (!user.IsEmailVerified)
            return Unauthorized(new MessageResponse { Message = "Veuillez vérifier votre email avant de vous connecter." });

        var token = _jwtService.GenerateToken(user);

        return Ok(new AuthResponse
        {
            Token = token,
            UserId = user.Id,
            FullName = user.FullName,
            Email = user.Email,
        });
    }
}
