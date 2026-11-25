# Spec : pastille de dégâts des sorts (décisions 85, 86, 88, 89)

Rédigée le 25/11/2026 par le chef de projet d'après la vérification de `regles-dnd` (196 pastilles relues une à une sur
les textes de production après la PR DeepCore #63). Ticket : « Nexus : pastille de dégâts des sorts, liste d'exceptions
(dégâts infligés seulement) ».

## Règle (décision 86)

La pastille (`DiceTypeBadge`) montre **le dé de dégâts infligé à la cible au niveau d'emplacement minimal** (option
d'attaque principale). Rien pour un bonus, une réserve de points de vie, des points de vie temporaires, un soin, une durée,
un nombre, un pourcentage, des dégâts subis par le lanceur, accidentels ou conditionnels secondaires. Sort à deux dés de
dégâts : le premier (Colonne de flamme, Tempête de grêle…), inchangé. Décision 89 : pas de pastille pour un sort utilitaire
dont l'option offensive est secondaire.

## Comportement actuel

`SpellDamageDiceExtractor.extract(description)` (`lib/features/characters/domain/spell_damage_dice_extractor.dart`) prend
le premier `NdM` de la description française. Utilisé par `character_spells_section.dart:418` et
`prepare_spells_sheet.dart:563` : **les deux** doivent appliquer la même correction.

## Exceptions, par nom français (tels qu'en production au 25/11/2026)

Les sorts sont reconnus par leur nom français, comme partout dans Nexus. Comparaison exacte (casse et accents compris,
après `trim`). Tout sort absent de la table garde le comportement actuel.

### Aucune pastille (30)

| Nom | Pastille actuelle | Motif |
|---|---|---|
| Agrandissement/Rapetissement | 1d4 | bonus aux dégâts des armes de la cible (décision 86) |
| Amélioration de caractéristique | 2d6 | PV temporaires |
| Animation d'objets | 1d4 | dés des objets animés |
| Arrêt du temps | 1d4 | durée |
| Aura de vitalité | 2d6 | soin |
| Bond cinétique | 1d8 | dégâts subis par le lanceur |
| Contact avec un autre plan | 6d6 | dégâts subis par le lanceur |
| Contrôle de l'eau | 2d8 | option offensive secondaire (décision 89) |
| Contrôle du climat | 1d4 | durée |
| Couleurs dansantes | 6d10 | réserve de PV |
| Espièglerie de Nathair | 1d4 | table d'effets, aucun dégât |
| Esprit guérisseur | 1d6 | soin |
| Fausse vie (et « Simulacre de vie », même sort, dette D261) | 1d4 | PV temporaires |
| Festin des héros | 2d10 | PV maximum |
| Fusion dans la pierre | 6d6 | dégâts subis par le lanceur |
| Modification d'apparence | 1d6 | option offensive secondaire (décision 89) |
| Mot de guérison | 1d4 | soin |
| Mot de guérison de groupe | 1d4 | soin |
| Porte dimensionnelle | 4d6 | dégâts subis par le lanceur |
| Prière de guérison | 2d8 | soin |
| Quête | 5d10 | sanction en cas de désobéissance (décision 89) |
| Régénération | 4d8 | soin |
| Soins | 1d8 | soin |
| Soins de groupe | 3d8 | soin |
| Sommeil | 5d8 | réserve de PV |
| Songe | 3d6 | option offensive secondaire (décision 89) |
| Souhait | 1d10 | dégâts subis par le lanceur |
| Téléportation | 1d10 | pourcentage d'écart |
| Toile d'araignée | 2d4 | dégâts accidentels |
| Transfert de vie | 4d8 | dégâts subis par le lanceur |

### Remplacer (2)

| Nom | Actuelle | Afficher |
|---|---|---|
| Main de Bigby | 2d6 | 4d8 (poing serré) |
| Tremblement de terre | 1d6 | 5d6 (effondrement) |

### Ajouter (7, décision 88)

Texte sans motif `NdM` (résumé ou « d8 » seul) :

| Nom | Afficher |
|---|---|
| Dragon illusoire | 7d6 |
| Force fantasmagorique | 1d6 |
| Fouet d'épines | 1d6 |
| Fureur de la nature | 4d6 |
| Gardien de la nature | 1d6 |
| Murmures dissonants | 3d6 |
| Trique noueuse | 1d8 |

## Notes d'implémentation

- La table vit côté domaine (à côté de l'extracteur), documentée avec la source (cette spec, décisions 85-89) ; l'extracteur
  prend le nom en plus de la description (ou une couche au-dessus applique la table) : à choisir par `dev-flutter`, sans
  dupliquer la logique entre les deux écrans.
- Tests unitaires : chaque entrée de la table (30 + alias + 2 + 7), un sort non listé (comportement inchangé), noms avec
  espaces en trop.
- Aucun changement de DeepCore : correction 100 % Nexus, visible dans la prochaine version publiée.
