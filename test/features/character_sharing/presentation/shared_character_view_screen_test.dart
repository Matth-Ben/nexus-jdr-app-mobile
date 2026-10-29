// Tests de widget de l'écran "Vue en lecture seule" d'un personnage partagé
// (`/p/:token`) — dépôt de test injecté via `overrideWithValue` sur
// `characterSharingRepositoryProvider`, même principe que
// `character_share_screen_test.dart`.
//
// `SharedPreferences.setMockInitialValues` (voir `setUp` global) : cet écran
// monte `CharacterSpellsTabBody`, qui lit depuis le 29/10/2026 le filtre de
// préparation mémorisé via `spell_preparation_filter_preference_provider.dart`
// (préférence globale à l'appareil, jamais liée à un compte — donc valable
// aussi pour ce lecteur anonyme, voir la doc de classe de ce provider) —
// remis à zéro avant chaque test pour que le reste de ce fichier ne dépende
// jamais d'une valeur mémorisée par un test antérieur.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/character_sharing/data/character_sharing_repository.dart';
import 'package:personnages/features/character_sharing/presentation/providers/character_sharing_providers.dart';
import 'package:personnages/features/character_sharing/presentation/shared_character_view_screen.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_gallery_photo.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_journal_entry.dart';
import 'package:personnages/features/characters/domain/pact_weapon_option.dart';
import 'package:personnages/features/characters/presentation/widgets/character_equipped_weapons_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_pact_weapon_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_stat_pills_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCharacterSharingRepository implements CharacterSharingRepository {
  @override
  Future<CharacterDetail?> fetchGroupMemberCharacter({
    required String groupId,
    required String characterId,
  }) async {
    lastGroupMember = (groupId: groupId, characterId: characterId);
    return detailToReturn;
  }

  ({String groupId, String characterId})? lastGroupMember;
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
    SharedPreferences.setMockInitialValues({});
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
    expect(find.text('APT.'), findsOneWidget);
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

    expect(find.text('VIT.'), findsOneWidget);
    expect(find.text('9 m'), findsOneWidget);
    expect(find.text('CA'), findsOneWidget);
    expect(find.text('INIT.'), findsOneWidget);
    expect(find.text('INSP.'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);

    // Tap sans effet : pas d'InkWell/Material tappable pour cette tuile
    // en lecture seule (`onTapInspiration` non fourni par cet écran).
    await tester.tap(find.text('INSP.'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('✓'), findsOneWidget);
  });

  testWidgets('armorClassBonus != 0 : affiche le suffixe signé, tuile "CA" non '
      'tappable (lecture seule, aucun repository de partage n\'expose de '
      'setArmorClassBonus)', (tester) async {
    // Bonus volontairement différent du modificateur d'initiative de
    // `_baseDetail` (dex 14 -> +2) : les deux suffixes partagent la même
    // tuile `CharacterStatPillsRow`, un "+2" collide avec l'autre sinon.
    fakeRepository.detailToReturn = _baseDetail.copyWith(armorClassBonus: 5);

    await pumpSharedView(tester);
    await tester.pumpAndSettle();

    // Recherche restreinte à la rangée de tuiles : "+5" peut aussi être le
    // modificateur d'une caractéristique/jet de sauvegarde affiché
    // ailleurs sur le même onglet.
    final suffixFinder = find.descendant(
      of: find.byType(CharacterStatPillsRow),
      matching: find.text('+5'),
    );
    expect(suffixFinder, findsOneWidget);

    // Tap sans effet : pas d'InkWell/Material tappable pour cette tuile
    // en lecture seule (`onTapArmorClass` non fourni par cet écran).
    await tester.tap(find.text('CA'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(suffixFinder, findsOneWidget);
  });

  testWidgets('changer d\'onglet affiche le contenu de l\'onglet Compétences '
      'en lecture seule', (tester) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpSharedView(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('APT.'));
    await tester.pumpAndSettle();

    expect(find.text('APTITUDES'), findsOneWidget);
  });

  // Sort inné de niveau >= 1 (D08) : pastille et marqueur affichés d'après
  // `innate_uses_spent`, sans aucune action.
  testWidgets('onglet Sorts : un sort inné épuisé affiche « INNÉ » et '
      '« Épuisé », un sort inné disponible sa pastille, aucun tap', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(
      spells: const [
        CharacterSpellEntry(
          id: 1,
          name: 'Ténèbres',
          level: 2,
          school: 'Évocation',
          status: SpellStatus.innate,
          innateUsesSpent: 1,
        ),
        CharacterSpellEntry(
          id: 2,
          name: 'Lueurs féeriques',
          level: 1,
          school: 'Évocation',
          status: SpellStatus.innate,
        ),
      ],
    );

    await pumpSharedView(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SORTS'));
    await tester.pumpAndSettle();

    expect(find.text('INNÉ'), findsNWidgets(2));
    expect(find.text('Épuisé'), findsOneWidget);

    await tester.tap(find.text('Ténèbres'));
    await tester.pumpAndSettle();
    // Referme ce premier panneau "Infos" avant le second tap : il reste
    // sinon ouvert par-dessus la ligne suivante (même motif de fermeture
    // que `character_detail_action_lock_test.dart`/`character_detail_
    // innate_spell_cast_test.dart`).
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lueurs féeriques'));
    await tester.pumpAndSettle();
    expect(find.text('LANCER'), findsNothing);
  });

  // Preuve bout-en-bout (qa-testeur) que le tap ouvre bien le panneau
  // "Infos" avec sa description — le test ci-dessus ne vérifie que
  // l'absence du bouton "LANCER", vraie aussi bien avant (tap bloqué net)
  // qu'après le passage en lecture seule (panneau ouvert sans ce bouton),
  // donc insuffisante à elle seule pour prouver que le panneau s'ouvre
  // réellement.
  testWidgets(
    'onglet Sorts : taper un sort ouvre bien le panneau "Infos" en lecture '
    'seule, avec son détail technique et sa description visibles',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        spells: const [
          CharacterSpellEntry(
            id: 1,
            name: 'Ténèbres',
            level: 2,
            school: 'Évocation',
            status: SpellStatus.innate,
            castingTime: '1 action',
            description: 'Une obscurité magique se répand depuis ce point.',
          ),
        ],
      );

      await pumpSharedView(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ténèbres'));
      await tester.pumpAndSettle();

      // Le panneau "Infos" s'est bien ouvert (titre en majuscules, détail
      // technique, description) — pas seulement l'absence du bouton
      // "LANCER" (déjà vérifiée par le test précédent).
      expect(find.text('TÉNÈBRES'), findsOneWidget);
      expect(find.text("Temps d'incantation"), findsOneWidget);
      expect(find.text('1 action'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(
        find.text('Une obscurité magique se répand depuis ce point.'),
        findsOneWidget,
      );
      expect(find.text('LANCER'), findsNothing);
    },
  );

  // BUG CORRIGE (qa-testeur a trouve le defaut le 29/10/2026, corrige par
  // dev-flutter le meme jour) -- trappe de regression permanente, conservee
  // telle quelle : contrairement a ce qu'affirmait la doc de classe de
  // `spell_preparation_filter_preference_provider.dart` ("valable aussi pour
  // un lecteur anonyme de shared_character_view_screen.dart") au moment ou
  // ce test a ete ecrit, le filtre memorise n'etait PAS applique a
  // l'ouverture de la fiche partagee -- il retombait silencieusement sur
  // "Tous", meme avec une valeur "prepared" deja en base au moment de
  // l'ouverture.
  //
  // Cause racine (corrigee) : `CharacterSpellsTabBody` lisait la preference
  // avec un `ref.read` UNIQUE en `initState` (snapshot figé, jamais
  // re-ecoute ensuite), jamais un `ref.watch` reactif. Or
  // `SpellPreparationFilterPreferenceController.build()` retombe lui-meme
  // "momentanement" sur `SpellPreparationFilter.all` tant que
  // `sharedPreferencesProvider` n'a pas resolu (`AsyncValue.loading` au tout
  // premier acces, `.value` nul -- voir sa propre doc de classe) : cette
  // resolution est TOUJOURS asynchrone (au moins un microtask Dart), meme
  // avec `SharedPreferences.getInstance()` deja "chaud" en coulisses. Le
  // `ref.read` de `initState` capturait donc systematiquement ce premier
  // retour a vide des que c'etait la PREMIERE lecture de ce provider dans la
  // session -- sans jamais se corriger ensuite, puisque rien ne re-ecoutait
  // le provider une fois la vraie valeur disponible.
  //
  // Sur la fiche du proprietaire, ce defaut ne se voyait quasiment jamais en
  // pratique : `character_list_screen.dart` (`UpdateSuggestedBanner`, voir
  // `features/app_update/presentation/widgets/update_suggested_banner.dart`
  // ligne 31) lit INCONDITIONNELLEMENT `updateBannerDismissalControllerProvider`
  // -> `sharedPreferencesProvider` des l'ecran d'accueil, largement avant que
  // le joueur ouvre une fiche puis l'onglet Sorts -- le provider avait donc
  // toujours resolu depuis longtemps. Mais `shared_character_view_screen.dart`
  // (lecteur anonyme d'un lien `/p/:token`) ne passe JAMAIS par
  // `character_list_screen.dart` : AUCUN autre widget de cet arbre ne lisait
  // jamais `sharedPreferencesProvider` avant que `CharacterSpellsTabBody` ne
  // le fasse lui-meme au premier tap sur "SORTS" -- le defaut etait donc
  // deterministe (pas une coincidence de timing du test), pas seulement une
  // possibilite theorique.
  //
  // Correctif applique : `CharacterSpellsTabBody.build()` lit desormais la
  // preference via `ref.watch` (plus de champ local `_preparationFilter` du
  // tout -- voir la doc de classe de `character_spells_tab_body.dart`),
  // pas via un `ref.read` figé en `initState` : la carte se met a jour
  // d'elle-meme dans le build suivant la resolution de
  // `sharedPreferencesProvider`, y compris sans rien qui "prechauffe" ce
  // provider en amont.
  group('onglet Sorts : filtre de préparation mémorisé sur l\'appareil '
      '(demande utilisateur du 29/10/2026) — s\'applique aussi en lecture '
      'seule, préférence locale jamais liée à un compte', () {
    const cantrip = CharacterSpellEntry(
      id: 1,
      name: 'Lumière',
      level: 0,
      school: 'Évocation',
      status: SpellStatus.known,
    );
    const preparedSpell = CharacterSpellEntry(
      id: 2,
      name: 'Bouclier',
      level: 1,
      school: 'Abjuration',
      status: SpellStatus.prepared,
    );
    const unpreparedSpell = CharacterSpellEntry(
      id: 3,
      name: 'Projectile magique',
      level: 1,
      school: 'Évocation',
      status: SpellStatus.known,
    );

    testWidgets(
      'un filtre "Préparés" déjà mémorisé sur l\'appareil (ex. choisi par '
      'le propriétaire de la fiche depuis son propre écran) s\'applique '
      'dès l\'ouverture de la fiche partagée, sans aucune action du '
      'lecteur anonyme',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'spell_preparation_filter_preference': 'prepared',
        });
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          spells: const [cantrip, preparedSpell, unpreparedSpell],
        );

        await pumpSharedView(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('SORTS'));
        await tester.pumpAndSettle();

        expect(find.text('PRÉPARATION DES SORTS'), findsOneWidget);
        expect(find.text('Bouclier'), findsOneWidget);
        expect(find.text('Lumière'), findsOneWidget);
        if (find.text('Projectile magique').evaluate().isNotEmpty) {
          fail(
            'Régression du correctif du 29/10/2026 (voir le commentaire de '
            'ce groupe) : le filtre "Préparés" mémorisé sur l\'appareil '
            'n\'est plus appliqué à l\'ouverture de la fiche partagée -- '
            '"Projectile magique" (non préparé) est resté visible, la '
            'fiche partagée est retombée sur "Tous" malgré la valeur '
            '"prepared" déjà en base au moment de l\'ouverture.',
          );
        }

        // Confirme que le lecteur anonyme garde la main pour en changer
        // (préférence, pas verrou) -- comme sur la fiche du joueur.
        await tester.tap(find.text('TOUS'));
        await tester.pumpAndSettle();
        expect(find.text('Projectile magique'), findsOneWidget);
      },
    );

    testWidgets('aucune valeur mémorisée (SharedPreferences vide) : la fiche '
        'partagée démarre sur "Tous", même comportement que l\'ancien état '
        'local', (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        spells: const [cantrip, preparedSpell, unpreparedSpell],
      );

      await pumpSharedView(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();

      expect(find.text('Projectile magique'), findsOneWidget);
    });
  });

  group('onglet Inventaire (SAC) : objet cliquable en lecture seule', () {
    testWidgets(
      'taper un objet ouvre bien le panneau "Infos" en lecture seule, avec '
      'son détail technique et sa description visibles, sans sheet '
      'd\'actions',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          inventory: const [
            CharacterInventoryItem(
              id: 'inv-1',
              itemId: 10,
              name: 'Grimoire de magicienne',
              category: 'equipement_general',
              quantity: 1,
              equipped: false,
              totalWeight: 3,
              unitWeight: 3,
              description: 'Un lourd grimoire relié de cuir noirci.',
            ),
          ],
        );

        await pumpSharedView(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('SAC'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Grimoire de magicienne'));
        await tester.pumpAndSettle();

        // Le panneau "Infos" s'est bien ouvert (titre en majuscules, détail
        // technique, description) — pas la sheet d'actions (aucun bouton
        // "Utiliser"/"Équiper"/"Retirer", jamais exposés en lecture seule).
        expect(find.text('GRIMOIRE DE MAGICIENNE'), findsOneWidget);
        expect(find.text('Poids unitaire'), findsOneWidget);
        expect(find.text('DESCRIPTION'), findsOneWidget);
        expect(
          find.text('Un lourd grimoire relié de cuir noirci.'),
          findsOneWidget,
        );
        expect(find.text('Utiliser'), findsNothing);
        expect(find.text('Équiper'), findsNothing);
        expect(find.text('Retirer'), findsNothing);
      },
    );
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
        final equippedWeaponsCard = find.byType(CharacterEquippedWeaponsCard);
        expect(
          find.descendant(
            of: equippedWeaponsCard,
            matching: find.text('Attaque'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: equippedWeaponsCard, matching: find.text('+2')),
          findsOneWidget,
        );
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

  group(
    'fiche d’un membre de groupe (SharedCharacterViewScreen.groupMember)',
    () {
      Future<void> pumpGroupMemberView(WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              characterSharingRepositoryProvider.overrideWithValue(
                fakeRepository,
              ),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/groups/g-1/members/c-9',
                routes: [
                  GoRoute(
                    path: '/groups/:id/members/:characterId',
                    builder: (context, state) =>
                        SharedCharacterViewScreen.groupMember(
                          groupId: state.pathParameters['id']!,
                          characterId: state.pathParameters['characterId']!,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      testWidgets(
        'charge la fiche via le groupe et l’affiche en lecture seule',
        (tester) async {
          fakeRepository.detailToReturn = _baseDetail;

          await pumpGroupMemberView(tester);

          expect(fakeRepository.lastGroupMember?.groupId, 'g-1');
          expect(fakeRepository.lastGroupMember?.characterId, 'c-9');
          expect(find.text('Vue en lecture seule'), findsOneWidget);
          expect(find.text('PERSO'), findsOneWidget);
        },
      );

      testWidgets('fiche inaccessible (résultat null) : message propre au '
          'groupe, sans parler de lien', (tester) async {
        fakeRepository.detailToReturn = null;

        await pumpGroupMemberView(tester);

        expect(find.text('MEMBRE DU GROUPE'), findsOneWidget);
        expect(find.text("Cette fiche n'est plus accessible"), findsOneWidget);
        expect(find.textContaining('lien'), findsNothing);
      });
    },
  );
}
