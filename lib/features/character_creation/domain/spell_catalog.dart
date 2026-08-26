import 'package:freezed_annotation/freezed_annotation.dart';

import 'spell_option.dart';

part 'spell_catalog.freezed.dart';

/// Sorts accessibles à une classe donnée pour l'étape 6/9 "Sorts" de
/// l'assistant de création, récupéré en une fois au chargement de l'écran
/// (`data/character_creation_repository.dart`) — mineurs (niveau 0) ET
/// niveau 1 mélangés, filtrés par niveau côté
/// `presentation/spells_step_screen.dart` selon l'onglet actif plutôt que
/// deux requêtes séparées (même rationale que `ToolCatalog`/`LanguageCatalog`
/// : volume faible par classe, pas besoin de pagination ni de fetch par
/// onglet).
///
/// Contrairement aux autres catalogues de cet assistant, dépend d'un
/// paramètre (`classId` de la classe déjà choisie à l'étape 2) : voir
/// `SupabaseCharacterCreationRepository.fetchSpellCatalog`.
@freezed
abstract class SpellCatalog with _$SpellCatalog {
  const factory SpellCatalog({required List<SpellOption> spells}) =
      _SpellCatalog;
}
