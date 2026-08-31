import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_creation_return_route_provider.g.dart';

/// Route de retour paramétrable pour l'assistant de création de personnage,
/// consommée par `character_creation/presentation/summary_step_screen.dart`
/// (`_submit`, dernière étape) une fois le personnage créé avec succès.
///
/// `null` (valeur par défaut) : comportement historique inchangé, retour à
/// la liste des personnages (`context.go('/')`).
///
/// Non `null` : un sous-flux a lancé l'assistant de création depuis un point
/// qui veut reprendre la main après coup plutôt que d'atterrir sur la liste
/// des personnages — à ce jour, uniquement l'étape 3/4 "Choix du personnage"
/// du flux "Rejoindre une histoire" (`features/join_story/presentation/
/// join_character_step_screen.dart::_startCharacterCreation`, bouton "+
/// Créer un nouveau personnage"), qui pose ici `/join/step-3?code=...` avant
/// de pousser `/characters/new`.
///
/// Choix technique délibéré (état porté par un provider `keepAlive`, plutôt
/// qu'un paramètre de route `?returnTo=...` propagé de force à travers les 9
/// écrans poussés par l'assistant, ou un `popUntil` par prédicat de route
/// fragile — voir la documentation de classe de `SummaryStepScreen` pour un
/// rationale similaire déjà tranché sur un problème voisin) : signalé au
/// chef de projet plutôt qu'appliqué silencieusement, ce point n'était pas
/// tranché dans le cahier des charges.
///
/// [consume] retire immédiatement la valeur lue (remise à `null`) : une
/// route de retour ne doit servir qu'une seule fois — une création de
/// personnage lancée normalement depuis `CharacterListScreen` juste après
/// doit atterrir sur `/`, pas rejouer un retour vers "Rejoindre une
/// histoire" laissé par une session précédente abandonnée avant l'étape 9
/// (`CharacterListScreen._startCreation` appelle aussi [set] avec `null`
/// pour ce même filet de sécurité, voir sa documentation).
@Riverpod(keepAlive: true)
class CharacterCreationReturnRouteController
    extends _$CharacterCreationReturnRouteController {
  @override
  String? build() => null;

  void set(String? route) => state = route;

  /// Lit puis efface la route de retour en une seule opération — voir la
  /// documentation de classe.
  String? consume() {
    final route = state;
    state = null;
    return route;
  }
}
