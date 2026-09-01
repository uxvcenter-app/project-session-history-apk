import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/navigation/app_route.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/avatar_service.dart';
import '../../services/data_transfer_service.dart';
import '../../services/notification_service.dart';
import '../auth/welcome_screen.dart';
import '../categories/categories_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
  }

  /// Ouvre un petit menu (Caméra / Galerie), puis enregistre la photo
  /// choisie comme photo de profil locale.
  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Photo de profil', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final path = await AvatarService.instance.pickAndSaveAvatar(source);
      if (path == null || !mounted) return;
      await context.read<AuthProvider>().updateAvatarPath(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger la photo : $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Déconnexion')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppRoute(const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  /// Exporte automatiquement les sessions vers un VRAI fichier JSON sur
  /// l'appareil (aucune étape manuelle), puis indique clairement à
  /// l'utilisateur où ce fichier a été enregistré : dialogue avec le
  /// chemin complet + notification système.
  Future<void> _exportData() async {
    final provider = context.read<SessionProvider>();
    setState(() => _exporting = true);
    await provider.loadSessions();
    final sessions = provider.allSessions;

    if (sessions.isEmpty) {
      setState(() => _exporting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune session à exporter')),
      );
      return;
    }

    try {
      final file = await DataTransferService.instance.exportSessionsToFile(sessions);
      final fileName = file.uri.pathSegments.last;

      // Notification système (pas une simple alerte in-app) confirmant
      // l'export et pointant vers le fichier créé.
      await NotificationService.instance.showExportCompleted(
        sessionsCount: sessions.length,
        fileName: fileName,
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Export terminé'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${sessions.length} session(s) enregistrée(s) dans :'),
              const SizedBox(height: 10),
              SelectableText(
                file.path,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chemin copié')),
                );
              },
              child: const Text('Copier le chemin'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'export : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// Liste automatiquement les fichiers d'export déjà présents sur
  /// l'appareil et laisse l'utilisateur en choisir un à importer : plus
  /// besoin de coller manuellement du texte JSON.
  Future<void> _importData() async {
    setState(() => _importing = true);
    final files = await DataTransferService.instance.listExportFiles();
    if (!mounted) return;
    setState(() => _importing = false);

    if (files.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Aucun fichier trouvé'),
          content: const Text(
            'Aucun fichier d\'export n\'a été trouvé sur cet appareil. '
            'Utilisez d\'abord "Export Data" pour créer un fichier, ou '
            'collez un JSON manuellement.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final selected = await showDialog<ExportFile>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choisir un fichier à importer'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: files.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final f = files[index];
              return ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(f.name, style: const TextStyle(fontSize: 13.5)),
                subtitle: Text(
                  DateFormat('dd MMM yyyy • HH:mm').format(f.modifiedAt),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, f),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ],
      ),
    );

    if (selected == null) return;

    setState(() => _importing = true);
    try {
      final result = await DataTransferService.instance.importSessionsFromFile(selected.file);
      if (!mounted) return;
      await context.read<SessionProvider>().loadSessions();

      // Notification système confirmant l'import et le fichier source.
      await NotificationService.instance.showImportCompleted(
        imported: result.imported,
        failed: result.failed,
        fileName: selected.name,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.imported} session(s) importée(s) depuis ${selected.name}'
            '${result.failed > 0 ? ', ${result.failed} échouée(s)' : ''}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'import : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Effacer toutes les données ?'),
        content: const Text('Toutes vos sessions seront définitivement supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Effacer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<SessionProvider>().loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('Réglages', style: TextStyle(fontWeight: FontWeight.w700)),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white24,
                                ),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.white,
                                  backgroundImage: (auth.currentUser?.photoPath != null)
                                      ? FileImage(File(auth.currentUser!.photoPath!))
                                      : null,
                                  child: (auth.currentUser?.photoPath != null)
                                      ? null
                                      : Text(
                                          (auth.currentUser?.fullName.isNotEmpty ?? false)
                                              ? auth.currentUser!.fullName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 24,
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.currentUser?.fullName ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                auth.currentUser?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              _sectionLabel('Général'),
              _settingsCard([
                _switchTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: AppColors.personal,
                  title: 'Mode sombre',
                  value: context.watch<ThemeProvider>().isDarkMode,
                  onChanged: (v) => context.read<ThemeProvider>().setDarkMode(v),
                ),
                _divider(),
                _settingsTile(
                  icon: Icons.category_outlined,
                  iconColor: AppColors.work,
                  title: 'Catégories',
                  onTap: () => Navigator.of(context).push(AppRoute(const CategoriesScreen())),
                ),
              ]),
              const SizedBox(height: 24),
              _sectionLabel('Données'),
              _settingsCard([
                _settingsTile(
                  icon: Icons.upload_file_outlined,
                  iconColor: AppColors.success,
                  title: 'Exporter les données',
                  loading: _exporting,
                  onTap: _exporting ? null : _exportData,
                ),
                _divider(),
                _settingsTile(
                  icon: Icons.download_outlined,
                  iconColor: AppColors.formation,
                  title: 'Importer les données',
                  loading: _importing,
                  onTap: _importing ? null : _importData,
                ),
                _divider(),
                _settingsTile(
                  icon: Icons.delete_sweep_outlined,
                  iconColor: AppColors.error,
                  title: 'Effacer toutes les données',
                  titleColor: AppColors.error,
                  onTap: _clearData,
                ),
              ]),
              const SizedBox(height: 24),
              _sectionLabel('À propos'),
              _settingsCard([
                _settingsTile(
                  icon: Icons.info_outline,
                  iconColor: AppColors.meeting,
                  title: 'À propos de l\'application',
                  onTap: () => Navigator.of(context).push(AppRoute(const AboutScreen())),
                ),
                _divider(),
                _settingsTile(
                  icon: Icons.numbers_rounded,
                  iconColor: AppColors.textSecondary,
                  title: 'Version',
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ]),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: AppColors.error, size: 19),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.error.withAlpha((0.06 * 255).round()),
                      side: BorderSide(color: AppColors.error.withAlpha((0.35 * 255).round())),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 20, 10),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _divider() => Divider(height: 1, indent: 68, color: AppColors.border);

  Widget _settingsCard(List<Widget> children) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.04 * 255).round()),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(children: children),
        ),
      );

  Widget _iconBadge(IconData icon, Color color) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withAlpha((0.14 * 255).round()),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 19, color: color),
      );

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? subtitle,
    Widget? trailing,
    bool loading = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: loading
          ? const SizedBox(
              width: 36, height: 36,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _iconBadge(icon, iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: AppColors.textSecondary.withAlpha((0.7 * 255).round()))
              : null),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _iconBadge(icon, iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      onTap: () => onChanged(!value),
    );
  }
}