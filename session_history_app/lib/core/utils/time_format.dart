import 'package:flutter/material.dart';

/// Formate un [TimeOfDay] en "HH:mm" sur 24 heures (00 à 23), toujours —
/// peu importe la langue ou les réglages régionaux de l'appareil.
///
/// À utiliser à la place de `TimeOfDay.format(context)`, qui peut afficher
/// un format 12 heures (1 à 12 + AM/PM) selon l'appareil de l'utilisateur.
String formatTime24(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// À passer en paramètre `builder:` de [showTimePicker] pour que le
/// sélecteur lui-même affiche les heures de 00 à 23 (au lieu de 1 à 12 avec
/// AM/PM), quel que soit le réglage régional de l'appareil.
Widget force24HourTimePicker(BuildContext context, Widget? child) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
    child: child!,
  );
}
