import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/data/group_error_mapper.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapGroupError', () {
    test('42501 (RLS) -> message dédié', () {
      final failure = mapGroupError(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );
      expect(failure.message, "Vous n'avez pas accès à ce groupe.");
      expect(failure.code, GroupErrorCode.accessDenied);
    });

    test('message non vide -> réutilisé tel quel', () {
      final failure = mapGroupError(
        const PostgrestException(message: 'Erreur serveur', code: '500'),
      );
      expect(failure.message, 'Erreur serveur');
      expect(failure.code, GroupErrorCode.generic);
    });

    test('message vide -> message réseau générique', () {
      final failure = mapGroupError(const PostgrestException(message: ''));
      expect(
        failure.message,
        'Impossible de contacter le serveur. Vérifiez votre connexion '
        'internet et réessayez.',
      );
    });
  });

  // Contrat DeepCore (migration `20261119090000`, PR #49) : le `message` porte
  // un code stable, lu AVANT le SQLSTATE / statut HTTP.
  group(
    'mapGroupError : codes stables de DeepCore (message lu en premier)',
    () {
      const cases = <(String, String, GroupErrorCode)>[
        ('combat_active', 'P0001', GroupErrorCode.combatActive),
        ('mj_already_assigned', 'P0001', GroupErrorCode.mjAlreadyAssigned),
        // 42501 seul donnerait « accès refusé » : le message l'emporte.
        ('not_group_owner', '42501', GroupErrorCode.notGroupOwner),
        ('not_member', 'P0002', GroupErrorCode.notMember),
        ('group_not_found', 'P0002', GroupErrorCode.groupNotFound),
        ('not_authenticated', '28000', GroupErrorCode.sessionExpired),
        // `not_member` / `group_not_found` peuvent arriver en HTTP 500 : si le
        // corps n'est pas du JSON, `code` vaut le statut HTTP.
        ('not_member', '500', GroupErrorCode.notMember),
        ('group_not_found', '500', GroupErrorCode.groupNotFound),
        ('combat_active', '400', GroupErrorCode.combatActive),
      ];
      for (final (message, code, expected) in cases) {
        test('« $message » ($code) -> $expected', () {
          final failure = mapGroupError(
            PostgrestException(message: message, code: code),
          );
          expect(failure.code, expected);
          expect(failure.message, isNot(message));
          expect(failure.message, isNotEmpty);
        });
      }

      test('message entouré d\'espaces : reconnu', () {
        expect(
          mapGroupError(
            const PostgrestException(message: ' combat_active ', code: 'P0001'),
          ).code,
          GroupErrorCode.combatActive,
        );
      });

      test('code inconnu dans le message : générique, message brut gardé', () {
        final failure = mapGroupError(
          const PostgrestException(message: 'combat_actif', code: 'P0001'),
        );
        expect(failure.code, GroupErrorCode.generic);
        expect(failure.message, 'combat_actif');
      });
    },
  );

  group('mapGroupError : SQLSTATE quand le message n\'est pas un code', () {
    test('40P01 (interblocage) -> conflit transitoire, « Réessayez »', () {
      final failure = mapGroupError(
        const PostgrestException(message: 'deadlock detected', code: '40P01'),
      );
      expect(failure.code, GroupErrorCode.transientConflict);
      expect(failure.message, contains('Réessayez'));
    });

    test('40001 (sérialisation) -> conflit transitoire', () {
      expect(
        mapGroupError(
          const PostgrestException(
            message: 'could not serialize access due to concurrent update',
            code: '40001',
          ),
        ).code,
        GroupErrorCode.transientConflict,
      );
    });

    test('PGRST202 (fonction absente, migration non appliquée) -> serveur '
        'pas à jour', () {
      expect(
        mapGroupError(
          const PostgrestException(
            message:
                'Could not find the function '
                'public.become_group_game_master(p_group_id) in the schema '
                'cache',
            code: 'PGRST202',
          ),
        ).code,
        GroupErrorCode.serverOutdated,
      );
    });
  });

  test('mapUnknownGroupError -> message réseau générique', () {
    expect(
      mapUnknownGroupError().message,
      'Impossible de contacter le serveur. Vérifiez votre connexion '
      'internet et réessayez.',
    );
    expect(mapUnknownGroupError().code, GroupErrorCode.network);
  });
}
