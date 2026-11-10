import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_clock_provider.g.dart';

/// Horloge de l'UI de synchro (libellé « Dernière synchronisation » du
/// Profil) — `DateTime.now` par défaut, surchargeable dans les tests.
@Riverpod(keepAlive: true)
DateTime Function() syncClock(Ref ref) => DateTime.now;
