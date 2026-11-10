import 'package:flutter/material.dart';

import '../../../../core/widgets/display_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_detail.dart';

/// Carte "Apparence physique" (données structurées) — voir
/// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` ligne 45
/// ("Section apparence physique (âge, taille, poids, yeux, peau,
/// cheveux)"). Omise de l'implémentation initiale de l'onglet "Personnage"
/// (commit `28338b8`), ajoutée ici après coup, puis retirée de cet onglet
/// (recettage direction-artistique du 13/09 — absente de la maquette de
/// l'onglet "Personnage") et réintégrée dans l'onglet "Histoire"
/// (`character_story_tab_body.dart`), à côté du champ texte libre
/// "Apparence physique" (les deux sont complémentaires : celui-ci est une
/// description en prose écrite par le joueur, cette carte est la donnée
/// structurée importée depuis aidedd.org).
///
/// Même gabarit que `character_saving_throws_card.dart` (carte parchemin +
/// titre en majuscules + `Wrap` de paires label/valeur), sans point de
/// maîtrise : les 7 champs sont du texte libre
/// (`characters.sexe/age/height/weight/eyes/skin/hair`), pas des bonus
/// calculés. Un champ vide (une fois `trim`) est omis du `Wrap` plutôt que
/// d'afficher une valeur vide ("Yeux : —") — voir [hasContent] pour le cas
/// où les 7 champs sont vides, qui masque la carte entière : à la charge de
/// l'appelant (voir `presentation/widgets/character_story_tab_body.dart`),
/// même principe que les cartes optionnelles de l'onglet "Compétences"
/// (`character_skills_tab_body.dart`, ex. `detail.knownLanguageNames.isNotEmpty`).
/// Purement affichage : contrairement aux 9 champs de texte libre de
/// l'onglet "Histoire", ces 7 champs ne viennent que de l'import XML
/// aidedd.org (jamais de l'assistant de création) — cette carte n'est donc
/// jamais tappable/éditable, contrairement aux cartes de champ qui
/// l'entourent dans cet onglet.
class CharacterAppearanceCard extends StatelessWidget {
  const CharacterAppearanceCard({required this.detail, super.key});

  final CharacterDetail detail;

  /// `true` si au moins un des 7 champs est renseigné (non vide une fois
  /// `trim`) — à vérifier par l'appelant avant d'insérer cette carte dans la
  /// liste défilante de l'onglet "Personnage" (et son séparateur associé).
  ///
  /// Ne dépend d'aucun libellé localisé (seules les *valeurs* comptent ici) :
  /// pas besoin d'`AppLocalizations`/`BuildContext`, contrairement à
  /// [_itemsOf].
  static bool hasContent(CharacterDetail detail) =>
      detail.sexe.trim().isNotEmpty ||
      detail.age.trim().isNotEmpty ||
      detail.height.trim().isNotEmpty ||
      detail.weight.trim().isNotEmpty ||
      detail.eyes.trim().isNotEmpty ||
      detail.skin.trim().isNotEmpty ||
      detail.hair.trim().isNotEmpty;

  static List<_AppearanceItem> _itemsOf(
    AppLocalizations l10n,
    CharacterDetail detail,
  ) {
    final candidates = <_AppearanceItem>[
      _AppearanceItem(
        l10n.characterAppearanceCardSexeLabel,
        detail.sexe.trim(),
      ),
      _AppearanceItem(l10n.characterAppearanceCardAgeLabel, detail.age.trim()),
      _AppearanceItem(
        l10n.characterAppearanceCardHeightLabel,
        detail.height.trim(),
      ),
      _AppearanceItem(
        l10n.characterAppearanceCardWeightLabel,
        detail.weight.trim(),
      ),
      _AppearanceItem(
        l10n.characterAppearanceCardEyesLabel,
        detail.eyes.trim(),
      ),
      _AppearanceItem(
        l10n.characterAppearanceCardSkinLabel,
        detail.skin.trim(),
      ),
      _AppearanceItem(
        l10n.characterAppearanceCardHairLabel,
        detail.hair.trim(),
      ),
    ];
    return candidates
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _itemsOf(l10n, detail);
    if (items.isEmpty) {
      // Ne devrait pas arriver en pratique : l'appelant est censé avoir déjà
      // vérifié [hasContent] avant d'insérer cette carte — filet de sécurité
      // plutôt qu'une carte parchemin vide affichée.
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DisplayText(
            l10n.characterAppearanceCardTitle,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in items) _AppearanceItemRow(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppearanceItem {
  const _AppearanceItem(this.label, this.value);

  final String label;
  final String value;
}

class _AppearanceItemRow extends StatelessWidget {
  const _AppearanceItemRow({required this.item});

  final _AppearanceItem item;

  @override
  Widget build(BuildContext context) {
    // `Wrap` : à grande taille de police, la valeur passe sous son libellé au
    // lieu de déborder de la carte.
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DisplayText(
          item.label,
          style: AppTypography.display(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          item.value,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
