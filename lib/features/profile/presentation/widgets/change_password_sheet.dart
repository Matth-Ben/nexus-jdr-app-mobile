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
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour.')));
}

/// Hors-ligne (vérifié *avant* l'appel réseau) — même texte que
/// `edit_display_name_sheet.dart`/`report_bug_sheet.dart`, pas de file
/// d'attente hors-ligne pour cette écriture (`AuthRepository.updatePassword`).
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    'Impossible de mettre à jour le mot de passe. Réessayez.';

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

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Vérifié *avant* toute tentative réseau — voir la documentation de
    // [_offlineMessage].
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
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.parchmentBg),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetHeaderBar(
                    title: 'MOT DE PASSE',
                    closeEnabled: !_isSaving,
                  ),
                  Padding(
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
                          'NOUVEAU MOT DE PASSE',
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
                          decoration: const InputDecoration(
                            hintText: '••••••••',
                          ),
                          validator: AuthValidators.password,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'CONFIRMER LE MOT DE PASSE',
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
                          decoration: const InputDecoration(
                            hintText: '••••••••',
                          ),
                          validator: (value) =>
                              AuthValidators.passwordConfirmation(
                                value,
                                _passwordController.text,
                              ),
                        ),
                      ],
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
                            label: 'Annuler',
                            surface: SecondaryButtonSurface.parchment,
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Enregistrer',
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
    );
  }
}
