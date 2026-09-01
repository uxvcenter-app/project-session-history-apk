import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// Utilisateur courant, tel que renvoyé par l'API (plus léger que le modèle
/// local SQLite : pas de mot de passe, id sous forme de string GUID).
class CurrentUser {
  final String id;
  final String fullName;
  final String email;
  /// Chemin local de la photo de profil (stockée sur l'appareil, pas sur
  /// le backend). Null tant que l'utilisateur n'en a pas choisi une.
  final String? photoPath;
  CurrentUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.photoPath,
  });

  CurrentUser copyWith({String? photoPath}) => CurrentUser(
        id: id,
        fullName: fullName,
        email: email,
        photoPath: photoPath ?? this.photoPath,
      );
}

/// Gère l'authentification via le backend ASP.NET Core :
/// inscription -> vérification du code reçu par email -> connexion.
/// Le token JWT est conservé par ApiService (SharedPreferences).
class AuthProvider extends ChangeNotifier {
  final _api = ApiService.instance;
  static const _profileKey = 'current_user_profile';
  static const _photoKey = '${_profileKey}_photo';

  CurrentUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  /// Email en attente de vérification (rempli juste après l'inscription).
  String? pendingVerificationEmail;

  CurrentUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkSession() async {
    final token = await _api.token;
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('${_profileKey}_id');
    final name = prefs.getString('${_profileKey}_name');
    final email = prefs.getString('${_profileKey}_email');
    final photoPath = prefs.getString(_photoKey);
    if (id != null && name != null && email != null) {
      _currentUser = CurrentUser(id: id, fullName: name, email: email, photoPath: photoPath);
      notifyListeners();
    }
  }

  Future<void> _saveProfile(CurrentUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_profileKey}_id', user.id);
    await prefs.setString('${_profileKey}_name', user.fullName);
    await prefs.setString('${_profileKey}_email', user.email);
    if (user.photoPath != null) {
      await prefs.setString(_photoKey, user.photoPath!);
    }
  }

  /// Étape 1 : inscription -> envoie le code par email, ne connecte pas encore.
  Future<bool> register(String fullName, String email, String password) async {
    _setLoading(true);
    try {
      await _api.register(fullName: fullName, email: email, password: password);
      pendingVerificationEmail = email;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Étape 2 : vérifie le code à 6 chiffres reçu par email -> connecte l'utilisateur.
  Future<bool> verifyEmail(String code) async {
    if (pendingVerificationEmail == null) return false;
    _setLoading(true);
    try {
      final body = await _api.verifyEmail(email: pendingVerificationEmail!, code: code);
      final prefs = await SharedPreferences.getInstance();
      _currentUser = CurrentUser(
        id: body['userId'] as String,
        fullName: body['fullName'] as String,
        email: body['email'] as String,
        photoPath: prefs.getString(_photoKey),
      );
      await _saveProfile(_currentUser!);
      pendingVerificationEmail = null;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendCode() async {
    if (pendingVerificationEmail == null) return false;
    try {
      await _api.resendCode(pendingVerificationEmail!);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final body = await _api.login(email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      _currentUser = CurrentUser(
        id: body['userId'] as String,
        fullName: body['fullName'] as String,
        email: body['email'] as String,
        photoPath: prefs.getString(_photoKey),
      );
      await _saveProfile(_currentUser!);
      _errorMessage = null;
      return true;
    } catch (e) {
      final message = e.toString();
      // Si le compte n'est pas encore vérifié, on renvoie l'utilisateur
      // vers l'écran de vérification plutôt que juste afficher une erreur.
      if (message.contains('vérifier votre email')) {
        pendingVerificationEmail = email;
      }
      _errorMessage = message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Enregistre la nouvelle photo de profil (déjà copiée sur le disque par
  /// AvatarService) et notifie l'UI.
  Future<void> updateAvatarPath(String path) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(photoPath: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoKey, path);
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_profileKey}_id');
    await prefs.remove('${_profileKey}_name');
    await prefs.remove('${_profileKey}_email');
    await prefs.remove(_photoKey);
    _currentUser = null;
    notifyListeners();
  }

  /// Email en attente de réinitialisation (rempli après "Mot de passe oublié").
  String? pendingResetEmail;

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _api.forgotPassword(email);
      pendingResetEmail = email;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String code, String newPassword) async {
    if (pendingResetEmail == null) return false;
    _setLoading(true);
    try {
      await _api.resetPassword(email: pendingResetEmail!, code: code, newPassword: newPassword);
      pendingResetEmail = null;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
