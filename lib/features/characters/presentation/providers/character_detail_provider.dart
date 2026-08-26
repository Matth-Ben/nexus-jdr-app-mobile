import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/character_detail.dart';
import 'character_providers.dart';

part 'character_detail_provider.g.dart';

/// Détail complet d'un personnage (onglet "Personnage" de la fiche,
/// `presentation/character_detail_screen.dart`), en famille par
/// [characterId].
///
/// Mêmes réglages que [characters] (`character_providers.dart`) :
/// `autoDispose` par défaut (pas besoin de survivre à la fermeture de
/// l'écran), et `retry: null` pour ne jamais masquer une erreur persistante
/// derrière des tentatives automatiques silencieuses — l'écran expose son
/// propre bouton "Réessayer".
///
/// Invalidé explicitement par les écritures de la fiche (ajustement PV,
/// upload/suppression de portrait) plutôt que rafraîchi automatiquement :
/// même pattern que `charactersProvider.invalidate()` après
/// `CharacterCreationRepository.createCharacter` (`summary_step_screen.dart`).
@Riverpod(retry: _noRetry)
Future<CharacterDetail> characterDetail(Ref ref, String characterId) {
  return ref
      .watch(characterRepositoryProvider)
      .fetchCharacterDetail(characterId);
}

Duration? _noRetry(int retryCount, Object error) => null;
