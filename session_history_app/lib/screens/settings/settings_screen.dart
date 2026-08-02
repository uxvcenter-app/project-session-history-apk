import 'package:flutter/material.dart';
import '../../core/navigation/app_route.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/data_transfer_service.dart';
import '../auth/welcome_screen.dart';
import '../categories/categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;

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

  Future<void> _exportData() async {
    final provider = context.read<SessionProvider>();
    setState(() => _exporting = true);
    await provider.loadSessions();
    final sessions = provider.allSessions;
    setState(() => _exporting = false);

    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune session à exporter')),
      );
      return;
    }

    final jsonText = DataTransferService.instance.buildExportJson(sessions);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Export (${sessions.length} session(s))'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copié dans le presse-papier')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copier'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final jsonText = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importer des données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collez ici le contenu JSON exporté précédemment.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '{ "sessions": [ ... ] }',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Importer'),
          ),
        ],
      ),
    );

    if (jsonText == null || jsonText.trim().isEmpty) return;

    setState(() => _importing = true);
    try {
      final result = await DataTransferService.instance.importSessionsFromJsonString(jsonText);
      if (!mounted) return;
      await context.read<SessionProvider>().loadSessions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.imported} session(s) importée(s)'
            '${result.failed > 0 ? ', ${result.failed} échouée(s)' : ''}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON invalide : vérifiez le texte collé')),
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withAlpha((0.15 * 255).round()),
                  child: Text(
                    (auth.currentUser?.fullName.isNotEmpty ?? false)
                        ? auth.currentUser!.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.currentUser?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(auth.currentUser?.email ?? '', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 30),
          _sectionLabel('General'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: context.watch<ThemeProvider>().isDarkMode,
            onChanged: (v) => context.read<ThemeProvider>().setDarkMode(v),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              AppRoute(const CategoriesScreen()),
            ),
          ),
          const Divider(height: 30),
          _sectionLabel('Data'),
          ListTile(
            leading: _exporting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            title: const Text('Export Data '),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exporting ? null : _exportData,
          ),
          ListTile(
            leading: _importing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            title: const Text('Import Data '),
            trailing: const Icon(Icons.chevron_right),
            onTap: _importing ? null : _importData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
            title: const Text('Clear All Data', style: TextStyle(color: AppColors.error)),
            onTap: _clearData,
          ),
          const Divider(height: 30),
          _sectionLabel('About'),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('About App')),
          const ListTile(leading: Icon(Icons.numbers), title: Text('Version 1.0.0')),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Text(text, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5)),
      );
}
