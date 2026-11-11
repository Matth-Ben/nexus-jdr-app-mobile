import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'die_skin.dart';

/// Charge un programme de fragment depuis un asset (remplaçable dans les
/// tests, où le moteur ne peut pas toujours le compiler).
typedef DieProgramLoader = Future<ui.FragmentProgram> Function(String asset);

/// Cache statique des programmes de fragment du dé animé : chaque shader est
/// chargé **une seule fois** (au premier lancer, avant l'ouverture de la
/// feuille), jamais pendant une animation. Un échec est mémorisé : le dé
/// retombe alors sur le rendu « niveau 1 » (couleurs de sommets seules), sans
/// rien afficher à l'utilisateur ; l'erreur n'est journalisée qu'en debug.
class DieShaderCache {
  DieShaderCache({DieProgramLoader? loader})
    : _loader = loader ?? ui.FragmentProgram.fromAsset;

  /// Instance partagée de l'application.
  static final DieShaderCache shared = DieShaderCache();

  final DieProgramLoader _loader;
  final Map<DieShaderId, ui.FragmentProgram> _programs = {};
  final Set<DieShaderId> _failed = {};
  final Map<DieShaderId, Future<void>> _pending = {};

  /// Programme déjà chargé, ou `null` (pas encore chargé, ou en échec).
  ui.FragmentProgram? programFor(DieShaderId id) => _programs[id];

  /// `true` si le chargement de [id] a échoué (définitivement, pour la
  /// durée de vie du cache).
  bool hasFailed(DieShaderId id) => _failed.contains(id);

  /// Lance (une seule fois) le chargement de [id]. Ne lève jamais.
  Future<void> preload(DieShaderId id) {
    if (_programs.containsKey(id) || _failed.contains(id)) {
      return Future.value();
    }
    return _pending[id] ??= _load(id);
  }

  Future<void> _load(DieShaderId id) async {
    try {
      _programs[id] = await _loader(id.asset);
    } on Object catch (error) {
      _failed.add(id);
      if (kDebugMode) {
        debugPrint('DieShaderCache : shader ${id.name} indisponible ($error)');
      }
    } finally {
      _pending.remove(id);
    }
  }
}
