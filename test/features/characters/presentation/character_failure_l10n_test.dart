// D141 : les erreurs de personnages, de groupes et de création sont portées
// par un code stable (couche `data/`) traduit en présentation selon la langue
// de l'app. Ces tests couvrent, pour chaque code, le texte FR (identique aux
// anciens messages en dur) et le texte EN, ainsi que le repli `generic`
// (message brut du serveur, jamais traduit) et les mappers d'erreurs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/character_creation_error_mapper.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/presentation/character_creation_failure_l10n.dart';
import 'package:personnages/features/characters/data/character_error_mapper.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/presentation/character_failure_l10n.dart';
import 'package:personnages/features/groups/data/group_error_mapper.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/presentation/group_failure_l10n.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _networkFr =
    'Impossible de contacter le serveur. Vérifiez votre connexion internet '
    'et réessayez.';
const _networkEn =
    "Couldn't reach the server. Check your internet connection and try again.";

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('CharacterFailure.localizedWith', () {
    const expected = <CharacterErrorCode, (String, String)>{
      CharacterErrorCode.accessDenied: (
        "Vous n'avez pas accès à ces personnages.",
        "You don't have access to these characters.",
      ),
      CharacterErrorCode.network: (_networkFr, _networkEn),
      CharacterErrorCode.loadFailed: (
        'Impossible de charger vos personnages. Réessayez.',
        "Couldn't load your characters. Try again.",
      ),
      CharacterErrorCode.characterNotFound: (
        'Personnage introuvable.',
        'Character not found.',
      ),
      CharacterErrorCode.itemNotFound: (
        'Objet introuvable.',
        'Item not found.',
      ),
      CharacterErrorCode.invalidQuantity: (
        'La quantité doit être au moins 1.',
        'Quantity must be at least 1.',
      ),
      CharacterErrorCode.noteAlreadyDeleted: (
        'Cette note a déjà été supprimée.',
        'This note was already deleted.',
      ),
      CharacterErrorCode.characterNotOwned: (
        'Ce personnage est introuvable ou ne vous appartient plus.',
        "This character can't be found or no longer belongs to you.",
      ),
      CharacterErrorCode.sessionExpired: (
        'Session expirée. Reconnectez-vous.',
        'Session expired. Please sign in again.',
      ),
    };

    test('chaque code (hors generic) a un texte FR et EN attendu', () {
      // Garde : un nouveau code sans entrée ici fait échouer le test.
      expect(
        expected.keys.toSet(),
        CharacterErrorCode.values.toSet()..remove(CharacterErrorCode.generic),
      );
      for (final entry in expected.entries) {
        final failure = CharacterFailure('brut serveur', code: entry.key);
        expect(
          failure.localizedWith(fr),
          entry.value.$1,
          reason: '${entry.key}',
        );
        expect(
          failure.localizedWith(en),
          entry.value.$2,
          reason: '${entry.key}',
        );
      }
    });

    test('generic : le message brut est repris tel quel', () {
      const failure = CharacterFailure('duplicate key value');
      expect(failure.localizedWith(fr), 'duplicate key value');
      expect(failure.localizedWith(en), 'duplicate key value');
    });

    test('mapper : 42501 -> accessDenied, message vide -> loadFailed, '
        'message serveur -> generic, hors Postgrest -> network', () {
      expect(
        mapCharacterError(
          const PostgrestException(message: 'denied', code: '42501'),
        ).code,
        CharacterErrorCode.accessDenied,
      );
      final empty = mapCharacterError(const PostgrestException(message: ''));
      expect(empty.code, CharacterErrorCode.loadFailed);
      expect(
        empty.localizedWith(en),
        "Couldn't load your characters. Try again.",
      );
      final raw = mapCharacterError(
        const PostgrestException(message: 'boom', code: '500'),
      );
      expect(raw.code, CharacterErrorCode.generic);
      expect(raw.message, 'boom');
      expect(mapUnknownCharacterError().code, CharacterErrorCode.network);
    });
  });

  group('GroupFailure.localizedWith', () {
    const expected = <GroupErrorCode, (String, String)>{
      GroupErrorCode.accessDenied: (
        "Vous n'avez pas accès à ce groupe.",
        "You don't have access to this group.",
      ),
      GroupErrorCode.network: (_networkFr, _networkEn),
      GroupErrorCode.groupNotFound: ('Groupe introuvable.', 'Group not found.'),
      GroupErrorCode.sessionExpired: (
        'Session expirée. Reconnectez-vous pour continuer.',
        'Session expired. Sign in again to continue.',
      ),
      GroupErrorCode.inviteCodeGenerationFailed: (
        'Impossible de générer un nouveau code. Réessayez.',
        "Couldn't generate a new code. Try again.",
      ),
    };

    test('chaque code (hors generic) a un texte FR et EN attendu', () {
      expect(
        expected.keys.toSet(),
        GroupErrorCode.values.toSet()..remove(GroupErrorCode.generic),
      );
      for (final entry in expected.entries) {
        final failure = GroupFailure('brut serveur', code: entry.key);
        expect(
          failure.localizedWith(fr),
          entry.value.$1,
          reason: '${entry.key}',
        );
        expect(
          failure.localizedWith(en),
          entry.value.$2,
          reason: '${entry.key}',
        );
      }
    });

    test('generic : le message brut est repris tel quel', () {
      const failure = GroupFailure('Erreur serveur.');
      expect(failure.localizedWith(en), 'Erreur serveur.');
    });

    test('mapper : 42501 -> accessDenied, message vide ou hors Postgrest '
        '-> network', () {
      expect(
        mapGroupError(
          const PostgrestException(message: 'denied', code: '42501'),
        ).code,
        GroupErrorCode.accessDenied,
      );
      expect(
        mapGroupError(const PostgrestException(message: '')).code,
        GroupErrorCode.network,
      );
      expect(
        mapGroupError(const PostgrestException(message: 'boom')).code,
        GroupErrorCode.generic,
      );
      expect(mapUnknownGroupError().localizedWith(en), _networkEn);
    });
  });

  group('CharacterCreationFailure.localizedWith', () {
    const expected = <CharacterCreationErrorCode, (String, String)>{
      CharacterCreationErrorCode.accessDenied: (
        "Vous n'avez pas accès à cette action.",
        "You don't have access to this action.",
      ),
      CharacterCreationErrorCode.network: (_networkFr, _networkEn),
      CharacterCreationErrorCode.sessionExpiredCreate: (
        'Session expirée. Reconnectez-vous pour créer un personnage.',
        'Session expired. Sign in again to create a character.',
      ),
      CharacterCreationErrorCode.sessionExpiredEdit: (
        'Session expirée. Reconnectez-vous puis réessayez.',
        'Session expired. Sign in again and try again.',
      ),
      CharacterCreationErrorCode.sessionExpiredImport: (
        'Session expirée. Reconnectez-vous pour importer un personnage.',
        'Session expired. Sign in again to import a character.',
      ),
      CharacterCreationErrorCode.characterNotFound: (
        'Personnage introuvable.',
        'Character not found.',
      ),
    };

    test('chaque code (hors generic) a un texte FR et EN attendu', () {
      expect(
        expected.keys.toSet(),
        CharacterCreationErrorCode.values.toSet()
          ..remove(CharacterCreationErrorCode.generic),
      );
      for (final entry in expected.entries) {
        final failure = CharacterCreationFailure(
          'brut serveur',
          code: entry.key,
        );
        expect(
          failure.localizedWith(fr),
          entry.value.$1,
          reason: '${entry.key}',
        );
        expect(
          failure.localizedWith(en),
          entry.value.$2,
          reason: '${entry.key}',
        );
      }
    });

    test('generic : le message brut est repris tel quel', () {
      const failure = CharacterCreationFailure('Une erreur est survenue.');
      expect(failure.localizedWith(en), 'Une erreur est survenue.');
    });

    test('mapper : 42501 -> accessDenied, hors Postgrest -> network', () {
      expect(
        mapCharacterCreationError(
          const PostgrestException(message: 'denied', code: '42501'),
        ).code,
        CharacterCreationErrorCode.accessDenied,
      );
      expect(mapUnknownCharacterCreationError().localizedWith(en), _networkEn);
    });
  });

  group('localized(context)', () {
    testWidgets('suit la langue de l\'app (EN puis FR) et retombe sur message '
        'sans délégué', (tester) async {
      Future<String> resolve(Locale? locale) async {
        late String text;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: locale == null
                ? null
                : AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: Builder(
              builder: (context) {
                text = mapUnknownCharacterError().localized(context);
                return const SizedBox();
              },
            ),
          ),
        );
        return text;
      }

      expect(await resolve(const Locale('en')), _networkEn);
      expect(await resolve(const Locale('fr')), _networkFr);
      expect(await resolve(null), _networkFr);
    });
  });
}
