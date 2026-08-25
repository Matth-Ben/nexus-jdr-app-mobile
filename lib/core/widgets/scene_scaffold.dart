import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// [Scaffold] avec le fond "scène" (dégradé bois foncé) utilisé par les
/// écrans listés en section 6 de `docs/cahier-des-charges/10-design-system.md`
/// (connexion, liste des personnages, récapitulatifs ponctuels), par
/// opposition au fond "parchemin" uni posé par défaut dans [AppTheme].
class SceneScaffold extends StatelessWidget {
  const SceneScaffold({required this.body, this.appBar, super.key});

  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.sceneBackground),
        child: body,
      ),
    );
  }
}
