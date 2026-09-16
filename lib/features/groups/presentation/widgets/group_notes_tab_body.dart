import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';

/// Callback "Enregistrer" de l'onglet "Notes" — voir
/// `GroupRepository.saveGroupNote`. Reçoit le texte intégral du champ, pas un
/// diff (même principe que `GroupRepository.addToTreasure`).
typedef SaveGroupNoteCallback = void Function(String body);

/// Contenu de l'onglet "Notes" de l'écran "Groupe" (demande utilisateur du
/// 16/09/2026, hors cahier des charges — carnet personnel pendant la partie,
/// jamais partagé avec les coéquipiers, voir `group_note.dart`).
///
/// Ne fait aucun appel réseau lui-même — collecte le texte (saisie clavier
/// ou dictée au micro via [_DictationButton]) et transmet à [onSave], appelé
/// par l'écran "Groupe" (même architecture que `GroupTreasureTabBody`, voir
/// la doc de classe de `GroupRepository` : "les sheets/onglets ne font que
/// collecter l'action/l'entrée").
class GroupNotesTabBody extends StatefulWidget {
  const GroupNotesTabBody({
    required this.initialBody,
    required this.isSaving,
    required this.onSave,
    required this.onDictationError,
    super.key,
  });

  final String initialBody;
  final bool isSaving;
  final SaveGroupNoteCallback onSave;

  /// Micro indisponible/refusé/erreur de reconnaissance — l'écran "Groupe"
  /// affiche un `SnackBar`, même widget n'ayant pas accès à un
  /// `ScaffoldMessenger` propre (pas de `Scaffold` imbriqué ici).
  final ValueChanged<String> onDictationError;

  @override
  State<GroupNotesTabBody> createState() => _GroupNotesTabBodyState();
}

class _GroupNotesTabBodyState extends State<GroupNotesTabBody> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialBody,
  )..addListener(_handleChanged);
  bool _isDirty = false;

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GroupNotesTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Un enregistrement réussi recharge `initialBody` avec exactement ce qui
    // vient d'être écrit — sans ce recalcul, `_isDirty` resterait bloqué à
    // `true` (comparé à l'ancien `initialBody`, jamais rafraîchi) et
    // "Enregistrer" resterait actif après un enregistrement réussi.
    if (oldWidget.initialBody != widget.initialBody) {
      _isDirty = _controller.text != widget.initialBody;
    }
  }

  void _handleChanged() {
    final dirty = _controller.text != widget.initialBody;
    if (dirty != _isDirty) setState(() => _isDirty = dirty);
  }

  void _save() {
    if (!_isDirty || widget.isSaving) return;
    widget.onSave(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText:
                    'Prends tes notes pendant la partie : événements, '
                    'indices, rebondissements…',
                alignLabelWithHint: true,
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
              _DictationButton(
                controller: _controller,
                onTextChanged: _handleChanged,
                onError: widget.onDictationError,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PrimaryButton(
                  label: 'Enregistrer',
                  isLoading: widget.isSaving,
                  onPressed: (_isDirty && !widget.isSaving) ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bouton micro : dictée vocale via `speech_to_text` (moteur du système,
/// aucun serveur à nous), append dans [controller] au fil des résultats
/// partiels. Un tap démarre/arrête l'écoute — pas de transcription continue
/// de toute la session (voir l'arbitrage chef de projet du 16/09/2026, en
/// réponse à la demande utilisateur : dictée ponctuelle, pas d'enregistrement
/// ambiant de plusieurs heures).
///
/// [SpeechToText] n'est jamais instancié en dehors d'une vraie interaction
/// utilisateur (pas d'`initialize()` à l'ouverture de l'onglet) : la première
/// pression déclenche l'init ET l'écoute, pour ne demander la permission
/// micro qu'au moment où l'utilisateur en exprime explicitement le besoin.
class _DictationButton extends StatefulWidget {
  const _DictationButton({
    required this.controller,
    required this.onTextChanged,
    required this.onError,
  });

  final TextEditingController controller;
  final VoidCallback onTextChanged;
  final ValueChanged<String> onError;

  @override
  State<_DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<_DictationButton> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isBusy = false;
  String _baseText = '';

  @override
  void dispose() {
    if (_isListening) unawaited(_speech.stop());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isBusy) return;
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isBusy = true);
    final available = await _speech.initialize(
      onError: (error) => _handleError(error),
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
    );
    if (!mounted) return;
    if (!available) {
      setState(() => _isBusy = false);
      widget.onError(
        'Reconnaissance vocale indisponible sur cet appareil ou accès '
        'micro refusé.',
      );
      return;
    }

    _baseText = widget.controller.text;
    setState(() {
      _isBusy = false;
      _isListening = true;
    });
    await _speech.listen(onResult: _handleResult);
  }

  void _handleError(SpeechRecognitionError error) {
    if (mounted) setState(() => _isListening = false);
    widget.onError('Erreur de reconnaissance vocale : ${error.errorMsg}');
  }

  void _handleResult(SpeechRecognitionResult result) {
    final needsSeparator =
        _baseText.isNotEmpty &&
        !_baseText.endsWith('\n') &&
        !_baseText.endsWith(' ');
    final newText =
        '$_baseText${needsSeparator ? ' ' : ''}${result.recognizedWords}';
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    widget.onTextChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _isListening ? AppColors.accentBrick : AppColors.parchmentCard,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: _isBusy ? null : _toggle,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening
                ? AppColors.parchmentBg
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
