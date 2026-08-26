// Test de non-régression documentant un bug confirmé en revue QA (voir le
// rapport QA de la fiche personnage, onglet "Personnage") : CORRIGÉ dans
// `character_detail_screen.dart` (état PV optimiste local
// `_localHpState`/`_effectiveDetail`, voir sa documentation). Ce test garde
// désormais la non-régression en permanence (plus de `skip: true`).
//
// Bug : les steppers rapides "+"/"-" du bandeau PV (`character_vitals_card.dart`)
// capturent `detail` (l'état PV avant modification) dans la closure du build
// courant. Si le joueur tape deux fois de suite avant que le premier
// aller-retour réseau (`CharacterRepository.updateHp`) ne se termine et ne
// déclenche un nouveau `fetchCharacterDetail`, le second tap calcule sa
// nouvelle valeur à partir du **même** `detail` obsolète que le premier —
// aucun état local optimiste, aucun verrou désactivant les boutons pendant
// l'écriture en cours. Résultat : le second point de soin/dégât est perdu
// silencieusement (la seconde écriture réécrit la même valeur que la
// première au lieu de l'incrémenter), sans aucune erreur visible pour le
// joueur — exactement le type de perte de donnée silencieuse que
// `character_detail_screen.dart`/`hp_adjustment_sheet.dart` doivent éviter
// (voir la consigne QA "une erreur ici modifierait silencieusement les
// données réelles d'un joueur").
//
// Piste de correctif pour dev-flutter : soit désactiver les boutons "+"/"-"
// pendant qu'une écriture `updateHp` est en vol (verrou local), soit calculer
// la nouvelle valeur à partir du dernier état écrit localement (accumulateur)
// plutôt que du `detail` capturé au moment du tap, soit les deux.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class _FakeRepository implements CharacterRepository {
  final List<int> updatedCurrentHpValues = [];

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      _detail;

  @override
  Future<void> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) async {
    // Simule un aller-retour réseau réaliste : bien plus court que
    // l'intervalle entre deux taps humains rapides sur un stepper, mais
    // suffisant pour laisser le second tap de ce test s'exécuter avant que
    // ce premier appel ne se termine et ne déclenche le refetch.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    updatedCurrentHpValues.add(currentHp);
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) async => 'https://example.com/portrait.png';

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) async {}
}

const _detail = CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: 'Guerrier',
      level: 1,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 10,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: {},
);

void main() {
  testWidgets(
    'deux taps rapides sur le stepper "+" du bandeau PV ne doivent jamais '
    'se perdre — doit finir à 12, pas 11',
    (tester) async {
      final repository = _FakeRepository();
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/characters/1',
              routes: [
                GoRoute(
                  path: '/characters/:id',
                  builder: (context, state) => CharacterDetailScreen(
                    characterId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Deux taps rapides sur le "+" du stepper, sans attendre entre les
      // deux que le premier `updateHp` se termine — reproduit un joueur qui
      // soigne son personnage de plusieurs points d'affilée.
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(
        repository.updatedCurrentHpValues,
        [11, 12],
        reason:
            'Le second tap doit incrémenter depuis 11, pas recalculer '
            'depuis le `detail` obsolète capturé au premier tap.',
      );
    },
  );
}
