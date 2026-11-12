import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/app_version_check_result.dart';
import '../../domain/app_version_status.dart';
import '../app_store_launcher.dart';
import '../providers/app_version_providers.dart';
import '../providers/update_banner_dismissal_provider.dart';

/// Bannière "Mise à jour suggérée" — recettage direction-artistique du
/// 13/09/2026 (`docs/cahier-des-charges/09-maquettes-captures.md`, section
/// "Bannière — Mise à jour suggérée"), insérée par
/// `character_list_screen.dart` entre l'en-tête et la barre de recherche.
///
/// Se réduit elle-même à `SizedBox.shrink()` (aucune place réservée) tant
/// que `appVersionCheckProvider`
/// (`presentation/providers/app_version_providers.dart`) n'a pas résolu un
/// statut `AppVersionStatus.updateSuggested`, ou que sa
/// `latestVersion` correspondante a déjà été refermée
/// (`providers/update_banner_dismissal_provider.dart`) — l'écran appelant
/// n'a donc aucune condition à évaluer lui-même, il insère ce widget
/// inconditionnellement.
///
/// [compact] (D211) : forme d'une ligne, un seul bouton, sans ✕. L'écran
/// appelant la demande pendant qu'une alerte de synchro est affichée ; ce
/// widget ne lit volontairement pas l'état de synchro (feature découplée de
/// `core/sync`). La forme compacte ne touche jamais à la fermeture mémorisée.
class UpdateSuggestedBanner extends ConsumerWidget {
  const UpdateSuggestedBanner({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(appVersionCheckProvider).value;
    final dismissedVersion = ref.watch(updateBannerDismissalControllerProvider);

    if (result == null || result.status != AppVersionStatus.updateSuggested) {
      return const SizedBox.shrink();
    }
    if (dismissedVersion == result.latestVersion) {
      return const SizedBox.shrink();
    }

    // Reduce motion : changement immédiat (même motif que `dice_roll_sheet`).
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    final Widget child = compact
        ? _CompactBanner(key: const ValueKey(true), storeUrl: result.storeUrl)
        : Padding(
            key: const ValueKey(false),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.parchmentCard,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.goldEnd,
                  width: AppBorders.card,
                ),
              ),
              // Police système agrandie / écran étroit (F21) : le lien « Mettre
              // à jour » passe sous le message quand les deux ne tiennent pas
              // côte à côte, au lieu de déborder ou de serrer le message sur
              // plusieurs lignes. Décision par largeur disponible, voir
              // [_shouldStack].
              child: LayoutBuilder(
                builder: (context, constraints) => _BannerContent(
                  result: result,
                  stacked: _shouldStack(context, constraints.maxWidth),
                  onDismiss: () => ref
                      .read(updateBannerDismissalControllerProvider.notifier)
                      .dismiss(result.latestVersion),
                ),
              ),
            ),
          );

    // Reduce motion : changement immédiat. Pas d'`AnimatedSize` à durée nulle
    // (assertion de layout au changement), on rend directement la forme.
    if (reduceMotion) return child;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.passthrough,
          children: [...previous, ?current],
        ),
        child: child,
      ),
    );
  }
}

/// Largeur (une seule ligne, sans contrainte) de [text] au style [style] et à
/// l'échelle de police courante.
double _measureWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// Style du libellé court de la forme compacte (corps 12, gras 700).
TextStyle _compactLabelStyle() => AppTypography.body(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
);

/// Forme compacte (D211) : une ligne, toute la barre est la cible de tap
/// (44 px de haut intérieur au minimum). Libellé court puis icône masqués, dans
/// cet ordre, quand ils ne tiennent pas sur une ligne ; le bouton ne perd
/// jamais de texte (il peut passer sur deux lignes à la frontière d'un mot).
class _CompactBanner extends StatelessWidget {
  const _CompactBanner({required this.storeUrl, super.key});

  final String? storeUrl;

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actionStyle = _UpdateLink.style().copyWith(
      decoration: TextDecoration.underline,
    );
    void open() => unawaited(openAppStorePage(context, storeUrl: storeUrl));

