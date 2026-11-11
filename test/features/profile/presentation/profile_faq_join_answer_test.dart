// Garde-fou de dérive de la réponse 2 de la FAQ ("Comment rejoindre
// l'histoire de mon MJ ?", P19) : le bouton « Rejoindre une histoire » est
// volontairement masqué dans la liste des personnages
// (`character_list_screen.dart`), la réponse doit décrire le parcours réel
// (lien d'invitation du MJ) et ne plus présenter ce bouton comme une action
// d'écran.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/l10n/app_localizations.dart';

void main() {
  final byLocale = <String, AppLocalizations>{
    'fr': lookupAppLocalizations(const Locale('fr')),
    'en': lookupAppLocalizations(const Locale('en')),
  };

  for (final entry in byLocale.entries) {
    final lang = entry.key;
    final answers = {
      'answer2': entry.value.profileFaqAnswer2,
      'answer1': entry.value.profileFaqAnswer1,
      'answer3': entry.value.profileFaqAnswer3,
      'answer4': entry.value.profileFaqAnswer4,
      'answer5': entry.value.profileFaqAnswer5,
      'answer6': entry.value.profileFaqAnswer6,
    };

    test('[$lang] la réponse 2 décrit le lien d\'invitation du MJ', () {
      final text = answers['answer2']!.toLowerCase();
      expect(text, isNotEmpty);
      expect(text, contains(lang == 'fr' ? 'lien' : 'link'));
      expect(text, contains(lang == 'fr' ? 'invitation' : 'invitation'));
      expect(text, contains(lang == 'fr' ? 'personnage' : 'character'));
    });

    test('[$lang] aucune réponse ne présente un bouton « Rejoindre une '
        'histoire »', () {
      for (final e in answers.entries) {
        final text = e.value.toLowerCase();
        expect(text, isNot(contains('rejoindre une histoire')), reason: e.key);
        expect(text, isNot(contains('join a story')), reason: e.key);
        expect(text, isNot(contains('bouton « rejoindre')), reason: e.key);
      }
    });
  }

  test('FR : accents corrects dans la réponse 2', () {
    final text = byLocale['fr']!.profileFaqAnswer2;
    expect(text, contains('téléphone'));
    expect(text, contains('« Histoires »'));
  });
}
