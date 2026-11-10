import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_activity_provider.g.dart';

/// `true` tant qu'au moins une passe de synchro de la file hors-ligne est en
/// cours — publié par `CharacterWriteSyncCoordinator` (features/characters),
/// lu par le bandeau de synchro. Compteur interne : deux passes qui se
/// chevauchent ne repassent à `false` qu'à la fin de la dernière.
@Riverpod(keepAlive: true)
class SyncActivity extends _$SyncActivity {
  int _running = 0;

  @override
  bool build() => false;

  void begin() {
    _running++;
    state = true;
  }

  void end() {
    if (_running > 0) _running--;
    state = _running > 0;
  }
}
