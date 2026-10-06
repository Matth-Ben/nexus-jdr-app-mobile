// Garde-fou sur les images du splash natif (`flutter_native_splash`, voir
// `pubspec.yaml` et `tool/generate_splash_assets.sh`) : des sources de
// 8000 x 6000 px y ont déjà été livrées, soit 192 Mo par image une fois
// décodée au lancement de l'app.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Plus grand côté toléré : l'icône Android 12 et plus (288 dp en xxxhdpi,
/// soit 1152 px) est la plus grande image légitime.
const _maxSide = 1200;

/// Lit les dimensions dans l'en-tête IHDR du PNG, sans décoder l'image.
({int width, int height}) _pngSize(File file) {
  final header = ByteData.sublistView(file.readAsBytesSync(), 0, 24);
  return (width: header.getUint32(16), height: header.getUint32(20));
}

List<File> _pngsIn(String directory) {
  return Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList();
}

void main() {
  test('aucune image native ne dépasse $_maxSide px de côté', () {
    final files = [
      ..._pngsIn('assets/splash'),
      ..._pngsIn('android/app/src/main/res'),
      ..._pngsIn('ios/Runner/Assets.xcassets'),
    ];
    expect(files, isNotEmpty);

    final tooLarge = [
      for (final file in files)
        if (_pngSize(file) case final size
            when size.width > _maxSide || size.height > _maxSide)
          '${file.path} (${size.width} x ${size.height})',
    ];
    expect(tooLarge, isEmpty);
  });

  test('les sources ont le format attendu par chaque plateforme', () {
    // Icône Android 12 et plus sans fond : 288 x 288 dp, sources en 4x.
    expect(_pngSize(File('assets/splash/splash_icon_android12.png')), (
      width: 1152,
      height: 1152,
    ));
    // Logo : 160 dp de large, pour ne pas être rogné sur un écran de 320 dp.
    expect(_pngSize(File('assets/splash/splash_logo.png')).width, 640);
  });

  test('Android 12 et plus : pas d\'image de marque', () {
    final brandingFiles = _pngsIn('android/app/src/main/res')
        .where((file) => file.path.contains('android12branding'));
    expect(brandingFiles, isEmpty);

    for (final styles in [
      'android/app/src/main/res/values-v31/styles.xml',
      'android/app/src/main/res/values-night-v31/styles.xml',
    ]) {
      expect(
        File(styles).readAsStringSync(),
        isNot(contains('windowSplashScreenBrandingImage')),
      );
    }
  });
}
