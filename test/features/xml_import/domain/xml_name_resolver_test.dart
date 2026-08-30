// Tests unitaires de la résolution "en clair" par nom pour l'import XML
// aidedd.org (`lib/features/xml_import/domain/xml_name_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/xml_import/domain/xml_field_resolution.dart';
import 'package:personnages/features/xml_import/domain/xml_name_resolver.dart';

class _Candidate {
  const _Candidate(this.name);
  final String name;
}

void main() {
  const candidates = [
    _Candidate('Aasimar'),
    _Candidate('Conil'),
    _Candidate('Haut-elfe'),
  ];

  test('correspondance exacte -> recognized', () {
    final result = XmlNameResolver.resolveByName(
      rawName: 'Aasimar',
      candidates: candidates,
      nameOf: (c) => c.name,
    );

    expect(result, isA<XmlFieldResolutionRecognized<_Candidate>>());
    expect(
      (result as XmlFieldResolutionRecognized<_Candidate>).value.name,
      'Aasimar',
    );
  });

  test('correspondance insensible à la casse et aux accents -> recognized', () {
    final result = XmlNameResolver.resolveByName(
      rawName: 'AASIMAR',
      candidates: candidates,
      nameOf: (c) => c.name,
    );
    expect(result, isA<XmlFieldResolutionRecognized<_Candidate>>());

    final result2 = XmlNameResolver.resolveByName(
      rawName: 'conil',
      candidates: candidates,
      nameOf: (c) => c.name,
    );
    expect(
      (result2 as XmlFieldResolutionRecognized<_Candidate>).value.name,
      'Conil',
    );
  });

  test('aucune correspondance -> unrecognized avec la valeur brute', () {
    final result = XmlNameResolver.resolveByName(
      rawName: 'Gobelours',
      candidates: candidates,
      nameOf: (c) => c.name,
    );

    expect(result, isA<XmlFieldResolutionUnrecognized<_Candidate>>());
    expect(
      (result as XmlFieldResolutionUnrecognized<_Candidate>).rawValue,
      'Gobelours',
    );
  });

  test('nom brut vide/null -> unrecognized', () {
    expect(
      XmlNameResolver.resolveByName(
        rawName: null,
        candidates: candidates,
        nameOf: (c) => c.name,
      ),
      isA<XmlFieldResolutionUnrecognized<_Candidate>>(),
    );
    expect(
      XmlNameResolver.resolveByName(
        rawName: '   ',
        candidates: candidates,
        nameOf: (c) => c.name,
      ),
      isA<XmlFieldResolutionUnrecognized<_Candidate>>(),
    );
  });

  test('liste de candidats vide -> toujours unrecognized', () {
    final result = XmlNameResolver.resolveByName<_Candidate>(
      rawName: 'Aasimar',
      candidates: const [],
      nameOf: (c) => c.name,
    );
    expect(result, isA<XmlFieldResolutionUnrecognized<_Candidate>>());
  });
}
