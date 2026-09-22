// Tests de widget de l'écran "Vue en lecture seule" d'un personnage partagé
// (`/p/:token`) — dépôt de test injecté via `overrideWithValue` sur
// `characterSharingRepositoryProvider`, même principe que
// `character_share_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/character_sharing/data/character_sharing_repository.dart';
import 'package:personnages/features/character_sharing/presentation/providers/character_sharing_providers.dart';
import 'package:personnages/features/character_sharing/presentation/shared_character_view_screen.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_gallery_photo.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_journal_entry.dart';
import 'package:personnages/features/characters/domain/pact_weapon_option.dart';
import 'package:personnages/features/characters/presentation/widgets/character_pact_weapon_card.dart';

class _FakeCharacterSharingRepository implements CharacterSharingRepository {
  CharacterDetail? detailToReturn;
  Object? errorToThrow;
  Completer<CharacterDetail?>? completer;

  @override
  Future<CharacterDetail?> fetchSharedCharacter(String token) async {
    if (completer != null) return completer!.future;
    if (errorToThrow != null) throw errorToThrow!;
    return detailToReturn;
  }

  @override
  Future<String> regenerateShareToken(String characterId) =>
      throw UnimplementedError();

  @override
  Future<void> disableShareToken(String characterId) =>
      throw UnimplementedError();
}

const _baseDetail = CharacterDetail(
  id: 'char-1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
      className: 'Magicienne',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: ['int', 'wis'],
    ),
  ],
  xp: 100,
  currentHp: 18,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: {
    'str': 8,
    'dex': 14,
    'con': 12,
    'int': 18,
    'wis': 13,
    'cha': 10,
  },
);

