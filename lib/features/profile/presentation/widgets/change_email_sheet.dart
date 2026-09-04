import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/domain/auth_validators.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Ouvre la sheet "Adresse email" (ligne "Email" de
/// `profile_edit_screen.dart`) — même famille que
/// `change_password_sheet.dart` (`Form`, `autovalidateMode:
/// AutovalidateMode.onUserInteraction`), avec un [InfoBanner] permanent
/// (pas un bandeau d'erreur) rappelant que le changement n'est pas
/// immédiat : `Supabase Auth` envoie un e-mail de confirmation à la
/// nouvelle adresse, voir `AuthRepository.updateEmail`.
///
/// [currentEmail] : rappel non éditable affiché sous le champ (`user
/// ?.email`, lu par l'appelant — cette sheet n'a pas besoin d'accéder à
/// `currentUserProvider` elle-même).
Future<void> showChangeEmailSheet(
  BuildContext context, {
  required String currentEmail,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Même rationale que `change_password_sheet.dart` : ne se ferme que via
    // ses propres boutons, jamais par le voile/le swipe/le geste retour
    // Android, qui contourneraient `closeEnabled: !_isSaving` pendant
    // l'appel réseau `updateEmail`.
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) =>
        _ChangeEmailSheetContent(currentEmail: currentEmail),
  );
  if (sent != true || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Email de confirmation envoyé. Vérifie ta boîte de réception pour '
        'finaliser le changement.',
      ),
    ),
  );
}

/// Hors-ligne (vérifié *avant* l'appel réseau) — même texte que
/// `change_password_sheet.dart`, pas de file d'attente hors-ligne pour cette
/// écriture (`AuthRepository.updateEmail`).
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    "Impossible d'envoyer le nouvel email. Réessayez.";

class _ChangeEmailSheetContent extends ConsumerStatefulWidget {
  const _ChangeEmailSheetContent({required this.currentEmail});

  final String currentEmail;

  @override
  ConsumerState<_ChangeEmailSheetContent> createState() =>
      _ChangeEmailSheetContentState();
}

class _ChangeEmailSheetContentState
    extends ConsumerState<_ChangeEmailSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    // Validation locale d'abord — même principe que
    // `change_password_sheet.dart::_submit`.
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
          .updateEmail(newEmail: _emailController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (error) {
      debugPrint('ChangeEmailSheet._submit: erreur inattendue: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Voir `change_password_sheet.dart` pour le rationale complet de ce
    // `PopScope`.
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
                    title: 'ADRESSE EMAIL',
                    closeEnabled: !_isSaving,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const InfoBanner(
                          icon: Icons.mark_email_unread_outlined,
                          message:
                              'Un email de confirmation sera envoyé à cette '
                              'adresse. Le changement ne sera effectif '
                              "qu'après confirmation.",
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_errorMessage != null) ...[
                          AlertBanner(message: _errorMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Text(
                          'NOUVELLE ADRESSE EMAIL',
                          style: AppTypography.body(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            hintText: 'nom@exemple.com',
                          ),
                          validator: AuthValidators.email,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Adresse actuelle : ${widget.currentEmail}',
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textMuted,
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
