import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_detail.dart';

/// Carte "Apparence physique" de l'onglet "Personnage" — voir
/// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` ligne 45
/// ("Section apparence physique (âge, taille, poids, yeux, peau,
/// cheveux)"). Omise de l'implémentation initiale de l'onglet "Personnage"
/// (commit `28338b8`), ajoutée ici après coup.
///
/// Même gabarit que `character_saving_throws_card.dart` (carte parchemin +
/// titre en majuscules + `Wrap` de paires label/valeur), sans point de
/// maîtrise : les 7 champs sont du texte libre
/// (`characters.sexe/age/height/weight/eyes/skin/hair`), pas des bonus
/// calculés. Un champ vide (une fois `trim`) est omis du `Wrap` plutôt que
/// d'afficher une valeur vide ("Yeux : —") — voir [hasContent] pour le cas
/// où les 7 champs sont vides, qui masque la carte entière : à la charge de
/// l'appelant (voir `presentation/character_detail_screen.dart::_CharacterTabBody`),
/// même principe que les cartes optionnelles de l'onglet "Compétences"
/// (`character_skills_tab_body.dart`, ex. `detail.knownLanguageNames.isNotEmpty`).
class CharacterAppearanceCard extends StatelessWidget {
  const CharacterAppearanceCard({required this.detail, super.key});

  final CharacterDetail detail;

  /// `true` si au moins un des 7 champs est renseigné (non vide une fois
  /// `trim`) — à vérifier par l'appelant avant d'insérer cette carte dans la
  /// liste défilante de l'onglet "Personnage" (et son séparateur associé).
  static bool hasContent(CharacterDetail detail) => _itemsOf(detail).isNotEmpty;

  static List<_AppearanceItem> _itemsOf(CharacterDetail detail) {
    final candidates = <_AppearanceItem>[
      _AppearanceItem('Sexe', detail.sexe.trim()),
      _AppearanceItem('Âge', detail.age.trim()),
      _AppearanceItem('Taille', detail.height.trim()),
      _AppearanceItem('Poids', detail.weight.trim()),
      _AppearanceItem('Yeux', detail.eyes.trim()),
      _AppearanceItem('Peau', detail.skin.trim()),
      _AppearanceItem('Cheveux', detail.hair.trim()),
    ];
    return candidates
        .where((item) => item.value.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsOf(detail);
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
          Text(
            'APPARENCE PHYSIQUE',
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: AppTypography.display(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
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