    return Semantics(
      container: true,
      button: true,
      label: l10n.updateBannerCompactSemantics,
      onTap: open,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.goldEnd,
              width: AppBorders.card,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: open,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final available = constraints.maxWidth;
                      final bounded = available.isFinite;
                      final actionWidth = _measureWidth(
                        context,
                        l10n.updateBannerAction,
                        actionStyle,
                      );
                      final labelWidth = _measureWidth(
                        context,
                        l10n.updateBannerCompactMessage,
                        _compactLabelStyle(),
                      );
                      const iconBlock = _iconSize + AppSpacing.sm;
                      final showLabel =
                          !bounded ||
                          iconBlock +
                                  labelWidth +
                                  AppSpacing.sm +
                                  actionWidth <=
                              available;
                      final showIcon =
                          !bounded || iconBlock + actionWidth <= available;
                      final action = Text(
                        l10n.updateBannerAction,
                        style: actionStyle,
                        softWrap: true,
                        textAlign: TextAlign.end,
                      );
                      return Row(
                        children: [
                          if (showIcon) ...[
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.file_download_outlined,
                                color: AppColors.goldEnd,
                                size: _iconSize,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (showLabel) ...[
                            Expanded(
                              child: Text(
                                l10n.updateBannerCompactMessage,
                                style: _compactLabelStyle(),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            action,
                          ] else
                            Expanded(child: action),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Largeur de la ligne du bandeau hors message/lien : icône, espacement et
/// bouton fermer (les paddings/bordure sont déjà exclus des contraintes du
/// `LayoutBuilder`).
const double _bannerChromeWidth = 20 + AppSpacing.sm + 44;

/// Nombre maximal de lignes tolérées pour le message à côté du lien : au-delà,
/// le lien passe dessous (F21).
const int _maxSideBySideMessageLines = 2;

/// Vrai quand, côte à côte avec le lien, le message devrait s'écrire sur plus
/// de [_maxSideBySideMessageLines] lignes (ou que le lien seul ne tient pas)
/// à la largeur [maxWidth] et à l'échelle de police courante. Une police
/// normale sur un écran de 360 px et plus n'empile donc jamais (apparence
/// inchangée). Repli sur le facteur d'échelle si la largeur n'est pas bornée.
bool _shouldStack(BuildContext context, double maxWidth) {
  final scaler = MediaQuery.textScalerOf(context);
  if (!maxWidth.isFinite) return scaler.scale(14) > 14 * 1.15;

  TextPainter layout(String text, TextStyle style, double width) {
    return TextPainter(
      // Même style résolu que le `Text` affiché (héritage du style par défaut,
      // dont l'espacement des lettres).
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout(maxWidth: width);
  }

  final link = layout(
    AppLocalizations.of(context)!.updateBannerAction,
    _UpdateLink.style(),
    double.infinity,
  );
  final linkWidth = link.width;
  link.dispose();

  final messageWidth = maxWidth - _bannerChromeWidth - linkWidth;
  if (messageWidth <= 0) return true;
  final message = layout(
    AppLocalizations.of(context)!.updateBannerMessage,
    _UpdateMessage.style(),
    messageWidth,
  );
  final lines = message.computeLineMetrics().length;
  message.dispose();
  return lines > _maxSideBySideMessageLines;
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.result,
    required this.stacked,
    required this.onDismiss,
  });

  final AppVersionCheckResult result;
  final bool stacked;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    const message = _UpdateMessage();
    return Row(
      children: [
        const Icon(
          Icons.file_download_outlined,
          color: AppColors.goldEnd,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    message,
                    _UpdateLink(storeUrl: result.storeUrl),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(child: message),
                    _UpdateLink(storeUrl: result.storeUrl),
                  ],
                ),
        ),
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            tooltip: AppLocalizations.of(context)!.updateBannerDismissTooltip,
            icon: const Icon(Icons.close, color: AppColors.textMuted),
            onPressed: onDismiss,
          ),
        ),
      ],
    );
  }
}

/// Lien « Mettre à jour » de [UpdateSuggestedBanner] (zone de tap d'au moins
/// 44 px de haut dans les deux modes, section 7 "Accessibilité" du design
/// system).
class _UpdateLink extends StatelessWidget {
  const _UpdateLink({required this.storeUrl});

  static TextStyle style() => AppTypography.body(
    fontWeight: FontWeight.w800,
    color: AppColors.accentBrick,
  );

  final String? storeUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openAppStorePage(context, storeUrl: storeUrl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              AppLocalizations.of(context)!.updateBannerAction,
              style: style(),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateMessage extends StatelessWidget {
  const _UpdateMessage();

  static TextStyle style() => AppTypography.body(
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.updateBannerMessage,
      style: style(),
    );
  }
}
