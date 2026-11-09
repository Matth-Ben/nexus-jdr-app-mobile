import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
class UpdateSuggestedBanner extends ConsumerWidget {
  const UpdateSuggestedBanner({super.key});

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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.parchmentCard,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.goldEnd, width: AppBorders.card),
        ),
        // Police système agrandie / écran étroit (F21) : le lien « Mettre à
        // jour » passe sous le message quand les deux ne tiennent pas côte à
        // côte, au lieu de déborder ou de serrer le message sur plusieurs
        // lignes. Décision par largeur disponible, voir [_shouldStack].
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

  final link = layout(_UpdateLink.label, _UpdateLink.style(), double.infinity);
  final linkWidth = link.width;
  link.dispose();

  final messageWidth = maxWidth - _bannerChromeWidth - linkWidth;
  if (messageWidth <= 0) return true;
  final message = layout(
    _UpdateMessage.label,
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
            tooltip: 'Fermer',
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

  static const label = 'Mettre à jour';

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
            child: Text(label, style: style()),
          ),
        ),
      ),
    );
  }
}

class _UpdateMessage extends StatelessWidget {
  const _UpdateMessage();

  static const label = 'Nouvelle version disponible';

  static TextStyle style() => AppTypography.body(
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Text(label, style: style());
  }
}
