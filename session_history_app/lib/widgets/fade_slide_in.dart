import 'package:flutter/material.dart';

/// Anime l'apparition d'un widget (fondu + léger glissement vers le haut),
/// avec un délai proportionnel à son index dans une liste — donne un effet
/// de cascade professionnel aux listes (sessions récentes, cartes...).
/// 100% natif Flutter (TweenAnimationBuilder), aucun package tiers.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 40),
  });

  @override
  Widget build(BuildContext context) {
    final delayMs = (baseDelay.inMilliseconds * index).clamp(0, 400);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
