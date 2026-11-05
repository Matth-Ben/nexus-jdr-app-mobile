import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/menu_tile.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../characters/domain/character_detail.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_identity_formatter.dart';
import '../../characters/presentation/character_failure_presenter.dart';
import '../../characters/presentation/providers/character_detail_provider.dart';
import 'providers/character_sharing_providers.dart';

/// Domaine public du lien de partage — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 5.3 pour le
/// même domaine déjà utilisé par le deep link "Rejoindre une histoire"
/// (`nexus-jdr.app/join/{code}`), même convention pour le partage de
/// personnage (`/p/{token}`, voir `core/router/app_router.dart`).
const String _shareLinkDomain = 'nexus-jdr.app';

/// Écran "Partager le personnage" (gérer le lien de partage en lecture
/// seule), route `/characters/:id/share` — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 1 et la
/// maquette "Partage — Gérer le lien"
/// (`docs/cahier-des-charges/09-maquettes-captures.md`).
///
/// Lit `characterDetailProvider(characterId)` (déjà utilisé par la fiche
/// personnage) plutôt qu'un fetch dédié : ce provider porte déjà
/// [CharacterDetail.shareToken] (voir
/// `character_repository.dart::fetchCharacterDetail`), aucune requête
/// supplémentaire n'est nécessaire pour afficher l'état courant du partage.
class CharacterShareScreen extends ConsumerStatefulWidget {
  const CharacterShareScreen({required this.characterId, super.key});

  final String characterId;

  @override
  ConsumerState<CharacterShareScreen> createState() =>
      _CharacterShareScreenState();
}

class _CharacterShareScreenState extends ConsumerState<CharacterShareScreen> {
  bool _isBusy = false;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _regenerate() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isBusy = true);
    try {
      await ref
          .read(characterSharingRepositoryProvider)
          .regenerateShareToken(widget.characterId);
      ref.invalidate(characterDetailProvider(widget.characterId));
      if (!mounted) return;
      _showSnackBar(l10n.characterShareScreenRegenerateSuccessMessage);
    } on CharacterFailure catch (failure) {
      _showSnackBar(resolveCharacterFailureMessage(l10n, failure));
    } catch (_) {
      _showSnackBar(l10n.characterShareScreenGenericErrorMessage);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmDisable() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.parchmentCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(
            color: AppColors.woodLight,
            width: AppBorders.card,
          ),
        ),
        title: Text(l10n.characterShareScreenDisableDialogTitle),
        content: Text(l10n.characterShareScreenDisableHelperText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.characterShareScreenDisableDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.characterShareScreenDisableDialogConfirm,
              style: const TextStyle(color: AppColors.accentBrick),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _disable();
  }

  Future<void> _disable() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isBusy = true);
    try {
      await ref
          .read(characterSharingRepositoryProvider)
          .disableShareToken(widget.characterId);
      ref.invalidate(characterDetailProvider(widget.characterId));
      if (!mounted) return;
      _showSnackBar(l10n.characterShareScreenDisableSuccessMessage);
    } on CharacterFailure catch (failure) {
      _showSnackBar(resolveCharacterFailureMessage(l10n, failure));
    } catch (_) {
      _showSnackBar(l10n.characterShareScreenGenericErrorMessage);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _copyLink(String token) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: _linkFor(token)));
    _showSnackBar(l10n.characterShareScreenLinkCopiedMessage);
  }

  static String _linkFor(String token) => 'https://$_shareLinkDomain/p/$token';

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(characterDetailProvider(widget.characterId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: l10n.characterShareScreenHeaderTitle,
            onBack: _goBack,
          ),
          Expanded(
            child: detailAsync.when(
              data: _buildContent,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is CharacterFailure
                    ? resolveCharacterFailureMessage(l10n, error)
                    : l10n.characterShareScreenLoadErrorMessage,
                onRetry: () =>
                    ref.invalidate(characterDetailProvider(widget.characterId)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CharacterDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final token = detail.shareToken;
    final isActive = token != null && token.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IdentityCard(detail: detail),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.characterShareScreenIntroText,
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isActive) ...[
            InfoBanner.success(message: l10n.characterShareScreenActiveBanner),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.characterShareScreenLinkLabel,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(child: _ShareLinkField(link: _linkFor(token))),
                const SizedBox(width: AppSpacing.sm),
                _CopyLinkButton(
                  onCopy: _isBusy ? null : () => _copyLink(token),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.characterShareScreenLinkHelperText,
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            MenuTile(
              icon: Icons.refresh,
              label: l10n.characterShareScreenRegenerateMenuLabel,
              onTap: _isBusy ? () {} : _regenerate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(height: 1, color: AppColors.gaugeTrack),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.characterShareScreenDangerZoneLabel,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.accentBrick,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DestructiveButton(
              label: l10n.characterShareScreenDisableButtonLabel,
              icon: Icons.block,
              onPressed: _isBusy ? null : _confirmDisable,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.characterShareScreenDisableHelperText,
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ] else ...[
            PrimaryButton(
              label: l10n.characterShareScreenActivateButtonLabel,
              isLoading: _isBusy,
              onPressed: _isBusy ? null : _regenerate,
            ),
          ],
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.detail});

  final CharacterDetail detail;

  @override
  Widget build(BuildContext context) {
    final subtitle = CharacterIdentityFormatter.subtitleLine1(detail);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortraitFrame(portraitUrl: detail.portraitUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: AppTypography.body(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareLinkField extends StatelessWidget {
  const _ShareLinkField({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Text(
        link,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Bouton "Copier le lien", détaché du champ (recettage direction-artistique
/// du 13/09/2026, écran "Partage — Gérer le lien") : carré ~48×48, fond
/// `AppColors.primaryButtonGradient`, icône `Icons.copy_outlined` blanche —
/// auparavant un `IconButton` transparent intégré à `_ShareLinkField`.
class _CopyLinkButton extends StatelessWidget {
  const _CopyLinkButton({required this.onCopy});

  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onCopy != null;
    final l10n = AppLocalizations.of(context)!;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onCopy,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Tooltip(
                  message: l10n.characterShareScreenCopyLinkTooltip,
                  child: const Icon(Icons.copy_outlined, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: Text(l10n.characterShareScreenRetryButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
