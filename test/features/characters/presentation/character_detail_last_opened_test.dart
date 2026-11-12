// P18 : l'ouverture de la fiche écrit l'horodatage LOCAL « dernière
// ouverture » (clé scopée par compte, jamais de donnée serveur).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../../support/fake_slot_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    "ouvrir la fiche écrit l'horodatage de CE personnage, pour le compte "
    'connecté uniquement',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final before = DateTime.now().millisecondsSinceEpoch;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterRepositoryProvider.overrideWithValue(
              FakeSlotRepository(wizardDetail()),
            ),
            currentUserProvider.overrideWithValue(
              User(
                id: 'owner-1',
                appMetadata: const {},
                userMetadata: const {},
                aud: 'authenticated',
                createdAt: '2026-01-01T00:00:00Z',
              ),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
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

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString('character_last_opened:owner-1')!) as Map;
      expect(stored.keys, ['1']);
      expect(
        stored['1'] as int,
        inInclusiveRange(before, DateTime.now().millisecondsSinceEpoch),
      );
      expect(prefs.getKeys(), {'character_last_opened:owner-1'});
    },
  );
}
