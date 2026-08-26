import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Placeholder des étapes de l'assistant de création de personnage pas
/// encore implémentées (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 3), affiché en attendant l'implémentation de l'étape suivante
/// (ex. `/characters/new/step-3`, juste après validation de l'étape 2
/// "Classe", voir `class_step_screen.dart`).
///
/// [stepText] plutôt qu'un texte en dur : ce placeholder est réutilisé d'une
/// étape à l'autre au fil de leur implémentation progressive, seul le
/// libellé change.
class CharacterCreationPlaceholderScreen extends StatelessWidget {
  const CharacterCreationPlaceholderScreen({required this.stepText, super.key});

  final String stepText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `AppBar` affiche automatiquement une flèche de retour tant que la
      // route peut être dépilée (cas normal ici : on arrive toujours depuis
      // l'étape précédente via `context.push`).
      appBar: AppBar(),
      body: Center(
        child: Text(stepText, style: AppTypography.body(fontSize: 16)),
      ),
    );
  }
}
