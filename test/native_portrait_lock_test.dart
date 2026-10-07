// Garde des fichiers natifs du verrou "portrait uniquement, sans écran
// partagé" (décisions produit du 06/10/2026).
//
// Ce verrou n'a aucun code Dart : il tient entièrement dans
// `AndroidManifest.xml`, `build.gradle.kts` et `Info.plist`. La CI ne
// construit rien de natif et l'app n'a aucune mise en page paysage : sans ce
// test, une régression de ces fichiers (régénération par `flutter create .`,
// montée de version, fusion malheureuse) partirait en production sans alerte.
//
// Ce que ce test ne prouve pas : il lit des fichiers de configuration, il ne
// dit rien du comportement réel sur appareil (tablettes Android 16+, iPad,
// surcharges d'un manifeste de variante ou d'un réglage Xcode). Le verrou
// reste à valider sur appareil.
//
// Hypothèse de chemin : `flutter test` lance chaque fichier de test avec la
// racine du projet comme répertoire courant (les fixtures de
// `test/features/xml_import/` reposent déjà dessus). Par prudence, la racine
// est retrouvée en remontant jusqu'au premier `pubspec.yaml`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

const _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const _gradlePath = 'android/app/build.gradle.kts';
const _plistPath = 'ios/Runner/Info.plist';

const _androidNamespace = 'http://schemas.android.com/apk/res/android';
const _compatProperty =
    'android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY';
const _pinnedTargetSdk = '36';
const _portrait = 'UIInterfaceOrientationPortrait';

const _whyItMatters =
    "L'app est en portrait uniquement, sans mise en page paysage ni écran "
    'partagé : ce réglage natif est à rétablir, pas ce test à assouplir '
    '(sauf décision produit contraire, à traiter avec le chef de projet).';

File _projectFile(String relativePath) {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/pubspec.yaml').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      fail(
        'Racine du projet introuvable (aucun pubspec.yaml en remontant depuis '
        '${Directory.current.path}) : lancer `flutter test` depuis le dépôt.',
      );
    }
    directory = parent;
  }
  final file = File('${directory.path}/$relativePath');
  if (!file.existsSync()) {
    fail(
      '$relativePath est introuvable : ce fichier porte le verrou portrait. '
      "S'il a été déplacé, adapter le chemin dans ce test ; s'il a été "
      'supprimé, le restaurer. $_whyItMatters',
    );
  }
  return file;
}

XmlDocument _parseXml(String relativePath) {
  final content = _projectFile(relativePath).readAsStringSync();
  try {
    return XmlDocument.parse(content);
  } on XmlException catch (error) {
    fail("$relativePath n'est pas un XML valide : $error");
  }
}

String? _androidAttribute(XmlElement element, String name) =>
    element.getAttribute(name, namespaceUri: _androidNamespace);

XmlElement _application(XmlDocument manifest) {
  final applications = manifest.rootElement
      .findElements('application')
      .toList();
  if (applications.length != 1) {
    fail(
      '$_manifestPath : ${applications.length} élément(s) <application> '
      'trouvé(s), 1 attendu.',
    );
  }
  return applications.single;
}

XmlElement _mainActivity(XmlDocument manifest) {
  final activities = _application(manifest)
      .findElements('activity')
      .where(
        (activity) => (_androidAttribute(activity, 'name') ?? '').endsWith(
          '.MainActivity',
        ),
      )
      .toList();
  if (activities.length != 1) {
    fail(
      '$_manifestPath : ${activities.length} <activity> « .MainActivity » '
      "trouvée(s), 1 attendue. Si l'activité principale a été renommée, "
      'adapter ce test et vérifier que le verrou portrait la suit. '
      '$_whyItMatters',
    );
  }
  return activities.single;
}

/// Valeurs de la `<property>` de compatibilité, cherchée sur `.MainActivity`
/// et sur `<application>` (Android accepte les deux niveaux). Vide si absente.
List<String?> _compatPropertyValues(XmlDocument manifest) {
  return [
        ..._mainActivity(manifest).findElements('property'),
        ..._application(manifest).findElements('property'),
      ]
      .where(
        (property) => _androidAttribute(property, 'name') == _compatProperty,
      )
      .map((property) => _androidAttribute(property, 'value'))
      .toList();
}

/// Lignes du script (hors lignes de commentaire `//`) qui mentionnent
/// `targetSdk`, quelle que soit la forme.
List<String> _targetSdkLines(String gradleSource) => const LineSplitter()
    .convert(gradleSource)
    .map((line) => line.trim())
    .where(
      (line) =>
          !line.startsWith('//') && line.toLowerCase().contains('targetsdk'),
    )
    .toList();

/// Élément valeur associé à [key] dans le `<dict>` racine du plist.
XmlElement _plistValue(XmlDocument plist, String key) {
  final dicts = plist.rootElement.findElements('dict').toList();
  if (dicts.length != 1) {
    fail('$_plistPath : <dict> racine introuvable ou multiple.');
  }
  final children = dicts.single.childElements.toList();
  final values = <XmlElement>[
    for (var index = 0; index + 1 < children.length; index += 2)
      if (children[index].name.local == 'key' &&
          children[index].innerText == key)
        children[index + 1],
  ];
  if (values.length != 1) {
    fail(
      '$_plistPath : la clé « $key » apparaît ${values.length} fois, 1 '
      'attendue (une clé citée dans un commentaire ne compte pas). La '
      'rétablir une seule fois. $_whyItMatters',
    );
  }
  return values.single;
}

