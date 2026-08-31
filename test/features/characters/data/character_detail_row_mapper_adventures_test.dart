// Tests unitaires de `CharacterDetailRowMapper.parseAdventures` — carte
// "Aventures" de l'onglet "Personnage". Fichier dédié (plutôt qu'ajouté au
// test existant du reste du mapper, non retrouvé isolé dans ce dépôt) pour
// isoler ce comportement nouveau, y compris la limite RLS connue (voir la
// documentation de classe de `CharacterAdventure`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_detail_row_mapper.dart';

void main() {
  group('CharacterDetailRowMapper.parseAdventures', () {
    test('construit une CharacterAdventure par ligne character_campaigns '
        'dont stories est résolu', () {
      final row = {
        'character_campaigns': [
          {
            'id': 'cc-1',
            'story_id': 'story-1',
            'stories': {
              'title': 'La Malédiction du Nord',
              'cover_image_path': 'a/b.png',
            },
          },
          {
            'id': 'cc-2',
            'story_id': 'story-2',
            'stories': {
              'title': 'Les Ombres de Faerûn',
              'cover_image_path': null,
            },
          },
        ],
      };

      final adventures = CharacterDetailRowMapper.parseAdventures(
        row,
        resolveCoverUrl: (path) =>
            path == null ? null : 'https://cdn.test/$path',
      );

      expect(adventures, hasLength(2));
      expect(adventures[0].characterCampaignId, 'cc-1');
      expect(adventures[0].storyId, 'story-1');
      expect(adventures[0].storyTitle, 'La Malédiction du Nord');
      expect(adventures[0].storyCoverUrl, 'https://cdn.test/a/b.png');
      expect(adventures[1].storyCoverUrl, isNull);
    });

    test(
      'omet silencieusement une ligne dont stories est null (limite RLS '
      'connue — le joueur ne peut pas encore lire la ligne stories liée)',
      () {
        final row = {
          'character_campaigns': [
            {'id': 'cc-1', 'story_id': 'story-1', 'stories': null},
          ],
        };

        final adventures = CharacterDetailRowMapper.parseAdventures(
          row,
          resolveCoverUrl: (path) => path,
        );

        expect(adventures, isEmpty);
      },
    );

    test('retourne une liste vide sans character_campaigns dans la ligne', () {
      final adventures = CharacterDetailRowMapper.parseAdventures(
        const <String, dynamic>{},
        resolveCoverUrl: (path) => path,
      );

      expect(adventures, isEmpty);
    });
  });
}
