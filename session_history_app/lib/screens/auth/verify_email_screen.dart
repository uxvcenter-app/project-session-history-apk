import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../home/main_navigation.dart';

/// Écran de saisie du code à 6 chiffres reçu par email après l'inscription
/// (ou après une tentative de connexion sur un compte non vérifié).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _resending = false;

  Future<void> _submit() async {
    if (_codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le code doit contenir 6 chiffres')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyEmail(_codeController.text.trim());
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        AppRoute(const MainNavigation()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Code invalide')),
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resendCode();
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Un nouveau code a été envoyé' : (auth.errorMessage ?? 'Erreur'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingVerificationEmail ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 24),
              const Text(
                'Vérifiez votre email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                'Un code à 6 chiffres a été envoyé à\n$email',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 10),
                decoration: const InputDecoration(counterText: '', hintText: '••••••'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Vérifier'),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Envoi en cours...' : "Je n'ai pas reçu de code — Renvoyer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