void main() {
  group('Verrou portrait natif — AndroidManifest.xml', () {
    test('.MainActivity force le portrait (android:screenOrientation)', () {
      final activity = _mainActivity(_parseXml(_manifestPath));

      expect(
        _androidAttribute(activity, 'screenOrientation'),
        'portrait',
        reason:
            '$_manifestPath : `android:screenOrientation="portrait"` doit '
            "être un attribut de l'<activity> .MainActivity (absent, modifié "
            'ou seulement cité en commentaire). Valeur exacte `portrait` : '
            '`sensorPortrait`, `userPortrait` et `reversePortrait` sont '
            'refusées (portrait droit uniquement, comme dans Info.plist). '
            '$_whyItMatters',
      );
    });

    test('.MainActivity refuse le multi-fenêtre '
        '(android:resizeableActivity)', () {
      final activity = _mainActivity(_parseXml(_manifestPath));

      expect(
        _androidAttribute(activity, 'resizeableActivity'),
        'false',
        reason:
            '$_manifestPath : `android:resizeableActivity="false"` doit être '
            "un attribut de l'<activity> .MainActivity (absent, modifié ou "
            "seulement cité en commentaire) : sans lui, l'app revient dans "
            "l'écran partagé sur téléphone. $_whyItMatters",
      );
    });

    test('la <property> de compatibilité rétablit le verrou sur tablette', () {
      expect(
        _compatPropertyValues(_parseXml(_manifestPath)),
        ['true'],
        reason:
            '$_manifestPath : `<property android:name="$_compatProperty" '
            'android:value="true" />` doit figurer une seule fois, dans '
            "l'<activity> .MainActivity ou directement sous <application> "
            '(absente, valeur modifiée ou seulement citée en commentaire). '
            'Sans elle, Android 16+ ignore '
            'screenOrientation et resizeableActivity sur tablettes et '
            'pliables dépliés. $_whyItMatters',
      );
    });
  });

  group('Verrou portrait natif — build.gradle.kts', () {
    test('targetSdk reste à $_pinnedTargetSdk tant que la <property> de '
        'compatibilité porte le verrou tablette', () {
      if (_compatPropertyValues(_parseXml(_manifestPath)).isEmpty) {
        markTestSkipped(
          'Non vérifié : la <property> $_compatProperty est absente de '
          "$_manifestPath, figer targetSdk n'a alors plus d'objet. C'est le "
          'test du manifeste qui signale la régression.',
        );
        return;
      }

      expect(
        _targetSdkLines(_projectFile(_gradlePath).readAsStringSync()),
        ['targetSdk = $_pinnedTargetSdk'],
        reason:
            '$_gradlePath : la seule ligne à mentionner targetSdk (hors '
            'lignes de commentaire `//`) doit être exactement '
            '`targetSdk = $_pinnedTargetSdk`, seule sur sa ligne, avec son '
            'commentaire sur la ligne du dessus. NE PAS se contenter de '
            'changer le nombre attendu dans ce test : à targetSdk 37, '
            "Android cesse d'appliquer la <property> $_compatProperty de "
            '$_manifestPath, et le verrou portrait tombe sur tablettes et '
            "pliables, alors que l'app n'a aucune mise en page paysage. "
            'Monter la version cible se traite en même temps que le verrou '
            'tablette (autre mécanisme ou mise en page adaptative, à décider '
            'avec le chef de projet) ; ce test est alors adapté dans le même '
            'changement.',
      );
    });
  });

  group('Verrou portrait natif — Info.plist', () {
    for (final key in [
      'UISupportedInterfaceOrientations',
      'UISupportedInterfaceOrientations~ipad',
    ]) {
      test('$key ne déclare que le portrait', () {
        final value = _plistValue(_parseXml(_plistPath), key);
        final orientations = value.childElements
            .map((element) => element.innerText)
            .toSet();

        // Type de l'élément puis orientations, sans doublon ni ordre imposé.
        expect(
          [value.name.local, ...orientations.toList()..sort()],
          ['array', _portrait],
          reason:
              '$_plistPath : « $key » doit être un <array> contenant '
              'uniquement <string>$_portrait</string> (retirer toute '
              'orientation paysage ou PortraitUpsideDown, souvent réapparues '
              'après une régénération du projet iOS). $_whyItMatters',
        );
      });
    }

    test('UIRequiresFullScreen est à true', () {
      expect(
        _plistValue(_parseXml(_plistPath), 'UIRequiresFullScreen').name.local,
        'true',
        reason:
            '$_plistPath : « UIRequiresFullScreen » doit valoir <true/>. '
            "Sans cette clé, l'iPad garde l'app dans le multitâche et l'App "
            "Store refuse un envoi qui ne déclare pas les quatre "
            'orientations. $_whyItMatters',
      );
    });
  });
}
