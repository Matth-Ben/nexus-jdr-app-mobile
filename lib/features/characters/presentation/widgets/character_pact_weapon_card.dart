import 'package:flutter/material.dart';

import '../../../../core/widgets/display_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/compact_action_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/inventory_category_rules.dart';
import '../../domain/pact_weapon_option.dart';
import 'character_name_tag_chip.dart';

/// Carte « ARME DE PACTE » de l'onglet « Personnage » (Occultiste, Pacte de
/// la lame) — même gabarit que `CharacterInvocationsCard`.
///
/// L'arme de pacte n'est PAS un objet d'inventaire (ni poids porté, ni
/// « ÉQUIPÉ ») : cette carte affiche seulement la forme courante
/// (`CharacterDetail.pactWeapon`, [weapon]) et le bouton qui ouvre la
/// feuille de choix. L'appelant décide de la monter (Pacte de la lame
/// uniquement) — y compris en vue partagée en lecture seule
/// (`shared_character_view_screen.dart`), à condition de passer
/// `readOnly: true` (voir [readOnly]).
///
/// [onChangeForm] `null` : bouton verrouillé (écriture d'inventaire en
/// cours) — sans effet quand [readOnly] est vrai (le bouton n'est alors pas
/// rendu du tout, voir sa documentation).
class CharacterPactWeaponCard extends StatelessWidget {
  const CharacterPactWeaponCard({
    required this.weapon,
    required this.hasCursedBlade,
    required this.onChangeForm,
    this.readOnly = false,
    super.key,
  });

  /// Forme courante, `null` si aucune n'a encore été choisie.
  final PactWeaponOption? weapon;

  /// Sous-classe Lame maudite : ajoute la ligne sur le Charisme.
  final bool hasCursedBlade;

  final VoidCallback? onChangeForm;

  /// `true` en vue partagée en lecture seule : le bouton "Choisir une
  /// forme"/"Changer de forme" n'est alors pas rendu du tout, plutôt que
  /// rendu désactivé (`onChangeForm: null` seul laisserait une affordance
  /// d'édition visible, à proscrire en lecture seule).
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = weapon;
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
            l10n.characterPactWeaponCardTitle,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (current == null) const _EmptyWeapon() else _Weapon(current),
          if (hasCursedBlade) ...[
            const SizedBox(height: AppSpacing.sm),
            const _CursedBladeLine(),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.characterPactWeaponCardReminderText,
            style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
          ),
          if (!readOnly) ...[
            const SizedBox(height: AppSpacing.sm),
            CompactActionButton(
              icon: Icons.swap_horiz,
              label: current == null
                  ? l10n.characterPactWeaponCardChooseFormButton
                  : l10n.characterPactWeaponCardChangeFormButton,
              onTap: onChangeForm,
            ),
          ],
        ],
      ),
    );
  }
}

class _Weapon extends StatelessWidget {
  const _Weapon(this.weapon);

  final PactWeaponOption weapon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final damage = weapon.damageLabel;
    final properties = weapon.propertiesLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          container: true,
          excludeSemantics: true,
          label: damage == null
              ? l10n.characterPactWeaponCardSemanticLabel(weapon.name)
              : l10n.characterPactWeaponCardSemanticLabelWithDamage(
                  weapon.name,
                  damage,
                ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccentIconBadge(
                icon: InventoryCategoryRules.iconFor('arme'),
                color: InventoryCategoryRules.colorFor('arme'),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weapon.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (damage != null)
                      Text(
                        damage,
                        style: AppTypography.body(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (properties != null)
                      Text(
                        properties,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            CharacterNameTagChip(
              name: l10n.characterPactWeaponCardMagicWeaponChip,
            ),
            CharacterNameTagChip(
              name: l10n.characterPactWeaponCardProficientChip,
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyWeapon extends StatelessWidget {
  const _EmptyWeapon();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.characterPactWeaponCardEmptyTitle,
          style: AppTypography.body(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          l10n.characterPactWeaponCardEmptyDescription,
          style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CursedBladeLine extends StatelessWidget {
  const _CursedBladeLine();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.accentTeal,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            l10n.characterPactWeaponCardCursedBladeText,
            style: AppTypography.body(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
