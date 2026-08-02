import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration de l'adresse du backend selon la plateforme d'exécution.
///
/// IMPORTANT :
/// - Émulateur Android  -> 10.0.2.2 pointe vers le PC hôte (PAS localhost)
/// - Simulateur iOS      -> localhost fonctionne directement
/// - Windows/Linux desktop -> localhost fonctionne directement
/// - Téléphone physique (Android ou iOS) -> il FAUT remplacer par l'adresse
///   IP locale de votre PC sur le Wi-Fi (ex: 192.168.1.25), trouvable avec
///   `ipconfig` (Windows) dans la section Wi-Fi > "Adresse IPv4".
///   Le téléphone et le PC doivent être sur le MÊME réseau Wi-Fi.
class ApiConfig {
  ApiConfig._();

  /// Port sur lequel tourne l'API ASP.NET Core (voir Properties/launchSettings.json)
  static const int port = 5080;

  /// Si vous testez sur un téléphone physique, mettez son IP ici, par ex:
  /// static const String? physicalDeviceIp = '192.168.1.25';
  static const String? physicalDeviceIp = null;

  static String get baseUrl {
    if (physicalDeviceIp != null) {
      return 'http://$physicalDeviceIp:$port';
    }
    if (kIsWeb) {
      return 'http://localhost:$port';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port';
    }
    // iOS simulator, Windows, Linux, macOS
    return 'http://localhost:$port';
  }
}
