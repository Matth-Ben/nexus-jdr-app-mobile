import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/app_update/domain/app_version_comparator.dart';

void main() {
  group('AppVersionComparator.compare', () {
    test('versions égales -> 0', () {
      expect(AppVersionComparator.compare('1.2.3', '1.2.3'), 0);
    });

    test('major supérieur -> positif', () {
      expect(AppVersionComparator.compare('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('minor supérieur, major égal -> positif', () {
      expect(AppVersionComparator.compare('1.3.0', '1.2.9'), greaterThan(0));
    });

    test('patch supérieur, major/minor égaux -> positif', () {
      expect(AppVersionComparator.compare('1.2.5', '1.2.4'), greaterThan(0));
    });

    test('comparaison NUMÉRIQUE, pas lexicographique : "1.10.0" > "1.2.0"', () {
      expect(AppVersionComparator.compare('1.10.0', '1.2.0'), greaterThan(0));
      expect(AppVersionComparator.isLowerThan('1.2.0', '1.10.0'), isTrue);
    });

    test('même piège sur le segment patch : "1.0.10" > "1.0.2"', () {
      expect(AppVersionComparator.compare('1.0.10', '1.0.2'), greaterThan(0));
    });

    test('segment manquant traité comme 0 : "1.2" == "1.2.0"', () {
      expect(AppVersionComparator.compare('1.2', '1.2.0'), 0);
    });

    test('segment non numérique traité comme 0, pas d\'exception', () {
      expect(
        () => AppVersionComparator.compare('1.x.0', '1.0.0'),
        returnsNormally,
      );
      expect(AppVersionComparator.compare('1.x.0', '1.0.0'), 0);
    });
  });

  group('AppVersionComparator.isLowerThan', () {
    test('true si a < b', () {
      expect(AppVersionComparator.isLowerThan('0.1.0', '0.3.0'), isTrue);
    });

    test('false si a == b', () {
      expect(AppVersionComparator.isLowerThan('1.0.0', '1.0.0'), isFalse);
    });

    test('false si a > b', () {
      expect(AppVersionComparator.isLowerThan('1.0.1', '1.0.0'), isFalse);
    });
  });
}
