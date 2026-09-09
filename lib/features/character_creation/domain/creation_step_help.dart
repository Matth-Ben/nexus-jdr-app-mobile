/// Contenu d'une aide contextuelle d'étape de l'assistant de création —
/// voir `presentation/widgets/step_help_sheet.dart`.
class StepHelpContent {
  const StepHelpContent({required this.title, required this.body});

  /// Titre affiché en tête de la sheet, ex. "1. Race" — même chaîne que le
  /// titre d'étape déjà affiché dans le bandeau bois (`_Header` de chaque
  /// écran d'étape), pour que l'aide ne renomme jamais l'étape sous un autre
  /// intitulé.
  final String title;

  /// Explication courte, pour un joueur débutant, du concept de règle D&D 5e
  /// couvert par cette étape — jamais un mode d'emploi de l'écran lui-même
  /// (ce que faire), seulement le sens du choix demandé.
  final String body;
}

/// Contenu des 9 aides contextuelles de l'assistant de création — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Création de personnage (assistant pas-à-pas)" : "Aide contextuelle à
/// chaque étape (tooltip explicatif pour un joueur débutant)".
///
/// Un champ par étape plutôt qu'une `Map<int, StepHelpContent>` indexée par
/// numéro d'étape : chaque écran d'étape connaît déjà statiquement son
/// contenu (pas de logique de sélection dynamique à porter ici), et un champ
/// nommé se détecte à la compilation si un écran est modifié sans que son
/// aide ne le soit — une entrée de map absente ne se remarquerait qu'à
/// l'exécution.
abstract final class CreationStepHelp {
  static const race = StepHelpContent(
    title: '1. Race',
    body:
        "La race de ton personnage détermine son ascendance (elfe, nain, "
        'humain…) et lui donne des traits particuliers : bonus de '
        'caractéristiques, capacités spéciales, vitesse de déplacement… '
        'Certaines races ont des sous-races (ex. Elfe des bois, Elfe noir) '
        'qui affinent encore ces traits. Tu pourras toujours revenir en '
        'arrière si tu changes d\'avis.',
  );

  static const classStep = StepHelpContent(
    title: '2. Classe',
    body:
        'La classe définit le rôle de combat et les capacités de ton '
        'personnage : guerrier robuste au corps-à-corps, magicien maniant '
        'les sorts, roublard discret et habile… Elle détermine tes points '
        'de vie, tes compétences de départ, ton équipement et, pour '
        'certaines classes, les sorts que tu pourras lancer.',
  );

  static const background = StepHelpContent(
    title: '3. Historique',
    body:
        "L'historique raconte ce que faisait ton personnage avant de "
        'devenir aventurier (soldat, érudit, criminel…). Il apporte des '
        'compétences et des outils supplémentaires, ainsi qu\'un trait de '
        'personnalité qui peut enrichir son histoire.',
  );

  static const abilityScore = StepHelpContent(
    title: '4. Caractéristiques',
    body:
        'Les 6 caractéristiques (Force, Dextérité, Constitution, '
        'Intelligence, Sagesse, Charisme) mesurent les aptitudes physiques '
        'et mentales de ton personnage. Elles influencent presque tout : '
        'dégâts au combat, points de vie, résistance aux sorts, '
        'discrétion… Plus un score est élevé, plus le modificateur '
        'associé (le bonus réellement appliqué aux jets de dés) est '
        'important.',
  );

  static const skillsAndTools = StepHelpContent(
    title: '5. Compétences',
    body:
        'Les compétences représentent ce que ton personnage sait '
        'particulièrement bien faire (Discrétion, Persuasion, Arcanes…). '
        'Être maître dans une compétence ajoute ton bonus de maîtrise à '
        'tes jets — ta classe et ton historique t\'en proposent chacun un '
        'certain nombre à choisir.',
  );

  static const spells = StepHelpContent(
    title: '6. Sorts',
    body:
        'Si ta classe lance des sorts, cette étape te permet de choisir '
        'tes sorts mineurs (utilisables à volonté, sans limite) et tes '
        'premiers sorts de niveau 1 (limités par le nombre d\'emplacements '
        'de sorts disponibles chaque jour).',
  );

  static const equipment = StepHelpContent(
    title: '7. Équipement',
    body:
        "Choisis l'équipement de départ de ton personnage : soit le "
        'paquetage standard proposé par ta classe et ton historique, soit '
        "un achat libre avec l'or de départ. Cet équipement inclut armes, "
        'armure et matériel d\'aventurier.',
  );

  static const appearanceAndBackstory = StepHelpContent(
    title: '8. Apparence, histoire et portrait',
    body:
        "Ces champs sont facultatifs : ils t'aident à donner vie à ton "
        'personnage (apparence physique, traits de personnalité, idéaux, '
        'liens, défauts, histoire personnelle…). Tu pourras toujours les '
        'modifier plus tard depuis la fiche du personnage.',
  );

  static const summary = StepHelpContent(
    title: '9. Récapitulatif',
    body:
        "Vérifie l'ensemble des choix faits aux étapes précédentes avant "
        'de créer définitivement ton personnage. Tu peux encore revenir '
        "sur n'importe quelle étape en la sélectionnant ci-dessous.",
  );
}
