# Rétro-ingénierie des identifiants numériques — import XML aidedd.org

Ce document consolide le travail de rétro-ingénierie demandé par
`docs/cahier-des-charges/03-import-xml-aidedd.md` (section « Point d'attention
majeur : les identifiants numériques »). Il fournit la table de correspondance
`xml_import_reference_mapping` prête à implémenter.

## Méthodologie

1. Deux exports XML réels fournis par l'utilisateur (personnages joués, pas
   des exemples synthétiques) : [`test/fixtures/xml_import/solan-valerius.xml`](../test/fixtures/xml_import/solan-valerius.xml)
   (Aasimar Paladin niv. 2, historique Héros du peuple) et
   [`test/fixtures/xml_import/pip.xml`](../test/fixtures/xml_import/pip.xml)
   (Conil Barde niv. 2, historique Grand voyageur).
2. **Source de vérité principale** : le code HTML généré côté serveur par
   l'outil aidedd.org lui-même (`https://www.aidedd.org/dnd-builder/`), en
   inspectant directement les `<option value="N">Libellé</option>` des
   `<select>` retournés par ses endpoints AJAX (`ajax_main.php`) — donc les
   vrais identifiants utilisés par l'outil, pas une supposition d'ordre
   alphabétique.
3. **Validation croisée** : chaque table a été vérifiée en reconstituant un
   personnage équivalent (même race/classe/historique) dans l'outil aidedd et
   en comparant les ID obtenus aux valeurs des deux fichiers réels — avec un
   succès de correspondance total (équipement de départ, compétences,
   alignement, sexe).
4. Pour l'alignement en particulier, la table confirme et résout une
   contradiction restée ouverte lors d'une première tentative de déduction
   narrative seule : l'ordre n'est pas [LG,NG,CG,LN,N,CN,LE,NE,CE] mais une
   grille 3×3 [Loyal/Neutre/Chaotique] × [bon/neutre/mauvais].

## Tables confirmées (ground truth, à charger telles quelles)

### Compétences (`skillsProf`)

18 valeurs, ordre alphabétique français — confirmé par le HTML serveur ET par
recoupement narratif (le texte de Pip nomme littéralement ses compétences
choisies entre parenthèses, qui correspondent exactement aux ID envoyés).

| id | Compétence | id | Compétence |
|----|------------|----|------------|
| 0 | Acrobaties | 9 | Investigation |
| 1 | Arcanes | 10 | Médecine |
| 2 | Athlétisme | 11 | Nature |
| 3 | Discrétion | 12 | Perception |
| 4 | Dressage | 13 | Persuasion |
| 5 | Escamotage | 14 | Religion |
| 6 | Histoire | 15 | Représentation |
| 7 | Intimidation | 16 | Survie |
| 8 | Intuition | 17 | Tromperie |

Les 4 index de `skillsProf id="0..3"` (et de même pour `toolsProf`,
`languages`) correspondent à la **source** du choix, confirmé par les libellés
HTML (`<h3>Compétences de la classe</h3>` pour id=1, `<h3>Compétences de
l'historique</h3>` pour id=2, `<h3>Langues de la race</h3>` pour id=0) :

| id | Source |
|----|--------|
| 0 | Race |
| 1 | Classe |
| 2 | Historique (background) |
| 3 | Autres (dons, choix optionnels) |

### Armures (`armor`)

0 = sans armure. 13 valeurs au total.

| id | Armure | id | Armure |
|----|--------|----|--------|
| 0 | Sans armure | 7 | Cuirasse |
| 1 | Armure matelassée | 8 | Demi-plate |
| 2 | Armure de cuir | 9 | Broigne |
| 3 | Armure de cuir clouté | 10 | Cotte de mailles |
| 4 | Armure de peaux | 11 | Clibanion |
| 5 | Chemise de mailles | 12 | Harnois |
| 6 | Armure d'écailles | | |

Validé : Solan `armor=10` (Cotte de mailles, cohérent avec pack Paladin),
Pip `armor=2` (Cuir, cohérent avec pack Barde).

### Bouclier (`shield`)

| id | Valeur |
|----|--------|
| 0 | Sans bouclier |
| 1 | Bouclier |

