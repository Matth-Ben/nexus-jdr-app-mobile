import 'package:personnages/features/groups/data/group_repository.dart';

/// Faux dépôt de groupes réduit à la recherche des groupes d'un personnage
/// (`fetchGroupIdsForCharacter`) : tout autre appel est une erreur de test.
class FakeGroupCharacterLookup implements GroupRepository {
  /// Réponse par personnage.
  final Map<String, List<String>> groupsByCharacter = {};

  /// Si posé, chaque appel échoue (hors ligne, erreur serveur...).
  Object? failure;

  /// Personnages demandés, dans l'ordre des appels.
  final List<String> requested = [];

  int get calls => requested.length;

  @override
  Future<List<String>> fetchGroupIdsForCharacter(String characterId) async {
    requested.add(characterId);
    final error = failure;
    if (error != null) throw error;
    return groupsByCharacter[characterId] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
