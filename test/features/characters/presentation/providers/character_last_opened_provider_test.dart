// Horodatage local « dernière ouverture » (P18) : écrit à l'ouverture, scopé
// par compte, purge des identifiants absents, jamais de donnée serveur.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/characters/presentation/providers/character_last_opened_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

ProviderContainer _container(User? user) {
  final container = ProviderContainer(
    overrides: [currentUserProvider.overrideWithValue(user)],
  );
  addTearDown(container.dispose);
  return container;
}

Future<Map<String, dynamic>> _stored(String ownerId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('character_last_opened:$ownerId');
  return raw == null ? {} : jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('record écrit l\'horodatage (epoch ms) sous une clé scopée par '
      'compte', () async {
    final container = _container(_user('owner-1'));
    final notifier = container.read(characterLastOpenedProvider.notifier);

    await notifier.record('c1', now: DateTime.fromMillisecondsSinceEpoch(1234));

    expect(container.read(characterLastOpenedProvider), {'c1': 1234});
    expect(await _stored('owner-1'), {'c1': 1234});
    expect(await _stored('owner-2'), isEmpty);
  });

  test('un second record du même personnage remplace l\'horodatage', () async {
    final container = _container(_user('owner-1'));
    final notifier = container.read(characterLastOpenedProvider.notifier);
    await notifier.record('c1', now: DateTime.fromMillisecondsSinceEpoch(1));
    await notifier.record('c2', now: DateTime.fromMillisecondsSinceEpoch(2));
    await notifier.record('c1', now: DateTime.fromMillisecondsSinceEpoch(3));

    expect(await _stored('owner-1'), {'c1': 3, 'c2': 2});
  });

  test('sans date injectée : horodatage = maintenant', () async {
    final container = _container(_user('owner-1'));
    final before = DateTime.now().millisecondsSinceEpoch;
    await container.read(characterLastOpenedProvider.notifier).record('c1');
    final after = DateTime.now().millisecondsSinceEpoch;

    final value = (await _stored('owner-1'))['c1'] as int;
    expect(value, inInclusiveRange(before, after));
  });

  test(
    'un autre compte du même appareil ne relit jamais ces valeurs',
    () async {
      SharedPreferences.setMockInitialValues({
        'character_last_opened:owner-1': jsonEncode({'c1': 99}),
      });
      final other = _container(_user('owner-2'));
      // Laisse `sharedPreferencesProvider` se résoudre.
      await other.read(characterLastOpenedProvider.notifier).purge({});
      expect(other.read(characterLastOpenedProvider), isEmpty);

      final owner = _container(_user('owner-1'));
      await owner.read(characterLastOpenedProvider.notifier).purge({'c1'});
      // Attend la résolution des préférences puis la reconstruction.
      await Future<void>.delayed(Duration.zero);
      expect(owner.read(characterLastOpenedProvider), {'c1': 99});
    },
  );

  test('purge retire les identifiants absents de la liste chargée', () async {
    SharedPreferences.setMockInitialValues({
      'character_last_opened:owner-1': jsonEncode({'c1': 1, 'c2': 2, 'c3': 3}),
    });
    final container = _container(_user('owner-1'));

    await container.read(characterLastOpenedProvider.notifier).purge({
      'c1',
      'c3',
    });

    expect(await _stored('owner-1'), {'c1': 1, 'c3': 3});
    expect(container.read(characterLastOpenedProvider), {'c1': 1, 'c3': 3});
  });

  test(
    'purge sans changement : aucune réécriture ni changement d\'état',
    () async {
      SharedPreferences.setMockInitialValues({
        'character_last_opened:owner-1': jsonEncode({'c1': 1}),
      });
      final container = _container(_user('owner-1'));
      await container.read(characterLastOpenedProvider.notifier).purge({'c1'});
      expect(await _stored('owner-1'), {'c1': 1});
    },
  );

  test('sans utilisateur connecté : rien n\'est écrit', () async {
    final container = _container(null);
    await container
        .read(characterLastOpenedProvider.notifier)
        .record('c1', now: DateTime.fromMillisecondsSinceEpoch(5));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
    expect(container.read(characterLastOpenedProvider), isEmpty);
  });

  test(
    'valeur corrompue en préférences : ignorée, jamais d\'exception',
    () async {
      SharedPreferences.setMockInitialValues({
        'character_last_opened:owner-1': 'pas du json',
      });
      final container = _container(_user('owner-1'));
      await container
          .read(characterLastOpenedProvider.notifier)
          .record('c1', now: DateTime.fromMillisecondsSinceEpoch(7));
      expect(await _stored('owner-1'), {'c1': 7});
    },
  );
}