### Armes (`weapon`, positionnel avec `weaponQ`)

0 = emplacement vide, 1 = « Mains nues ». 39 valeurs au total.

| id | Arme | id | Arme | id | Arme |
|----|------|----|------|----|------|
| 0 | *(vide)* | 14 | Fléchette | 27 | Maillet |
| 1 | Mains nues | 15 | Fronde | 28 | Marteau de guerre |
| 2 | Bâton | 16 | Cimeterre | 29 | Morgenstern |
| 3 | Dague | 17 | Coutille | 30 | Pic de guerre |
| 4 | Gourdin | 18 | Épée à deux mains | 31 | Pique |
| 5 | Hachette | 19 | Épée courte | 32 | Rapière |
| 6 | Javeline | 20 | Épée longue | 33 | Trident |
| 7 | Lance | 21 | Fléau d'armes | 34 | Arbalète de poing |
| 8 | Marteau léger | 22 | Fouet | 35 | Arbalète lourde |
| 9 | Masse d'armes | 23 | Hache à deux mains | 36 | Arc long |
| 10 | Massue | 24 | Hache d'armes | 37 | Filet |
| 11 | Serpe | 25 | Hallebarde | 38 | Sarbacane |
| 12 | Arbalète légère | 26 | Lance d'arçon | | |
| 13 | Arc court | | | | |

