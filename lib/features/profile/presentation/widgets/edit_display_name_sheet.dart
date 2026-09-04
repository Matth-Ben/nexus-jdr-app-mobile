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
import '../../../auth/presentation/providers/auth_providers.dart';

/// Ouvre la sheet "Pseudo" (ligne "Pseudo" de `profile_edit_screen.dart`,
/// sous-écran poussé depuis la tuile "Modifier le profil" de
/// `profile_screen.dart`) — sheet autoportante calquée sur
/// `character_story_edit_sheet.dart` (voir sa documentation de classe pour le
/// rationale complet du pattern "attend le résultat réseau sur place"), mais
/// réduite à un seul champ mono-ligne : le nom d'affichage
/// (`user_metadata['full_name']`).
///
/// Titre `SheetHeaderBar`/message de confirmation renommés "PSEUDO"/"Pseudo
/// mis à jour." (spec direction-artistique du flux "Modifier le profil" à 4
/// lignes) — anciennement "MODIFIER LE PROFIL"/"Profil mis à jour.", quand
/// cette sheet était le seul contenu de la tuile "Modifier le profil".
///
/// Même split de responsabilité que `showCharacterStoryEditSheet` : cette
/// fonction ouvrante affiche le `SnackBar` de confirmation une fois la sheet
/// refermée avec succès (`pop(true)`), sur le [BuildContext] de l'écran
/// appelant plutôt que celui — éphémère — de la sheet.
Future<void> showEditDisplayNameSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Même rationale que `character_story_edit_sheet.dart` : ne se ferme que
    // via ses propres boutons, jamais par le voile/le swipe/le geste retour
    // Android, qui contourneraient `closeEnabled: !_isSaving` pendant
    // l'appel réseau `updateDisplayName`.
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => const _EditDisplayNameSheetContent(),
  );
  if (saved != true || !context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Pseudo mis à jour.')));
}

/// Message hors-ligne — texte identique à
/// `character_story_edit_sheet.dart::_offlineMessage` (même bandeau inline,
/// jamais un `SnackBar` pendant que la sheet reste ouverte).
///
/// Contrairement à `CharacterRepository.updateHp`/`updateStoryFields`...,
/// `AuthRepository.updateDisplayName` n'a pas de file d'attente hors-ligne
/// (`Supabase Auth` n'en a pas dans ce dépôt, voir sa documentation) : cette
/// sheet vérifie donc elle-même la connectivité *avant* de tenter l'appel
/// réseau (voir [_EditDisplayNameSheetContentState._submit]), pour ne
/// jamais laisser un vrai appel réseau échouer silencieusement en "hors
/// ligne" — même geste que `SupabaseCharacterRepository.updateHp`, reproduit
/// ici côté sheet faute d'équivalent côté dépôt pour cette écriture précise.
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    "Impossible d'enregistrer les modifications. Réessayez.";

class _EditDisplayNameSheetContent extends ConsumerStatefulWidget {
  const _EditDisplayNameSheetContent();

  @override
  ConsumerState<_EditDisplayNameSheetContent> createState() =>
      _EditDisplayNameSheetContentState();
}

class _EditDisplayNameSheetContentState
    extends ConsumerState<_EditDisplayNameSheetContent> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Préremplissage synchrone depuis `currentUserProvider`, déjà en
    // mémoire — jamais avec le fallback d'affichage "Aventurier"
    // (`profile_screen.dart`), qui n'existe qu'à l'affichage, pas comme
    // valeur réellement stockée (spec direction-artistique de la tâche).
    final rawName =
        ref.read(currentUserProvider)?.userMetadata?['full_name'] as String?;
    _controller = TextEditingController(text: rawName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Un champ vidé (texte blanc après `trim`) devient `null` — même
  /// coalescing que `character_story_edit_sheet.dart::_valueAt`, ce que
  /// `AuthRepository.updateDisplayName` traduit ensuite en un retrait pur et
  /// simple de la clé `full_name` (voir sa documentation).
  String? get _trimmedValue {
    final text = _controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Vérifié *avant* toute tentative réseau — voir la documentation de
    // [_offlineMessage] : `AuthRepository.updateDisplayName` n'a aucune file
    // d'attente hors-ligne vers laquelle se replier.
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
          .updateDisplayName(displayName: _trimmedValue);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (error) {
      debugPrint('EditDisplayNameSheet._submit: erreur inattendue: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Voir `character_story_edit_sheet.dart` pour le rationale complet de ce
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHeaderBar(title: 'PSEUDO', closeEnabled: !_isSaving),
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
                        "NOM D'AFFICHAGE",
                        style: AppTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: "Comment veux-tu qu'on t'appelle ?",
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
    );
  }
}
