import 'dart:async';

import '../cache/sync_alert_store.dart';

/// État affiché par `SyncStatusBanner` — un seul à la fois.
enum SyncBannerKind {
  /// Rien (usage normal : en ligne, rien en attente, aucune alerte).
  none,

  /// Alerte persistée (abandon/conflit) : [SyncBannerState.alert].
  alert,

  /// Synchronisation en cours (visible seulement après 1 s continue).
  syncing,

  /// Hors ligne ([SyncBannerState.pendingCount] modifications en attente).
  offline,

  /// En ligne mais des modifications attendent depuis plus de 3 s.
  pending,

  /// Confirmation transitoire « Synchronisé ».
  synced,
}

class SyncBannerState {
  const SyncBannerState(
    this.kind, {
    this.pendingCount = 0,
    this.alert,
    this.moreAlerts = 0,
  });

  static const SyncBannerState none = SyncBannerState(SyncBannerKind.none);

  final SyncBannerKind kind;

  /// Renseigné pour [SyncBannerKind.offline] et [SyncBannerKind.pending].
  final int pendingCount;

  /// Renseignée pour [SyncBannerKind.alert] : la plus ancienne alerte.
  final SyncAlert? alert;

  /// Nombre d'autres alertes en attente derrière [alert] (suffixe « +N »).
  final int moreAlerts;

  @override
  bool operator ==(Object other) =>
      other is SyncBannerState &&
      other.kind == kind &&
      other.pendingCount == pendingCount &&
      other.alert?.id == alert?.id &&
      other.moreAlerts == moreAlerts;

  @override
  int get hashCode => Object.hash(kind, pendingCount, alert?.id, moreAlerts);

  @override
  String toString() =>
      'SyncBannerState($kind, n=$pendingCount, alert=${alert?.id}, '
      'more=$moreAlerts)';
}

/// Machine à états du bandeau de synchro : agrège les entrées brutes
/// (connectivité, nombre d'écritures en attente, activité de synchro,
/// alertes) en **un seul** [SyncBannerState], avec les temporisations de la
/// spec DA — précédence : alerte > synchro en cours > hors-ligne > en attente
/// (en ligne) > « Synchronisé » transitoire > rien.
///
/// Dart pur (aucun Riverpod/Flutter) : testable avec `fakeAsync`, les
/// délais s'appuient uniquement sur [Timer].
///
/// - « en cours » : visible après [syncingDelay] de synchro continue, puis
///   maintenu au moins [syncingMinHold] ;
/// - hors-ligne : visible après [offlineDelay] hors connexion (une coupure
///   plus brève ne clignote pas), disparaît dès le retour du réseau ; avec
///   0 modification en attente il n'est montré que si [showOfflineWhenEmpty]
///   (fiche, pas liste) ;
/// - en attente en ligne : visible si N > 0 depuis [pendingDelay] ;
/// - « Synchronisé » : [syncedDuration], seulement si un bandeau
///   hors-ligne/en attente venait d'être visible, jamais si une alerte a pris
///   la place entre-temps.
class SyncBannerEngine {
  SyncBannerEngine({
    required this.showOfflineWhenEmpty,
    this.syncingDelay = const Duration(seconds: 1),
    this.syncingMinHold = const Duration(milliseconds: 800),
    this.offlineDelay = const Duration(seconds: 2),
    this.pendingDelay = const Duration(seconds: 3),
    this.syncedDuration = const Duration(seconds: 2),
  });

  final bool showOfflineWhenEmpty;
  final Duration syncingDelay;
  final Duration syncingMinHold;
  final Duration offlineDelay;
  final Duration pendingDelay;
  final Duration syncedDuration;

  /// Rappelé à chaque changement d'état (jamais pendant le constructeur).
  void Function(SyncBannerState state)? onChanged;

  SyncBannerState _state = SyncBannerState.none;
  SyncBannerState get state => _state;

  bool _online = true;
  int _pending = 0;
  bool _syncingRaw = false;
  List<SyncAlert> _alerts = const [];

