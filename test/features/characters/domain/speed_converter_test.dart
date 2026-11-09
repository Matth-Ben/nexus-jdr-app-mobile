import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/speed_converter.dart';

void main() {
  group('SpeedConverter.feetToMetres', () {
    const expected = {0: 0.0, 25: 7.5, 30: 9.0, 35: 10.5, 40: 12.0};
    expected.forEach((feet, metres) {
      test('$feet pieds -> $metres m', () {
        expect(SpeedConverter.feetToMetres(feet), metres);
      });
    });
  });
}
