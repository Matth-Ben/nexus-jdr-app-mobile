import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/utils/uuid_v4.dart';

void main() {
  test('generateUuidV4 : forme v4 RFC, minuscules, valide pour isUuid', () {
    final id = generateUuidV4(Random(42));
    expect(isUuid(id), isTrue);
    expect(id, id.toLowerCase());
    expect(id[14], '4');
    expect('89ab'.contains(id[19]), isTrue);
  });

  test('deux identifiants successifs diffèrent', () {
    expect(generateUuidV4(), isNot(generateUuidV4()));
  });

  test('isUuid refuse les formes invalides', () {
    expect(isUuid(''), isFalse);
    expect(isUuid('pas-un-uuid'), isFalse);
    expect(isUuid('11111111111111111111111111111111'), isFalse);
    expect(isUuid('1111111g-1111-4111-8111-111111111111'), isFalse);
  });
}
