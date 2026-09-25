import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/character_creation_failure.dart';
import '../../domain/character_edit_hydrator.dart';
import '../../domain/spellcasting_rules.dart';
import '../providers/character_creation_draft_provider.dart';
import '../providers/character_creation_providers.dart';
import '../providers/character_creation_return_route_provider.dart';
import '../providers/character_edit_session_provider.dart';

/// Lance la modification d'un personnage existant (entrée « Modifier » du
/// menu ⋮ de la fiche) : charge le personnage et les catalogues nécessaires,
/// pré-remplit le brouillon de l'assistant, ouvre une
/// [CharacterEditSession] puis ouvre l'étape 1 de l'assistant.
Future<void> startCharacterEdit(
  BuildContext context,
  WidgetRef ref, {
  required String characterId,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator(color: AppColors.goldEnd)),
    ),
  );

  try {
    final snapshot = await ref
        .read(characterEditRepositoryProvider)
        .fetchSnapshot(characterId);
    final repository = ref.read(characterCreationRepositoryProvider);
    final classCatalog = await repository.fetchClassCatalog();
    final backgroundCatalog = await repository.fetchBackgroundCatalog();
    final skillCatalog = await repository.fetchSkillCatalog();
    final toolCatalog = await repository.fetchToolCatalog();
    final languageCatalog = await repository.fetchLanguageCatalog();

    final classOption = classCatalog.classes
        .where((option) => option.id == snapshot.primaryClassId)
        .firstOrNull;
    final backgroundOption = backgroundCatalog.backgrounds
        .where((option) => option.id == snapshot.backgroundId)
        .firstOrNull;
    final spellCatalog =
        snapshot.totalLevel <= 1 &&
            classOption != null &&
            SpellcastingRules.isSpellcastingClass(classOption.name)
        ? await repository.fetchSpellCatalog(classId: classOption.id)
        : null;

    final draft = CharacterEditHydrator.toDraft(
      snapshot: snapshot,
      classOption: classOption,
      backgroundOption: backgroundOption,
      skillCatalog: skillCatalog,
      toolCatalog: toolCatalog,
      languageCatalog: languageCatalog,
      spellCatalog: spellCatalog,
    );

    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .replaceWith(draft);
    ref
        .read(characterEditSessionControllerProvider.notifier)
        .start(
          CharacterEditSession(
            snapshot: snapshot,
            originalDraft: draft,
            originalClass: classOption,
            originalBackground: backgroundOption,
            originalSpellCatalog: spellCatalog,
          ),
        );
    ref.read(characterCreationReturnRouteControllerProvider.notifier).set(null);

    navigator.pop();
    if (!context.mounted) return;
    context.push('/characters/new');
  } catch (error) {
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error is CharacterCreationFailure
              ? error.message
              : 'Impossible de charger le personnage à modifier. Réessayez.',
        ),
      ),
    );
  }
}

/// Termine la session de modification (enregistrée ou annulée) : vide le
/// brouillon et la session, puis revient sur la fiche du personnage.
void finishCharacterEdit(BuildContext context, WidgetRef ref) {
  final session = ref.read(characterEditSessionControllerProvider);
  ref.read(characterCreationDraftControllerProvider.notifier).reset();
  ref.read(characterEditSessionControllerProvider.notifier).clear();
  context.go(session == null ? '/' : '/characters/${session.characterId}');
}
