import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/domain/auth_validators.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Ouvre la sheet "Mot de passe" (ligne "Mot de passe" de
/// `profile_edit_screen.dart`) — même famille autoportante que
/// `edit_display_name_sheet.dart` (`isDismissible: false`, `enableDrag:
/// false`, `PopScope(canPop: !_isSaving)`), mais avec un vrai `Form`
/// (`autovalidateMode: AutovalidateMode.onUserInteraction`, comme
/// `login_screen.dart`) plutôt que le pattern "bandeau-only" des autres
/// sheets : deux champs mot de passe/confirmation, validés localement avant
/// tout appel réseau.
///
/// Aucune redemande du mot de passe actuel — voir
/// `AuthRepository.updatePassword`, la session déjà valide suffit.
Future<void> showChangePasswordSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Même rationale que `edit_display_name_sheet.dart` : ne se ferme que
    // via ses propres boutons, jamais par le voile/le swipe/le geste retour
    // Android, qui contourneraient `closeEnabled: !_isSaving` pendant
    // l'appel réseau `updatePassword`.
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => const _ChangePasswordSheetContent(),
  );
  if (saved != true || !context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.profileChangePasswordUpdatedSnackbar)),
  );
}

class _ChangePasswordSheetContent extends ConsumerStatefulWidget {
  const _ChangePasswordSheetContent();

  @override
  ConsumerState<_ChangePasswordSheetContent> createState() =>
      _ChangePasswordSheetContentState();
}

class _ChangePasswordSheetContentState
    extends ConsumerState<_ChangePasswordSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    // Validation locale d'abord : en cas de champ vide/trop court/non
    // confirmé, on ne contacte jamais Supabase — même principe que
    // `login_screen.dart::_submit`.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Vérifié *avant* toute tentative réseau — voir la documentation de
    // `profileChangePasswordOfflineMessage`.
    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.profileChangePasswordOfflineMessage;
      });
      return;
    }

    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(newPassword: _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (error) {
      debugPrint('ChangePasswordSheet._submit: erreur inattendue: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.profileChangePasswordGenericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Voir `edit_display_name_sheet.dart` pour le rationale complet de ce
    // `PopScope` (seul garde-fou qui couvre le geste retour Android, chemin
    // entièrement distinct du voile/du drag).
    return PopScope(
      canPop: !_isSaving,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            // Plafonne la hauteur de la sheet pour le contenu long (champs en
            // erreur + texte agrandi, voir `10-design-system.md` section 7) :
            // au-delà, c'est la zone défilante ajoutée ci-dessous qui absorbe
            // le débordement plutôt que l'écran.
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: AppColors.parchmentBg),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetHeaderBar(
                      title: l10n.profileChangePasswordTitle,
                      closeEnabled: !_isSaving,
                    ),
                    Flexible(
                      // `SingleChildScrollView` n'a pas de paramètre
                      // `shrinkWrap` (contrairement à `ListView`) : il n'en a
                      // pas besoin — avec les contraintes lâches que lui
                      // donne ce `Flexible`, il épouse déjà la hauteur de
                      // son contenu, et ne défile que si le contenu dépasse
                      // l'espace laissé par le `ConstrainedBox` ci-dessus.
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_errorMessage != null) ...[
                                AlertBanner(message: _errorMessage!),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              Text(
                                l10n.profileChangePasswordNewLabel,
                                style: AppTypography.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: l10n.profileChangePasswordHint,
                                ),
                                validator: (value) =>
                                    AuthValidators.password(value, l10n),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                l10n.profileChangePasswordConfirmLabel,
                                style: AppTypography.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: l10n.profileChangePasswordHint,
                                ),
                                validator: (value) =>
                                    AuthValidators.passwordConfirmation(
                                      value,
                                      _passwordController.text,
                                      l10n,
                                    ),
                              ),
                            ],
                          ),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: l10n.profileChangePasswordCancel,
                              surface: SecondaryButtonSurface.parchment,
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PrimaryButton(
                              label: l10n.profileChangePasswordSave,
                              isLoading: _isSaving,
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
