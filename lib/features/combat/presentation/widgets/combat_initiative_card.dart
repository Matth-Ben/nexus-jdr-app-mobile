import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';

/// État affiché par [CombatInitiativeCard] (spec `docs/combat-grimoire-ui.md`
/// §3).
enum CombatInitiativeCardState {
  requested,
  sending,
  sent,
  received,
  notReceived,
  requestedAgain,
  failed,
}

/// Carte « Le MJ demande ton initiative » : appel à l'action (même cadre que
/// les bandeaux : `parchment.card`, bordure 2 `goldEnd`, `radius.md`, padding
/// `md`), valeurs en `font.body` 800, jamais en police pixel.
///
/// Vue pure : l'appelant fournit l'état, les textes variables et l'action.
/// [unavailableReason] non nul désactive le bouton avec ce texte **visible**
/// (hors ligne, MJ hors ligne) ; [failureMessage] s'affiche sous le bouton
/// réactivé après un échec d'envoi.
class CombatInitiativeCard extends StatelessWidget {
  const CombatInitiativeCard({
    required this.state,
    required this.characterName,
    this.value,
    this.preparing = false,
    this.unavailableReason,
    this.failureMessage,
    this.onSend,
    super.key,
  });

  final CombatInitiativeCardState state;

  /// Personnage concerné (« Pour {name} »).
  final String characterName;

  /// Valeur envoyée ou reçue (`null` : inconnue).
  final int? value;

  /// Combat en préparation : une initiative reçue peut encore être ajustée.
  final bool preparing;

  final String? unavailableReason;
  final String? failureMessage;
  final VoidCallback? onSend;

  bool get _hasButton => switch (state) {
    CombatInitiativeCardState.sent ||
    CombatInitiativeCardState.received => false,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('combatInitiativeCard'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.goldEnd, width: AppBorders.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _hasButton ? _request(l10n) : _acknowledged(l10n),
      ),
    );
  }

  List<Widget> _request(AppLocalizations l10n) {
    final note = switch (state) {
      CombatInitiativeCardState.notReceived => l10n.combatInitiativeNotReceived,
      CombatInitiativeCardState.requestedAgain =>
        l10n.combatInitiativeRequestedAgain,
      _ => null,
    };
    final unavailable = unavailableReason;
    final failure = state == CombatInitiativeCardState.failed
        ? failureMessage
        : null;
    return [
      Text(
        l10n.combatInitiativeRequestTitle,
        style: AppTypography.body(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      Text(
        l10n.combatInitiativeRequestFor(characterName),
        style: AppTypography.body(fontSize: 13, color: AppColors.textSecondary),
      ),
      if (note != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          note,
          style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
      const SizedBox(height: AppSpacing.sm),
      PrimaryButton(
        key: const Key('combatSendInitiative'),
        label: l10n.combatSendInitiative,
        isLoading: state == CombatInitiativeCardState.sending,
        onPressed: unavailable == null ? onSend : null,
      ),
      if (unavailable != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          unavailable,
          style: AppTypography.body(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ] else if (failure != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline,
              size: 16,
              color: AppColors.accentBrick,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                failure,
                style: AppTypography.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _acknowledged(AppLocalizations l10n) {
    final sent = state == CombatInitiativeCardState.sent;
    final known = value;
    final headline = sent
        ? l10n.combatInitiativeSent(known ?? 0)
        : known == null
        ? l10n.combatInitiativeKnownByGm
        : l10n.combatInitiativeReceived(known);
    final detail = sent
        ? l10n.combatInitiativeAwaitingReceipt
        : preparing
        ? l10n.combatInitiativeMayAdjust
        : null;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              sent ? Icons.send_outlined : Icons.check_circle_outline,
              size: 20,
              color: AppColors.accentTeal,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              headline,
              style: AppTypography.body(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      if (detail != null) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail,
          style: AppTypography.body(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ];
  }
}
