import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Gère le choix et le stockage local de la photo de profil de
/// l'utilisateur (galerie ou appareil photo).
///
/// La photo n'est pas envoyée au backend : elle est simplement copiée dans
/// le dossier documents de l'application (dossier "profile"), comme le fait
/// déjà [DataTransferService] pour les exports. Une seule photo est
/// conservée à la fois (l'ancienne est supprimée avant d'enregistrer la
/// nouvelle).
class AvatarService {
  AvatarService._();
  static final AvatarService instance = AvatarService._();

  final _picker = ImagePicker();

  Future<Directory> _avatarDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/profile');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Ouvre le sélecteur (galerie ou appareil photo selon [source]), copie
  /// l'image choisie dans le dossier permanent de l'app et renvoie son
  /// chemin. Renvoie `null` si l'utilisateur annule la sélection.
  Future<String?> pickAndSaveAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final dir = await _avatarDirectory();

    // Supprime toute ancienne photo de profil avant d'enregistrer la
    // nouvelle (une seule à la fois, peu importe son extension d'origine).
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.uri.pathSegments.last.startsWith('avatar.')) {
          await entity.delete();
        }
      }
    }

    final extension = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
    final destination = File('${dir.path}/avatar.$extension');
    await File(picked.path).copy(destination.path);
    return destination.path;
  }
}
