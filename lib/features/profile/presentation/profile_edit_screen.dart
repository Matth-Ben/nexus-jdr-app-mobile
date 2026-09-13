import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/menu_tile.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../../core/widgets/sheet_action_row.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../auth/domain/auth_failure.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'widgets/avatar_edit_sheet.dart';
import 'widgets/change_email_sheet.dart';
import 'widgets/change_password_sheet.dart';

/// Sous-écran "Modifier le profil", route `/profile/edit` — poussé depuis la
/// tuile "Modifier le profil" de `profile_screen.dart`.
///
/// Refonte de conformité visuelle du 13/09/2026 (recettage
/// direction-artistique) : remplace l'ancien patron "4 lignes résumé +
/// crayon, chacune ouvrant sa propre sheet" par une édition directe et
/// inline (voir maquette `docs/cahier-des-charges/09-maquettes-captures.md`,
/// section "Profil — Modifier le profil") :
/// - avatar centré (badge caméra + 2 liens "Prendre une photo"/"Choisir dans
///   la galerie", tous deux vers [showAvatarEditSheet]) ;
/// - "Pseudo" : vrai `TextFormField` inline, enregistré par le bouton
///   "Enregistrer" en bas d'écran (voir [_submit], logique reprise de
///   `showEditDisplayNameSheet`/`_EditDisplayNameSheetContentState._submit`
///   — cette sheet n'est plus ouverte depuis nulle part dans l'app, mais
///   n'a volontairement pas été supprimée comme l'a été
///   `delete_account_sheet.dart` : de nombreux autres fichiers du module
///   profil (`change_password_sheet.dart`, `report_bug_sheet.dart`,
///   `avatar_crop_screen.dart`...) la citent comme référence pour le
///   patron "sheet non-`dismissible`, sans file d'attente hors-ligne,
///   voir son rationale complet" — la garder en état évite de devoir
///   dupliquer ce rationale ailleurs. Son test associé
///   (`edit_display_name_sheet_test.dart`) reste donc lui aussi en place) ;
/// - "E-mail" : champ visuellement désactivé (lecture seule), tap ouvre
///   toujours [showChangeEmailSheet] ;
/// - "Changer le mot de passe" : ligne de menu (`MenuTile`), ouvre toujours
///   [showChangePasswordSheet].
///
/// [showAvatarEditSheet]/[showChangeEmailSheet]/[showChangePasswordSheet]
/// gardent leur logique métier inchangée (seuls leurs points d'entrée
/// visuels bougent) : voir leur documentation de classe respective.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _pseudoController;

  /// Valeur réellement stockée (`user_metadata['full_name']`, trim, jamais
  /// le repli d'affichage "Aventurier") au moment où l'écran s'est ouvert —
  /// sert de référence pour désactiver "Enregistrer" tant que le pseudo n'a
  /// pas changé, et est mise à jour après chaque sauvegarde réussie. Même
  /// principe de lecture que
  /// `_EditDisplayNameSheetContentState.initState`.
  late String _initialPseudo;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final rawName =
        ref.read(currentUserProvider)?.userMetadata?['full_name'] as String?;
    _initialPseudo = rawName?.trim() ?? '';
    _pseudoController = TextEditingController(text: _initialPseudo)
      ..addListener(_handlePseudoChanged);
  }

  @override
  void dispose() {
    _pseudoController.removeListener(_handlePseudoChanged);
    _pseudoController.dispose();
    super.dispose();
  }

  /// Le pseudo saisi pilote seul l'activation du bouton "Enregistrer" — même
  /// principe qu'un `setState` vide sur chaque frappe que
  /// `summary_step_screen.dart::_handleNameChanged`.
  void _handlePseudoChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSave {
    final trimmed = _pseudoController.text.trim();
    return !_isSaving && trimmed.isNotEmpty && trimmed != _initialPseudo;
  }

  /// Sauvegarde du pseudo — logique reprise à l'identique de
  /// `edit_display_name_sheet.dart::_EditDisplayNameSheetContentState
  /// ._submit` (vérification hors-ligne *avant* l'appel réseau, même
  /// distinction `AuthFailure`/erreur générique), à la différence près que
  /// le champ vide n'est plus un cas valide ici : le bouton "Enregistrer"
  /// est désactivé tant que le pseudo (trim) est vide, voir [_canSave] — la
  /// sheet, elle, traduit un champ vidé en un retrait de `full_name`
  /// (repli "Aventurier" à l'affichage), un geste qui n'a plus d'entrée
  /// dédiée sur cet écran (décision assumée pour cette refonte : la
  /// consigne demande explicitement de désactiver "Enregistrer" sur un
  /// pseudo vide).
  Future<void> _submit() async {
    if (!_canSave) return;
    final trimmed = _pseudoController.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _offlineMessage;
      });
      return;
    }

    try {
      await ref
          .read(authRepositoryProvider)
          .updateDisplayName(displayName: trimmed);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _initialPseudo = trimmed;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pseudo mis à jour.')));
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (error) {
      debugPrint('ProfileEditScreen._submit: erreur inattendue: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  void _goBack() {
    if (_isSaving) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(title: 'MODIFIER LE PROFIL', onBack: _goBack),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          _AvatarSection(avatarUrl: avatarUrl),
                          const SizedBox(height: AppSpacing.lg),
                          _FieldLabel('Pseudo'),
                          const SizedBox(height: AppSpacing.xs),
                          TextFormField(
                            controller: _pseudoController,
                            enabled: !_isSaving,
                            minLines: 1,
                            maxLines: 1,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: "Comment veux-tu qu'on t'appelle ?",
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _FieldLabel('E-mail'),
                          const SizedBox(height: AppSpacing.xs),
                          _DisabledEmailField(
                            email: email,
                            onTap: () => showChangeEmailSheet(
                              context,
                              currentEmail: email,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            "Modifier l'e-mail envoie un lien de "
                            'confirmation à la nouvelle adresse.',
                            style: AppTypography.body(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MenuTile(
                            icon: Icons.lock_outline,
                            label: 'Changer le mot de passe',
                            onTap: () => showChangePasswordSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        if (_errorMessage != null) ...[
                          AlertBanner(message: _errorMessage!),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SheetActionDivider(),
                        const SizedBox(height: AppSpacing.sm),
                        PrimaryButton(
                          label: 'Enregistrer',
                          isLoading: _isSaving,
                          onPressed: _canSave ? _submit : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hors-ligne (vérifié *avant* l'appel réseau) — même texte que
/// `edit_display_name_sheet.dart`, pas de file d'attente hors-ligne pour
/// cette écriture (`AuthRepository.updateDisplayName`).
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    "Impossible d'enregistrer les modifications. Réessayez.";

/// Libellé de champ ("Pseudo"/"E-mail") — copie de
/// `login_screen.dart::_FieldLabel` (même style, privé à son propre
/// fichier : pas encore de 3e usage identique qui justifierait une
/// extraction dans `core/widgets/`).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}

/// Avatar centré (88px, [ProfileAvatar] partagé avec `profile_screen.dart`)
/// + badge caméra superposé (même recette que
/// `character_identity_card.dart::_PortraitWithCameraBadge`, mis à l'échelle)
/// + 2 liens texte "Prendre une photo"/"Choisir dans la galerie".
///
/// **Choix d'implémentation** : l'avatar/le badge et les 2 liens ouvrent
/// tous le même [showAvatarEditSheet] — cette fonction n'a qu'un seul point
/// d'entrée (une sheet de choix caméra/galerie/suppression), pas 2 points
/// d'entrée séparés "caméra seule"/"galerie seule" qu'on pourrait câbler
/// distinctement sans toucher à sa logique interne (hors périmètre de cette
/// tâche, voir la documentation de classe de [ProfileEditScreen]).
class _AvatarSection extends ConsumerWidget {
  const _AvatarSection({required this.avatarUrl});

  final String? avatarUrl;

  static const double _avatarSize = 88;
  static const double _badgeSize = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openAvatarSheet() =>
        showAvatarEditSheet(context, ref: ref, avatarUrl: avatarUrl);

    return Column(
      children: [
        GestureDetector(
          onTap: openAvatarSheet,
          child: SizedBox(
            width: _avatarSize + _badgeSize / 2,
            height: _avatarSize + _badgeSize / 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(avatarUrl: avatarUrl, size: _avatarSize),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.goldEnd,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.woodDark,
                        width: AppBorders.cardEmphasisHalo,
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_camera,
                      size: 16,
                      color: AppColors.woodDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvatarLink(label: 'Prendre une photo', onTap: openAvatarSheet),
            Text(
              ' · ',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            _AvatarLink(
              label: 'Choisir dans la galerie',
              onTap: openAvatarSheet,
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarLink extends StatelessWidget {
  const _AvatarLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        // Élargit la zone de tap (section 7 "Accessibilité" du design
        // system) sans agrandir le texte, même principe que
        // `login_screen.dart` ("Mot de passe oublié ?"/"Créer un compte").
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          label,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Champ "E-mail" visuellement désactivé — fond `parchment.card-alt`
/// (légèrement plus grisé que `parchment.card`, seul token de ce ton
/// disponible dans le design système : pas de fond "disabled" documenté
/// section 4 "Champ de formulaire"), texte `text.secondary`. Volontairement
/// pas un vrai `TextFormField(enabled: false)` : ce champ n'édite jamais
/// rien lui-même (tout passe par [showChangeEmailSheet]), un simple
/// conteneur tapable évite les ambiguïtés de focus/clavier d'un champ de
/// texte réellement désactivé.
class _DisabledEmailField extends StatelessWidget {
  const _DisabledEmailField({required this.email, required this.onTap});

  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.parchmentCardAlt,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
