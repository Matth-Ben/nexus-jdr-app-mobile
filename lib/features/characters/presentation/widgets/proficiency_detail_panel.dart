import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dice_type_badge.dart';
import '../../../../core/widgets/error_retry_state.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/dice_notation_parser.dart';
import '../../domain/inventory_armor_dex_bonus_formatter.dart';
import '../../domain/pact_weapon_rules.dart';
import '../../domain/proficiency_catalog.dart';
import '../../domain/proficiency_token_detail.dart';
import '../../domain/proficiency_token_resolver.dart';
import '../../domain/proficiency_token_title_formatter.dart';
import '../providers/proficiency_catalog_providers.dart';

/// Ouvre le panneau "Infos" d'un token de maîtrise d'armes/d'armures (chip de
/// `CharacterWeaponProficienciesCard`/`CharacterArmorProficienciesCard`,
/// onglet "Compétences") : liste ce que ce token recouvre concrètement dans
/// le catalogue — voir `ProficiencyTokenResolver` pour la résolution et
/// `ProficiencyTokenTitleFormatter` pour le titre affiché.
///
/// Même gabarit que `feat_info_panel.dart` : [SheetHeaderBar] + contenu
/// scrollable, AUCUN pied/bouton d'action — panneau purement informatif,
/// fermeture par la croix de [SheetHeaderBar] uniquement (spec
/// direction-artistique).
Future<void> showProficiencyDetailPanel(
  BuildContext context, {
  required String token,
  required ProficiencyTokenKind kind,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _ProficiencyDetailPanelContent(token: token, kind: kind),
  );
}

class _ProficiencyDetailPanelContent extends ConsumerWidget {
  const _ProficiencyDetailPanelContent({
    required this.token,
    required this.kind,
  });

  final String token;
  final ProficiencyTokenKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(proficiencyCatalogProvider);

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(
                title: ProficiencyTokenTitleFormatter.titleFor(token),
              ),
              Expanded(
                child: catalogAsync.when(
                  data: _buildDetail,
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.woodMedium,
                    ),
                  ),
                  error: (error, stackTrace) => ErrorRetryState(
                    message: 'Impossible de charger le catalogue. Réessayez.',
                    onRetry: () => ref.invalidate(proficiencyCatalogProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(ProficiencyCatalog catalog) {
    final ProficiencyTokenDetail detail = switch (kind) {
      ProficiencyTokenKind.weapon => ProficiencyTokenResolver.resolveWeapon(
        token: token,
        weapons: catalog.weapons,
      ),
      ProficiencyTokenKind.armor => ProficiencyTokenResolver.resolveArmor(
        token: token,
        armors: catalog.armors,
        shields: catalog.shields,
      ),
    };

    if (detail.weapons.isEmpty && detail.armors.isEmpty) {
      // Seul cas documenté par la spec direction-artistique : le token
      // `'boucliers (non métalliques)'` est TOUJOURS vide dans ce
      // catalogue (voir `DruidNonMetallicEquipment`). Les autres tokens
      // connus renvoient toujours au moins une entrée sur un contenu peuplé
      // normal ; message neutre générique en repli défensif (pas couvert
      // par la spec, signalé dans le rapport de cette tâche).
      final message =
          PactWeaponRules.normalize(token) == 'boucliers (non metalliques)'
          ? 'Aucun bouclier non métallique disponible dans le catalogue '
                'actuel.'
          : 'Aucun objet correspondant disponible dans le catalogue '
                'actuel.';
      return _EmptyCatalogState(message: message);
    }

    final rows = <Widget>[
      for (final weapon in detail.weapons) _WeaponDetailRow(weapon: weapon),
      for (final armor in detail.armors) _ArmorDetailRow(armor: armor),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const SheetActionDivider(),
          ],
        ],
      ),
    );
  }
}

/// État "liste vide" centré — voir la doc de classe de
/// [_ProficiencyDetailPanelContent._buildDetail].
class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.body(fontSize: 13, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

/// Ligne d'arme — titre + (dé de dégâts/type si connus) + propriétés si non
/// vides. Spec direction-artistique : même gabarit que
/// `item_info_panel.dart`, section arme, mais le dé et le type de dégâts
/// partagent une seule ligne sous le titre (plutôt que des lignes libellé/
/// valeur séparées).
class _WeaponDetailRow extends StatelessWidget {
  const _WeaponDetailRow({required this.weapon});

  final ProficiencyCatalogWeapon weapon;

  @override
  Widget build(BuildContext context) {
    final dice = weapon.damageDice != null
        ? DiceNotationParser.parse(weapon.damageDice!)
        : null;
    final hasDamageLine = dice != null || weapon.damageType != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weapon.name,
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (hasDamageLine) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                if (dice != null) ...[
                  DiceTypeBadge(
                    sides: dice.sides,
                    label: '${dice.count}d${dice.sides}',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (weapon.damageType != null)
                  Text(
                    weapon.damageType!,
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ],
          if (weapon.properties.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Propriétés : ',
                    style: AppTypography.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: weapon.properties.join(', '),
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne d'armure OU de bouclier (`armor.category`) — spec
/// direction-artistique : gabarit complet (CA de base/bonus Dex/force
/// requise si renseignée/désavantage discrétion si vrai) pour une armure,
/// gabarit réduit ("CA" -> "+2") pour un bouclier.
class _ArmorDetailRow extends StatelessWidget {
  const _ArmorDetailRow({required this.armor});

  final ProficiencyCatalogArmor armor;

  @override
  Widget build(BuildContext context) {
    final isShield = armor.category == 'bouclier';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            armor.name,
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          if (isShield)
            _DetailInfoRow(label: 'CA', value: '+${armor.acBase}')
          else ...[
            _DetailInfoRow(label: 'CA de base', value: '${armor.acBase}'),
            _DetailInfoRow(
              label: 'Bonus Dex',
              value: InventoryArmorDexBonusFormatter.format(armor.acDexBonus),
            ),
            if (armor.strengthRequirement case final strengthRequirement?)
              _DetailInfoRow(
                label: 'Force requise',
                value: '$strengthRequirement',
              ),
            if (armor.stealthDisadvantage)
              _DetailInfoRow(label: 'Désavantage discrétion', value: 'Oui'),
          ],
        ],
      ),
    );
  }
}

/// Ligne "libellé/valeur" — même gabarit que
/// `item_info_panel.dart::_ItemInfoRow`, dupliqué ici (usage isolé dans ce
/// panneau, même rationale de duplication que le reste de ce dépôt).
class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
