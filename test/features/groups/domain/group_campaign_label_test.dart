// Règles d'affichage de l'étiquette « Campagne » (étape 4 de Grimoire) :
// rognage aligné sur les contraintes CHECK de DeepCore, décision n° 36
// (titre identique au nom du groupe) et résumé jamais affiché sans titre.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/group_campaign_label.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';

void main() {
  group('GroupCampaignLabel.clean', () {
    test('null ou fait seulement de blancs : null', () {
      expect(GroupCampaignLabel.clean(null), isNull);
      expect(GroupCampaignLabel.clean(''), isNull);
      expect(GroupCampaignLabel.clean(' \t\n'), isNull);
    });

    test('rogne les blancs de DeepCore que String.trim garde (U+200B, '
        'U+2060)', () {
      expect(GroupCampaignLabel.clean('\u200b\u2060'), isNull);
      expect(
        GroupCampaignLabel.clean('\u200b\u00a0La Mine perdue\u202f\u2060'),
        'La Mine perdue',
      );
    });

    test('garde les blancs intérieurs et les retours à la ligne', () {
      expect(
        GroupCampaignLabel.clean('  Ligne 1\n\nLigne 2  '),
        'Ligne 1\n\nLigne 2',
      );
    });
  });

  group('GroupCampaignLabel.displayedTitle (décision n° 36)', () {
    test('sans titre : null', () {
      expect(
        GroupCampaignLabel.displayedTitle(storyTitle: null, groupName: 'G'),
        isNull,
      );
    });

    test('titre distinct du nom : titre rogné', () {
      expect(
        GroupCampaignLabel.displayedTitle(
          storyTitle: '  La Mine perdue ',
          groupName: 'Les Lames',
        ),
        'La Mine perdue',
      );
    });

    test('titre identique au nom, casse et blancs ignorés : null', () {
      expect(
        GroupCampaignLabel.displayedTitle(
          storyTitle: ' les lames de l’AUBE ',
          groupName: 'Les Lames de l’Aube',
        ),
        isNull,
      );
    });

    test('titre qui contient le nom sans lui être identique : affiché', () {
      expect(
        GroupCampaignLabel.displayedTitle(
          storyTitle: 'Les Lames, saison 2',
          groupName: 'Les Lames',
        ),
        'Les Lames, saison 2',
      );
    });
  });

  group('GroupCampaignLabel.displayedSummary', () {
    test('résumé sans titre : jamais affiché', () {
      expect(
        GroupCampaignLabel.displayedSummary(
          storyTitle: null,
          storySummary: 'Un résumé.',
        ),
        isNull,
      );
    });

    test('titre identique au nom : le résumé reste affiché', () {
      expect(
        GroupCampaignLabel.displayedSummary(
          storyTitle: 'Les Lames',
          storySummary: ' Un résumé. ',
        ),
        'Un résumé.',
      );
    });

    test('résumé vide ou absent : null', () {
      expect(
        GroupCampaignLabel.displayedSummary(
          storyTitle: 'T',
          storySummary: null,
        ),
        isNull,
      );
      expect(
        GroupCampaignLabel.displayedSummary(
          storyTitle: 'T',
          storySummary: '  ',
        ),
        isNull,
      );
    });

    test('retours à la ligne gardés, CRLF normalisés en LF', () {
      expect(
        GroupCampaignLabel.displayedSummary(
          storyTitle: 'T',
          storySummary: 'Ligne 1\r\nLigne 2\rLigne 3\nLigne 4',
        ),
        'Ligne 1\nLigne 2\nLigne 3\nLigne 4',
      );
    });
  });

  group('GroupPreview.campaignTitle', () {
    test('avec un titre distinct du nom', () {
      const preview = GroupPreview(
        name: 'Les Lames',
        memberCount: 3,
        storyTitle: 'La Mine perdue',
      );
      expect(preview.campaignTitle, 'La Mine perdue');
    });

    test('sans titre', () {
      const preview = GroupPreview(name: 'Les Lames', memberCount: 3);
      expect(preview.storyTitle, isNull);
      expect(preview.campaignTitle, isNull);
    });

    test('titre identique au nom : null', () {
      const preview = GroupPreview(
        name: 'Les Lames',
        memberCount: 3,
        storyTitle: 'LES LAMES',
      );
      expect(preview.campaignTitle, isNull);
    });
  });
}
