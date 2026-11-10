import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personnages/features/profile/presentation/widgets/last_sync_label.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

/// Règle 12 : libellé « Dernière synchronisation » du Profil — formats
/// relatif/absolu, « jamais », suffixe N.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
  });

  final fr = AppLocalizationsFr();
  final en = AppLocalizationsEn();
  final now = DateTime(2026, 11, 10, 15, 0);

  String label(
    Duration ago, {
    int pending = 0,
    bool english = false,
    DateTime? lastSync,
  }) => lastSyncLabel(
    english ? en : fr,
    lastSync: lastSync ?? now.subtract(ago),
    now: now,
    pendingCount: pending,
  );

  group('relatif', () {
    test('< 1 min : « à l\'instant »', () {
      expect(label(Duration.zero), 'Dernière synchronisation : à l\'instant');
      expect(
        label(const Duration(seconds: 59)),
        'Dernière synchronisation : à l\'instant',
      );
    });

    test('un écart négatif (horloge reculée) reste « à l\'instant »', () {
      expect(
        label(const Duration(minutes: -5)),
        'Dernière synchronisation : à l\'instant',
      );
    });

    test('< 60 min : « il y a N min »', () {
      expect(
        label(const Duration(minutes: 1)),
        'Dernière synchronisation : il y a 1 min',
      );
      expect(
        label(const Duration(minutes: 5, seconds: 30)),
        'Dernière synchronisation : il y a 5 min',
      );
      expect(
        label(const Duration(minutes: 59, seconds: 59)),
        'Dernière synchronisation : il y a 59 min',
      );
    });

    test('< 24 h : « il y a N h »', () {
      expect(
        label(const Duration(hours: 1)),
        'Dernière synchronisation : il y a 1 h',
      );
      expect(
        label(const Duration(hours: 23, minutes: 59)),
        'Dernière synchronisation : il y a 23 h',
      );
    });
  });

  group('absolu (au-delà de 24 h)', () {
    test('FR : « 10 nov. 2026 à 14:32 »', () {
      final lastSync = DateTime(2026, 11, 10, 14, 32);
      final later = DateTime(2026, 11, 12, 9, 0);
      expect(
        lastSyncLabel(fr, lastSync: lastSync, now: later, pendingCount: 0),
        'Dernière synchronisation : 10 nov. 2026 à 14:32',
      );
    });

    test('exactement 24 h : date absolue', () {
      expect(
        label(const Duration(hours: 24)),
        'Dernière synchronisation : 9 nov. 2026 à 15:00',
      );
    });

    test('EN : date dans la langue de l\'app', () {
      final text = label(const Duration(days: 3), english: true);
      expect(text, startsWith('Last sync: Nov 7, 2026 at '));
    });
  });

  group('jamais et suffixe', () {
    test('jamais synchronisé : « jamais » / "never"', () {
      expect(
        lastSyncLabel(fr, lastSync: null, now: now, pendingCount: 0),
        'Dernière synchronisation : jamais',
      );
      expect(
        lastSyncLabel(en, lastSync: null, now: now, pendingCount: 0),
        'Last sync: never',
      );
    });

    test('suffixe « · N en attente » si N > 0, jamais à 0', () {
      expect(
        label(const Duration(minutes: 5), pending: 2),
        'Dernière synchronisation : il y a 5 min · 2 en attente',
      );
      expect(
        label(const Duration(minutes: 5), pending: 0),
        isNot(contains('en attente')),
      );
      expect(
        lastSyncLabel(fr, lastSync: null, now: now, pendingCount: 1),
        'Dernière synchronisation : jamais · 1 en attente',
      );
      expect(
        label(const Duration(minutes: 5), pending: 2, english: true),
        'Last sync: 5 min ago · 2 pending',
      );
    });
  });
}
