import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Clé globale du [ScaffoldMessenger] de l'application.
///
/// Elle est attachée à [MaterialApp] (voir `main.dart`), au-dessus du
/// [Navigator]. Cela permet d'afficher un message dans l'application
/// (SnackBar) depuis n'importe où — y compris depuis SessionProvider, qui
/// n'a pas de [BuildContext] — et ce message reste visible même juste après
/// un `Navigator.pop()`, contrairement à un SnackBar attaché à l'écran qui
/// vient de se fermer.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Affiche un message en haut de l'écran, à ne pas
/// confondre avec une notification système : il n'apparaît que si
/// l'application est ouverte, et disparaît tout seul après quelques
/// secondes.
void showAppMessage(
  String message, {
  IconData icon = Icons.error_outline_rounded,
  Color iconColor = AppColors.error,
}) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentMaterialBanner()
    ..showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        leading: Icon(icon, color: iconColor),
        backgroundColor: Colors.white,
        elevation: 4,
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: const Text('Fermer'),
          ),
        ],
      ),
    );

  Future<void>.delayed(const Duration(seconds: 4), () {
    messenger.hideCurrentMaterialBanner();
  });
}
