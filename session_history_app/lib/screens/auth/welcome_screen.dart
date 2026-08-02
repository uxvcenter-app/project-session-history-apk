import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Écran d'accueil intermédiaire (avant login/register), reprend
/// le style violet de la maquette.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Session History',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enregistrez, retrouvez et analysez\nvos sessions en toute simplicité.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.5),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      AppRoute(const LoginScreen()),
                    ),
                    child: const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      AppRoute(const RegisterScreen()),
                    ),
                    child: const Text('Créer un compte'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
