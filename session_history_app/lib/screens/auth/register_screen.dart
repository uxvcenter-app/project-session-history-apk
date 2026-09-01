import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import '../../core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).push(
        AppRoute(const VerifyEmailScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? "Erreur d'inscription")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

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
                _backButton(context),
                const SizedBox(height: 24),

                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 26),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.4),
                ),
                const SizedBox(height: 6),
                Text('Please fill the details', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.5)),
                const SizedBox(height: 26),

                _fieldCard(
                  child: CustomTextField(
                    controller: _nameController,
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Nom requis' : null,
                  ),
                ),
                const SizedBox(height: 14),
                _fieldCard(
                  child: CustomTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                  ),
                ),
                const SizedBox(height: 14),
                _fieldCard(
                  child: CustomTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) => (v == null || v.length < 4) ? '4 caractères minimum' : null,
                  ),
                ),
                const SizedBox(height: 14),
                _fieldCard(
                  child: CustomTextField(
                    controller: _confirmController,
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) =>
                    v != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                        : const Text('Register'),
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        AppRoute(const LoginScreen()),
                      ),
                      child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
      ),
    );
  }

  /// Enveloppe les champs personnalisés dans une carte avec ombre douce
  /// pour un rendu plus soigné, sans toucher au widget CustomTextField.
  Widget _fieldCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}