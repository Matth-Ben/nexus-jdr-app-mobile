import 'package:freezed_annotation/freezed_annotation.dart';

part 'xml_field_resolution.freezed.dart';

/// Résultat de la résolution d'un champ de personnage exporté par
/// aidedd.org (voir `docs/cahier-des-charges/03-import-xml-aidedd.md`),
/// qu'il s'agisse d'un champ "en clair" (résolu par recherche du nom dans
/// une table de référence interne de l'app, ex. race/classe/historique via
/// `xml_character_import_resolver.dart`) ou d'un champ "codé" (identifiant
/// numérique propre au format aidedd.org, résolu via
/// `data/aidedd_reference_tables.dart`, ex. armure/objet/alignement).
///
/// Union à 3 variantes plutôt qu'un simple booléen "reconnu ?" + une valeur
/// nullable, sur consigne explicite du chef de projet pour ce chantier :
/// [custom] doit rester un état à part entière, jamais confondu avec
/// [unrecognized] — voir sa documentation pour le cas `itemX` qui motive
/// cette distinction. Premier usage d'une union freezed dans ce dépôt
/// (aucun autre modèle de ce dépôt n'utilisait `sealed class` + plusieurs
/// factory constructors avant cette tâche, voir `character_creation_failure
/// .dart`/`character_failure.dart` pour le pattern précédent, une simple
/// classe à un seul constructeur) : jugé le bon outil pour ce besoin précis
/// (voir la consigne d'origine de la tâche), signalé ici plutôt
/// qu'introduit silencieusement.
@freezed
sealed class XmlFieldResolution<T> with _$XmlFieldResolution<T> {
  const XmlFieldResolution._();

  /// Le champ XML a été résolu avec succès vers [value] — une entrée d'une
  /// table de référence interne de l'app (ex. `RaceOption`) pour un champ
  /// "en clair", ou le libellé issu de `AideddReferenceTables` (`String`)
  /// pour un champ "codé".
  const factory XmlFieldResolution.recognized(T value) =
      XmlFieldResolutionRecognized<T>;

  /// Le nom ou l'identifiant numérique du champ XML ne correspond à rien de
  /// connu (contenu homebrew, nom légèrement différent, ou identifiant
  /// absent de `AideddReferenceTables`) — pas un échec de tout l'import
  /// (voir `03-import-xml-aidedd.md` point 3/4 du "Comportement attendu de
  /// l'import"), à proposer à l'utilisateur pour confirmation/correction
  /// manuelle par le futur écran de récapitulatif (increment suivant).
  /// [rawValue] est le contenu brut tel qu'il apparaissait dans le XML
  /// (nom de texte ou identifiant numérique converti en `String`), gardé
  /// pour l'affichage — jamais vide pour un champ réellement présent dans
  /// le XML (voir `XmlNameResolver`/`XmlCodedFieldResolver`).
  const factory XmlFieldResolution.unrecognized(String rawValue) =
      XmlFieldResolutionUnrecognized<T>;

  /// Contenu texte libre par construction, jamais un identifiant à chercher
  /// dans une table — cas d'usage unique à ce jour : `itemX`
  /// (objets personnalisés), qu'aidedd.org traite déjà comme du texte libre
  /// dès la saisie utilisateur (décision produit actée, voir la consigne
  /// d'origine de la tâche). Un état neutre, **pas** une erreur de
  /// résolution : ne doit jamais être compté ni affiché comme un
  /// [unrecognized] par le futur écran de récapitulatif.
  const factory XmlFieldResolution.custom(String text) =
      XmlFieldResolutionCustom<T>;

  /// `true` si ce champ a été résolu avec succès (voir [recognized]) — pour
  /// les écrans/logiques qui n'ont besoin que de compter les champs à
  /// vérifier manuellement, sans être un `sealed class` complet client-side.
  bool get isRecognized => this is XmlFieldResolutionRecognized<T>;

  /// `true` pour [unrecognized] uniquement — **pas** pour [custom], qui
  /// n'est jamais un état d'erreur (voir sa documentation).
  bool get isUnrecognized => this is XmlFieldResolutionUnrecognized<T>;
}
