// Tests unitaires de la résolution "codée" (identifiant numérique aidedd.org
// -> libellé) pour l'import XML
// (`lib/features/xml_import/domain/xml_coded_field_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/xml_import/domain/xml_coded_field_resolver.dart';
import 'package:personnages/features/xml_import/domain/xml_field_resolution.dart';

void main() {
  const table = {0: 'Sans armure', 10: 'Cotte de mailles'};

  test('identifiant présent dans la table -> recognized(libellé)', () {
    final result = XmlCodedFieldResolver.resolveById(id: 10, table: table);
    expect(
      result,
      const XmlFieldResolution<String>.recognized('Cotte de mailles'),
    );
  });

  test('identifiant `0` légitime (ex. armure/bouclier) -> recognized', () {
    final result = XmlCodedFieldResolver.resolveById(id: 0, table: table);
    expect(result, const XmlFieldResolution<String>.recognized('Sans armure'));
  });

  test('identifiant absent de la table -> unrecognized(id en texte)', () {
    final result = XmlCodedFieldResolver.resolveById(id: 42, table: table);
    expect(result, const XmlFieldResolution<String>.unrecognized('42'));
  });

  test('identifiant null -> unrecognized', () {
    final result = XmlCodedFieldResolver.resolveById(id: null, table: table);
    expect(result.isUnrecognized, isTrue);
  });
}
