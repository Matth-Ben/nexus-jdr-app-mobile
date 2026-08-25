import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Placeholder des étapes 2 à 9 de l'assistant de création de personnage
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3),
/// affiché à la route `/characters/new/next` (juste après validation de
/// l'étape 1 "Race", voir `race_step_screen.dart`) en attendant
/// l'implémentation des étapes suivantes (Classe/Historique/...).
class CharacterCreationPlaceholderScreen extends StatelessWidget {
  const CharacterCreationPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `AppBar` affiche automatiquement une flèche de retour tant que la
      // route peut être dépilée (cas normal ici : on arrive toujours depuis
      // `/characters/new` via `context.push`).
      appBar: AppBar(),
      body: Center(
        child: Text(
          'Étape 2/9 — Classe — à venir',
          style: AppTypography.body(fontSize: 16),
        ),
      ),
    );
  }
}
