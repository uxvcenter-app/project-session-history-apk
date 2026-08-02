using System.Net;
using System.Net.Mail;

namespace SessionHistoryApi.Services;

/// <summary>
/// Envoi d'emails via SMTP (ex: Gmail avec un "mot de passe d'application").
/// Toute la configuration se trouve dans appsettings.json > "Email".
/// </summary>
public class SmtpEmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(IConfiguration config, ILogger<SmtpEmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendVerificationCodeAsync(string toEmail, string fullName, string code)
    {
        var host = _config["Email:SmtpHost"]!;
        var port = int.Parse(_config["Email:SmtpPort"]!);
        var senderEmail = _config["Email:SenderEmail"]!;
        var senderName = _config["Email:SenderName"]!;
        var senderPassword = _config["Email:SenderPassword"]!;
        var enableSsl = bool.Parse(_config["Email:EnableSsl"]!);

        var message = new MailMessage
        {
            From = new MailAddress(senderEmail, senderName),
            Subject = "Votre code de vérification - Session History",
            Body = $@"
                <div style='font-family: Arial, sans-serif; max-width: 480px; margin: auto;'>
                  <h2 style='color:#6C4BA6;'>Bonjour {fullName},</h2>
                  <p>Merci de vous être inscrit sur <b>Session History</b>.</p>
                  <p>Voici votre code de vérification :</p>
                  <div style='font-size: 28px; font-weight: bold; letter-spacing: 6px;
                              background:#F7F6FB; padding: 16px; text-align:center;
                              border-radius: 10px; color:#6C4BA6;'>{code}</div>
                  <p style='margin-top:16px;'>Ce code expire dans 10 minutes.</p>
                  <p style='color:#8B8797; font-size:12px;'>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
                </div>",
            IsBodyHtml = true,
        };
        message.To.Add(toEmail);

        using var client = new SmtpClient(host, port)
        {
            Credentials = new NetworkCredential(senderEmail, senderPassword),
            EnableSsl = enableSsl,
        };

        try
        {
            await client.SendMailAsync(message);
            _logger.LogInformation("Email de vérification envoyé à {Email}", toEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Échec de l'envoi de l'email à {Email}", toEmail);
            throw;
        }
    }
}
