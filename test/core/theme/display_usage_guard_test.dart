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
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_typography.dart';

/// Liste blanche : fichiers autorisés à appeler `AppTypography.display(` hors
/// d'un `DisplayText`. Toute entrée doit être justifiée ici, et retirée dès
/// qu'elle n'a plus d'usage (le test le vérifie).
///
/// Ne figurent pas ici `app_typography.dart` (définition du token, aucun
/// appel) ni `display_text.dart` (son implémentation, aucun appel) : le
/// détecteur ne les voit pas.
const Map<String, String> _allowlist = {
  // Seul reste `elevatedButtonTheme.textStyle` (display 11) : un `ThemeData`
  // ne peut pas plafonner, donc tout `ElevatedButton` reçoit un `DisplayText`
  // control (seul usage : « Réessayer » de `main.dart`). Le `textTheme` et le
  // dialogue sont en corps depuis la PR 3 (D192) ; `findThemeDisplayLeaks`
  // interdit tout autre display dans ce fichier.
  'lib/core/theme/app_theme.dart': 'textStyle du bouton Material (control)',
  // `_displayWordWidth` : mesure de largeur (TextPainter) pour choisir entre
  // boutons côte à côte et empilés ; aucun texte rendu, donc rien à plafonner.
  'lib/features/xml_import/presentation/xml_import_review_screen.dart':
      'mesure de largeur de mot, aucun rendu',
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

int _lineOf(String code, int index) =>
    code.substring(0, index).split('\n').length;

/// Appels display dont la taille littérale est inférieure à 11 px (plancher
/// d'accessibilité, décision du 10/11/2026 : jamais sous 11 px, dès x1,0). Une
/// taille passée par un identifiant est résolue vers `const double id = N;`
/// du même fichier.
List<String> findTooSmallDisplayUses(String source) {
  final code = _blank(source);
  final problems = <String>[];
  for (final m in RegExp(r'AppTypography\.display\(').allMatches(code)) {
    final args = code.substring(m.end, math.min(code.length, m.end + 400));
    final size = RegExp(r'fontSize:\s*([A-Za-z_][\w.]*|\d+(?:\.\d+)?)')
        .firstMatch(args)
        ?.group(1);
    if (size == null) continue;
    var value = double.tryParse(size);
    if (value == null) {
      final decl = RegExp(
        r'(?:const|final) double '
        '${RegExp.escape(size)}'
        r'\s*=\s*(\d+(?:\.\d+)?)',
      ).firstMatch(code);
      value = decl == null ? null : double.parse(decl.group(1)!);
    }
    if (value != null && value < AppTypography.minDisplayFontSize) {
      final line = _lineOf(code, m.start);
      problems.add('ligne $line (fontSize $value px)');
    }
  }
  return problems;
}

/// Usages du `textTheme` display (titres/boutons du thème Material) hors du
/// thème : ils hériteraient de la police pixel sans `DisplayText`.
List<String> findDisplayTextThemeUses(String source) {
  final code = _blank(source);
  return [
    for (final m in RegExp(
      r'textTheme\s*\.\s*(headlineSmall|titleLarge|titleMedium|labelLarge)',
    ).allMatches(code))
      'ligne ${_lineOf(code, m.start)} (${m.group(0)})',
  ];
}

/// Index de la parenthèse fermante qui correspond à la `(` à [open].
int _matchingParen(String code, int open) {
  var depth = 0;
  for (var i = open; i < code.length; i++) {
    if (code[i] == '(') depth++;
    if (code[i] == ')' && --depth == 0) return i;
  }
  return code.length;
}

/// Styles display tolérés dans le `textTheme` de `app_typography.dart` : le
/// titre d'AppBar, aujourd'hui sans usage.
const allowedDisplayTextThemeStyles = {'titleLarge'};

/// Fuites de police pixel dans le thème Material :
/// - dans le getter `textTheme` de [typographySource] (`app_typography.dart`),
///   tout style autre que [allowedDisplayTextThemeStyles] appelant `display(` ;
/// - dans [themeSource] (`app_theme.dart`), tout `display(` hors de
///   `elevatedButtonTheme` (bouton, plafonné par `DisplayText` control).
List<String> findThemeDisplayLeaks(
  String typographySource,
  String themeSource,
) {
  final problems = <String>[];
  final typo = _blank(typographySource);
  final start = typo.indexOf('TextTheme get textTheme');
  if (start < 0) {
    problems.add('getter textTheme introuvable dans app_typography.dart');
  } else {
    final open = typo.indexOf('TextTheme(', start) + 'TextTheme'.length;
    final body = typo.substring(open, _matchingParen(typo, open));
    for (final m in RegExp(r'(\w+)\s*:\s*display\(').allMatches(body)) {
      if (!allowedDisplayTextThemeStyles.contains(m.group(1))) {
        problems.add('textTheme.${m.group(1)} en police display');
      }
    }
  }
  final theme = _blank(themeSource);
  final button = theme.indexOf('elevatedButtonTheme');
  final buttonEnd = button < 0
      ? -1
      : _matchingParen(theme, theme.indexOf('(', button));
  for (final m in RegExp(r'\bdisplay\(').allMatches(theme)) {
    final inButton = button >= 0 && m.start > button && m.start < buttonEnd;
    if (!inButton) {
      problems.add(
        'app_theme.dart ligne ${_lineOf(theme, m.start)} : display(',
      );
    }
  }
  return problems;
}

/// Normalise un chemin (séparateurs Windows compris) en chemin POSIX.
String normalizeGuardPath(String path) => path.replaceAll(r'\', '/');

/// Écarts d'un fichier : display sous le plancher, et usages du `textTheme`
/// display hors de `lib/core/theme/` (exempté).
List<String> displayGuardOffenders(String rawPath, String source) {
  final path = normalizeGuardPath(rawPath);
  return [
    for (final p in findTooSmallDisplayUses(source)) '$path : $p',
    if (!path.startsWith('lib/core/theme/'))
      for (final p in findDisplayTextThemeUses(source)) '$path : $p',
  ];
}

void main() {
  group('détecteurs de taille et de textTheme', () {
    test('exempte lib/core/theme/ (POSIX et Windows), pas le reste', () {
      const src = 'final s = Theme.of(c).textTheme.titleLarge;';
      expect(
        displayGuardOffenders('lib/core/theme/app_theme.dart', src),
        isEmpty,
      );
      expect(
        displayGuardOffenders(r'lib\core\theme\app_theme.dart', src),
        isEmpty,
      );
      expect(
        displayGuardOffenders('lib/features/x/presentation/y.dart', src),
        hasLength(1),
      );
      expect(
        displayGuardOffenders(r'lib\features\x\y.dart', src),
        hasLength(1),
      );
    });

    test('refuse un display sous 11 px (littéral ou constante)', () {
      const src = '''
const double _small = 10;
DisplayText('A', style: AppTypography.display(fontSize: 9)),
DisplayText('B', style: AppTypography.display(fontSize: _small)),
DisplayText('C', style: AppTypography.display(fontSize: 11)),
''';
      expect(findTooSmallDisplayUses(src), hasLength(2));
    });

    test('refuse le textTheme display hors thème', () {
      const src = 'final s = Theme.of(context).textTheme.titleLarge;';
      expect(findDisplayTextThemeUses(src), hasLength(1));
      expect(findDisplayTextThemeUses('textTheme.bodyMedium'), isEmpty);
    });
  });

  group('findThemeDisplayLeaks (thème Material)', () {
    String typo(String extra) =>
        '''
static TextTheme get textTheme {
  return TextTheme(
    headlineSmall: body(fontSize: 17),
    titleLarge: display(fontSize: 13),
    labelLarge: body(fontSize: 14),
    $extra
  );
}
''';
    const okTheme = '''
ThemeData(
  textTheme: AppTypography.textTheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(textStyle: AppTypography.display(fontSize: 11)),
  ),
);
''';

    test('accepte titleLarge en display et le bouton', () {
      expect(findThemeDisplayLeaks(typo(''), okTheme), isEmpty);
    });

    test('refuse labelLarge, headlineSmall ou titleMedium en display', () {
      for (final style in ['labelLarge', 'headlineSmall', 'titleMedium']) {
        final src = style == 'titleMedium'
            ? typo('titleMedium: display(fontSize: 11),')
            : typo('').replaceFirst('$style: body(', '$style: display(');
        expect(findThemeDisplayLeaks(src, okTheme), [
          'textTheme.$style en police display',
        ], reason: style);
      }
    });

    test('refuse un display hors du bouton dans app_theme.dart', () {
      const theme = '''
ThemeData(
  textTheme: AppTypography.textTheme.copyWith(
    labelLarge: AppTypography.display(fontSize: 11),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(),
);
''';
      expect(findThemeDisplayLeaks(typo(''), theme), hasLength(1));
    });
  });

  test('le thème Material de lib/core/theme/ ne fuit pas de police pixel', () {
    expect(
      findThemeDisplayLeaks(
        File('lib/core/theme/app_typography.dart').readAsStringSync(),
        File('lib/core/theme/app_theme.dart').readAsStringSync(),
      ),
      isEmpty,
      reason:
          'Le textTheme (hors titleLarge) et app_theme.dart (hors bouton) '
          'doivent rester en police corps : un ThemeData ne peut pas '
          "plafonner l'agrandissement du texte display.",
    );
  });

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

  test('aucun display sous 11 px et aucun textTheme display hors thème', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      offenders.addAll(
        displayGuardOffenders(entity.path, entity.readAsStringSync()),
      );
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Display sous 11 px (plancher dès x1,0) ou textTheme display '
          'utilisé hors du thème : relever à 11 px ou utiliser DisplayText.',
    );
  });
}
