import 'xml_character_import_resolved.dart';
import 'xml_field_resolution.dart';

/// Résultat du dénombrement d'une liste homogène de [XmlFieldResolution]
/// (quel que soit `T`) : combien sont [XmlFieldResolution.recognized],
/// combien sont [XmlFieldResolution.custom] (jamais compté comme un problème,
/// voir la documentation de classe de [XmlFieldResolution]), et la valeur
/// brute (`rawValue`) de chaque [XmlFieldResolution.unrecognized] — dans
/// l'ordre d'origine, pour un affichage "une ligne par entrée non reconnue"
/// (consolidation d'une carte d'alerte, voir `presentation/`).
typedef XmlImportGroupSummary = ({
  int recognizedCount,
  int customCount,
  List<String> unrecognizedRawValues,
});

/// Compte/regroupe les champs [XmlFieldResolution] d'un
/// [XmlCharacterImportResolved] pour l'écran de vérification de l'import XML
/// aidedd.org — logique pure, sans dépendance Flutter, pour rester testable
/// en isolation (voir la consigne d'origine de la tâche : "tests unitaires
/// sur la logique de comptage/regroupement des alertes et la distinction
/// custom/unrecognized").
///
/// [summarize] est le seul point d'entrée réellement générique : il fonctionne
/// pour n'importe quel `T` (race, classe, sort, libellé aidedd...) puisque
/// [XmlFieldResolution] expose les 3 variantes via un `sealed class` — aucun
/// besoin d'une surcharge par type de champ. Les champs du modèle qui ne sont
/// pas de simples `List<XmlFieldResolution<T>>` (les 4 groupes
/// `skillProficiencies`/`toolProficiencies`/`languages` par source, les
/// `weapons`/`toolEquipment`/`items` avec quantité, les `innateSpells`/
/// `knownSpells` avec niveau) sont d'abord aplatis par les méthodes dédiées
/// ci-dessous, qui délèguent ensuite toutes à [summarize].
abstract final class XmlImportAlertSummary {
  /// Dénombrement générique d'une liste homogène de résolutions.
  static XmlImportGroupSummary summarize<T>(
    List<XmlFieldResolution<T>> resolutions,
  ) {
    var recognizedCount = 0;
    var customCount = 0;
    final unrecognizedRawValues = <String>[];

    for (final resolution in resolutions) {
      switch (resolution) {
        case XmlFieldResolutionRecognized<T>():
          recognizedCount++;
        case XmlFieldResolutionCustom<T>():
          customCount++;
        case XmlFieldResolutionUnrecognized<T>(:final rawValue):
          unrecognizedRawValues.add(rawValue);
      }
    }

    return (
      recognizedCount: recognizedCount,
      customCount: customCount,
      unrecognizedRawValues: unrecognizedRawValues,
    );
  }

  /// Aplatit les 4 groupes (`0` race, `1` classe, `2` historique, `3` autres
  /// — voir `AideddReferenceTables.proficiencySources`) d'un champ
  /// `Map<int, List<XmlFieldResolution<T>>>` (`skillProficiencies`/
  /// `toolProficiencies`/`languages`) en une seule liste, dans l'ordre des
  /// clés `0` à `3`, avant de le passer à [summarize] — un compteur unique
  /// pour "Compétences"/"Outils"/"Langues" plutôt qu'un par groupe, voir la
  /// consigne d'origine de la tâche ("Le texte de statut compte le nombre
  /// réel de champs individuels concernés").
  static XmlImportGroupSummary summarizeGrouped<T>(
    Map<int, List<XmlFieldResolution<T>>> groups,
  ) {
    final flattened = <XmlFieldResolution<T>>[
      for (var groupId = 0; groupId <= 3; groupId++) ...?groups[groupId],
    ];
    return summarize(flattened);
  }

  /// Aplatit une liste de [XmlQuantifiedResolution] (`weapons`/
  /// `toolEquipment`/`items`) en la liste de ses seules résolutions avant de
  /// la passer à [summarize] — la quantité n'a aucun impact sur le
  /// dénombrement.
  static XmlImportGroupSummary summarizeQuantified(
    List<XmlQuantifiedResolution> resolutions,
  ) {
    return summarize([for (final entry in resolutions) entry.resolution]);
  }

  /// Aplatit une liste de [XmlSpellResolution] (`innateSpells`/`knownSpells`)
  /// en la liste de ses seules résolutions avant de la passer à [summarize] —
  /// le niveau du sort n'a aucun impact sur le dénombrement.
  static XmlImportGroupSummary summarizeSpells(
    List<XmlSpellResolution> resolutions,
  ) {
    return summarize([for (final entry in resolutions) entry.resolution]);
  }

  /// Nombre total de champs individuels réellement "à corriger" (état
  /// [XmlFieldResolution.unrecognized], jamais [XmlFieldResolution.custom])
  /// pour tout [resolved] — pilote à la fois le texte de statut de l'écran de
  /// vérification et le déclenchement du dialogue de confirmation "CHAMPS NON
  /// RÉSOLUS" avant sauvegarde (voir la consigne d'origine de la tâche :
  /// bouton "VALIDER LE PERSONNAGE" toujours actif, jamais grisé).
  ///
  /// Périmètre volontairement limité aux champs que cet écran affiche
  /// réellement (voir `presentation/xml_import_review_screen.dart`) : ni
  /// `styleCombat1`/`styleCombat2`/`favoredEnemy0`/`favoredEnemy6`/
  /// `favoredEnemy14`/`pack` (aucune table de correspondance fiable, aucune
  /// table `character_class_options`/`class_features` encore précédente dans
  /// ce dépôt, décision de périmètre signalée au chef de projet) ni
  /// `subclass`/`knownInvocations` (aucun catalogue réel encore câblé, voir
  /// `xml_character_import_resolver.dart` — l'assistant de création manuel
  /// lui-même ne propose encore aucun choix de sous-classe/invocation)
  /// n'entrent dans ce total.
  static int countUnresolved(XmlCharacterImportResolved resolved) {
    var count = 0;

    if (resolved.race.isUnrecognized) count++;
    if (resolved.characterClass.isUnrecognized) count++;
    if (resolved.background.isUnrecognized) count++;
    if (resolved.armor.isUnrecognized) count++;
    if (resolved.shield.isUnrecognized) count++;
    if (resolved.alignment.isUnrecognized) count++;
    if (resolved.sexe.isUnrecognized) count++;

    count += summarizeGrouped(resolved.skillProficiencies)
        .unrecognizedRawValues
        .length;
    count += summarizeGrouped(resolved.toolProficiencies)
        .unrecognizedRawValues
        .length;
    count += summarizeGrouped(resolved.languages).unrecognizedRawValues.length;
    count += summarizeSpells(resolved.innateSpells)
        .unrecognizedRawValues
        .length;
    count += summarizeSpells(resolved.knownSpells).unrecognizedRawValues.length;
    count += summarizeQuantified(resolved.weapons).unrecognizedRawValues.length;
    count += summarizeQuantified(resolved.toolEquipment)
        .unrecognizedRawValues
        .length;
    count += summarizeQuantified(resolved.items).unrecognizedRawValues.length;

    return count;
  }
}
