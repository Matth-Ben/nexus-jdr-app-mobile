import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_story_field.dart';
import '../../domain/character_story_fields_resolver.dart';

/// Contenu de l'onglet "Histoire" de la fiche personnage — voir
/// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Onglet
/// Histoire".
///
/// Contrairement aux onglets "Compétences"/"Inventaire", cet onglet n'a
/// aucune logique métier (pas de bonus/quantité/poids à calculer) : il
/// n'affiche que les 9 champs de texte libre déjà stockés tels quels sur
/// `characters.*_text` (voir `CharacterStoryFieldsResolver`), en lecture
/// seule. Portée volontairement en lecture seule à cette itération, comme
/// les autres onglets déjà livrés : aucun bouton "Modifier" ici — les 9
/// champs ne sont modifiables qu'à l'étape 8/9 de l'assistant de création
/// pour l'instant (`character_creation/presentation/appearance_and_backstory_step_screen.dart`).
///
/// Une carte par champ renseigné (titre en majuscules au-dessus, texte dans
/// une carte parchemin encadrée bois clair), un champ vide/non renseigné
/// masque entièrement sa carte plutôt que d'en afficher une vide — même
/// principe que les cartes optionnelles de l'onglet "Compétences" (outils/
/// langues masquées si vides, voir `character_skills_tab_body.dart`). Voir
/// [_EmptyStoryState] pour le cas où les 9 champs sont vides.
class CharacterStoryTabBody extends StatelessWidget {
  const CharacterStoryTabBody({required this.detail, super.key});

  final CharacterDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = CharacterStoryFieldsResolver.resolveRows(detail);
    if (rows.isEmpty) {
      return const _EmptyStoryState();
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          _StoryFieldRow(fields: rows[i]),
        ],
      ],
    );
  }
}

/// Une ligne de [CharacterStoryFieldsResolver.resolveRows] : 1 champ (pleine
/// largeur) ou 2 champs côte à côte (Idéaux/Défauts, seule paire de la
/// maquette — voir sa documentation de classe).
class _StoryFieldRow extends StatelessWidget {
  const _StoryFieldRow({required this.fields});

  final List<CharacterStoryField> fields;

  @override
  Widget build(BuildContext context) {
    if (fields.length == 1) {
      return _StoryFieldCard(field: fields.single);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _StoryFieldCard(field: fields[i])),
        ],
      ],
    );
  }
}

/// Titre en majuscules (`AppTypography.display`, même token que les titres
/// des autres cartes de la fiche, ex. `character_skills_card.dart::"LES 18
/// COMPÉTENCES"`) au-dessus d'une carte parchemin contenant le texte brut.
class _StoryFieldCard extends StatelessWidget {
  const _StoryFieldCard({required this.field});

  final CharacterStoryField field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: AppTypography.display(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Text(field.text, style: AppTypography.body(fontSize: 14)),
        ),
      ],
    );
  }
}

/// État vide (les 9 champs sont vides — personnage créé sans rien renseigner
/// à l'étape 8/9) : même agencement (icône + titre + sous-titre centrés) que
/// `character_list_screen.dart::_EmptyState` et
/// `character_detail_screen.dart::_ErrorState`, mais pas factorisé en
/// composant partagé ici — ces deux écrans n'ont pas
/// exactement la même palette (fond "scène"/bois pour `_EmptyState` de la
/// liste, fond parchemin ici, comme `_ErrorState`) ni le même contenu
/// (icône/titre/sous-titre vs. juste icône/titre), et une factorisation
/// aurait élargi cette tâche à un composant partagé `core/widgets/` non
/// demandé explicitement. Signalé comme dette potentielle plutôt que
/// tranché silencieusement (voir le rapport de la tâche qui a introduit cet
/// onglet).
class _EmptyStoryState extends StatelessWidget {
  const _EmptyStoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'AUCUNE HISTOIRE RENSEIGNÉE',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Apparence, traits, idéaux... ces informations ne sont '
              'renseignables que depuis l\'assistant de création pour '
              "l'instant.",
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
