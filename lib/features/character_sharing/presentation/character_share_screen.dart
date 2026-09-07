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
import '../../characters/domain/character_detail.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_identity_formatter.dart';
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
    setState(() => _isBusy = true);
    try {
      await ref
          .read(characterSharingRepositoryProvider)
          .regenerateShareToken(widget.characterId);
      ref.invalidate(characterDetailProvider(widget.characterId));
      if (!mounted) return;
      _showSnackBar('Lien de partage régénéré.');
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar('Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _confirmDisable() async {
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
        title: const Text('Désactiver le partage ?'),
        content: const Text(
          'Le lien actuel cessera immédiatement de fonctionner. Tu pourras '
          'en générer un nouveau plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Désactiver',
              style: TextStyle(color: AppColors.accentBrick),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _disable();
  }

  Future<void> _disable() async {
    setState(() => _isBusy = true);
    try {
      await ref
          .read(characterSharingRepositoryProvider)
          .disableShareToken(widget.characterId);
      ref.invalidate(characterDetailProvider(widget.characterId));
      if (!mounted) return;
      _showSnackBar('Partage désactivé.');
    } on CharacterFailure catch (failure) {
      _showSnackBar(failure.message);
    } catch (_) {
      _showSnackBar('Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _copyLink(String token) async {
    await Clipboard.setData(ClipboardData(text: _linkFor(token)));
    _showSnackBar('Lien copié.');
  }

  static String _linkFor(String token) => 'https://$_shareLinkDomain/p/$token';

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(characterDetailProvider(widget.characterId));

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'PARTAGER LE PERSONNAGE',
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
                    ? error.message
                    : 'Impossible de charger ce personnage. Réessayez.',
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
            'Génère un lien pour montrer cette fiche en lecture seule à un '
            "ami ou à ton MJ, sans qu'il ait besoin d'un compte Nexus JDR.",
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isActive) ...[
            const InfoBanner(
              message: 'Partage actif',
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'LIEN DE PARTAGE',
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _ShareLinkField(
              link: _linkFor(token),
              onCopy: _isBusy ? null : () => _copyLink(token),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Quiconque possède ce lien peut consulter la fiche tant que le '
              'partage reste actif.',
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            MenuTile(
              icon: Icons.refresh,
              label: 'Régénérer le lien',
              onTap: _isBusy ? () {} : _regenerate,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(height: 1, color: AppColors.gaugeTrack),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'ZONE DANGEREUSE',
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.accentBrick,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DestructiveButton(
              label: 'Désactiver le partage',
              onPressed: _isBusy ? null : _confirmDisable,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Le lien actuel cessera immédiatement de fonctionner. Tu '
              'pourras en générer un nouveau plus tard.',
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ] else ...[
            PrimaryButton(
              label: 'Activer le partage',
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
  const _ShareLinkField({required this.link, required this.onCopy});

  final String link;
  final VoidCallback? onCopy;

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
      child: Row(
        children: [
          Expanded(
            child: Text(
              link,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'Copier le lien',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, color: AppColors.woodMedium),
          ),
        ],
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
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
