import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/character_edit_repository.dart';
import '../../domain/background_option.dart';
import '../../domain/character_creation_draft.dart';
import '../../domain/character_edit_snapshot.dart';
import '../../domain/class_option.dart';
import '../../domain/spell_catalog.dart';

part 'character_edit_session_provider.g.dart';

@Riverpod(keepAlive: true)
CharacterEditRepository characterEditRepository(Ref ref) {
  return SupabaseCharacterEditRepository(ref.watch(supabaseClientProvider));
}

/// Session de modification d'un personnage existant via l'assistant de
/// création (entrée « Modifier » de la fiche, demande utilisateur du
/// 2026-09-25). Tant qu'elle existe, les écrans de l'assistant sont en mode
/// modification : bandeau « MODIFICATION », étape Classe verrouillée au-delà
/// du niveau 1, caractéristiques en valeurs finales, étape Équipement
/// sautée, étape Sorts limitée au niveau 1, et « Enregistrer les
/// modifications » à la fin au lieu de créer un personnage.
class CharacterEditSession {
  const CharacterEditSession({
    required this.snapshot,
    required this.originalDraft,
    this.originalClass,
    this.originalBackground,
    this.originalSpellCatalog,
  });

  final CharacterEditSnapshot snapshot;

  /// Brouillon pré-rempli au lancement — référence du diff à
  /// l'enregistrement (`CharacterEditPlanner`).
  final CharacterCreationDraft originalDraft;
  final ClassOption? originalClass;
  final BackgroundOption? originalBackground;
  final SpellCatalog? originalSpellCatalog;

  String get characterId => snapshot.characterId;

  /// Décision utilisateur : classe et sous-classe modifiables au niveau 1
  /// seulement.
  bool get canChangeClass => snapshot.totalLevel <= 1;

  /// Les choix de sorts de l'assistant (mineurs + niveau 1) ne décrivent
  /// qu'un personnage de niveau 1 ; au-delà, les sorts se gèrent par la
  /// montée de niveau et l'onglet Sorts.
  bool get canEditSpells => snapshot.totalLevel <= 1;
}

@Riverpod(keepAlive: true)
class CharacterEditSessionController extends _$CharacterEditSessionController {
  @override
  CharacterEditSession? build() => null;

  void start(CharacterEditSession session) => state = session;

  void clear() => state = null;
}
