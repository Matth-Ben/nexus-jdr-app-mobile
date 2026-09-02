import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_failure.dart';
import '../../domain/write_outcome.dart';
import '../providers/character_detail_provider.dart';
import '../providers/character_providers.dart';

/// Ouvre la sheet "Modifier l'histoire" (icône crayon du bandeau bois de
/// l'onglet "Histoire", et bouton de son état vide — voir
/// `character_detail_screen.dart` et `character_story_tab_body.dart`).
///
/// Contrairement à `showAddRewardSheet` (ferme immédiatement, écriture
/// déléguée à l'appelant via un callback), cette sheet est **autoportante** :
/// elle effectue elle-même l'appel réseau et n'appelle `Navigator.pop`
/// qu'une fois celui-ci résolu (voir la documentation de classe de
/// [_CharacterStoryEditSheetContent]) — pattern calqué sur
/// `portrait_upload_sheet.dart::_PortraitUrlDialog`, approuvé par le chef de
/// projet pour cet écran précisément (perte potentielle de plusieurs
/// paragraphes de texte libre en cas de fermeture aveugle sur échec, coût
/// sans commune mesure avec un montant de monnaie ou un objet à réajouter en
/// un tap).
///
/// Cette fonction ouvrante affiche le `SnackBar` de confirmation une fois la
/// sheet refermée avec succès (`pop(true)`) — split de responsabilité
/// identique à `portrait_upload_sheet.dart::_confirmAndRemove` : la sheet
/// gère son propre cycle de vie (état de sauvegarde, bandeau d'erreur
/// inline), la fonction appelante gère le feedback post-fermeture, sur le
/// [BuildContext] de l'écran appelant plutôt que celui — éphémère — de la
/// sheet une fois refermée.
Future<void> showCharacterStoryEditSheet(
  BuildContext context, {
  required String characterId,
  required CharacterDetail detail,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // La sheet ne doit se fermer que via ses propres boutons ("Annuler"/X du
    // `SheetHeaderBar`) — jamais par le voile, le swipe-down ou le geste
    // retour Android, qui contourneraient sinon le `closeEnabled: !_isSaving`
    // pendant l'appel réseau `updateStoryFields` (voir la documentation de
    // classe de [_CharacterStoryEditSheetContent]).
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => _CharacterStoryEditSheetContent(
      characterId: characterId,
      detail: detail,
    ),
  );
  if (saved != true || !context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Histoire mise à jour.')));
}

/// Libellé + placeholder d'un des 9 champs — copie exacte de
/// `appearance_and_backstory_step_screen.dart::_TextFieldSpec`/
/// `_fieldSpecs` (seul précédent de saisie de ces 9 champs). Duplication
/// assumée plutôt que factorisation prématurée (2e usage seulement) — voir
/// la spec direction-artistique de la tâche qui a introduit ce fichier.
class _StoryFieldSpec {
  const _StoryFieldSpec({required this.label, required this.hint});

  final String label;
  final String hint;
}

/// Ordre canonique 1..9 (`CharacterStoryFieldsResolver`), mono-colonne —
/// contrairement à la vue lecture de l'onglet (`character_story_tab_body.dart`),
/// qui regroupe Idéaux/Défauts sur une même ligne à 2 colonnes pour coller à
/// la maquette. Écart assumé entre vue lecture et vue édition (spec
/// direction-artistique) : la vue lecture suit la maquette, la vue édition
/// calque l'étape 8/9 de l'assistant de création (seul précédent de saisie),
/// qui est mono-colonne.
const List<_StoryFieldSpec> _fieldSpecs = [
  _StoryFieldSpec(
    label: 'APPARENCE PHYSIQUE',
    hint: "Décris l'apparence physique de ton personnage…",
  ),
  _StoryFieldSpec(
    label: 'TRAITS DE PERSONNALITÉ',
    hint: 'Décris les traits de personnalité de ton personnage…',
  ),
  _StoryFieldSpec(
    label: 'IDÉAUX',
    hint: 'Quels idéaux guident ton personnage ?',
  ),
  _StoryFieldSpec(
    label: 'LIENS',
    hint: "Quels liens unissent ton personnage à d'autres ?",
  ),
  _StoryFieldSpec(
    label: 'DÉFAUTS',
    hint: 'Quels défauts ou faiblesses a ton personnage ?',
  ),
  _StoryFieldSpec(
    label: 'HISTOIRE PERSONNELLE',
    hint: "Raconte l'histoire personnelle de ton personnage…",
  ),
  _StoryFieldSpec(
    label: 'ALLIÉS',
    hint: 'Quels alliés ou organisations soutiennent ton personnage ?',
  ),
  _StoryFieldSpec(
    label: 'PARTICULARITÉS',
    hint: 'Décris les particularités de ton personnage…',
  ),
  _StoryFieldSpec(
    label: 'TRÉSOR',
    hint: 'Quels trésors ou objets précieux possède ton personnage ?',
  ),
];

/// Message hors-ligne — même texte que le bandeau/`SnackBar` déjà utilisé
/// ailleurs sur la fiche (`character_detail_screen.dart::_offlineNotPersistedMessage`),
/// jamais dupliqué dans une constante partagée (chaque écran affiche ce
/// message par un mécanisme différent : bandeau inline ici, `SnackBar`
/// ailleurs — voir la documentation de classe de
/// [_CharacterStoryEditSheetContentState._submit]).
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

const String _genericErrorMessage =
    "Impossible d'enregistrer les modifications. Réessayez.";

/// Gabarit B autoportant (`showModalBottomSheet`, `isScrollControlled: true`,
/// `FractionallySizedBox(heightFactor: 0.92)`) : `SheetHeaderBar`, 9 champs
/// mono-colonne dans l'ordre canonique, pied fixe "Annuler"/"Enregistrer".
///
/// `ConsumerStatefulWidget` — appelle elle-même
/// `ref.read(characterRepositoryProvider).updateStoryFields(...)` au tap
/// "Enregistrer" et **attend le résultat avant de se fermer** (ne `pop` pas
/// immédiatement, contrairement à `add_reward_sheet.dart`) : en cas d'échec,
/// le texte saisi dans les 9 champs reste intact et un bandeau d'alerte
/// inline (jamais un `SnackBar`, la sheet reste ouverte) explique l'échec,
/// pour que le joueur puisse retenter "Enregistrer" sans retaper — voir la
/// documentation de [showCharacterStoryEditSheet] pour le rationale complet
/// de ce pattern (approuvé par le chef de projet spécifiquement pour cet
/// écran).
class _CharacterStoryEditSheetContent extends ConsumerStatefulWidget {
  const _CharacterStoryEditSheetContent({
    required this.characterId,
    required this.detail,
  });

  final String characterId;
  final CharacterDetail detail;

  @override
  ConsumerState<_CharacterStoryEditSheetContent> createState() =>
      _CharacterStoryEditSheetContentState();
}

class _CharacterStoryEditSheetContentState
    extends ConsumerState<_CharacterStoryEditSheetContent> {
  late final List<TextEditingController> _controllers;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Préremplissage synchrone depuis `widget.detail`, déjà en mémoire —
    // pas d'état de chargement à l'ouverture (spec de la tâche).
    final detail = widget.detail;
    final values = <String>[
      detail.appearanceText,
      detail.traitsText,
      detail.idealsText,
      detail.bondsText,
      detail.flawsText,
      detail.backstoryText,
      detail.alliesText,
      detail.featuresText,
      detail.treasureText,
    ];
    _controllers = [
      for (final value in values) TextEditingController(text: value),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Un champ vidé (texte blanc après `trim`) devient `null` — voir la
  /// documentation de [CharacterRepository.updateStoryFields] pour ce que la
  /// méthode de repository en fait ensuite (coalescé vers `''` avant
  /// écriture, jamais un `null` littéral envoyé au serveur).
  String? _valueAt(int index) {
    final text = _controllers[index].text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final outcome = await ref
          .read(characterRepositoryProvider)
          .updateStoryFields(
            characterId: widget.characterId,
            appearanceText: _valueAt(0),
            traitsText: _valueAt(1),
            idealsText: _valueAt(2),
            bondsText: _valueAt(3),
            flawsText: _valueAt(4),
            backstoryText: _valueAt(5),
            alliesText: _valueAt(6),
            featuresText: _valueAt(7),
            treasureText: _valueAt(8),
          );

      if (outcome == WriteOutcome.queued) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _errorMessage = _offlineMessage;
        });
        return;
      }

      // `mounted` vérifié AVANT `ref.invalidate` (et non après, comme le
      // reste de cette méthode) : `ref.invalidate` sur un `ConsumerState`
      // lève un `StateError` si le widget a été démonté entre-temps, ce qui
      // serait autrement rattrapé par le `catch` générique ci-dessous et
      // avalé silencieusement — laissant `characterDetailProvider` non
      // invalidé alors que l'écriture a bien réussi côté serveur.
      if (!mounted) return;
      ref.invalidate(characterDetailProvider(widget.characterId));
      Navigator.of(context).pop(true);
    } on CharacterFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.message;
      });
    } catch (error) {
      debugPrint('CharacterStoryEditSheet._submit: erreur inattendue: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // `isDismissible: false`/`enableDrag: false` (voir
    // `showCharacterStoryEditSheet`) bloquent respectivement le tap sur le
    // voile et le swipe-down, mais ni l'un ni l'autre ne bloque le geste
    // retour Android (ni tout appel programmatique à `Navigator.maybePop`) :
    // celui-ci passe par un mécanisme entièrement séparé
    // (`ModalRoute.popDisposition`), jamais consulté par le voile ou le
    // drag. D'où ce `PopScope` dédié, seule garde qui couvre ce chemin —
    // `canPop: !_isSaving` reste cohérent avec `closeEnabled`/`onPressed`
    // désactivés ailleurs dans ce widget pendant l'appel réseau.
    return PopScope(
      canPop: !_isSaving,
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            decoration: const BoxDecoration(color: AppColors.parchmentBg),
            child: Column(
              children: [
                SheetHeaderBar(
                  title: "MODIFIER L'HISTOIRE",
                  closeEnabled: !_isSaving,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMessage != null) ...[
                          _AlertBanner(message: _errorMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        for (var i = 0; i < _fieldSpecs.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.md),
                          _StoryTextFieldBlock(
                            spec: _fieldSpecs[i],
                            controller: _controllers[i],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
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

/// Titre + `TextFormField` d'un des 9 champs — même agencement que
/// `appearance_and_backstory_step_screen.dart::_TextFieldBlock`
/// (`minLines: 1, maxLines: null`, `AppTheme.light.inputDecorationTheme` par
/// défaut, sans surcharge locale), sans les `FocusNode`/`onFieldSubmitted`
/// de navigation clavier séquentielle de cet écran-là (pas demandé par la
/// spec de cette sheet).
class _StoryTextFieldBlock extends StatelessWidget {
  const _StoryTextFieldBlock({required this.spec, required this.controller});

  final _StoryFieldSpec spec;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.label,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          minLines: 1,
          maxLines: null,
          decoration: InputDecoration(hintText: spec.hint),
        ),
      ],
    );
  }
}

/// "Bandeau d'alerte inline" du design système — dupliqué depuis
/// `summary_step_screen.dart::_AlertBanner` (`AppColors.alertBannerBackground`,
/// bordure 2px `AppColors.accentBrick`, `Icons.warning_amber_rounded`),
/// même rationale de duplication que le reste de ce module (chaque écran
/// garde sa propre copie privée plutôt qu'un composant partagé introduit
/// pour un 2e usage).
class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.accentBrick,
          width: AppBorders.card,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentBrick,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
