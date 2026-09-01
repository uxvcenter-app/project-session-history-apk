import 'package:flutter/material.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Écran d'accueil intermédiaire (avant login/register), reprend
/// le style violet de la maquette — version design pro.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      body: Stack(
        children: [
          // Fond dégradé + halos décoratifs
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: _blurCircle(200, Colors.white.withOpacity(0.08)),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: _blurCircle(220, Colors.white.withOpacity(0.06)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Icône principale avec ombre et léger dégradé
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.22),
                          Colors.white.withOpacity(0.10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Session History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enregistrez, retrouvez et analysez\nvos sessions en toute simplicité.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14.5,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 4),

                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        AppRoute(const LoginScreen()),
                      ),
                      child: const Text('Se connecter'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Bouton secondaire
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        AppRoute(const RegisterScreen()),
                      ),
                      child: const Text('Créer un compte'),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Indicateur de page (style maquette)
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}