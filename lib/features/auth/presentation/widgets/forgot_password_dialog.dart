import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/auth_validators.dart';
import '../providers/auth_providers.dart';

/// Ouvre la boîte de dialogue "Mot de passe oublié ?" (lien sous le champ
/// mot de passe de [LoginScreen], visible uniquement en mode connexion).
///
/// Affiche ensuite le [SnackBar] neutre (`AppLocalizations
/// .authForgotPasswordNeutralMessage`) si l'envoi a été tenté (succès ou
/// échec réseau générique confondus, cf. doc de classe de
/// [AuthRepository.resetPasswordForEmail]) — rien ne s'affiche si le joueur
/// annule la boîte de dialogue sans avoir tenté d'envoi.
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  required WidgetRef ref,
  required String initialEmail,
}) async {
  final attempted = await showDialog<bool>(
    context: context,
    builder: (context) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );
  if (attempted != true || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.authForgotPasswordNeutralMessage)),
  );
}

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  const _ForgotPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    final repository = ref.read(authRepositoryProvider);
    try {
      await repository.resetPasswordForEmail(
        email: _emailController.text.trim(),
      );
    } catch (_) {
      // Volontairement ignoré : que l'envoi réussisse ou échoue (y compris
      // "aucun compte avec cet email", jamais distingué par Supabase pour
      // cet appel), l'appelant affiche systématiquement le même message
      // neutre (voir `showForgotPasswordDialog`).
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppColors.parchmentCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(
          color: AppColors.woodLight,
          width: AppBorders.card,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.authForgotPasswordTitle,
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.authForgotPasswordDescription,
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: l10n.authForgotPasswordEmailHint,
                ),
                validator: (value) => AuthValidators.email(value, l10n),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: l10n.authForgotPasswordCancel,
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.authForgotPasswordSubmit,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