*(id=1 « Mains nues » n'apparaît jamais dans le `<select>` de l'outil — il
existe dans la table de référence interne d'aidedd mais n'est pas un choix
achetable ; à conserver dans la table de correspondance par exhaustivité,
sans t'attendre à le rencontrer dans un export réel.)*

Validé de façon irréfutable en recoupant avec le contenu texte des packs de
départ (array `PACK`, cf. section suivante) : Solan `weapon="20,6"`
`weaponQ="1,5"` = 1 Épée longue + 5 Javelines, qui est **exactement** le
contenu du « Pack (a) de paladin » (`pack=16` : Cotte de mailles, Bouclier,
1 arme de guerre, 5 javelines, Symbole sacré, Sac d'ecclésiastique). Pip
`weapon="32,3"` `weaponQ="1,1"` = 1 Rapière + 1 Dague, qui est **exactement**
le contenu du « Pack (a) de barde » (`pack=2` : Armure de cuir, Rapière,
Dague, Luth, Sac de diplomate). Table extraite directement des attributs
`value=` du `<select>` généré par le serveur (`ajax_main.php`), aucune
déduction manuelle.

### Outils / instruments (`tools` — objets physiques possédés, *différent* de `toolsProf`)

0 = emplacement vide. 39 valeurs. **Important** : ce champ code des objets
d'équipement achetés (positionnel, comme `weapon`/`weaponQ`), pas les
maîtrises d'outils du personnage (qui sont dans `toolsProf`, déjà en clair).
Validé sur Pip : `tools="12,10"` = Luth + Flûte, qui correspondent
mot pour mot à sa description physique (« son luth est solidement attaché
dans son dos [...] plusieurs flûtes [...] dépassent de sa sacoche »).

| id | Outil | id | Outil | id | Outil |
|----|-------|----|-------|----|-------|
| 0 | *(vide)* | 14 | Tambour | 28 | Outils de charpentier |
| 1 | Kit d'empoisonneur | 15 | Tympanon | 29 | Outils de cordonnier |
| 2 | Kit d'herboriste | 16 | Viole | 30 | Outils de forgeron |
| 3 | Kit de contrefaçon | 17 | Dés | 31 | Outils de maçon |
| 4 | Kit de déguisement | 18 | Jeu d'échecs draconiques | 32 | Outils de menuisier |
| 5 | Outils de navigateur | 19 | Jeu de cartes | 33 | Outils de potier |
| 6 | Outils de voleur | 20 | Jeu des Dragons | 34 | Outils de souffleur de verre |
| 7 | Chalemie | 21 | Matériel d'alchimiste | 35 | Outils de tanneur |
| 8 | Cor | 22 | Matériel de brasseur | 36 | Outils de tisserand |
| 9 | Cornemuse | 23 | Matériel de calligraphe | 37 | Ustensiles de cuisinier |
| 10 | Flûte | 24 | Matériel de peintre | 38 | Véhicules (terrestres) |
| 11 | Flûte de pan | 25 | Outils de bijoutier | 39 | Véhicules (aquatiques) |
| 12 | Luth | 26 | Outils de bricoleur | | |
| 13 | Lyre | 27 | Outils de cartographe | | |

### Objets d'équipement (`item`, positionnel avec `itemQ`, `itemX` pour le texte libre complémentaire)

0 = emplacement vide. **Catalogue non séquentiel** (confirme qu'il s'agit
bien d'une vraie table de référence interne à figer, pas d'un ordre
devinable) — 98 objets, IDs de 1 à 99 avec quelques trous.

| id | Objet | id | Objet | id | Objet |
|----|-------|----|-------|----|-------|
| 1 | Acide/fiole | 34 | Focaliseur druidique/baguette d'if | 67 | Piège à mâchoires |
| 2 | Antidote/fiole | 35 | Focaliseur druidique/bâton | 68 | Pierre à aiguiser |
| 3 | Bélier portable | 36 | Focaliseur druidique/branche de gui | 69 | Pioche de mineur |
| 4 | Billes/1000 | 37 | Focaliseur druidique/totem | 70 | Piton |
| 5 | Boite d'allume-feu | 38 | Gamelle | 71 | Plume d'écriture |
| 6 | Bougie | 39 | Gourde | 72 | Pointes en fer/10 |
| 7 | Boulier | 40 | Grappin | 73 | Poison/fiole |
| 8 | Sacoche | 41 | Grimoire | 74 | Pot en fer |
| 9 | Cadenas | 42 | Huile/flasque | 75 | Potion de guérison |
| 10 | Carquois | 43 | Lampe | 76 | Rations/1 jour |
| 11 | Chaîne de 3 m | 44 | Lanterne sourde | 77 | Robes |
| 12 | Chevalière | 45 | Lanterne à capote | 78 | Sablier |
| 13 | Chausse-trappes/20 | 46 | Livre | 79 | Sac |
| 14 | Cire à cacheter | 47 | Longue-vue | 80 | Sac à dos |
| 15 | Cloche | 48 | Loupe | 81 | Sac de couchage |
| 16 | Coffre | 49 | Marteau | 82 | Sacoche à composantes |
| 17 | Corde en chanvre de 15 m | 50 | Marteau de forgeron | 83 | Savon |
| 18 | Corde en soie de 15 m | 51 | Kit d'escalade | 84 | Seau |
| 19 | Couverture | 52 | Balance de marchand | 85 | Sifflet |
| 20 | Craie | 53 | Matériel de pêche | 86 | Symbole sacré/amulette |
| 21 | Eau bénite/flasque | 54 | Menottes | 87 | Symbole sacré/emblème |
| 22 | Échelle de 3 m | 55 | 20 billes de fronde | 88 | Symbole sacré/reliquaire |
| 23 | Encre/bouteille | 56 | 20 carreaux | 89 | Tente |
| 24 | Étui à carreaux | 57 | 20 flèches | 90 | Torche |
| 25 | Étui à cartes ou parchemins | 58 | 50 aiguilles de sarbacane | 91 | Trousse de soins |
| 26 | Feu grégeois/flasque | 59 | Palan | 92 | Vêtements communs |
| 27 | Fiole | 60 | Papier | 93 | Vêtements/costume |
| 28 | Flasque | 61 | Parchemin | 94 | Vêtements fins |
| 29 | Focaliseur arcanique/baguette | 62 | Parfum/fiole | 95 | Vêtements de voyage |
| 30 | Focaliseur arcanique/bâton | 63 | Pelle | 96 | Tonneau |
| 31 | Focaliseur arcanique/boule de cristal | 64 | Perche de 3 m | 97 | Panier |
| 32 | Focaliseur arcanique/orbe | 65 | Miroir en acier | 98 | Cruche |
| 33 | Focaliseur arcanique/sceptre | 66 | Pied-de-biche | 99 | Bouteille |

### Packs de départ (`pack`)

26 valeurs (2 par classe : a/b), confirmées par l'array `PACK` serveur.

| id | Pack | id | Pack |
|----|------|----|------|
| 0 | Pack (a) de barbare | 13 | Pack (b) de magicien |
| 1 | Pack (b) de barbare | 14 | Pack (a) de moine |
| 2 | Pack (a) de barde | 15 | Pack (b) de moine |
| 3 | Pack (b) de barde | 16 | Pack (a) de paladin |
| 4 | Pack (a) de clerc | 17 | Pack (b) de paladin |
| 5 | Pack (b) de clerc | 18 | Pack (a) de rôdeur |
| 6 | Pack (a) de druide | 19 | Pack (b) de rôdeur |
| 7 | Pack (b) de druide | 20 | Pack (a) de roublard |
| 8 | Pack (a) d'ensorceleur | 21 | Pack (b) de roublard |
| 9 | Pack (b) d'ensorceleur | 22 | Pack (a) d'occultiste |
| 10 | Pack (a) de guerrier | 23 | Pack (b) d'occultiste |
| 11 | Pack (b) de guerrier | 24 | Pack (a) d'artificier |
| 12 | Pack (a) de magicien | 25 | Pack (b) d'artificier |

Le contenu texte de chaque pack (pour affichage) est également disponible
dans l'array `PACK` — à dupliquer dans les données de référence internes de
l'app plutôt que d'être recalculé depuis ce champ.

### Alignement (`alignment`)

9 valeurs, grille 3×3. **Confirmé et corrige une hypothèse d'ordre erronée
posée lors d'une première tentative de déduction narrative seule** :

| id | Alignement | id | Alignement |
|----|------------|----|------------|
| 0 | Loyal bon | 5 | Neutre mauvais |
| 1 | Loyal neutre | 6 | Chaotique bon |
| 2 | Loyal mauvais | 7 | Chaotique neutre |
| 3 | Neutre bon | 8 | Chaotique mauvais |
| 4 | Neutre | | |

Validé parfaitement : Solan `alignment=0` = Loyal bon (son idéal : « La loi
doit être au service des gens ») ; Pip `alignment=6` = Chaotique bon (son
idéal : « Le mouvement, c'est la vie »).

### Sexe (`sexe`)

| id | Valeur |
|----|--------|
| 0 | Homme |
| 1 | Femme |
| 2 | Non binaire |

### Langues (`languages`)

**Pas d'ID numérique** — champ texte libre en clair dans le XML (confirmé sur
les deux fichiers réels), malgré la structure `id="0..3"` qui ne code que la
*source* du choix (race/classe/historique/autres, cf. section Compétences).
Aucune table de correspondance nécessaire pour ce champ.

## Champs non numériques confirmés (aucune correspondance nécessaire)

`race`, `class`, `background`, spells (`innateSpell`/`knownSpell`/
`knownInvocation`), `languages`.

## ⚠️ Correction : `styleCombat1/2` et `favoredEnemyN` sont NUMÉRIQUES, pas texte

Erreur dans une version précédente de ce document (trouvée par `qa-testeur`
lors de la revue de l'increment 1 d'implémentation) : `styleCombat1`/
`styleCombat2`/`favoredEnemy0`/`favoredEnemy6`/`favoredEnemy14` avaient été
classés à tort comme texte libre. La fixture réelle `solan-valerius.xml`
contient `<styleCombat1>11</styleCombat1>` — une valeur numérique (Solan,
Paladin niveau 2, obtient bien un style de combat à ce niveau en 5e).

**Table de correspondance non reconstituée.** Le sélecteur de style de
combat n'apparaît nulle part dans le parcours anonyme de l'outil aidedd.org :
à l'étape "Capacités de classe", le style de combat n'est listé qu'en texte
informatif (confirmé par la réponse serveur brute de `ajax_main.php` pour
cette étape, aucun `<select>`/`<input>` de choix rendu) — cette sélection est
une fonctionnalité verrouillée derrière un compte payant aidedd.org,
inaccessible en session anonyme. Idem très probablement pour
`favoredEnemyN` (ennemi juré du Rôdeur), non vérifié faute de personnage
Rôdeur dans les échantillons.

**Traitement recommandé pour l'implémentation** : tant que la vraie table
n'est pas reconstituée (nécessiterait un compte aidedd.org premium, ou un
futur export XML d'un personnage Guerrier/Rôdeur de niveau adéquat couplé à
un accès identifié à l'outil), traiter ces champs comme systématiquement
`unrecognized(idBrut)` dès qu'ils sont non vides — jamais deviner un ordre
(ex. alphabétique sur les noms de styles de combat de la liste PHB) sans
confirmation, le risque de résolution silencieusement fausse étant pire
qu'un champ correctement flagué "à corriger manuellement". Le champ doit
rester visible et corrigeable manuellement dans l'écran de vérification,
exactement comme un ID d'objet/arme non reconnu.

## Point encore ouvert : `raceCustom`

Solan a `<raceCustom>1</raceCustom>` bien que « Aasimar » soit une race
officielle (non custom). Hypothèse la plus probable après ce travail : ce
flag ne signale pas « race personnalisée par rapport au nom » mais plutôt
« variante/sous-race sélectionnée manuellement en dehors du sous-menu standard »
(l'Aasimar a plusieurs lignées – Protecteur/Flagellant/Déchu – qui pourraient
forcer ce mode). **Non vérifié empiriquement** (nécessiterait de sélectionner
Aasimar dans l'outil, indisponible en session anonyme — fonctionnalité
premium sur aidedd.org). À traiter comme un champ informatif à ignorer sans
risque pour l'import (`race` reste le champ de résolution par nom, fiable) ;
ne pas bloquer l'import dessus.

## Points non vérifiables en session anonyme (mineurs, non bloquants)

- ⚠️ **`aug_caracN` (ASI) — correction, signalée par `qa-testeur` lors de la
  revue de l'increment 2** : l'affirmation précédente de ce document (« aucune
  donnée positive dans les 2 échantillons ») était fausse. La fixture réelle
  `solan-valerius.xml` contient bien des valeurs positives DÈS le niveau 1 :
  `<lvl lvl="1"><aug_carac0>5</aug_carac0><aug_carac1>-1</aug_carac1><aug_carac2>5</aug_carac2></lvl>`
  (Force et Constitution à `5`, Dextérité à `-1`). **Mais cette donnée
  contredit l'hypothèse initiale** : un delta d'ASI D&D 5e vaut normalement
  +1 ou +2, jamais `5`, et un personnage n'a normalement pas de palier ASI au
  niveau 1. L'hypothèse « -1 = pas d'augmentation, valeur ≥ 0 = delta à
  appliquer » doit donc être considérée **non confirmée, probablement fausse**
  plutôt que simplement "non vérifiée". Deux pistes non tranchées : (a) ces
  champs pourraient encoder autre chose que l'ASI classique (allocation de
  points lors de la répartition initiale des caractéristiques, effet d'un don
  type « Compétent », etc.), (b) l'indexation `aug_carac0/1/2` pourrait ne
  pas correspondre 1:1 aux 6 caractéristiques (seulement 3 index observés,
  0/1/2, jamais 3/4/5 — à vérifier si un futur export en révèle). **Ne pas
  construire de logique de persistance sur cette hypothèse tant qu'elle n'est
  pas revérifiée via l'outil aidedd.org lui-même** (répartition de points en
  session anonyme, à recouper avec les valeurs finales de caractéristiques) —
  en attendant, traiter ce champ comme non interprété automatiquement plutôt
  que de deviner un mapping qui pourrait fausser silencieusement les
  caractéristiques d'un personnage importé.

## Recommandation d'implémentation

Cette table de correspondance est **une donnée de référence figée, propre à
l'app mobile** (spécifique au format d'export d'un outil tiers) — elle ne
concerne pas le modèle de données partagé avec l'app web et n'a pas besoin de
vivre en base Supabase. Recommandation : l'implémenter comme des constantes
Dart statiques (ex. `lib/features/xml_import/data/aidedd_reference_tables.dart`),
chargées en mémoire, plutôt que comme une table Supabase — pas de migration
côté dépôt web nécessaire pour cette fonctionnalité.
