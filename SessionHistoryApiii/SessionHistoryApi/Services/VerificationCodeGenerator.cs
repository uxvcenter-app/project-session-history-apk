namespace SessionHistoryApi.Services;

/// <summary>
/// Génère un code de vérification numérique à 6 chiffres, cryptographiquement
/// sûr (utilisé pour la confirmation d'email à l'inscription).
/// </summary>
public static class VerificationCodeGenerator
{
    public static string Generate()
    {
        var number = System.Security.Cryptography.RandomNumberGenerator.GetInt32(0, 1_000_000);
        return number.ToString("D6");
    }
}
