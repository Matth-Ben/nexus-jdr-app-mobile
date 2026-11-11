// Garde-fou de dérive de la réponse 3 de la FAQ ("Mes personnages
// sont-ils sauvegardés hors ligne ?", F17) : le texte doit rester cohérent
// avec le chantier hors ligne (inventaire, monnaies et journal sont mis en
// file) et mentionner ce qui demande encore une connexion.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/l10n/app_localizations.dart';

void main() {
  final answers = <String, String>{
    'fr': lookupAppLocalizations(const Locale('fr')).profileFaqAnswer3,
    'en': lookupAppLocalizations(const Locale('en')).profileFaqAnswer3,
  };

  // Séparation de la partie "fonctionne hors ligne" de la partie
  // "demande toujours une connexion".
  const markers = {'fr': 'Demandent toujours', 'en': 'Still needing'};

  for (final entry in answers.entries) {
    final lang = entry.key;
    final text = entry.value;
    final cut = text.indexOf(markers[lang]!);

    test('[$lang] la partie "connexion requise" existe', () {
      expect(cut, greaterThan(0));
    });

    final offlineOk = cut > 0 ? text.substring(0, cut) : text;
    final needsConnection = cut > 0 ? text.substring(cut) : '';

    test(
      '[$lang] inventaire, monnaies, journal : hors ligne, pas "connexion"',
      () {
        final words = lang == 'fr'
            ? ['inventaire', 'monnaies', 'journal']
            : ['inventory', 'currency', 'journal'];
        for (final w in words) {
          expect(offlineOk.toLowerCase(), contains(w));
          expect(needsConnection.toLowerCase(), isNot(contains(w)));
        }
      },
    );

    test('[$lang] mentionne bannière, alerte de conflit et catalogue', () {
      final lower = text.toLowerCase();
      final words = lang == 'fr'
          ? ['bannière', 'alerte', 'catalogue', 'un seul repos']
          : ['banner', 'alert', 'catalog', 'only one rest'];
      for (final w in words) {
        expect(lower, contains(w));
      }
    });

    test('[$lang] liste ce qui demande une connexion', () {
      final lower = needsConnection.toLowerCase();
      final words = lang == 'fr'
          ? ['création', 'montée de niveau', 'groupes', 'import']
          : ['creation', 'level-up', 'groups', 'import'];
      for (final w in words) {
        expect(lower, contains(w));
      }
    });
  }
}