  bool _offlineConfirmed = false;
  bool _pendingConfirmed = false;
  bool _syncingShown = false;
  bool _holdElapsed = true;
  bool _syncedActive = false;
  bool _episode = false;
  bool _disposed = false;

  Timer? _offlineTimer;
  Timer? _pendingTimer;
  Timer? _syncingTimer;
  Timer? _holdTimer;
  Timer? _syncedTimer;

  void setOnline(bool online) {
    _online = online;
    _evaluate();
  }

  void setPendingCount(int count) {
    _pending = count;
    _evaluate();
  }

  void setSyncing(bool syncing) {
    _syncingRaw = syncing;
    _evaluate();
  }

  void setAlerts(List<SyncAlert> alerts) {
    _alerts = alerts;
    _evaluate();
  }

  void dispose() {
    _disposed = true;
    _offlineTimer?.cancel();
    _pendingTimer?.cancel();
    _syncingTimer?.cancel();
    _holdTimer?.cancel();
    _syncedTimer?.cancel();
  }

  void _evaluate() {
    if (_disposed) return;

    // Hors-ligne : confirmé après [offlineDelay], remis à zéro au retour.
    if (_online) {
      _offlineTimer?.cancel();
      _offlineTimer = null;
      _offlineConfirmed = false;
    } else {
      _offlineTimer ??= Timer(offlineDelay, () {
        _offlineConfirmed = true;
        _evaluate();
      });
    }

    // En attente en ligne : N > 0 continu pendant [pendingDelay].
    if (_online && _pending > 0) {
      _pendingTimer ??= Timer(pendingDelay, () {
        _pendingConfirmed = true;
        _evaluate();
      });
    } else {
      _pendingTimer?.cancel();
      _pendingTimer = null;
      _pendingConfirmed = false;
    }

    // Synchro en cours : visible après [syncingDelay] continu, maintenue
    // [syncingMinHold] après son affichage.
    if (_syncingRaw) {
      if (!_syncingShown) {
        _syncingTimer ??= Timer(syncingDelay, () {
          _syncingShown = true;
          _holdElapsed = false;
          _holdTimer?.cancel();
          _holdTimer = Timer(syncingMinHold, () {
            _holdElapsed = true;
            _evaluate();
          });
          _evaluate();
        });
      }
    } else {
      _syncingTimer?.cancel();
      _syncingTimer = null;
    }
    if (!_syncingRaw && _syncingShown && _holdElapsed) _syncingShown = false;

    final next = _compute();
    if (next != _state) {
      _state = next;
      onChanged?.call(next);
    }
  }

  SyncBannerState _compute() {
    if (_alerts.isNotEmpty) {
      // Fermer l'alerte avant l'échéance ne doit pas faire réapparaître
      // « Synchronisé ».
      _syncedTimer?.cancel();
      _syncedActive = false;
      _episode = false;
      return SyncBannerState(
        SyncBannerKind.alert,
        alert: _alerts.first,
        moreAlerts: _alerts.length - 1,
      );
    }
    if (_syncingShown) {
      return const SyncBannerState(SyncBannerKind.syncing);
    }
    if (_offlineConfirmed && (showOfflineWhenEmpty || _pending > 0)) {
      _episode = true;
      return SyncBannerState(SyncBannerKind.offline, pendingCount: _pending);
    }
    if (_pendingConfirmed && _pending > 0) {
      _episode = true;
      return SyncBannerState(SyncBannerKind.pending, pendingCount: _pending);
    }
    // « Synchronisé » seulement si tout est effectivement parti : en ligne ET
    // plus rien en attente. Sinon l'épisode reste armé (retour réseau avec
    // N > 0, synchro en échec, N tombé à 0 hors-ligne : pas de faux succès).
    if (_episode && _online && _pending == 0) {
      _episode = false;
      _syncedActive = true;
      _syncedTimer?.cancel();
      _syncedTimer = Timer(syncedDuration, () {
        _syncedActive = false;
        _evaluate();
      });
    }
    if (_syncedActive) return const SyncBannerState(SyncBannerKind.synced);
    return SyncBannerState.none;
  }
}
