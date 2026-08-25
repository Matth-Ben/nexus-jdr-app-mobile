import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Placeholder de l'assistant de création de personnage
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3),
/// affiché à la route `/characters/new` en attendant son implémentation
/// (étapes Race/Classe/Historique/...).
class CharacterCreationPlaceholderScreen extends StatelessWidget {
  const CharacterCreationPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `AppBar` affiche automatiquement une flèche de retour tant que la
      // route peut être dépilée (cas normal ici : on arrive toujours depuis
      // `/` via `context.push`).
      appBar: AppBar(),
      body: Center(
        child: Text(
          'Assistant de création — à venir',
          style: AppTypography.body(fontSize: 16),
        ),
      ),
    );
  }
}
