import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pixel_icon.dart';
import '../../../../core/widgets/pixel_icons/combat_pixel_icons.dart';
import 'initiative_row.dart' show kCombatTurnFill;

/// Variante du signal global de combat (`docs/combat-grimoire-ui.md` §6).
enum CombatCalloutVariant {
  /// « Combat ! » ou « Initiative demandée » : fond `parchment.card`, bordure
  /// 2 `goldEnd`.
  announce,

  /// « À toi de jouer » : fond turn-fill, bordure emphasis (3 `woodMedium` +
  /// halo 1 `woodDark`).
  turn,
}

/// Carte du signal global de combat — vue pure (aucun fournisseur), posée par
/// `CombatCalloutHost` en bas de l'écran.
///
/// Toute la carte (hauteur 56 au moins) ouvre l'écran Combat ; bouton
/// « Fermer » 44×44. Textes plafonnés ×2,0 ; hauteur au plus [maxHeight]
/// (25 % de la vue), défilement interne au-delà. Le nom du groupe passe à la
/// ligne, jamais coupé. Sémantique : bouton « Ouvrir le combat », action
/// « Fermer » ; région vivante pour la variante annonce **seulement** (le
/// tour a déjà son annonce assertive « C'est ton tour. », revue visuelle du
/// 24/11/2026).
///
/// [onScene] : écran « scène » (accueil, connexion, montée de niveau...) :
/// la variante annonce prend le cadre `border.card-emphasis` et les deux
/// variantes l'ombre diffuse des cartes sur fond scène ; sur fond parchemin,
/// cadre doré et aucune ombre.
///
/// Aucun `Tooltip` : la carte vit au-dessus du navigateur, hors de tout
/// `Overlay`.
class CombatCalloutView extends StatelessWidget {
  const CombatCalloutView({
    required this.variant,
    required this.title,
    required this.body,
    required this.openLabel,
    required this.closeLabel,
    required this.onOpen,
    required this.onClose,
    required this.maxHeight,
    this.onScene = false,
    super.key,
  });

  final CombatCalloutVariant variant;
  final String title;
  final String body;

  /// Action du bouton (« Ouvrir le combat »).
  final String openLabel;

  /// Libellé du bouton de fermeture (« Fermer »).
  final String closeLabel;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final double maxHeight;
  final bool onScene;

  bool get _turn => variant == CombatCalloutVariant.turn;

  /// Cadre `border.card-emphasis` (3 `woodMedium` + halo 1 `woodDark`) :
  /// variante tour partout, variante annonce sur un écran scène.
  bool get _emphasis => _turn || onScene;

  /// Libellé lu : titre puis texte, sans « . » ajouté après un titre déjà
  /// ponctué (« Combat ! »).
  String get _semanticLabel {
    final trimmed = title.trimRight();
    final punctuated = RegExp(r'[.!?…:;]$').hasMatch(trimmed);
    return punctuated ? '$trimmed $body' : '$trimmed. $body';
  }

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: _emphasis
          ? const BorderSide(
              color: AppColors.woodMedium,
              width: AppBorders.cardEmphasis,
            )
          : const BorderSide(color: AppColors.goldEnd, width: AppBorders.card),
    );
    final card = Material(
      color: _turn ? kCombatTurnFill : AppColors.parchmentCard,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        // Cadre emphasis : le halo (1 dp de chaque côté) compte dans la
        // hauteur maximale.
        constraints: BoxConstraints(
          maxHeight: _emphasis
              ? maxHeight - 2 * AppBorders.cardEmphasisHalo
              : maxHeight,
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: _semanticLabel,
                onTapHint: openLabel,
                onTap: onOpen,
                customSemanticsActions: {
                  CustomSemanticsAction(label: closeLabel): onClose,
                },
                excludeSemantics: true,
                child: InkWell(
                  key: const Key('combatCallout'),
                  onTap: onOpen,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.xs,
                        0,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          const PixelIcon(
                            matrix: kCombatSwordsMatrix,
                            size: 16,
                            color: AppColors.accentTeal,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    style: AppTypography.body(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    body,
                                    style: AppTypography.body(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: closeLabel,
              onTap: onClose,
              excludeSemantics: true,
              child: SizedBox(
                width: 44,
                height: 44,
                child: InkResponse(
                  key: const Key('combatCalloutClose'),
                  onTap: onClose,
                  radius: 22,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTypography.maxTextScaleFactor,
      child: Semantics(
        container: true,
        liveRegion: !_turn,
        explicitChildNodes: true,
        child: _frame(card),
      ),
    );
  }

  /// Halo 1 `woodDark` du cadre emphasis (comme la ligne en cours) et, sur un
  /// écran scène, ombre diffuse des cartes (comme `CharacterCard`).
  Widget _frame(Widget card) {
    if (!_emphasis && !onScene) return card;
    return Container(
      margin: _emphasis
          ? const EdgeInsets.all(AppBorders.cardEmphasisHalo)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          if (_emphasis)
            const BoxShadow(
              color: AppColors.woodDark,
              spreadRadius: AppBorders.cardEmphasisHalo,
            ),
          if (onScene)
            const BoxShadow(
              color: AppColors.cardDiffuseShadow,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
        ],
      ),
      child: card,
    );
  }
}
