import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import 'group_join_routes.dart';
import 'widgets/group_join_step_header.dart';

/// Étape 1/3 du flux "Rejoindre un groupe" : saisie du code d'invitation —
/// calque exact de `features/join_story/presentation/join_code_step_screen.dart`
/// (`docs/cahier-des-charges/12-partage-et-groupes.md` section 2), sous-texte
/// propre à cette tâche ("Code fourni par le créateur du groupe").
class GroupJoinCodeStepScreen extends StatefulWidget {
  const GroupJoinCodeStepScreen({this.initialCode, super.key});

  /// Pré-remplissage du champ — utilisé par le bouton "Modifier le code" de
  /// l'étape 2/3 en cas de code invalide.
  final String? initialCode;

  @override
  State<GroupJoinCodeStepScreen> createState() =>
      _GroupJoinCodeStepScreenState();
}

class _GroupJoinCodeStepScreenState extends State<GroupJoinCodeStepScreen> {
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
    context.push(GroupJoinRoutes.confirmation(code));
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
          GroupJoinStepHeader(
            stepTitle: 'Code',
            currentStep: 1,
            onBack: _goBack,
          ),
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
                                _UpperCaseTextFormatter(),
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
                              'Code fourni par le créateur du groupe '
                              '(lettres et chiffres).',
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

/// Force la saisie en majuscules à chaque frappe — duplication volontaire de
/// `features/join_story/presentation/join_code_step_screen.dart::UpperCaseTextFormatter`
/// (voir sa documentation pour le rationale complet) : ce dépôt duplique
/// plutôt que d'importer un écran d'une autre feature pour une seule petite
/// classe utilitaire, même convention que `GroupMemberRowMapper`/
/// `CharacterRowMapper`.
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
