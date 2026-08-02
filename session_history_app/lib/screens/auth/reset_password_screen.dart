import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';

/// Étape 2 du flux "mot de passe oublié" : saisie du code reçu par email
/// + définition du nouveau mot de passe.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _resending = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      _codeController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé, connectez-vous.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        AppRoute(const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Code invalide')),
      );
    }
  }

  Future<void> _resend() async {
    final email = context.read<AuthProvider>().pendingResetEmail;
    if (email == null) return;
    setState(() => _resending = true);
    final success = await context.read<AuthProvider>().forgotPassword(email);
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Un nouveau code a été envoyé' : 'Erreur, réessayez')),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingResetEmail ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nouveau mot de passe',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez le code reçu à $email et choisissez un nouveau mot de passe.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
                  decoration: const InputDecoration(counterText: '', hintText: '••••••'),
                  validator: (v) => (v == null || v.trim().length != 6) ? 'Code à 6 chiffres requis' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(_resending ? 'Envoi en cours...' : 'Renvoyer le code'),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _passwordController,
                  hint: 'Nouveau mot de passe',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: _confirmController,
                  hint: 'Confirmer le mot de passe',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) =>
                      v != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Réinitialiser le mot de passe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
