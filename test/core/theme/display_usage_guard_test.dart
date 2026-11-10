// Garde du plafond de la police pixel (chantier D192, PR 2) : tout texte en
// police `AppTypography.display` doit passer par `DisplayText` (qui plafonne
// l'agrandissement du système à x1,3 ou x1,5) ; un `Text` brut en display
// repartirait à x3,0 et casserait les mises en page étroites.
//
// Le test parcourt les sources de `lib/` et exige que chaque appel
// `AppTypography.display(` soit l'argument direct d'un `DisplayText(` ou d'un
// `DisplayText.rich(` (le plus proche appel englobant), en ignorant les
// commentaires et les littéraux de chaîne. Un écran ajouté plus tard sans le
// plafond fait échouer ce test.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Liste blanche : fichiers autorisés à appeler `AppTypography.display(` hors
/// d'un `DisplayText`. Toute entrée doit être justifiée ici, et retirée dès
/// qu'elle n'a plus d'usage (le test le vérifie).
///
/// Ne figurent pas ici `app_typography.dart` (définition du token, aucun
/// appel) ni `display_text.dart` (son implémentation, aucun appel) : le
/// détecteur ne les voit pas.
const Map<String, String> _allowlist = {
  // `TextStyle` du thème Material (`textTheme`, bouton, dialogue) : migrés en
  // corps par la PR 3 du chantier (D192) ; ne pas les convertir ici.
  'lib/core/theme/app_theme.dart': 'styles du thème Material, PR 3 (D192)',
};

/// Retire commentaires et littéraux de chaîne en conservant la position des
/// caractères (remplacés par des espaces) pour que les index restent valides.
String _blank(String src) {
  final out = StringBuffer();
  var i = 0;
  while (i < src.length) {
    final c = src[i];
    final next = i + 1 < src.length ? src[i + 1] : '';
    if (c == '/' && next == '/') {
      while (i < src.length && src[i] != '\n') {
        out.write(' ');
        i++;
      }
    } else if (c == '/' && next == '*') {
      while (i < src.length &&
          !(src[i] == '*' && src[i + 1 < src.length ? i + 1 : i] == '/')) {
        out.write(src[i] == '\n' ? '\n' : ' ');
        i++;
      }
      out.write('  ');
      i += 2;
    } else if (c == "'" || c == '"') {
      final triple = src.startsWith(c * 3, i);
      final end = triple ? c * 3 : c;
      out.write(' ' * end.length);
      i += end.length;
      while (i < src.length && !src.startsWith(end, i)) {
        if (src[i] == r'\') {
          out.write('  ');
          i += 2;
          continue;
        }
        if (!triple && src[i] == '\n') break;
        out.write(src[i] == '\n' ? '\n' : ' ');
        i++;
      }
      out.write(' ' * end.length);
      i += end.length;
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

/// Nom de l'appel qui englobe directement la position [index] (le plus proche
/// `(` non refermé), ou `null` hors de tout appel.
String? _enclosingCall(String code, int index) {
  var depth = 0;
  for (var i = index - 1; i >= 0; i--) {
    final c = code[i];
    if (c == ')' || c == ']' || c == '}') {
      depth++;
    } else if (c == '(' || c == '[' || c == '{') {
      if (depth == 0) {
        if (c != '(') return null;
        final match = RegExp(r'([A-Za-z_][\w.]*)\s*$')
            .firstMatch(code.substring(0, i));
        return match?.group(1);
      }
      depth--;
    }
  }
  return null;
}

/// Occurrences fautives de [source] (`ligne: contexte`).
List<String> findUncappedDisplayUses(String source) {
  final code = _blank(source);
  final problems = <String>[];
  for (final m in RegExp(r'AppTypography\.display\(').allMatches(code)) {
    final call = _enclosingCall(code, m.start);
    if (call != 'DisplayText' && call != 'DisplayText.rich') {
      final line = '\n'.allMatches(code.substring(0, m.start)).length + 1;
      problems.add('ligne $line (englobé par ${call ?? 'aucun appel'})');
    }
  }
  return problems;
}

void main() {
  group('findUncappedDisplayUses (le détecteur)', () {
    test('accepte le style passé à DisplayText et DisplayText.rich', () {
      const src = '''
DisplayText('A', style: AppTypography.display(fontSize: 11)),
DisplayText.rich(TextSpan(), style: AppTypography.display(fontSize: 11).copyWith(height: 1)),
''';
      expect(findUncappedDisplayUses(src), isEmpty);
    });

    test('refuse un Text brut, une variable et un TextSpan', () {
      const src = '''
Text('A', style: AppTypography.display(fontSize: 11)),
final s = AppTypography.display(fontSize: 11);
DisplayText.rich(TextSpan(style: AppTypography.display(fontSize: 11))),
''';
      expect(findUncappedDisplayUses(src), hasLength(3));
    });

    test('ignore commentaires et chaînes', () {
      const src = '''
// Text(style: AppTypography.display(fontSize: 11))
/// AppTypography.display(
final s = 'AppTypography.display(';
''';
      expect(findUncappedDisplayUses(src), isEmpty);
    });
  });

  test('tout AppTypography.display( de lib/ passe par DisplayText', () {
    final offenders = <String>[];
    final seenAllowed = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
      final problems = findUncappedDisplayUses(entity.readAsStringSync());
      if (problems.isEmpty) continue;
      if (_allowlist.containsKey(path)) {
        seenAllowed.add(path);
        continue;
      }
      offenders.add('$path : ${problems.join(', ')}');
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Texte en police pixel sans plafond : utiliser `DisplayText` '
          '(lib/core/widgets/display_text.dart, palier title ou control) '
          'plutôt que `Text` + `AppTypography.display`. Exception justifiée : '
          'l\'ajouter à _allowlist avec sa raison.',
    );
    // Une entrée de liste blanche devenue inutile doit être retirée.
    expect(
      _allowlist.keys.toSet().difference(seenAllowed),
      isEmpty,
      reason: 'Entrée de liste blanche sans usage non plafonné : la retirer.',
    );
  });
}
