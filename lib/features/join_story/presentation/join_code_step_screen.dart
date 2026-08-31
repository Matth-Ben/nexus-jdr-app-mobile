import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import 'join_routes.dart';
import 'widgets/join_step_header.dart';

/// Étape 1/4 du flux "Rejoindre une histoire" : saisie du code d'invitation
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 7.1,
/// `05-ux-navigation.md`).
///
/// Sautée entièrement quand le flux est ouvert via le deep link
/// `nexus-jdr.app/join/{code}` — voir la route `/join/:code`
/// (`core/router/app_router.dart`), qui pousse directement
/// [JoinConfirmationStepScreen] avec le code déjà résolu.
class JoinCodeStepScreen extends StatefulWidget {
  const JoinCodeStepScreen({this.initialCode, super.key});

  /// Pré-remplissage du champ — utilisé par le bouton "Modifier le code" de
  /// l'étape 2/4 (`join_confirmation_step_screen.dart`) en cas de code
  /// invalide/invitation désactivée, pour ne pas faire retaper un code déjà
  /// saisi une fois.
  final String? initialCode;

  @override
  State<JoinCodeStepScreen> createState() => _JoinCodeStepScreenState();
}

class _JoinCodeStepScreenState extends State<JoinCodeStepScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialCode ?? '',
  );

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _submit() {
    final code = _controller.text.trim();
    if (code.length < 6) return;
    context.push(JoinRoutes.confirmation(code));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          JoinStepHeader(stepTitle: 'Code', currentStep: 1, onBack: _goBack),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _controller,
                              autofocus: true,
                              maxLength: 8,
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                UpperCaseTextFormatter(),
                                FilteringTextInputFormatter.allow(
                                  RegExp('[A-Za-z0-9]'),
                                ),
                              ],
                              style: AppTypography.body(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ).copyWith(letterSpacing: 6),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'AB3F7K',
                                hintTextDirection: TextDirection.ltr,
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Code fourni par ton MJ (lettres et chiffres).',
                              textAlign: TextAlign.center,
                              style: AppTypography.body(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PrimaryButton(
                      label: 'Suivant',
                      onPressed: _controller.text.trim().length >= 6
                          ? _submit
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Force la saisie en majuscules à chaque frappe — `textCapitalization`
/// n'agit que sur le clavier logiciel (suggestion de casse), pas sur le
/// texte réellement inséré (ex. clavier physique, autocomplétion) : ce
/// formatter est le seul mécanisme fiable pour garantir un code toujours
/// affiché/enregistré en majuscules, quelle que soit la source de la saisie.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
