import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/app_update/domain/changelog_parser.dart';

const _sample = '''
# Changelog

## Publier une nouvelle version

1. Étape de procédure, jamais affichée.

## [Non publié]

### Notes de version (stores)

```
<fr-FR>
• Pas encore sortie
</fr-FR>
```

## [1.2.0] — 2026-10-02 (build 7)

### Notes de version (stores)

```
<fr-FR>
• Nouveauté A
• Nouveauté B
</fr-FR>
```

### Ajouté
- Détail technique, jamais affiché.

## [1.1.0] — 2026-09-30 (build 6) — non publiée sur les stores

### Ajouté
- Sans notes de version : ignorée.

## [1.0.0] — 2026-09-01

### Notes de version (stores)

```
<fr-FR>
Première version.
</fr-FR>
```
''';

void main() {
  group('ChangelogParser.parse', () {
    test('ne garde que les versions publiées avec notes de version, dans '
        "l'ordre du fichier", () {
      final releases = ChangelogParser.parse(_sample);

      expect(releases.map((release) => release.version), ['1.2.0', '1.0.0']);
    });

    test('extrait date et lignes de notes, sans balise de langue', () {
      final release = ChangelogParser.parse(_sample).first;

      expect(release.date, '2026-10-02');
      expect(release.notes, ['• Nouveauté A', '• Nouveauté B']);
    });

    test('accepte les fins de ligne Windows', () {
      final releases = ChangelogParser.parse(_sample.replaceAll('\n', '\r\n'));

      expect(releases, hasLength(2));
      expect(releases.last.notes, ['Première version.']);
    });

    test('texte vide : aucune version', () {
      expect(ChangelogParser.parse(''), isEmpty);
    });

    test('le CHANGELOG.md du dépôt (embarqué dans l’app) est lisible : au '
        'moins une version, toutes avec des notes', () {
      final releases = ChangelogParser.parse(
        File('CHANGELOG.md').readAsStringSync(),
      );

      expect(releases, isNotEmpty);
      for (final release in releases) {
        expect(release.notes, isNotEmpty, reason: release.version);
        expect(release.date, isNotNull, reason: release.version);
      }
    });
  });
}
