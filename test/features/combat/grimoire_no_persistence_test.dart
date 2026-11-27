// Le combat mené depuis Grimoire reste **en mémoire** : rien n'est écrit sur
// le disque (noms des autres joueurs, combat éphémère). Garde statique : aucun
// fichier du suivi Grimoire n'importe drift, le cache local ni un stockage.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Fichiers qui lisent ou affichent le combat Grimoire.
const _consumers = [
  'lib/features/combat/presentation/combat_screen.dart',
  'lib/features/combat/presentation/widgets/combat_banner.dart',
  'lib/features/combat/presentation/widgets/combat_sheet_banner.dart',
  'lib/features/combat/presentation/providers/character_combat_provider.dart',
  // Signal global et notifications du combat (PR 2 de l'étape 7).
  'lib/features/combat/presentation/combat_callout_host.dart',
  'lib/features/combat/presentation/combat_notification_handler.dart',
  'lib/features/combat/presentation/providers/combat_callout_providers.dart',
  'lib/features/combat/presentation/widgets/combat_callout.dart',
];

/// Fichiers du suivi Grimoire (domaine, données, fournisseurs, écran), plus
/// ceux qui le lisent ou l'affichent.
List<File> _grimoireSources() => [
  for (final entity in Directory(
    'lib/features/combat',
  ).listSync(recursive: true))
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        entity.uri.pathSegments.last.startsWith('grimoire_'))
      entity,
  for (final path in _consumers) File(path),
];

const _forbidden = [
  'package:drift',
  'package:sqlite3',
  'package:shared_preferences',
  'package:flutter_secure_storage',
  'package:path_provider',
  'core/cache/',
  'core/sync/',
  'dart:io',
];

void main() {
  test('les fichiers du suivi Grimoire existent', () {
    final names = _grimoireSources()
        .map((file) => file.uri.pathSegments.last)
        .toSet();
    expect(
      names,
      containsAll([
        'grimoire_combat_view.dart',
        'grimoire_combat_reducer.dart',
        'grimoire_combat_session.dart',
        'grimoire_combat_gateway.dart',
        'grimoire_combat_providers.dart',
        'grimoire_banner_provider.dart',
        'grimoire_combat_body.dart',
        'combat_screen.dart',
        'combat_banner.dart',
        'combat_sheet_banner.dart',
        'character_combat_provider.dart',
        'grimoire_groups_providers.dart',
        'combat_callout_host.dart',
        'combat_callout_providers.dart',
      ]),
    );
  });

  test('aucun import de drift, du cache local ni d\'un stockage', () {
    for (final file in _grimoireSources()) {
      final imports = file.readAsLinesSync().where(
        (line) => line.startsWith('import '),
      );
      for (final line in imports) {
        for (final forbidden in _forbidden) {
          expect(
            line.contains(forbidden),
            isFalse,
            reason: '${file.path} : $line',
          );
        }
      }
      expect(
        file.readAsStringSync().contains('AppDatabase'),
        isFalse,
        reason: file.path,
      );
    }
  });
}
