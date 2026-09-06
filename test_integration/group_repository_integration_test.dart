import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_invite_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Test d'intégration de `SupabaseGroupRepository` contre un vrai stack
/// Supabase local (voir `test_integration/README.md`) — 3 edge functions
/// (`create-group`/`preview-group-invite`/`join-group`), la fonction Postgres
/// `claim_group_treasure_currency`, et les policies RLS "Système de groupe"
/// (`docs/cahier-des-charges/12-partage-et-groupes.md` section 2), déployées
/// côté dépôt web (`markdown-editor`).
///
/// Utilise volontairement 2 `SupabaseClient` distincts, chacun authentifié
/// avec son propre utilisateur de test ([_ownerClient]/[_joinerClient]) —
/// première utilisation de ce pattern dans `test_integration/` (les fichiers
/// existants n'exercent qu'un seul utilisateur) : nécessaire ici pour vérifier
/// les policies RLS multi-utilisateurs (isolation cross-groupe, lecture d'un
/// coéquipier) qu'un seul client ne peut par construction jamais couvrir.
void main() {
  group('SupabaseGroupRepository (intégration)', () {
    late SupabaseClient ownerClient;
    late SupabaseClient joinerClient;
    late SupabaseGroupRepository ownerRepo;
    late SupabaseGroupRepository joinerRepo;
    late String ownerCharacterId;
    late String joinerCharacterId;

    setUpAll(() async {
      ownerClient = createTestSupabaseClient();
      await signUpTestUser(ownerClient);
      final reference = await fetchReferenceContent(ownerClient);

      joinerClient = createTestSupabaseClient();
      await signUpTestUser(joinerClient);

      ownerRepo = SupabaseGroupRepository(ownerClient);
      joinerRepo = SupabaseGroupRepository(joinerClient);

      ownerCharacterId = await _createTestCharacter(
        ownerClient,
        name: 'Owner PJ (intégration groupe)',
        raceId: reference.raceId,
      );
      joinerCharacterId = await _createTestCharacter(
        joinerClient,
        name: 'Joiner PJ (intégration groupe)',
        raceId: reference.raceId,
      );
    });

    tearDownAll(() async {
      await ownerClient.from('characters').delete().eq('id', ownerCharacterId);
      await joinerClient
          .from('characters')
          .delete()
          .eq('id', joinerCharacterId);
    });

    test('création : create-group crée groups + group_members(owner) + '
        'group_treasure automatiquement', () async {
      final created = await ownerRepo.createGroup(
        name: 'Groupe Intégration Création',
        characterId: ownerCharacterId,
      );
      addTearDown(
        () => ownerClient.from('groups').delete().eq('id', created.id),
      );

      expect(created.name, 'Groupe Intégration Création');
      expect(created.inviteCode, hasLength(8));

      final detail = await ownerRepo.fetchGroupDetail(created.id);
      expect(detail.isOwner, isTrue);
      expect(detail.members, hasLength(1));
      expect(detail.members.single.characterId, ownerCharacterId);

      final treasureRow = await ownerClient
          .from('group_treasure')
          .select('group_id')
          .eq('group_id', created.id)
          .maybeSingle();
      expect(
        treasureRow,
        isNotNull,
        reason:
            'group_treasure doit être créé automatiquement à la création '
            'du groupe (edge function create-group)',
      );
    });

    test('rejoindre : preview puis join créent l\'adhésion, une 2e tentative '
        'du même personnage est refusée (already_in_group)', () async {
      final created = await ownerRepo.createGroup(
        name: 'Groupe Intégration Rejoindre',
        characterId: ownerCharacterId,
      );
      addTearDown(
        () => ownerClient.from('groups').delete().eq('id', created.id),
      );

      final preview = await joinerRepo.previewGroupInvite(created.inviteCode);
      expect(preview.name, 'Groupe Intégration Rejoindre');
      expect(preview.memberCount, 1);

      final joined = await joinerRepo.joinGroup(
        code: created.inviteCode,
        characterId: joinerCharacterId,
      );
      expect(joined.groupId, created.id);

      await expectLater(
        joinerRepo.joinGroup(
          code: created.inviteCode,
          characterId: joinerCharacterId,
        ),
        throwsA(
          isA<GroupInviteFailure>().having(
            (f) => f.kind,
            'kind',
            GroupInviteFailureKind.alreadyInGroup,
          ),
        ),
      );

      final detail = await ownerRepo.fetchGroupDetail(created.id);
      expect(detail.members, hasLength(2));
    });

    test('isolation cross-groupe : un joueur non membre ne voit pas le groupe '
        '(RLS) — ni dans fetchMyGroups, ni via fetchGroupDetail', () async {
      final created = await ownerRepo.createGroup(
        name: 'Groupe Intégration Isolé',
        characterId: ownerCharacterId,
      );
      addTearDown(
        () => ownerClient.from('groups').delete().eq('id', created.id),
      );

      final joinerGroups = await joinerRepo.fetchMyGroups();
      expect(joinerGroups.any((g) => g.id == created.id), isFalse);

      await expectLater(
        joinerRepo.fetchGroupDetail(created.id),
        throwsA(isA<GroupFailure>()),
      );
    });

    test(
      'claim_group_treasure_currency : décrémentation atomique réelle, '
      'crédite l\'inventaire personnel, refuse un montant supérieur au solde',
      () async {
        final created = await ownerRepo.createGroup(
          name: 'Groupe Intégration Butin',
          characterId: ownerCharacterId,
        );
        addTearDown(
          () => ownerClient.from('groups').delete().eq('id', created.id),
        );

        await ownerClient
            .from('group_treasure')
            .update({'currency_gp': 10})
            .eq('group_id', created.id);
        final beforeCharacterRow = await ownerClient
            .from('characters')
            .select('currency_gp')
            .eq('id', ownerCharacterId)
            .single();
        final beforeCurrencyGp = (beforeCharacterRow['currency_gp'] as num)
            .toInt();

        final claimed = await ownerRepo.claimTreasureCurrency(
          groupId: created.id,
          characterId: ownerCharacterId,
          currency: CurrencyKind.gold,
          amount: 6,
        );
        expect(claimed, isTrue);

        final treasureAfter = await ownerClient
            .from('group_treasure')
            .select('currency_gp')
            .eq('group_id', created.id)
            .single();
        expect(treasureAfter['currency_gp'], 4);

        final characterAfter = await ownerClient
            .from('characters')
            .select('currency_gp')
            .eq('id', ownerCharacterId)
            .single();
        expect(characterAfter['currency_gp'], beforeCurrencyGp + 6);

        // Solde insuffisant (il ne reste que 4 PO) : refusé, aucune écriture.
        final refused = await ownerRepo.claimTreasureCurrency(
          groupId: created.id,
          characterId: ownerCharacterId,
          currency: CurrencyKind.gold,
          amount: 999,
        );
        expect(refused, isFalse);

        final treasureUnchanged = await ownerClient
            .from('group_treasure')
            .select('currency_gp')
            .eq('group_id', created.id)
            .single();
        expect(treasureUnchanged['currency_gp'], 4);
      },
    );

    test('RLS coéquipiers : un membre peut lire la ligne characters complète '
        'd\'un coéquipier du même groupe (nécessaire pour Realtime)', () async {
      final created = await ownerRepo.createGroup(
        name: 'Groupe Intégration RLS',
        characterId: ownerCharacterId,
      );
      addTearDown(
        () => ownerClient.from('groups').delete().eq('id', created.id),
      );
      await joinerRepo.joinGroup(
        code: created.inviteCode,
        characterId: joinerCharacterId,
      );

      final teammateRow = await joinerClient
          .from('characters')
          .select('id, name')
          .eq('id', ownerCharacterId)
          .maybeSingle();
      expect(
        teammateRow,
        isNotNull,
        reason:
            'un membre de groupe doit pouvoir lire characters d\'un '
            'coéquipier du même groupe (policy RLS dédiée)',
      );
      expect(teammateRow!['name'], 'Owner PJ (intégration groupe)');
    });

    test(
      "isolation cross-groupe (butin) : un membre d'un AUTRE groupe ne peut "
      "ni lire ni réclamer le butin d'un groupe dont il n'est pas membre",
      () async {
        // Groupe A (ownerClient) et Groupe B (joinerClient), sans adhésion
        // croisée : joinerClient est membre de B, jamais de A. Vérifie que
        // l'isolation RLS/RPC porte bien sur le `group_id` exact, pas
        // seulement sur "être membre d'un groupe quelconque" (le scénario
        // "isolation cross-groupe" ci-dessus ne couvre que le cas d'un
        // joueur qui n'est membre d'AUCUN groupe).
        final groupA = await ownerRepo.createGroup(
          name: 'Groupe Intégration Isolation Butin A',
          characterId: ownerCharacterId,
        );
        addTearDown(
          () => ownerClient.from('groups').delete().eq('id', groupA.id),
        );
        final groupB = await joinerRepo.createGroup(
          name: 'Groupe Intégration Isolation Butin B',
          characterId: joinerCharacterId,
        );
        addTearDown(
          () => joinerClient.from('groups').delete().eq('id', groupB.id),
        );

        await ownerClient
            .from('group_treasure')
            .update({'currency_gp': 50})
            .eq('group_id', groupA.id);

        // Lecture : un membre du groupe B ne doit jamais voir le butin du
        // groupe A (RLS `group_treasure` scoping par `group_id`, pas juste
        // "être membre de group_members").
        final treasureSeenByOutsider = await joinerRepo.fetchGroupTreasure(
          groupA.id,
        );
        expect(
          treasureSeenByOutsider.currencyGp,
          0,
          reason:
              "un non-membre du groupe A ne doit jamais lire son butin réel "
              "(50 PO), RLS group_treasure trop permissive sinon",
        );

        // Écriture : `claim_group_treasure_currency` doit refuser (ou
        // échouer) pour un appelant qui n'est pas membre du groupe visé,
        // même s'il est membre d'un AUTRE groupe (groupB) — sans quoi
        // n'importe quel membre d'un groupe pourrait piller le butin d'un
        // groupe tiers dont il connaît juste l'identifiant.
        var claimedByOutsider = false;
        try {
          claimedByOutsider = await joinerRepo.claimTreasureCurrency(
            groupId: groupA.id,
            characterId: joinerCharacterId,
            currency: CurrencyKind.gold,
            amount: 10,
          );
        } on GroupFailure {
          claimedByOutsider = false;
        }
        expect(
          claimedByOutsider,
          isFalse,
          reason:
              "claim_group_treasure_currency doit refuser un appelant qui "
              "n'est pas membre du groupe visé (isolation RPC), pas "
              "seulement se fier au filtre applicatif côté client",
        );

        final treasureAfter = await ownerClient
            .from('group_treasure')
            .select('currency_gp')
            .eq('group_id', groupA.id)
            .single();
        expect(
          treasureAfter['currency_gp'],
          50,
          reason: 'le butin du groupe A ne doit pas avoir bougé',
        );
      },
    );
  });
}

Future<String> _createTestCharacter(
  SupabaseClient client, {
  required String name,
  required Object raceId,
}) async {
  final ownerId = client.auth.currentUser!.id;
  final row = await client
      .from('characters')
      .insert({'owner_id': ownerId, 'name': name, 'xp': 0, 'race_id': raceId})
      .select('id')
      .single();
  return row['id'] as String;
}