void main() {
  late _FakeCharacterSharingRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeCharacterSharingRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        characterSharingRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/p/tok-abc',
          routes: [
            GoRoute(
              path: '/p/:token',
              builder: (context, state) => SharedCharacterViewScreen(
                token: state.pathParameters['token']!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Surface agrandie : les cartes de l'onglet "Personnage" (grille de
  // caractéristiques, jets de sauvegarde) sont autrement hors du cacheExtent
  // par défaut d'un `ListView` sur 800×600 — même ajustement que
  // `character_detail_screen_test.dart`.
  Future<void> pumpSharedView(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestWidget());
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    tester,
  ) async {
    fakeRepository.completer = Completer<CharacterDetail?>();

    await pumpSharedView(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'token invalide/révoqué (résultat null) : affiche l\'état "lien non '
    'valide", pas la barre d\'onglets',
    (tester) async {
      fakeRepository.detailToReturn = null;

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('n\'est plus valide'), findsOneWidget);
      expect(find.text('PERSO'), findsNothing);
    },
  );

  testWidgets('personnage partagé valide : affiche le bandeau "lecture seule", '
      'l\'identité et les caractéristiques, avec la barre de 5 onglets', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpSharedView(tester);
    await tester.pumpAndSettle();

    expect(find.text('Vue en lecture seule'), findsOneWidget);
    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Elfe · Magicienne · Niveau 5'), findsOneWidget);
    expect(find.text('PERSO'), findsOneWidget);
    expect(find.text('COMP.'), findsOneWidget);
    expect(find.text('SORTS'), findsOneWidget);
    expect(find.text('SAC'), findsOneWidget);
    expect(find.text('HIST.'), findsOneWidget);
  });

  testWidgets(
    'carte "Apparence physique" structuree (recettage direction-artistique '
    'du 13/09) : absente de l\'onglet "Personnage", affichee une seule '
    'fois sur l\'onglet "Histoire" (pas de doublon entre les deux onglets '
    'qui reutilisent tous deux CharacterStoryTabBody/le contenu partage)',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(sexe: 'Femme');

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      // Onglet "Personnage" (actif par defaut) : ni la carte structuree ni
      // son contenu ne doivent apparaitre.
      expect(find.text('APPARENCE PHYSIQUE'), findsNothing);
      expect(find.text('Sexe'), findsNothing);
      expect(find.text('Femme'), findsNothing);

      await tester.tap(find.text('HIST.'));
      await tester.pumpAndSettle();

      // Onglet "Histoire" : une seule occurrence (aucun champ de texte
      // libre "Apparence physique" renseigne sur _baseDetail, donc seule la
      // carte structuree peut porter ce titre).
      expect(find.text('APPARENCE PHYSIQUE'), findsOneWidget);
      expect(find.text('Sexe'), findsOneWidget);
      expect(find.text('Femme'), findsOneWidget);
    },
  );

  testWidgets('affiche la rangée Vitesse/Classe d\'Armure/Inspiration, tuile '
      '"Inspiration" non tappable (lecture seule, aucun repository de '
      'partage n\'expose de setInspiration)', (tester) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(
      speed: 9,
      inspiration: true,
    );

    await pumpSharedView(tester);
    await tester.pumpAndSettle();

    expect(find.text('VITESSE'), findsOneWidget);
    expect(find.text('9 m'), findsOneWidget);
    expect(find.text("CLASSE D'ARMURE"), findsOneWidget);
    expect(find.text('INSPIRATION'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);

    // Tap sans effet : pas d'InkWell/Material tappable pour cette tuile
    // en lecture seule (`onTapInspiration` non fourni par cet écran).
    await tester.tap(find.text('INSPIRATION'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('✓'), findsOneWidget);
  });

  testWidgets('changer d\'onglet affiche le contenu de l\'onglet Compétences '
      'en lecture seule', (tester) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpSharedView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('COMP.'));
    await tester.pumpAndSettle();

    expect(find.text('COMPÉTENCES'), findsOneWidget);
  });

  group('onglet Histoire (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section "Onglet Histoire")', () {
    testWidgets(
      'galerie/journal affichés en lecture seule (contenu présent), sans '
      'tuile "+"/"Ajouter une note"',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          galleryPhotos: [
            CharacterGalleryPhoto(
              id: 'photo-1',
              url: 'https://example.com/1.png',
              createdAt: DateTime(2026, 9, 1),
            ),
          ],
          journalEntries: [
            CharacterJournalEntry(
              id: 'entry-1',
              body: 'Première séance.',
              createdAt: DateTime(2026, 9, 1, 20, 0),
            ),
          ],
        );

        await pumpSharedView(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('HIST.'));
        await tester.pumpAndSettle();

        expect(find.text('GALERIE'), findsOneWidget);
        expect(find.text('JOURNAL DE CAMPAGNE'), findsOneWidget);
        expect(find.text('Première séance.'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsNothing);
        expect(find.text('Ajouter une note'), findsNothing);
      },
    );

    testWidgets(
      'aucun champ, aucune photo, aucune entrée : bandeau "AUCUNE HISTOIRE '
      'RENSEIGNÉE" sans sous-titre/bouton, GALERIE/JOURNAL absentes (rien '
      'à ajouter/montrer en lecture seule)',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;

        await pumpSharedView(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('HIST.'));
        await tester.pumpAndSettle();

        expect(find.text('AUCUNE HISTOIRE RENSEIGNÉE'), findsOneWidget);
        expect(find.text('RENSEIGNER MON HISTOIRE'), findsNothing);
        expect(find.text('GALERIE'), findsNothing);
        expect(find.text('JOURNAL DE CAMPAGNE'), findsNothing);
      },
    );
  });

  group('carte "ARMES ÉQUIPÉES" (onglet "Personnage")', () {
    testWidgets(
      'arme équipée : nom, attaque, dégâts avec modificateur (propriétés/'
      'portée retirées de cette ligne compacte)',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          inventory: const [
            CharacterInventoryItem(
              id: 'inv-1',
              itemId: 10,
              name: 'Arc long',
              category: 'arme',
              quantity: 1,
              equipped: true,
              weaponProperties: CharacterInventoryWeaponProperties(
                damageDice: '1d8',
                damageType: 'perforant',
                properties: ['lourde', 'munitions'],
                rangeNormal: 150,
                rangeMax: 600,
              ),
            ),
            CharacterInventoryItem(
              id: 'inv-2',
              itemId: 11,
              name: 'Dague non équipée',
              category: 'arme',
              quantity: 1,
              equipped: false,
            ),
          ],
        );

        await pumpSharedView(tester);
        await tester.pumpAndSettle();

        expect(find.text('ARMES ÉQUIPÉES'), findsOneWidget);
        expect(find.text('Arc long'), findsOneWidget);
        // Munitions -> Dextérité (14 -> +2), aucune maîtrise déclarée sur
        // `_baseDetail` -> bonus d'attaque +2 seul, même modificateur
        // intégré aux dégâts.
        expect(find.text('Attaque : +2'), findsOneWidget);
        expect(find.text('1d8+2 perforant'), findsOneWidget);
        expect(find.text('lourde, munitions'), findsNothing);
        expect(find.textContaining('Portée'), findsNothing);
        expect(find.text('Dague non équipée'), findsNothing);
      },
    );

    testWidgets('aucune arme équipée : état vide', (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      expect(find.text('Aucune arme équipée'), findsOneWidget);
    });
  });

  group('carte "ARME DE PACTE" en lecture seule (Pacte de la lame)', () {
    testWidgets('Occultiste Pacte de la lame : carte affichée sans bouton', (
      tester,
    ) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Occultiste',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: [],
            hitDie: 8,
          ),
        ],
        classChoices: const [
          CharacterClassChoice(
            featureName: 'Faveur de pacte',
            chosenValue: 'lame',
          ),
        ],
        pactWeapon: const PactWeaponOption(
          id: 1,
          name: 'Rapière',
          damageDice: '1d8',
          damageType: 'perforant',
          properties: ['finesse'],
        ),
      );

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      expect(find.byType(CharacterPactWeaponCard), findsOneWidget);
      expect(find.text('ARME DE PACTE'), findsOneWidget);
      expect(find.text('Rapière'), findsOneWidget);
      expect(find.text('Choisir une forme'), findsNothing);
      expect(find.text('Changer de forme'), findsNothing);
    });

    testWidgets('autre classe/pacte : aucune carte', (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      expect(find.byType(CharacterPactWeaponCard), findsNothing);
    });
  });

  testWidgets(
    'échec réseau : affiche le message d\'erreur avec un bouton "Réessayer"',
    (tester) async {
      fakeRepository.errorToThrow = const CharacterFailure(
        'Impossible de charger ce personnage. Réessayez.',
      );

      await pumpSharedView(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger ce personnage. Réessayez.'),
        findsOneWidget,
      );

      fakeRepository.errorToThrow = null;
      fakeRepository.detailToReturn = _baseDetail;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    },
  );
}
