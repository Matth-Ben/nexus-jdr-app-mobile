import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/portrait_storage_path_resolver.dart';

void main() {
  group('PortraitStoragePathResolver.resolve', () {
    test('extrait le chemin depuis une URL publique Supabase Storage', () {
      const url =
          'http://127.0.0.1:54321/storage/v1/object/public/character-portraits/'
          'abc/def/123456.png';
      expect(PortraitStoragePathResolver.resolve(url), 'abc/def/123456.png');
    });

    test('fonctionne avec un domaine de production https', () {
      const url =
          'https://xyzcompany.supabase.co/storage/v1/object/public/'
          'character-portraits/owner-1/char-2/999.png';
      expect(
        PortraitStoragePathResolver.resolve(url),
        'owner-1/char-2/999.png',
      );
    });

    test(
      'retourne null pour une URL externe qui ne pointe pas vers le bucket',
      () {
        expect(
          PortraitStoragePathResolver.resolve('https://example.com/foo.jpg'),
          isNull,
        );
      },
    );

    test('retourne null si le chemin après le marqueur est vide', () {
      const url =
          'https://xyz.supabase.co/storage/v1/object/public/character-portraits/';
      expect(PortraitStoragePathResolver.resolve(url), isNull);
    });
  });
}
