import 'package:flutter/material.dart';

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

/// Affiche un simple message en bas de l'écran (SnackBar), à ne pas
/// confondre avec une notification système : il n'apparaît que si
/// l'application est ouverte, et disparaît tout seul après quelques
/// secondes.
void showAppMessage(String message) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
