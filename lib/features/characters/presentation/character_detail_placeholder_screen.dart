import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';

/// Placeholder de la fiche personnage (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 4), affiché à la route `/characters/:id` en attendant son
/// implémentation (4 onglets : identité, combat, inventaire, sorts).
///
/// [characterName] est passé en `extra` depuis la carte de la liste
/// d'accueil quand il est disponible, pour un placeholder un peu plus
/// informatif ; sinon un libellé générique est affiché (ex. navigation
/// directe par URL, non couverte par le parcours normal de l'app).
class CharacterDetailPlaceholderScreen extends StatelessWidget {
  const CharacterDetailPlaceholderScreen({
    required this.characterId,
    this.characterName,
    super.key,
  });

  final String characterId;
  final String? characterName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // `AppBar` affiche automatiquement une flèche de retour tant que la
      // route peut être dépilée (cas normal ici : on arrive toujours depuis
      // `/` via `context.push`).
      appBar: AppBar(),
      body: Center(
        child: Text(
          characterName != null
              ? 'Fiche personnage — $characterName — à venir'
              : 'Fiche personnage — à venir',
          style: AppTypography.body(fontSize: 16),
        ),
      ),
    );
  }
}
