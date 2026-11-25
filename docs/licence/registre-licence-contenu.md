# Registre de licence du contenu de jeu de DeepCore

Ticket Project #7 : « DeepCore : audit de licence de tout le contenu de jeu », lancé par Matthias le 25/11/2026.
Audit en **lecture seule** : aucune migration, aucune écriture en base (même locale), aucune branche, aucune PR, aucun
accès à la production. Ce registre ne tranche **aucune question juridique ni produit** : il classe, mesure et recommande.
Toute recommandation marquée « à valider par un conseil » doit l'être avant décision.

- Base auditée : pile Supabase locale de DeepCore (`H:/Projets/Labo/markdown-editor`, branche `fix/items-2014-srd51-texts`,
  185 migrations appliquées jusqu'à `20261124091700_items_2014_srd51_descriptions.sql`, PR #60 comprise).
- Textes de référence : SRD 5.1 anglais et français, SRD 5.2.1 anglais et français (PDF officiels de Wizards of the Coast,
  copies texte dans `scratchpad/deepcore-tmp-e8c/`).
- Requêtes d'usage : `requetes-usage.sql` (même dossier), à lancer par le chef de projet en production.
- Déjà réglé, hors du présent audit : objets 2014 (PR #60, texte du SRD 5.1) et monstres (SRD 5.1 et 5.2, PR #58 et #59).
  Ils figurent dans les totaux pour mémoire.

## 0. Synthèse

### 0.1 Totaux par type et par classification

| Type | Total | SRD 5.1 | SRD 5.2 | SRD mais texte non conforme | hors SRD |
|---|---:|---:|---:|---:|---:|
| Races | 36 | 0 | 0 | 10 | 26 |
| Sous-races | 18 | 0 | 0 | 7 | 11 |
| Lignées (race_lineages) | 43 | 0 | 0 | 34 | 9 |
| Classes | 13 | 0 | 0 | 12 | 1 |
| Aptitudes de classe | 228 | 3 | 0 | 208 | 17 |
| Sous-classes | 121 | 0 | 0 | 12 | 109 |
| Aptitudes de sous-classe | 802 | 14 | 0 | 91 | 697 |
| Options de classe (styles, métamagie, pactes, manœuvres...) | 97 | 0 | 0 | 21 | 76 |
| Dons | 116 | 1 | 8 | 4 | 103 |
| Invocations d'occultiste | 54 | 32 | 0 | 5 | 17 |
| Historiques | 71 | 0 | 0 | 4 | 67 |
| Sorts | 514 | 0 | 6 | 334 | 174 |
| Objets | 454 | 95 | 353 | 0 | 6 |
| **Total** | **2567** | **145** | **367** | **742** | **1313** |

Sans les objets (déjà réglés) : 2113 éléments, dont 1307 « hors SRD », 742 « SRD mais texte non conforme » et 64 conformes.

Lecture rapide :

- **Conformes** (texte issu du SRD) : les objets (SRD 5.1 et 5.2), les 32 invocations du Manuel des Joueurs (traduction
  non officielle du SRD 5.1), 9 dons (Empoignade, 7 faveurs épiques et l'Amélioration de caractéristique du SRD 5.2),
  6 sorts 2024, et 17 aptitudes dont le texte reprend presque mot pour mot le SRD français officiel.
- **SRD mais texte non conforme** : presque tout le socle « Manuel des Joueurs » qui est aussi dans le SRD (9 races, 12
  classes et leurs aptitudes, les 12 sous-classes SRD, 319 sorts...) porte un texte **qui ne vient pas du SRD** :
  reformulation maison, résumé repris d'aidedd.org, ou texte 2014 d'un élément dont seule la version 2024 est au SRD 5.2.
- **Hors SRD** : 26 races (dont le Goliath 2014 et l'Aasimar 2024) et 11 sous-races, 109 sous-classes et leurs 697 aptitudes, 103 dons, 67
  historiques, 76 options de classe, 17 invocations, 174 sorts.

### 0.2 Volume de texte concerné (caractères, descriptions françaises sauf mention)

| Type | SRD mais texte non conforme | hors SRD |
|---|---:|---:|
| Traits de race et de sous-race (jsonb `traits`) | 6 894 (10 races, 7 sous-races) | 21 886 (26 races, 11 sous-races) |
| Lignées | 11 097 | 3 653 |
| Aptitudes de classe | 86 763 | 3 168 |
| Aptitudes de sous-classe | 22 483 | 125 573 |
| Options de classe | 2 871 | 12 346 |
| Dons | 959 | 41 251 |
| Invocations | 1 644 | 5 162 |
| Historiques | 859 | 19 337 |
| Sorts (FR) | 36 543 | 24 861 |
| Sorts (**EN, texte intégral des livres**) | 15 sorts 2014 homonymes du SRD 5.2 | **142 sorts, 99 668 car.** |

### 0.3 Les cinq risques principaux

1. **Textes anglais intégraux des livres, publics sans compte.** 142 sorts hors SRD (Xanathar 90, Manuel des Joueurs 31,
   Tasha 21...) et 15 sorts 2014 homonymes du SRD 5.2 portent en `translations` (locale `en`) le texte **mot pour mot**
   du livre, importé de `brouberol/dnd5e-card-generator`. Aucun client ne l'affiche (Nexus et la Bibliothèque lisent le
   français), mais la politique `Anonymous users can read library translations` le rend téléchargeable par n'importe qui
   avec la clé publique. C'est la seule copie intégrale de texte non libre identifiée (les autres textes n'ont pas pu être comparés aux livres).
2. **Résumés d'aidedd.org repris tels quels.** 420 descriptions françaises de sorts (265 sorts SRD 5.1, 14 homonymes
   SRD 5.2, 141 hors SRD) viennent de la table de filtres d'aidedd.org (miroir GitHub `dinde451/Tapouweb`). Ce sont des
   résumés rédigés par un tiers (ni Wizards, ni le projet) : droit d'auteur d'aidedd et, pour une extraction en bloc,
   droit sui generis du producteur de base de données. Le risque ne disparaît pas pour les sorts du SRD. **À valider par
   un conseil.**
3. **Volume de contenu hors SRD exposé publiquement.** 1 307 éléments hors SRD (≈ 257 000 caractères de texte
   français, traits compris) sont lus par Nexus, affichés sans connexion par la Bibliothèque web publique et lisibles par le rôle
   `anon`. Les en-têtes de migration les décrivent comme des « reformulations entièrement originales » des mécaniques ;
   savoir si cela suffit (mécaniques non protégeables, expression reformulée) est **une question pour un conseil**.
   Grimoire (payant) n'en affiche aujourd'hui que des **noms** (race, classe, sous-classe d'un personnage).
4. **Mentions de licence inexactes ou absentes.** Nexus affiche « Le contenu de règles [...] provient d'Open5e et du
   System Reference Document (SRD 5.1/5.2) [...] sous licence CC-BY 4.0 » : c'est faux pour la majorité du contenu
   (hors SRD, aidedd), et la formulation n'est pas la déclaration d'attribution exigée par Wizards (ni la ligne
   « Modifié » de CC BY 4.0). La Bibliothèque web n'a de mention que sur la page Créatures.
5. **Traçabilité de la source et dérive de schéma.** Les colonnes `source` sont trompeuses (319 sorts du SRD 5.1
   étiquetés « Manuel des Joueurs » ; sous-classes, historiques, invocations, sous-races, aptitudes sans colonne source),
   alors que Grimoire filtre déjà sur `source` (`isSrdSource`). La colonne `races.traits_2024` / `subraces.traits_2024`,
   lue par Nexus depuis le 24/10/2026, n'existe dans **aucune** migration de DeepCore : son contenu (en production
   seulement) n'a pas pu être audité (requête Q4 fournie).

### 0.4 Recommandation globale (à valider)

Traiter en trois temps, du moins coûteux au plus structurant :

1. **Tout de suite (effort S, aucun impact Nexus)** : retirer les 157 descriptions anglaises copiées des livres (142 hors
   SRD et 15 homonymes 2014), remplacer par le texte du SRD 5.2 anglais là où il existe ; corriger les mentions de
   Nexus et de la Bibliothèque (déclaration d'attribution exacte, ligne « Modifié », phrase honnête sur le contenu qui
   n'est pas issu du SRD) ; ajouter la migration manquante de `traits_2024` à l'historique de DeepCore après l'avoir
   auditée (Q4).
2. **Ensuite (effort M à L)** : pour tout élément présent au SRD, remplacer le texte par celui du SRD officiel français
   (5.1 pour la version 2014, 5.2.1 pour 2024), **sans renommer** les éléments (les noms servent de clés à Nexus et à
   l'import XML). Cela supprime aussi la dépendance aux résumés d'aidedd pour 265 sorts (279 si l'on adopte le texte 2024 des 14
   homonymes). Ajouter une colonne de licence
   (`srd_5_1`, `srd_5_2`, `hors_srd`) et corriger `source`.
3. **Sur avis d'un conseil** : pour le hors SRD, choisir entre « nom + résumé mécanique maison neutre » (proche de
   l'existant, sauf les 141 résumés d'aidedd à réécrire), « retiré de la lecture publique » (rôle `anon`, Bibliothèque),
   ou « masqué pour les nouveaux personnages ». Ne jamais **supprimer** une ligne utilisée : voir l'impact en 5.3.
   Garder Grimoire strictement SRD tant que la question n'est pas tranchée (c'est le cas aujourd'hui).

## 1. Méthode et limites

### 1.1 Appartenance au SRD

- **Sorts** : chaque description anglaise en base est rapprochée du bloc de sort le plus proche dans le SRD 5.1 anglais
  (319 blocs) et dans le SRD 5.2.1 anglais (339 blocs). 319 sorts en base correspondent un à un aux 319 sorts du SRD 5.1
  (recouvrement ≥ 0,60 sur le **même** sort, aucun doublon ; un faux positif écarté : Charme-monstre → Charm Person).
  Les 22 sorts du SRD 5.2 absents du SRD 5.1 ont été rapprochés par nom (français 5.2.1 et anglais) : 21 sont en base.
- **Autres types** : listes du SRD vérifiées dans les textes (12 sous-classes par SRD, un seul don au SRD 5.1, 32
  invocations au SRD 5.1, 28 invocations au SRD 5.2, 17 dons et 4 historiques au SRD 5.2, options de métamagie, de
  pacte et styles de combat des deux SRD), puis appariées aux noms en base.
- Un élément 2014 dont **seule la version 2024** est au SRD 5.2 (ex. don Alerte, sort Maléfice, historique Sage) est
  classé « SRD mais texte non conforme » : le nom est au SRD, mais le texte en base est celui de 2014, qui n'est pas libre.

### 1.2 Conformité du texte

- Mesure : part des 5-grammes de mots (texte normalisé) d'une description que l'on retrouve dans le SRD officiel
  français (5.1 ou 5.2.1, la meilleure des deux), colonne « Recouvr. » des tableaux. Repères observés :
  ≥ 0,60 texte repris quasi mot pour mot du SRD français officiel ; 0,30 à 0,60 phrases partagées (traduction proche ou
  formules de règles communes) ; < 0,30 reformulation ou autre source.
- La provenance déclarée dans les en-têtes de migration et dans les scripts (`scripts/import-spells.mjs`,
  `scripts/import-class-features-srd.mjs`, `scripts/generate-class-features-non-srd-migration.py`) complète la mesure.
- Une « traduction non officielle du SRD anglais » (invocations, dons du SRD 5.2, objets 2024, sorts 2024) est classée
  conforme : CC BY 4.0 autorise l'adaptation, à condition de citer la source et de signaler la modification.

### 1.3 Limites

- **Les livres non libres n'ont pas été comparés** (pas de copie disponible, et il n'y avait pas lieu d'en chercher) :
  pour le hors SRD, « reformulation d'après le livre » s'appuie sur les en-têtes de migration, la longueur et le style,
  pas sur une mesure. Seuls les textes anglais des sorts ont pu être identifiés comme copies intégrales (source connue).
- **Production non auditée directement** : 37 races en production contre 36 en local, 72 historiques contre 71
  (ébauches créées par l'import XML hors migration, cf. D58/D59), identifiants différents, et colonne `traits_2024`
  absente du local. Les requêtes Q3 et Q4 rattrapent ces écarts.
- Le recouvrement sous-estime la reprise d'une traduction officielle reformulée ; il ne mesure pas une paraphrase proche.

### 1.4 Provenance des textes (d'après les migrations et scripts)

| Contenu | Provenance déclarée | Tiers concernés |
|---|---|---|
| Sorts FR 1 à 57 | « traduction FR maison » (phase 1) | - |
| Sorts FR 58 à 477 | résumé de la table de filtres aidedd.org (miroir `dinde451/Tapouweb`) | aidedd.org |
| Sorts EN (482) | texte intégral de `brouberol/dnd5e-card-generator` | Wizards of the Coast (livres) |
| Listes de classes des sorts | `5etools-mirror-3/5etools-2014-src` | données factuelles |
| Sorts 478 à 483 | traduction du SRD 5.2 | Wizards (CC BY) |
| Sorts 484 à 515 | résumés maison (suppléments) | - |
| Races et sous-races 2014 | « reformulées, basées sur les règles ouvertes du SRD » | - |
| Sous-classes (91), historiques (15) | fichier local `CodexArcanum_V2.html` (origine non documentée) | inconnu |
| Aptitudes « SRD » (313) | fichier croisé aidedd / 5e-bits / Open5e, statut `srd_cc_by` | aidedd (FR ?) |
| Aptitudes hors SRD, dons, options, invocations hors SRD, historiques 16+ | « reformulation » rédigée par un agent | - |
| Invocations 1 à 32, Empoignade | « traduction fidèle » du SRD 5.1 anglais (via Open5e) | Wizards (CC BY) |
| Faveurs épiques SRD 5.2, objets 2024 | traduction du SRD 5.2 anglais | Wizards (CC BY) |

### 1.5 Exposition actuelle

| Surface | Ce qui est exposé | Mention de licence |
|---|---|---|
| API DeepCore, rôle `anon` (clé publique) | **tout** le référentiel et ses `translations` (FR et EN), sans compte | aucune |
| Bibliothèque web `nexus-jdr-library` (en ligne) | sorts, races, sous-races, lignées, classes, aptitudes, sous-classes, dons, invocations, historiques, options, objets, créatures, en français, sans connexion | page Créatures seulement |
| Nexus (gratuit) | tout le référentiel en français (création, fiche, montée de niveau, import XML) | écran Crédits, formulation inexacte (risque 4) |
| Grimoire (payant) | monstres et objets du SRD seulement (filtre `isSrdSource`), plus les **noms** de race, classe et sous-classe des personnages d'un groupe (`api_v1.group_snapshot`) | mentions SRD 5.1, 5.2, 5.2.1 exactes, avec « Modifié » |

## 2. Inventaire par type de contenu

Colonnes : **id** (pile locale, différent en production), **Élément**, **Nom EN** (en base, ou nom SRD rapproché pour
les sorts), **Source déclarée** (colonne `source` ou équivalent ; « (pas de colonne) » suivi de la source connue par la
migration), **Classification**, **Réf. SRD**, **Champs** concernés, **Nature du texte**, **Recouvr.** (recouvrement avec
le SRD français officiel).

Les **noms seuls** sont un sujet à part, moins risqué : ils sont signalés en 2.14 sans être comptés comme du texte.

### 2.1 Races (36)

Les traits (jsonb `traits`, liste nom + description) portent l'essentiel du texte ; la description de la race est
une phrase de flaveur maison. Les 9 races du Manuel des Joueurs 2014 sont au SRD 5.1, mais leurs traits sont reformulés
(moyenne de recouvrement 0,20) : quelques traits reprennent presque mot pour mot le SRD officiel (Ascendance féerique,
Brave, Ruse gnome, Résistance aux dégâts). Humain : un trait « Polyvalence » inventé remplace les traits du SRD.
Goliath : traits 2014 (Elemental Evil), hors SRD ; seule sa version 2024 (avec ascendance de géant) est au SRD 5.2, et
ses 6 lignées 2024 en base relèvent du SRD 5.2. Aasimar (Manuel des Joueurs 2024) n'est pas au SRD 5.2.
`traits_2024` : absent de la pile locale, voir 4.1.

Répartition : SRD mais texte non conforme 10, hors SRD 26.

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Humain |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (1) | reformulation maison ; 0 trait(s) sur 1 repris quasi mot pour mot du SRD FR officiel | 0.04 |
| 2 | Elfe |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (4) | reformulation maison ; 1 trait(s) sur 4 repris quasi mot pour mot du SRD FR officiel | 0.24 |
| 3 | Nain |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (5) | reformulation maison ; 0 trait(s) sur 5 repris quasi mot pour mot du SRD FR officiel | 0.22 |
| 4 | Halfelin |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (3) | reformulation maison ; 1 trait(s) sur 3 repris quasi mot pour mot du SRD FR officiel | 0.56 |
| 5 | Drakéide |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (3) | reformulation maison ; 1 trait(s) sur 3 repris quasi mot pour mot du SRD FR officiel | 0.35 |
| 6 | Gnome |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (2) | reformulation maison ; 1 trait(s) sur 2 repris quasi mot pour mot du SRD FR officiel | 0.40 |
| 7 | Demi-elfe |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (3) | reformulation maison ; 1 trait(s) sur 3 repris quasi mot pour mot du SRD FR officiel | 0.33 |
| 8 | Demi-orque |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (4) | reformulation maison ; 0 trait(s) sur 4 repris quasi mot pour mot du SRD FR officiel | 0.17 |
| 9 | Tieffelin |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (1 phrase), traits (3) | reformulation maison ; 0 trait(s) sur 3 repris quasi mot pour mot du SRD FR officiel | 0.14 |
| 10 | Aarakocra |  | Elemental Evil Player's Companion | hors SRD |  | nom, description (1 phrase), traits (2) | reformulation d'après le livre | 0.12 |
| 11 | Génasi |  | Elemental Evil Player's Companion | hors SRD |  | nom, description (1 phrase), traits (0) | aucun trait propre (portés par les sous-races et lignées) |  |
| 12 | Goliath |  | Elemental Evil Player's Companion | hors SRD |  | nom, description (1 phrase), traits (4) | traits 2014 (Elemental Evil / Volo), reformulés ; homonyme SRD 5.2 au contenu différent | 0.16 |
| 13 | Orc |  | Manuel des Joueurs (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, description (1 phrase), traits (4) | reformulation maison (texte 2024) | 0.11 |
| 14 | Aasimar | Aasimar | Manuel des Joueurs (2024) | hors SRD |  | nom, description (1 phrase), traits (6) | reformulation d'après le livre | 0.29 |
| 15 | Gobelours | Bugbear | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (8) | reformulation d'après le livre | 0.21 |
| 16 | Centaure | Centaur | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (6) | reformulation d'après le livre | 0.10 |
| 17 | Changelin | Changeling | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (4) | reformulation d'après le livre | 0.08 |
| 18 | Fée | Fairy | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (4) | reformulation d'après le livre | 0.20 |
| 19 | Firbolg | Firbolg | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (6) | reformulation d'après le livre | 0.14 |
| 20 | Githyanki | Githyanki | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (5) | reformulation d'après le livre | 0.27 |
| 21 | Githzerai | Githzerai | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (5) | reformulation d'après le livre | 0.40 |
| 22 | Gobelin | Goblin | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (6) | reformulation d'après le livre | 0.29 |
| 23 | Hobgobelin | Hobgoblin | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (6) | reformulation d'après le livre | 0.22 |
| 24 | Kenku | Kenku | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (5) | reformulation d'après le livre | 0.17 |
| 25 | Kobold | Kobold | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (5) | reformulation d'après le livre | 0.15 |
| 26 | Homme-lézard | Lizardfolk | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (8) | reformulation d'après le livre | 0.22 |
| 27 | Minotaure | Minotaur | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (6) | reformulation d'après le livre | 0.15 |
| 28 | Satyre | Satyr | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (6) | reformulation d'après le livre | 0.27 |
| 29 | Tabaxi | Tabaxi | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (7) | reformulation d'après le livre | 0.19 |
| 30 | Tortue | Tortle | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (7) | reformulation d'après le livre | 0.08 |
| 31 | Triton | Triton | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (7) | reformulation d'après le livre | 0.20 |
| 32 | Yuan-ti | Yuan-ti | Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (6) | reformulation d'après le livre | 0.33 |
| 33 | Owlin | Owlin | Strixhaven : un programme de chaos | hors SRD |  | nom, description (1 phrase), traits (5) | reformulation d'après le livre | 0.18 |
| 34 | Changeforme | Shifter | Eberron / Monstres du Multivers | hors SRD |  | nom, description (1 phrase), traits (5) | reformulation d'après le livre | 0.13 |
| 35 | Forgelier | Warforged | Eberron : l'ascension après la Dernière Guerre | hors SRD |  | nom, description (1 phrase), traits (5) | reformulation d'après le livre | 0.11 |
| 36 | Kalashtar | Kalashtar | Eberron : l'ascension après la Dernière Guerre | hors SRD |  | nom, description (1 phrase), traits (5) | reformulation d'après le livre | 0.39 |

<details><summary>Détail des traits (nom : recouvrement avec le SRD français officiel)</summary>

- **Humain** (1) : Polyvalence : 0.04
- **Elfe** (2) : Vision dans le noir : 0.09 ; Sens aiguisés : 0.00 ; Ascendance féerique : 0.69 ; Transe : 0.18
- **Nain** (3) : Vision dans le noir : 0.07 ; Résistance naine : 0.44 ; Entraînement au combat nain : 0.00 ; Maîtrise des outils : 0.38 ; Connaissance de la pierre : 0.20
- **Halfelin** (4) : Chanceux : 0.22 ; Brave : 0.88 ; Agilité halfeline : 0.57
- **Drakéide** (5) : Ascendance draconique : 0.20 ; Souffle destructeur : 0.24 ; Résistance aux dégâts : 0.62
- **Gnome** (6) : Vision dans le noir : 0.09 ; Ruse gnome : 0.71
- **Demi-elfe** (7) : Vision dans le noir : 0.09 ; Ascendance féerique : 0.69 ; Polyvalence en compétences : 0.20
- **Demi-orque** (8) : Vision dans le noir : 0.09 ; Intimidant : 0.00 ; Robustesse implacable : 0.29 ; Attaques sauvages : 0.32
- **Tieffelin** (9) : Vision dans le noir : 0.09 ; Résistance infernale : 0.00 ; Legs infernal : 0.32
- **Aarakocra** (10) : Vol : 0.18 ; Serre : 0.07
- **Génasi** (11) : aucun trait
- **Goliath** (12) : Athlète naturel : 0.00 ; Endurance de la pierre : 0.29 ; Puissamment bâti : 0.25 ; Montagnard : 0.12
- **Orc** (13) : Type de créature :  ; Poussée d'adrénaline : 0.18 ; Vision dans le noir : 0.10 ; Acharnement : 0.14
- **Aasimar** (14) : Type de créature :  ; Résistance céleste : 0.80 ; Vision dans le noir : 0.15 ; Mains guérisseuses : 0.21 ; Porteur de lumière : 0.42 ; Révélation céleste : 0.18
- **Gobelours** (15) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Vision dans le noir : 0.15 ; Ascendance féerique : 0.55 ; Long bras : 0.20 ; Puissamment bâti : 0.25 ; Furtif : 0.00 ; Attaque surprise : 0.30
- **Centaure** (16) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Charge : 0.25 ; Sabots : 0.00 ; Constitution équine : 0.05 ; Affinité naturelle : 0.00
- **Changelin** (17) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Instincts de changelin : 0.00 ; Métamorphe : 0.06
- **Fée** (18) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Magie féerique : 0.08 ; Vol : 0.47
- **Firbolg** (19) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Magie firbolg : 0.10 ; Pas caché : 0.11 ; Puissamment bâti : 0.26 ; Langage des bêtes et du feuillage : 0.11
- **Githyanki** (20) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Savoir astral : 0.32 ; Psionique githyanki : 0.07 ; Résilience psychique : 0.67
- **Githzerai** (21) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Discipline mentale : 1.00 ; Psionique githzerai : 0.07 ; Résilience psychique : 0.67
- **Gobelin** (22) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Vision dans le noir : 0.15 ; Ascendance féerique : 0.55 ; Colère des petits : 0.19 ; Fuite agile : 0.57
- **Hobgobelin** (23) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Vision dans le noir : 0.15 ; Ascendance féerique : 0.55 ; Don féerique : 0.10 ; Fortune du nombre : 0.27
- **Kenku** (24) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Copie experte : 0.21 ; Mémoire kenku : 0.11 ; Mimétisme : 0.24
- **Kobold** (25) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Vision dans le noir : 0.15 ; Cri draconique : 0.17 ; Héritage kobold : 0.17
- **Homme-lézard** (26) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Nage : 0.75 ; Morsure : 0.00 ; Mâchoires affamées : 0.15 ; Retenir son souffle : 0.00 ; Armure naturelle : 0.58 ; Instincts du chasseur : 0.00
- **Minotaure** (27) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Cornes : 0.00 ; Charge encornée : 0.10 ; Cornes martelantes : 0.22 ; Mémoire du labyrinthe : 0.29
- **Satyre** (28) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Bélier : 0.00 ; Résistance à la magie : 1.00 ; Bonds joyeux : 0.12 ; Fêtard : 0.25
- **Tabaxi** (29) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Vision dans le noir : 0.15 ; Escalade : 0.75 ; Griffes félines : 0.00 ; Talent félin : 0.00 ; Agilité féline : 0.19
- **Tortue** (30) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Griffes : 0.00 ; Retenir son souffle : 0.00 ; Armure naturelle : 0.04 ; Défense de la carapace : 0.25 ; Instinct de survie : 0.00
- **Triton** (31) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Amphibie : 0.33 ; Contrôle de l'air et de l'eau : 0.00 ; Vision dans le noir : 0.15 ; Émissaire de la mer : 0.07 ; Gardien des profondeurs : 0.57
- **Yuan-ti** (32) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Vision dans le noir : 0.15 ; Résistance à la magie : 1.00 ; Résilience au poison : 0.44 ; Héritage serpentin : 0.09
- **Owlin** (33) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Vision dans le noir : 0.15 ; Vol : 0.47 ; Silencieux : 0.00
- **Changeforme** (34) : Augmentation de caractéristiques : 0.27 ; Type de créature :  ; Vision dans le noir : 0.15 ; Sens bestiaux : 0.12 ; Transformation : 0.10
- **Forgelier** (35) : Type de créature : 0.00 ; Résilience d'artifice : 0.46 ; Repos de sentinelle : 0.00 ; Protection intégrée : 0.09 ; Conception spécialisée : 0.00
- **Kalashtar** (36) : Type de créature :  ; Esprit double : 1.00 ; Discipline mentale : 0.67 ; Lien mental : 0.24 ; Coupé des rêves : 0.05

</details>

### 2.2 Sous-races (18)

Pas de colonne source. SRD 5.1 : Haut-elfe, Nain des collines, Halfelin pied-léger, Gnome des roches. Elfe des bois, Drow et Gnome des forêts n'existent au SRD que comme lignées 2024 (SRD 5.2).

Répartition : SRD mais texte non conforme 7, hors SRD 11.

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Elfe : Haut-elfe |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, traits (3) | reformulation maison | 0.25 |
| 2 | Elfe : Elfe des bois |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, traits (3) | texte 2014 (hors SRD 5.1) ; homonyme lignée 2024 du SRD 5.2 | 0.00 |
| 3 | Elfe : Elfe noir (Drow) |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, traits (4) | texte 2014 (hors SRD 5.1) ; homonyme lignée 2024 du SRD 5.2 | 0.20 |
| 4 | Nain : Nain des collines |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, traits (1) | reformulation maison | 0.56 |
| 5 | Nain : Nain des montagnes |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, traits (1) | reformulation d'après le livre | 0.00 |
| 6 | Halfelin : Halfelin pied-léger |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, traits (1) | reformulation maison | 0.18 |
| 7 | Halfelin : Halfelin robuste |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, traits (1) | reformulation d'après le livre | 0.44 |
| 8 | Gnome : Gnome des forêts |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, traits (2) | texte 2014 (hors SRD 5.1) ; homonyme lignée 2024 du SRD 5.2 | 0.04 |
| 9 | Gnome : Gnome des roches |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, traits (2) | reformulation maison | 0.20 |
| 10 | Génasi : Génasi de l'air |  | (pas de colonne) Elemental Evil | hors SRD |  | nom, traits (2) | reformulation d'après le livre | 0.24 |
| 11 | Génasi : Génasi de la terre |  | (pas de colonne) Elemental Evil | hors SRD |  | nom, traits (2) | reformulation d'après le livre | 0.12 |
| 12 | Génasi : Génasi du feu |  | (pas de colonne) Elemental Evil | hors SRD |  | nom, traits (3) | reformulation d'après le livre | 0.10 |
| 13 | Génasi : Génasi de l'eau |  | (pas de colonne) Elemental Evil | hors SRD |  | nom, traits (4) | reformulation d'après le livre | 0.12 |
| 14 | Gnome : Gnome des profondeurs (Svirfnebelin) |  | (pas de colonne) Elemental Evil / Mordenkainen | hors SRD |  | nom, traits (3) | reformulation d'après le livre | 0.12 |
| 15 | Elfe : Eladrin | Eladrin | (pas de colonne) Mordenkainen / Monstres du Multivers | hors SRD |  | nom, traits (2) | reformulation d'après le livre | 0.21 |
| 16 | Elfe : Elfe marin | Sea Elf | (pas de colonne) Mordenkainen | hors SRD |  | nom, traits (4) | reformulation d'après le livre | 0.12 |
| 17 | Elfe : Shadar-kai | Shadar-kai | (pas de colonne) Mordenkainen | hors SRD |  | nom, traits (2) | reformulation d'après le livre | 0.61 |
| 18 | Nain : Duergar | Duergar | (pas de colonne) Mordenkainen / Manuel des Joueurs (SCAG) | hors SRD |  | nom, traits (4) | reformulation d'après le livre | 0.30 |

<details><summary>Détail des traits (nom : recouvrement avec le SRD français officiel)</summary>

- **Elfe : Haut-elfe** (1) : Cantrip elfique : 0.26 ; Entraînement martial elfique : 0.00 ; Langue supplémentaire : 0.50
- **Elfe : Elfe des bois** (2) : Entraînement martial elfique : 0.00 ; Foulée légère : 0.00 ; Camouflage naturel : 0.00
- **Elfe : Elfe noir (Drow)** (3) : Vision dans le noir supérieure : 0.14 ; Sensibilité à la lumière du soleil : 0.35 ; Magie féerique drow : 0.29 ; Entraînement martial drow : 0.00
- **Nain : Nain des collines** (4) : Ténacité naine : 0.56
- **Nain : Nain des montagnes** (5) : Entraînement au combat nain (armures) : 0.00
- **Halfelin : Halfelin pied-léger** (6) : Discrétion naturelle : 0.18
- **Halfelin : Halfelin robuste** (7) : Résistance robuste : 0.44
- **Gnome : Gnome des forêts** (8) : Illusionniste inné : 0.08 ; Communication avec les petites bêtes : 0.00
- **Gnome : Gnome des roches** (9) : Connaissances de l'artisan : 0.32 ; Bricoleur ingénieux : 0.08
- **Génasi : Génasi de l'air** (10) : Souffle sans fin : 0.33 ; Se mêler au vent : 0.15
- **Génasi : Génasi de la terre** (11) : Marche de la terre : 0.00 ; Fusionner avec la pierre : 0.23
- **Génasi : Génasi du feu** (12) : Vision dans le noir : 0.00 ; Résistance au feu : 0.00 ; Atteindre le brasier : 0.29
- **Génasi : Génasi de l'eau** (13) : Résistance à l'acide : 0.00 ; Amphibien : 0.00 ; Nage : 0.20 ; Appeler la vague : 0.27
- **Gnome : Gnome des profondeurs (Svirfnebelin)** (14) : Vision dans le noir supérieure : 0.09 ; Teint pierreux : 0.27 ; Langue supplémentaire : 0.00
- **Elfe : Eladrin** (15) : Pas féerique : 0.17 ; Saisons changeantes : 0.25
- **Elfe : Elfe marin** (16) : Entraînement martial des elfes marins : 0.00 ; Enfant de la mer : 0.07 ; Ami de la mer : 0.06 ; Langue supplémentaire : 0.33
- **Elfe : Shadar-kai** (17) : Résistance nécrotique : 1.00 ; Bénédiction de la Reine corbeau : 0.23
- **Nain : Duergar** (18) : Vision dans le noir supérieure : 0.08 ; Résilience duergar : 0.50 ; Magie duergar : 0.16 ; Sensibilité au soleil : 0.48

</details>

### 2.3 Lignées (race_lineages) (43)

Effet mécanique en style télégraphique (résumé maison). Ascendances draconiques 2014 : table du SRD 5.1 ; lignées 2024 : SRD 5.2 ; Fizban et génasi : hors SRD.

Répartition : SRD mais texte non conforme 34, hors SRD 9.

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Drakéide : Ascendance draconique : Noir |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (332 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 2 | Drakéide : Ascendance draconique : Bleu |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (339 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 3 | Drakéide : Ascendance draconique : Airain |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (328 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 4 | Drakéide : Ascendance draconique : Bronze |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (339 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 5 | Drakéide : Ascendance draconique : Cuivre |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (332 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 6 | Drakéide : Ascendance draconique : Or |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (317 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 7 | Drakéide : Ascendance draconique : Vert |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (325 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 8 | Drakéide : Ascendance draconique : Rouge |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (317 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 9 | Drakéide : Ascendance draconique : Argent |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (321 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 10 | Drakéide : Ascendance draconique : Blanc |  | Player's Handbook (2014) | SRD mais texte non conforme | SRD 5.1 | nom, effet mécanique (321 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 11 | Drakéide : Ascendance métallique (Fizban's) : Airain |  | Fizban's Treasury of Dragons (2021) | hors SRD |  | nom, effet mécanique (593 car.) | résumé mécanique maison (style télégraphique) | 0.01 |
| 12 | Drakéide : Ascendance métallique (Fizban's) : Argent |  | Fizban's Treasury of Dragons (2021) | hors SRD |  | nom, effet mécanique (597 car.) | résumé mécanique maison (style télégraphique) | 0.01 |
| 13 | Drakéide : Ascendance métallique (Fizban's) : Bronze |  | Fizban's Treasury of Dragons (2021) | hors SRD |  | nom, effet mécanique (604 car.) | résumé mécanique maison (style télégraphique) | 0.01 |
| 14 | Drakéide : Ascendance métallique (Fizban's) : Cuivre |  | Fizban's Treasury of Dragons (2021) | hors SRD |  | nom, effet mécanique (597 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 15 | Drakéide : Ascendance métallique (Fizban's) : Or |  | Fizban's Treasury of Dragons (2021) | hors SRD |  | nom, effet mécanique (593 car.) | résumé mécanique maison (style télégraphique) | 0.01 |
| 16 | Génasi : Génasi de l'air |  | Elemental Evil Player's Companion | hors SRD |  | nom, effet mécanique (135 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 17 | Génasi : Génasi de la terre |  | Elemental Evil Player's Companion | hors SRD |  | nom, effet mécanique (135 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 18 | Génasi : Génasi du feu |  | Elemental Evil Player's Companion | hors SRD |  | nom, effet mécanique (182 car.) | résumé mécanique maison (style télégraphique) | 0.12 |
| 19 | Génasi : Génasi de l'eau |  | Elemental Evil Player's Companion | hors SRD |  | nom, effet mécanique (217 car.) | résumé mécanique maison (style télégraphique) | 0.06 |
| 20 | Elfe : Drow |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (343 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 21 | Elfe : Haut-elfe |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (391 car.) | résumé mécanique maison (style télégraphique) | 0.02 |
| 22 | Elfe : Elfe des bois |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (331 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 23 | Gnome : Gnome des forêts |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (282 car.) | résumé mécanique maison (style télégraphique) | 0.11 |
| 24 | Gnome : Gnome des roches |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (283 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 25 | Goliath : Géant des nuages |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (127 car.) | résumé mécanique maison (style télégraphique) | 0.06 |
| 26 | Goliath : Géant du feu |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (140 car.) | résumé mécanique maison (style télégraphique) | 0.05 |
| 27 | Goliath : Géant du givre |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (206 car.) | résumé mécanique maison (style télégraphique) | 0.18 |
| 28 | Goliath : Géant des collines |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (170 car.) | résumé mécanique maison (style télégraphique) | 0.32 |
| 29 | Goliath : Géant de pierre |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (181 car.) | résumé mécanique maison (style télégraphique) | 0.09 |
| 30 | Goliath : Géant des tempêtes |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (155 car.) | résumé mécanique maison (style télégraphique) | 0.14 |
| 31 | Tieffelin : Abyssal |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (346 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 32 | Tieffelin : Chtonien |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (338 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 33 | Tieffelin : Infernal |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (327 car.) | résumé mécanique maison (style télégraphique) | 0.00 |
| 34 | Drakéide : Ancêtre draconique 2024 : Noir |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (420 car.) | résumé mécanique maison (style télégraphique) | 0.01 |
| 35 | Drakéide : Ancêtre draconique 2024 : Bleu |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (427 car.) | résumé mécanique maison (style télégraphique) | 0.03 |
| 36 | Drakéide : Ancêtre draconique 2024 : Airain |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (416 car.) | résumé mécanique maison (style télégraphique) | 0.03 |
| 37 | Drakéide : Ancêtre draconique 2024 : Bronze |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (427 car.) | résumé mécanique maison (style télégraphique) | 0.03 |
| 38 | Drakéide : Ancêtre draconique 2024 : Cuivre |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (420 car.) | résumé mécanique maison (style télégraphique) | 0.01 |
| 39 | Drakéide : Ancêtre draconique 2024 : Or |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (416 car.) | résumé mécanique maison (style télégraphique) | 0.03 |
| 40 | Drakéide : Ancêtre draconique 2024 : Vert |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (424 car.) | résumé mécanique maison (style télégraphique) | 0.03 |
| 41 | Drakéide : Ancêtre draconique 2024 : Rouge |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (416 car.) | résumé mécanique maison (style télégraphique) | 0.03 |
| 42 | Drakéide : Ancêtre draconique 2024 : Argent |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (420 car.) | résumé mécanique maison (style télégraphique) | 0.03 |
| 43 | Drakéide : Ancêtre draconique 2024 : Blanc |  | Player's Handbook (2024) / SRD 5.2 | SRD mais texte non conforme | SRD 5.2 | nom, effet mécanique (420 car.) | résumé mécanique maison (style télégraphique) | 0.03 |

### 2.4 Classes (13)

Les 12 classes du Manuel des Joueurs sont au SRD 5.1 et 5.2 ; description = une phrase de flaveur maison. L'Artificier (Tasha) est hors SRD.

Répartition : SRD mais texte non conforme 12, hors SRD 1.

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Barbare |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 2 | Barde |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 3 | Clerc |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 4 | Druide |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 5 | Guerrier |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.20 |
| 6 | Moine |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 7 | Paladin |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 8 | Rôdeur |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 9 | Roublard |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 10 | Occultiste |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.09 |
| 11 | Magicien |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 12 | Ensorceleur |  | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 et 5.2 | nom, description (1 phrase) | flaveur maison | 0.00 |
| 13 | Artificier | Artificer | Chaudron de Tasha | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |

### 2.5 Aptitudes de classe (228)

Aptitudes de base (sans sous-classe). Celles des 12 classes SRD viennent du fichier croisé aidedd / 5e-bits / Open5e (statut `srd_cc_by`) ou de la phase 1 : traduction ou reformulation non officielle, rarement le texte officiel (3 aptitudes ≥ 0,60). Les 17 aptitudes de l'Artificier sont hors SRD.

Répartition : SRD 5.1 3, SRD mais texte non conforme 208, hors SRD 17.

<details><summary>Tableau complet (228 lignes)</summary>

| id | Élément (propriétaire / niveau / aptitude) | Nom EN | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. | Provenance |
|---|---|---|---|---|---|---|---|---|
| 1 | Barbare / niv. 1 / Rage |  | SRD mais texte non conforme | SRD 5.1 | nom, description (155 car.) | traduction/reformulation non officielle | 0.18 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 2 | Barbare / niv. 1 / Défense sans armure |  | SRD 5.1 | SRD 5.1 | nom, description (121 car.) | proche du SRD FR officiel | 0.93 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 3 | Barbare / niv. 2 / Attaque impétueuse |  | SRD mais texte non conforme | SRD 5.1 | nom, description (143 car.) | traduction/reformulation non officielle | 0.09 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 4 | Barbare / niv. 3 / Voie primitive |  | SRD mais texte non conforme | SRD 5.1 | nom, description (73 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 5 | Barde / niv. 1 / Incantation |  | SRD mais texte non conforme | SRD 5.1 | nom, description (139 car.) | traduction/reformulation non officielle | 0.06 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 6 | Barde / niv. 1 / Inspiration bardique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (118 car.) | traduction/reformulation non officielle | 0.06 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 7 | Barde / niv. 3 / Collège bardique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (56 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 8 | Clerc / niv. 1 / Incantation |  | SRD mais texte non conforme | SRD 5.1 | nom, description (109 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 9 | Clerc / niv. 1 / Domaine divin |  | SRD mais texte non conforme | SRD 5.1 | nom, description (105 car.) | traduction/reformulation non officielle | 0.25 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 10 | Clerc / niv. 2 / Conduit divin |  | SRD mais texte non conforme | SRD 5.1 | nom, description (100 car.) | traduction/reformulation non officielle | 0.27 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 11 | Druide / niv. 1 / Druidique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (46 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 12 | Druide / niv. 1 / Incantation |  | SRD mais texte non conforme | SRD 5.1 | nom, description (93 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 13 | Druide / niv. 2 / Forme sauvage |  | SRD mais texte non conforme | SRD 5.1 | nom, description (105 car.) | traduction/reformulation non officielle | 0.23 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 14 | Druide / niv. 2 / Cercle druidique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (90 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 15 | Guerrier / niv. 1 / Style de combat |  | SRD mais texte non conforme | SRD 5.1 | nom, description (61 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 16 | Guerrier / niv. 1 / Récupération au combat |  | SRD mais texte non conforme | SRD 5.1 | nom, description (104 car.) | traduction/reformulation non officielle | 0.13 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 17 | Guerrier / niv. 2 / Fougue guerrière |  | SRD mais texte non conforme | SRD 5.1 | nom, description (99 car.) | traduction/reformulation non officielle | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 18 | Guerrier / niv. 3 / Archétype martial |  | SRD mais texte non conforme | SRD 5.1 | nom, description (66 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 19 | Moine / niv. 1 / Défense sans armure |  | SRD 5.1 | SRD 5.1 | nom, description (128 car.) | proche du SRD FR officiel | 0.75 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 20 | Moine / niv. 1 / Arts martiaux |  | SRD mais texte non conforme | SRD 5.1 | nom, description (136 car.) | traduction/reformulation non officielle | 0.30 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 21 | Moine / niv. 2 / Ki |  | SRD mais texte non conforme | SRD 5.1 | nom, description (132 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 22 | Moine / niv. 3 / Tradition monastique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (81 car.) | traduction/reformulation non officielle | 0.33 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 23 | Paladin / niv. 1 / Sens divin |  | SRD mais texte non conforme | SRD 5.1 | nom, description (78 car.) | traduction/reformulation non officielle | 0.10 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 24 | Paladin / niv. 1 / Imposition des mains |  | SRD mais texte non conforme | SRD 5.1 | nom, description (90 car.) | traduction/reformulation non officielle | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 25 | Paladin / niv. 2 / Style de combat |  | SRD mais texte non conforme | SRD 5.1 | nom, description (61 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 26 | Paladin / niv. 2 / Incantation |  | SRD mais texte non conforme | SRD 5.1 | nom, description (99 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 27 | Paladin / niv. 3 / Serment sacré |  | SRD mais texte non conforme | SRD 5.1 | nom, description (80 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 28 | Rôdeur / niv. 1 / Ennemi juré |  | SRD mais texte non conforme | SRD 5.1 | nom, description (82 car.) | traduction/reformulation non officielle | 0.10 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 29 | Rôdeur / niv. 1 / Explorateur né |  | SRD mais texte non conforme | SRD 5.1 | nom, description (86 car.) | traduction/reformulation non officielle | 0.30 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 30 | Rôdeur / niv. 2 / Style de combat |  | SRD mais texte non conforme | SRD 5.1 | nom, description (61 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 31 | Rôdeur / niv. 2 / Incantation |  | SRD mais texte non conforme | SRD 5.1 | nom, description (97 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 32 | Rôdeur / niv. 3 / Archétype de rôdeur |  | SRD mais texte non conforme | SRD 5.1 | nom, description (69 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 33 | Roublard / niv. 1 / Expertise |  | SRD mais texte non conforme | SRD 5.1 | nom, description (110 car.) | traduction/reformulation non officielle | 0.07 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 34 | Roublard / niv. 1 / Attaque sournoise |  | SRD mais texte non conforme | SRD 5.1 | nom, description (109 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 35 | Roublard / niv. 1 / Argot des voleurs |  | SRD mais texte non conforme | SRD 5.1 | nom, description (59 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 36 | Roublard / niv. 3 / Archétype de roublard |  | SRD mais texte non conforme | SRD 5.1 | nom, description (58 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 37 | Occultiste / niv. 1 / Magie de pacte |  | SRD mais texte non conforme | SRD 5.1 | nom, description (100 car.) | traduction/reformulation non officielle | 0.08 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 38 | Occultiste / niv. 1 / Patron protecteur |  | SRD mais texte non conforme | SRD 5.1 | nom, description (89 car.) | traduction/reformulation non officielle | 0.30 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 39 | Occultiste / niv. 2 / Invocations occultes |  | SRD mais texte non conforme | SRD 5.1 | nom, description (123 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 40 | Magicien / niv. 1 / Incantation |  | SRD mais texte non conforme | SRD 5.1 | nom, description (97 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 41 | Magicien / niv. 1 / Récupération arcanique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (112 car.) | traduction/reformulation non officielle | 0.25 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 42 | Magicien / niv. 2 / Tradition arcanique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (76 car.) | traduction/reformulation non officielle | 0.25 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 43 | Ensorceleur / niv. 1 / Incantation |  | SRD mais texte non conforme | SRD 5.1 | nom, description (77 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 44 | Ensorceleur / niv. 1 / Origine magique innée |  | SRD mais texte non conforme | SRD 5.1 | nom, description (70 car.) | traduction/reformulation non officielle | 0.12 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 45 | Ensorceleur / niv. 2 / Métamagie |  | SRD mais texte non conforme | SRD 5.1 | nom, description (77 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 149 | Barbare / niv. 2 / Sens du danger |  | SRD mais texte non conforme | SRD 5.1 | nom, description (420 car.) | traduction/reformulation non officielle | 0.15 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 150 | Barbare / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 151 | Barbare / niv. 5 / Attaque supplémentaire |  | SRD mais texte non conforme | SRD 5.1 | nom, description (141 car.) | traduction/reformulation non officielle | 0.50 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 152 | Barbare / niv. 5 / Déplacement rapide |  | SRD mais texte non conforme | SRD 5.1 | nom, description (92 car.) | traduction/reformulation non officielle | 0.57 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 153 | Barbare / niv. 7 / Instinct sauvage |  | SRD mais texte non conforme | SRD 5.1 | nom, description (330 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 154 | Barbare / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 155 | Barbare / niv. 9 / Critique brutal (1 dé) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (289 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 156 | Barbare / niv. 11 / Rage implacable |  | SRD mais texte non conforme | SRD 5.1 | nom, description (491 car.) | traduction/reformulation non officielle | 0.36 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 157 | Barbare / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 158 | Barbare / niv. 13 / Critique brutal (2 dés) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (289 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 159 | Barbare / niv. 15 / Rage persistante |  | SRD mais texte non conforme | SRD 5.1 | nom, description (172 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 160 | Barbare / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 161 | Barbare / niv. 17 / Critique brutal (3 dés) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (289 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 162 | Barbare / niv. 18 / Puissance indomptable |  | SRD mais texte non conforme | SRD 5.1 | nom, description (166 car.) | traduction/reformulation non officielle | 0.31 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 163 | Barbare / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 164 | Barbare / niv. 20 / Champion primitif |  | SRD mais texte non conforme | SRD 5.1 | nom, description (200 car.) | traduction/reformulation non officielle | 0.53 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 165 | Barde / niv. 2 / Touche-à-tout |  | SRD mais texte non conforme | SRD 5.1 | nom, description (188 car.) | traduction/reformulation non officielle | 0.52 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 166 | Barde / niv. 2 / Chant reposant (d6) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (548 car.) | traduction/reformulation non officielle | 0.30 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 167 | Barde / niv. 3 / Expertise |  | SRD mais texte non conforme | SRD 5.1 | nom, description (287 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 168 | Barde / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 169 | Barde / niv. 5 / Inspiration bardique (d8) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (1213 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 170 | Barde / niv. 5 / Source d'inspiration |  | SRD mais texte non conforme | SRD 5.1 | nom, description (118 car.) | traduction/reformulation non officielle | 0.40 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 171 | Barde / niv. 6 / Contre-charme |  | SRD mais texte non conforme | SRD 5.1 | nom, description (651 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 172 | Barde / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 173 | Barde / niv. 9 / Chant reposant (d8) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (548 car.) | traduction/reformulation non officielle | 0.30 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 174 | Barde / niv. 10 / Inspiration bardique (d10) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (1213 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 175 | Barde / niv. 10 / Expertise |  | SRD mais texte non conforme | SRD 5.1 | nom, description (287 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 176 | Barde / niv. 10 / Secrets magiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (547 car.) | traduction/reformulation non officielle | 0.21 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 177 | Barde / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 178 | Barde / niv. 13 / Chant reposant (d10) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (548 car.) | traduction/reformulation non officielle | 0.30 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 179 | Barde / niv. 14 / Secrets magiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (547 car.) | traduction/reformulation non officielle | 0.21 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 180 | Barde / niv. 15 / Inspiration bardique (d12) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (1213 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 181 | Barde / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 182 | Barde / niv. 17 / Chant reposant (d12) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (548 car.) | traduction/reformulation non officielle | 0.30 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 183 | Barde / niv. 18 / Secrets magiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (547 car.) | traduction/reformulation non officielle | 0.21 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 184 | Barde / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 185 | Barde / niv. 20 / Inspiration supérieure |  | SRD mais texte non conforme | SRD 5.1 | nom, description (116 car.) | traduction/reformulation non officielle | 0.07 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 186 | Clerc / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 187 | Clerc / niv. 5 / Destruction des morts-vivants (FP 1/2) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (381 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 188 | Clerc / niv. 6 / Conduit divin (2/repos) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (1766 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 189 | Clerc / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 190 | Clerc / niv. 8 / Destruction des morts-vivants (FP 1) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (381 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 191 | Clerc / niv. 10 / Intervention divine |  | SRD mais texte non conforme | SRD 5.1 | nom, description (730 car.) | traduction/reformulation non officielle | 0.27 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 192 | Clerc / niv. 11 / Destruction des morts-vivants (FP 2) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (381 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 193 | Clerc / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 194 | Clerc / niv. 14 / Destruction des morts-vivants (FP 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (381 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 195 | Clerc / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 196 | Clerc / niv. 17 / Destruction des morts-vivants (FP 4) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (381 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 197 | Clerc / niv. 18 / Conduit divin (3/repos) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (1766 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 198 | Clerc / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 199 | Clerc / niv. 20 / Intervention divine supérieure |  | SRD mais texte non conforme | SRD 5.1 | nom, description (730 car.) | traduction/reformulation non officielle | 0.27 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 200 | Druide / niv. 4 / Forme sauvage améliorée |  | SRD mais texte non conforme | SRD 5.1 | nom, description (3906 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 201 | Druide / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 202 | Druide / niv. 8 / Forme sauvage améliorée |  | SRD mais texte non conforme | SRD 5.1 | nom, description (3906 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 203 | Druide / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 204 | Druide / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 205 | Druide / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 206 | Druide / niv. 18 / Jeunesse éternelle |  | SRD mais texte non conforme | SRD 5.1 | nom, description (166 car.) | traduction/reformulation non officielle | 0.12 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 207 | Druide / niv. 18 / Incantation animale |  | SRD mais texte non conforme | SRD 5.1 | nom, description (278 car.) | traduction/reformulation non officielle | 0.36 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 208 | Druide / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 209 | Druide / niv. 20 / Archidruide |  | SRD mais texte non conforme | SRD 5.1 | nom, description (364 car.) | traduction/reformulation non officielle | 0.08 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 210 | Ensorceleur / niv. 2 / Source de magie |  | SRD mais texte non conforme | SRD 5.1 | nom, description (1590 car.) | traduction/reformulation non officielle | 0.30 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 211 | Ensorceleur / niv. 3 / Métamagie |  | SRD mais texte non conforme | SRD 5.1 | nom, description (2605 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 212 | Ensorceleur / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 213 | Ensorceleur / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 214 | Ensorceleur / niv. 10 / Métamagie |  | SRD mais texte non conforme | SRD 5.1 | nom, description (2605 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 215 | Ensorceleur / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 216 | Ensorceleur / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 217 | Ensorceleur / niv. 17 / Métamagie |  | SRD mais texte non conforme | SRD 5.1 | nom, description (2605 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 218 | Ensorceleur / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 219 | Ensorceleur / niv. 20 / Restauration magique |  | SRD 5.1 | SRD 5.1 | nom, description (106 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 220 | Guerrier / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (299 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 221 | Guerrier / niv. 5 / Attaque supplémentaire (1) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (300 car.) | traduction/reformulation non officielle | 0.39 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 222 | Guerrier / niv. 6 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (299 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 223 | Guerrier / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (299 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 224 | Guerrier / niv. 9 / Inflexible (1) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (399 car.) | traduction/reformulation non officielle | 0.42 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 225 | Guerrier / niv. 11 / Attaque supplémentaire (2) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (300 car.) | traduction/reformulation non officielle | 0.39 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 226 | Guerrier / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (299 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 227 | Guerrier / niv. 13 / Inflexible (2) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (399 car.) | traduction/reformulation non officielle | 0.42 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 228 | Guerrier / niv. 14 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (299 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 229 | Guerrier / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (299 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 230 | Guerrier / niv. 17 / Fougue (2) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (381 car.) | traduction/reformulation non officielle | 0.34 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 231 | Guerrier / niv. 17 / Inflexible (3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (399 car.) | traduction/reformulation non officielle | 0.42 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 232 | Guerrier / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (299 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 233 | Guerrier / niv. 20 / Attaque supplémentaire (3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (300 car.) | traduction/reformulation non officielle | 0.39 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 234 | Magicien / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 235 | Magicien / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 236 | Magicien / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 237 | Magicien / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 238 | Magicien / niv. 18 / Maîtrise des sorts |  | SRD mais texte non conforme | SRD 5.1 | nom, description (587 car.) | traduction/reformulation non officielle | 0.28 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 239 | Magicien / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 240 | Magicien / niv. 20 / Sorts de prédilection |  | SRD mais texte non conforme | SRD 5.1 | nom, description (642 car.) | traduction/reformulation non officielle | 0.28 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 241 | Moine / niv. 2 / Déplacement sans armure |  | SRD mais texte non conforme | SRD 5.1 | nom, description (420 car.) | traduction/reformulation non officielle | 0.16 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 242 | Moine / niv. 3 / Parade de projectiles |  | SRD mais texte non conforme | SRD 5.1 | nom, description (926 car.) | traduction/reformulation non officielle | 0.29 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 243 | Moine / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 244 | Moine / niv. 4 / Chute ralentie |  | SRD mais texte non conforme | SRD 5.1 | nom, description (173 car.) | traduction/reformulation non officielle | 0.26 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 245 | Moine / niv. 5 / Attaque supplémentaire |  | SRD mais texte non conforme | SRD 5.1 | nom, description (130 car.) | traduction/reformulation non officielle | 0.50 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 246 | Moine / niv. 5 / Frappe étourdissante |  | SRD mais texte non conforme | SRD 5.1 | nom, description (385 car.) | traduction/reformulation non officielle | 0.44 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 247 | Moine / niv. 6 / Frappes de ki |  | SRD mais texte non conforme | SRD 5.1 | nom, description (184 car.) | traduction/reformulation non officielle | 0.29 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 248 | Moine / niv. 7 / Esquive totale |  | SRD mais texte non conforme | SRD 5.1 | nom, description (411 car.) | traduction/reformulation non officielle | 0.37 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 249 | Moine / niv. 7 / Sérénité |  | SRD mais texte non conforme | SRD 5.1 | nom, description (141 car.) | traduction/reformulation non officielle | 0.39 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 250 | Moine / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 251 | Moine / niv. 9 / Déplacement sans armure amélioré |  | SRD mais texte non conforme | SRD 5.1 | nom, description (420 car.) | traduction/reformulation non officielle | 0.16 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 252 | Moine / niv. 10 / Pureté physique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (103 car.) | traduction/reformulation non officielle | 0.07 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 253 | Moine / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 254 | Moine / niv. 13 / Langue du soleil et de la lune |  | SRD mais texte non conforme | SRD 5.1 | nom, description (240 car.) | traduction/reformulation non officielle | 0.42 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 255 | Moine / niv. 14 / Âme de diamant |  | SRD mais texte non conforme | SRD 5.1 | nom, description (252 car.) | traduction/reformulation non officielle | 0.29 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 256 | Moine / niv. 15 / Jeunesse éternelle |  | SRD mais texte non conforme | SRD 5.1 | nom, description (258 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 257 | Moine / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 258 | Moine / niv. 18 / Désertion de l'âme |  | SRD mais texte non conforme | SRD 5.1 | nom, description (452 car.) | traduction/reformulation non officielle | 0.18 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 259 | Moine / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 260 | Moine / niv. 20 / Perfection de l'être |  | SRD mais texte non conforme | SRD 5.1 | nom, description (117 car.) | traduction/reformulation non officielle | 0.06 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 261 | Occultiste / niv. 3 / Faveur de pacte |  | SRD mais texte non conforme | SRD 5.1 | nom, description (4292 car.) | traduction/reformulation non officielle | 0.19 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 262 | Occultiste / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 263 | Occultiste / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 264 | Occultiste / niv. 11 / Arcanum mystique (niveau 6) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (613 car.) | traduction/reformulation non officielle | 0.15 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 265 | Occultiste / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 266 | Occultiste / niv. 13 / Arcanum mystique (niveau 7) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (613 car.) | traduction/reformulation non officielle | 0.15 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 267 | Occultiste / niv. 15 / Arcanum mystique (niveau 8) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (613 car.) | traduction/reformulation non officielle | 0.15 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 268 | Occultiste / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 269 | Occultiste / niv. 17 / Arcanum mystique (niveau 9) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (613 car.) | traduction/reformulation non officielle | 0.15 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 270 | Occultiste / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 271 | Occultiste / niv. 20 / Maître de l'occulte |  | SRD mais texte non conforme | SRD 5.1 | nom, description (424 car.) | traduction/reformulation non officielle | 0.18 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 272 | Paladin / niv. 2 / Châtiment divin |  | SRD mais texte non conforme | SRD 5.1 | nom, description (531 car.) | traduction/reformulation non officielle | 0.24 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 273 | Paladin / niv. 3 / Santé divine |  | SRD mais texte non conforme | SRD 5.1 | nom, description (90 car.) | traduction/reformulation non officielle | 0.46 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 274 | Paladin / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 275 | Paladin / niv. 5 / Attaque supplémentaire |  | SRD mais texte non conforme | SRD 5.1 | nom, description (141 car.) | traduction/reformulation non officielle | 0.50 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 276 | Paladin / niv. 6 / Aura de protection |  | SRD mais texte non conforme | SRD 5.1 | nom, description (304 car.) | traduction/reformulation non officielle | 0.20 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 277 | Paladin / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 278 | Paladin / niv. 10 / Aura de courage |  | SRD mais texte non conforme | SRD 5.1 | nom, description (197 car.) | traduction/reformulation non officielle | 0.17 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 279 | Paladin / niv. 11 / Châtiment divin amélioré |  | SRD mais texte non conforme | SRD 5.1 | nom, description (242 car.) | traduction/reformulation non officielle | 0.19 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 280 | Paladin / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 281 | Paladin / niv. 14 / Contact purifiant |  | SRD mais texte non conforme | SRD 5.1 | nom, description (264 car.) | traduction/reformulation non officielle | 0.38 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 282 | Paladin / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 283 | Paladin / niv. 18 / Amélioration d'auras |  | SRD mais texte non conforme | SRD 5.1 | nom, description (503 car.) | traduction/reformulation non officielle | 0.21 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 284 | Paladin / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 285 | Rôdeur / niv. 3 / Vigilance primitive |  | SRD mais texte non conforme | SRD 5.1 | nom, description (538 car.) | traduction/reformulation non officielle | 0.24 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 286 | Rôdeur / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 287 | Rôdeur / niv. 5 / Attaque supplémentaire |  | SRD mais texte non conforme | SRD 5.1 | nom, description (141 car.) | traduction/reformulation non officielle | 0.50 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 288 | Rôdeur / niv. 6 / Amélioration de l'Ennemi juré et de l'Explorateur-né |  | SRD mais texte non conforme | SRD 5.1 | nom, description (2159 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 289 | Rôdeur / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 290 | Rôdeur / niv. 8 / Foulée tellurique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (464 car.) | traduction/reformulation non officielle | 0.16 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 291 | Rôdeur / niv. 10 / Amélioration de l'Explorateur-né |  | SRD mais texte non conforme | SRD 5.1 | nom, description (1215 car.) | traduction/reformulation non officielle | 0.26 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 292 | Rôdeur / niv. 10 / Camouflage naturel |  | SRD mais texte non conforme | SRD 5.1 | nom, description (729 car.) | traduction/reformulation non officielle | 0.27 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 293 | Rôdeur / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 294 | Rôdeur / niv. 14 / Amélioration de l'Ennemi juré |  | SRD mais texte non conforme | SRD 5.1 | nom, description (942 car.) | traduction/reformulation non officielle | 0.24 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 295 | Rôdeur / niv. 14 / Disparition |  | SRD mais texte non conforme | SRD 5.1 | nom, description (215 car.) | traduction/reformulation non officielle | 0.30 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 296 | Rôdeur / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 297 | Rôdeur / niv. 18 / Sens sauvages |  | SRD mais texte non conforme | SRD 5.1 | nom, description (498 car.) | traduction/reformulation non officielle | 0.20 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 298 | Rôdeur / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (292 car.) | traduction/reformulation non officielle | 0.22 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 299 | Rôdeur / niv. 20 / Tueur implacable |  | SRD mais texte non conforme | SRD 5.1 | nom, description (370 car.) | traduction/reformulation non officielle | 0.50 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 300 | Roublard / niv. 2 / Ruse |  | SRD mais texte non conforme | SRD 5.1 | nom, description (269 car.) | traduction/reformulation non officielle | 0.18 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 301 | Roublard / niv. 4 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (296 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 302 | Roublard / niv. 5 / Esquive instinctive |  | SRD mais texte non conforme | SRD 5.1 | nom, description (187 car.) | traduction/reformulation non officielle | 0.34 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 303 | Roublard / niv. 6 / Expertise |  | SRD mais texte non conforme | SRD 5.1 | nom, description (381 car.) | traduction/reformulation non officielle | 0.19 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 304 | Roublard / niv. 7 / Esquive totale |  | SRD mais texte non conforme | SRD 5.1 | nom, description (396 car.) | traduction/reformulation non officielle | 0.21 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 305 | Roublard / niv. 8 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (296 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 306 | Roublard / niv. 10 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (296 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 307 | Roublard / niv. 11 / Savoir-faire |  | SRD mais texte non conforme | SRD 5.1 | nom, description (283 car.) | traduction/reformulation non officielle | 0.21 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 308 | Roublard / niv. 12 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (296 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 309 | Roublard / niv. 14 / Perception aveugle |  | SRD mais texte non conforme | SRD 5.1 | nom, description (167 car.) | traduction/reformulation non officielle | 0.07 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 310 | Roublard / niv. 15 / Esprit fuyant |  | SRD mais texte non conforme | SRD 5.1 | nom, description (129 car.) | traduction/reformulation non officielle | 0.37 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 311 | Roublard / niv. 16 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (296 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 312 | Roublard / niv. 18 / Insaisissable |  | SRD mais texte non conforme | SRD 5.1 | nom, description (165 car.) | traduction/reformulation non officielle | 0.39 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 313 | Roublard / niv. 19 / Amélioration de caractéristiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (296 car.) | traduction/reformulation non officielle | 0.23 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 314 | Roublard / niv. 20 / Coup de chance |  | SRD mais texte non conforme | SRD 5.1 | nom, description (396 car.) | traduction/reformulation non officielle | 0.20 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 988 | Artificier / niv. 1 / Bricolage magique | Magical Tinkering | hors SRD |  | nom, description (278 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 989 | Artificier / niv. 1 / Incantation | Spellcasting | hors SRD |  | nom, description (377 car.) | reformulation maison | 0.11 | lot 5 (sous-classes, reformulé) |
| 990 | Artificier / niv. 2 / Infusion d'objets | Infuse Item | hors SRD |  | nom, description (300 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 991 | Artificier / niv. 3 / Spécialisation d'artificier | Artificer Specialist | hors SRD |  | nom, description (149 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 992 | Artificier / niv. 3 / Le bon outil pour la tâche | The Right Tool for the Job | hors SRD |  | nom, description (187 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 993 | Artificier / niv. 4 / Amélioration de caractéristiques | Ability Score Improvement | hors SRD |  | nom, description (101 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 994 | Artificier / niv. 6 / Expertise des outils | Tool Expertise | hors SRD |  | nom, description (88 car.) | reformulation maison | 0.27 | lot 5 (sous-classes, reformulé) |
| 995 | Artificier / niv. 7 / Éclair de génie | Flash of Genius | hors SRD |  | nom, description (265 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 996 | Artificier / niv. 8 / Amélioration de caractéristiques | Ability Score Improvement | hors SRD |  | nom, description (101 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 997 | Artificier / niv. 10 / Adepte des objets magiques | Magic Item Adept | hors SRD |  | nom, description (174 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 998 | Artificier / niv. 11 / Objet de stockage de sort | Spell-Storing Item | hors SRD |  | nom, description (361 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 999 | Artificier / niv. 12 / Amélioration de caractéristiques | Ability Score Improvement | hors SRD |  | nom, description (101 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 1000 | Artificier / niv. 14 / Savant des objets magiques | Magic Item Savant | hors SRD |  | nom, description (181 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 1001 | Artificier / niv. 16 / Amélioration de caractéristiques | Ability Score Improvement | hors SRD |  | nom, description (101 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 1002 | Artificier / niv. 18 / Maître des objets magiques | Magic Item Master | hors SRD |  | nom, description (57 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 1003 | Artificier / niv. 19 / Amélioration de caractéristiques | Ability Score Improvement | hors SRD |  | nom, description (101 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 1004 | Artificier / niv. 20 / Âme de l'artifice | Soul of Artifice | hors SRD |  | nom, description (246 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |

</details>

### 2.6 Sous-classes (121)

Pas de colonne source. Description = une phrase de flaveur maison (source des 91 sous-classes de la phase 5 : `CodexArcanum_V2.html`). SRD 5.1 et 5.2 : une sous-classe par classe (Berserker, Savoir, Vie, Terre, Champion, Main ouverte, **Dévotion**, Chasseur, Voleur, Fiélon, Évocation, Lignage draconique). **Serment des Anciens (id 7)** a été posé en phase 1 comme sous-classe « iconique », mais il n'est pas au SRD.

Répartition : SRD mais texte non conforme 12, hors SRD 109.

<details><summary>Tableau complet (121 lignes)</summary>

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Barbare : Voie du Berserker |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 2 | Barde : Collège du Savoir |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 3 | Clerc : Domaine de la Vie |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 4 | Druide : Cercle de la Terre |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.20 |
| 5 | Guerrier : Champion |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 6 | Moine : Voie de la Main Ouverte |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.25 |
| 7 | Paladin : Serment des Anciens |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison **Note :** Posée en phase 1 comme sous-classe « iconique » SRD, mais le Serment des Anciens n'est pas dans le SRD (le paladin SRD est le Serment de dévotion, id 83). | 0.00 |
| 8 | Rôdeur : Chasseur |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 9 | Roublard : Voleur |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 10 | Occultiste : Protecteur Fiélon |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 11 | Magicien : École de l'évocation |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 12 | Ensorceleur : Lignage draconique |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 13 | Barbare : Guerrier totem |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 14 | Barbare : Bête |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 15 | Barbare : Gardien ancestral |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 16 | Barbare : Géant |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 17 | Barbare : Héraut des tempêtes |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.14 |
| 18 | Barbare : Magie sauvage |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 19 | Barbare : Zélote |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 20 | Barde : Collège de la vaillance |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 21 | Barde : Collège de l'éloquence |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 22 | Barde : Collège de la création |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 23 | Barde : Collège de la séduction |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 24 | Barde : Collège des épées |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 25 | Barde : Collège des esprits |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 26 | Barde : Collège des murmures |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 27 | Clerc : Duperie |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 28 | Clerc : Guerre |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 29 | Clerc : Lumière |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 30 | Clerc : Nature |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 31 | Clerc : Savoir |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 32 | Clerc : Tempête |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 33 | Clerc : Crépuscule |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 34 | Clerc : Forge |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 35 | Clerc : Tombe |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 36 | Druide : Cercle de la lune |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 37 | Druide : Cercle des astres |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 38 | Druide : Cercle du berger |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 39 | Druide : Cercle des fournaises |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 40 | Druide : Cercle des rêves |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.06 |
| 41 | Druide : Cercle des spores |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 42 | Ensorceleur : Magie sauvage |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 43 | Ensorceleur : Âme divine |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 44 | Ensorceleur : Âme mécanique |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 45 | Ensorceleur : Aberrance |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 46 | Ensorceleur : Magie des ombres |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 47 | Ensorceleur : Sorcellerie des tempêtes |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 48 | Guerrier : Maître de guerre |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 49 | Guerrier : Chevalier occulte |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 50 | Guerrier : Archer arcanique |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 51 | Guerrier : Cavalier |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 52 | Guerrier : Chevalier runique |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 53 | Guerrier : Samouraï |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 54 | Guerrier : Soldat psi |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 55 | Magicien : Abjuration |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 56 | Magicien : Divination |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 57 | Magicien : Enchantement |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 58 | Magicien : Illusion |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 59 | Magicien : Invocation |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 60 | Magicien : Nécromancie |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 61 | Magicien : Transmutation |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 62 | Magicien : Chantelames |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 63 | Magicien : Magie de guerre |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.06 |
| 64 | Magicien : Scribes |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.06 |
| 65 | Moine : Voie de l'ombre |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 66 | Moine : Voie des quatre éléments |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 67 | Moine : Voie de l'âme solaire |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 68 | Moine : Voie de l'astre intérieur |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 69 | Moine : Voie de la miséricorde |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 70 | Moine : Voie du dragon ascendant |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 71 | Moine : Voie du kensei |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 72 | Moine : Voie du maître ivre |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 73 | Occultiste : Archifée |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 74 | Occultiste : Grand Ancien |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 75 | Occultiste : Céleste |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 76 | Occultiste : Génie - Dao |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 77 | Occultiste : Génie - Djinn |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 78 | Occultiste : Génie - Éfrit |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 79 | Occultiste : Génie - Maride |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 80 | Occultiste : Insondable |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 81 | Occultiste : Lame maudite |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 82 | Occultiste : Mort-vivant |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 83 | Paladin : Serment de dévotion |  | (pas de colonne) | SRD mais texte non conforme | SRD 5.1 (homonyme 2024 au SRD 5.2) | nom, description (1 phrase) | flaveur maison | 0.00 |
| 84 | Paladin : Serment de vengeance |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 85 | Paladin : Serment de conquête |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 86 | Paladin : Serment de gloire |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 87 | Paladin : Serment des guetteurs |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 88 | Paladin : Serment de rédemption |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 89 | Rôdeur : Maître des bêtes |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 90 | Rôdeur : Arpenteur de l'horizon |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 91 | Rôdeur : Gardien de drake |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 92 | Rôdeur : Gardien des nuées |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 93 | Rôdeur : Traqueur des ténèbres |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 94 | Rôdeur : Tueur de monstres |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 95 | Rôdeur : Vagabond féerique |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 96 | Roublard : Assassin |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 97 | Roublard : Escroc arcanique |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 98 | Roublard : Âme acérée |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 99 | Roublard : Bretteur |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 100 | Roublard : Conspirateur |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 101 | Roublard : Éclaireur |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 102 | Roublard : Enquêteur |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 103 | Roublard : Phantôme |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 104 | Clerc : Arcanes |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 105 | Clerc : Mort |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 106 | Clerc : Ordre |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.04 |
| 107 | Clerc : Paix |  | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 108 | Barbare : Berserker ancestral | Path of the Battlerager | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 109 | Moine : Voie de la longue mort | Way of the Long Death | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 110 | Occultiste : Immortel | The Undying | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 111 | Guerrier : Chevalier dragon pourpre | Purple Dragon Knight (Banneret) | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 112 | Paladin : Serment de la couronne | Oath of the Crown | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 113 | Paladin : Parjure | Oathbreaker | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 114 | Ensorceleur : Sorcellerie lunaire | Lunar Sorcery | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 115 | Magicien : Chronurgie | Chronurgy Magic | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 116 | Magicien : Graviturgie | Graviturgy Magic | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 117 | Guerrier : Chevalier de l'écho | Echo Knight | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 118 | Artificier : Alchimiste | Alchemist | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 119 | Artificier : Armurier | Armorer | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 120 | Artificier : Artilleur | Artillerist | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |
| 121 | Artificier : Forgeron de guerre | Battle Smith | (pas de colonne) | hors SRD |  | nom, description (1 phrase) | flaveur maison | 0.00 |

</details>

### 2.7 Aptitudes de sous-classe (802)

Classification héritée de la sous-classe. Aptitudes des 12 sous-classes SRD : traduction/reformulation non officielle (14 proches du texte officiel). Aptitudes hors SRD : reformulations maison (brouillon du lot 4 relu par le chef de projet, puis lots suivants).

Répartition : SRD 5.1 14, SRD mais texte non conforme 91, hors SRD 697.

<details><summary>Tableau complet (802 lignes)</summary>

| id | Élément (propriétaire / niveau / aptitude) | Nom EN | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. | Provenance |
|---|---|---|---|---|---|---|---|---|
| 46 | Barbare : Voie du Berserker / niv. 3 / Fureur sauvage |  | SRD mais texte non conforme | SRD 5.1 | nom, description (167 car.) | traduction/reformulation non officielle | 0.08 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 47 | Barde : Collège du Savoir / niv. 3 / Coupure de savoir |  | SRD mais texte non conforme | SRD 5.1 | nom, description (175 car.) | traduction/reformulation non officielle | 0.19 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 48 | Clerc : Domaine de la Vie / niv. 1 / Disciple de la vie |  | SRD mais texte non conforme | SRD 5.1 | nom, description (67 car.) | traduction/reformulation non officielle | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 49 | Druide : Cercle de la Terre / niv. 2 / Incantation circonstancielle |  | SRD mais texte non conforme | SRD 5.1 | nom, description (119 car.) | traduction/reformulation non officielle | 0.06 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 50 | Guerrier : Champion / niv. 3 / Critique amélioré |  | SRD mais texte non conforme | SRD 5.1 | nom, description (83 car.) | traduction/reformulation non officielle | 0.54 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 51 | Moine : Voie de la Main Ouverte / niv. 3 / Technique de la main ouverte |  | SRD mais texte non conforme | SRD 5.1 | nom, description (123 car.) | traduction/reformulation non officielle | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 52 | Paladin : Serment des Anciens / niv. 3 / Châtiment de la nature |  | hors SRD |  | nom, description (95 car.) | reformulation maison | 0.08 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 53 | Rôdeur : Chasseur / niv. 3 / Proie du chasseur |  | SRD mais texte non conforme | SRD 5.1 | nom, description (87 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 54 | Roublard : Voleur / niv. 3 / Doigts agiles |  | SRD mais texte non conforme | SRD 5.1 | nom, description (94 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 55 | Occultiste : Protecteur Fiélon / niv. 1 / Résilience sombre |  | SRD mais texte non conforme | SRD 5.1 | nom, description (105 car.) | traduction/reformulation non officielle | 0.57 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 56 | Magicien : École de l'évocation / niv. 2 / Sculpteur de sorts |  | SRD mais texte non conforme | SRD 5.1 | nom, description (112 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 57 | Ensorceleur : Lignage draconique / niv. 1 / Résilience draconique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (142 car.) | traduction/reformulation non officielle | 0.20 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 58 | Barbare : Guerrier totem / niv. 3 / Esprit totémique |  | hors SRD |  | nom, description (154 car.) | reformulation maison | 0.10 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 59 | Barbare : Bête / niv. 3 / Forme de la bête |  | hors SRD |  | nom, description (149 car.) | reformulation maison | 0.14 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 60 | Barbare : Gardien ancestral / niv. 3 / Gardiens ancestraux |  | hors SRD |  | nom, description (210 car.) | reformulation maison | 0.06 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 61 | Barbare : Géant / niv. 3 / Ravages du géant |  | hors SRD |  | nom, description (181 car.) | reformulation maison | 0.10 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 62 | Barbare : Héraut des tempêtes / niv. 3 / Aura de tempête |  | hors SRD |  | nom, description (201 car.) | reformulation maison | 0.03 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 63 | Barbare : Magie sauvage / niv. 3 / Sursaut de magie sauvage |  | hors SRD |  | nom, description (168 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 64 | Barbare : Zélote / niv. 3 / Fureur divine |  | hors SRD |  | nom, description (187 car.) | reformulation maison | 0.08 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 65 | Barde : Collège de la vaillance / niv. 3 / Inspiration au combat |  | hors SRD |  | nom, description (141 car.) | reformulation maison | 0.15 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 66 | Barde : Collège de l'éloquence / niv. 3 / Langue d'argent |  | hors SRD |  | nom, description (214 car.) | reformulation maison | 0.03 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 67 | Barde : Collège de la création / niv. 3 / Performance de la création |  | hors SRD |  | nom, description (120 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 68 | Barde : Collège de la séduction / niv. 3 / Manteau d'inspiration |  | hors SRD |  | nom, description (148 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 69 | Barde : Collège des épées / niv. 3 / Fioriture de lame |  | hors SRD |  | nom, description (195 car.) | reformulation maison | 0.08 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 70 | Barde : Collège des esprits / niv. 3 / Contes d'outre-tombe |  | hors SRD |  | nom, description (164 car.) | reformulation maison | 0.05 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 71 | Barde : Collège des murmures / niv. 3 / Lames psychiques |  | hors SRD |  | nom, description (203 car.) | reformulation maison | 0.15 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 72 | Clerc : Duperie / niv. 1 / Bénédiction du trompeur |  | hors SRD |  | nom, description (126 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 73 | Clerc : Guerre / niv. 1 / Prêtre guerrier |  | hors SRD |  | nom, description (137 car.) | reformulation maison | 0.22 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 74 | Clerc : Lumière / niv. 1 / Éclat de mise en garde |  | hors SRD |  | nom, description (160 car.) | reformulation maison | 0.09 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 75 | Clerc : Nature / niv. 1 / Acolyte de la nature |  | hors SRD |  | nom, description (143 car.) | reformulation maison | 0.05 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 76 | Clerc : Savoir / niv. 1 / Bénédictions de la connaissance |  | hors SRD |  | nom, description (143 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 77 | Clerc : Tempête / niv. 1 / Courroux de la tempête |  | hors SRD |  | nom, description (125 car.) | reformulation maison | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 78 | Clerc : Crépuscule / niv. 1 / Vision de la nuit |  | hors SRD |  | nom, description (127 car.) | reformulation maison | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 79 | Clerc : Forge / niv. 1 / Bénédiction de la forge |  | hors SRD |  | nom, description (144 car.) | reformulation maison | 0.24 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 80 | Clerc : Tombe / niv. 1 / Cercle de mortalité |  | hors SRD |  | nom, description (113 car.) | reformulation maison | 0.25 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 81 | Druide : Cercle de la lune / niv. 2 / Forme sauvage de combat |  | hors SRD |  | nom, description (137 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 82 | Druide : Cercle des astres / niv. 2 / Forme astrale |  | hors SRD |  | nom, description (208 car.) | reformulation maison | 0.04 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 83 | Druide : Cercle du berger / niv. 2 / Totem spirituel |  | hors SRD |  | nom, description (135 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 84 | Druide : Cercle des fournaises / niv. 2 / Esprit de la fournaise |  | hors SRD |  | nom, description (143 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 85 | Druide : Cercle des rêves / niv. 2 / Baume de la Cour d'été |  | hors SRD |  | nom, description (149 car.) | reformulation maison | 0.05 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 86 | Druide : Cercle des spores / niv. 2 / Entité symbiotique |  | hors SRD |  | nom, description (168 car.) | reformulation maison | 0.04 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 87 | Ensorceleur : Magie sauvage / niv. 1 / Marées du chaos |  | hors SRD |  | nom, description (165 car.) | reformulation maison | 0.04 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 88 | Ensorceleur : Âme divine / niv. 1 / Favorisé des dieux |  | hors SRD |  | nom, description (132 car.) | reformulation maison | 0.05 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 89 | Ensorceleur : Âme mécanique / niv. 1 / Rétablir l'équilibre |  | hors SRD |  | nom, description (134 car.) | reformulation maison | 0.06 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 90 | Ensorceleur : Aberrance / niv. 1 / Parole télépathique |  | hors SRD |  | nom, description (139 car.) | reformulation maison | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 91 | Ensorceleur : Magie des ombres / niv. 1 / Regard des ténèbres |  | hors SRD |  | nom, description (119 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 92 | Ensorceleur : Sorcellerie des tempêtes / niv. 1 / Magie tempétueuse |  | hors SRD |  | nom, description (136 car.) | reformulation maison | 0.26 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 93 | Guerrier : Maître de guerre / niv. 3 / Supériorité au combat |  | hors SRD |  | nom, description (173 car.) | reformulation maison | 0.10 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 94 | Guerrier : Chevalier occulte / niv. 3 / Incantation martiale |  | hors SRD |  | nom, description (186 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 95 | Guerrier : Archer arcanique / niv. 3 / Tir arcanique |  | hors SRD |  | nom, description (133 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 96 | Guerrier : Cavalier / niv. 3 / Marque inébranlable |  | hors SRD |  | nom, description (160 car.) | reformulation maison | 0.04 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 97 | Guerrier : Chevalier runique / niv. 3 / Gravure runique |  | hors SRD |  | nom, description (171 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 98 | Guerrier : Samouraï / niv. 3 / Détermination martiale |  | hors SRD |  | nom, description (172 car.) | reformulation maison | 0.09 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 99 | Guerrier : Soldat psi / niv. 3 / Énergie psionique |  | hors SRD |  | nom, description (187 car.) | reformulation maison | 0.08 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 100 | Magicien : Abjuration / niv. 2 / Rempart arcanique |  | hors SRD |  | nom, description (127 car.) | reformulation maison | 0.22 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 101 | Magicien : Divination / niv. 2 / Présage |  | hors SRD |  | nom, description (185 car.) | reformulation maison | 0.07 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 102 | Magicien : Enchantement / niv. 2 / Regard hypnotique |  | hors SRD |  | nom, description (106 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 103 | Magicien : Illusion / niv. 2 / Illusion mineure améliorée |  | hors SRD |  | nom, description (141 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 104 | Magicien : Invocation / niv. 2 / Invocation mineure |  | hors SRD |  | nom, description (203 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 105 | Magicien : Nécromancie / niv. 2 / Moisson funeste |  | hors SRD |  | nom, description (141 car.) | reformulation maison | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 106 | Magicien : Transmutation / niv. 2 / Pierre du transmutateur |  | hors SRD |  | nom, description (155 car.) | reformulation maison | 0.18 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 107 | Magicien : Chantelames / niv. 2 / Chant des lames |  | hors SRD |  | nom, description (175 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 108 | Magicien : Magie de guerre / niv. 2 / Déviation arcanique |  | hors SRD |  | nom, description (197 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 109 | Magicien : Scribes / niv. 2 / Grimoire éveillé |  | hors SRD |  | nom, description (160 car.) | reformulation maison | 0.04 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 110 | Moine : Voie de l'ombre / niv. 3 / Arts de l'ombre |  | hors SRD |  | nom, description (144 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 111 | Moine : Voie des quatre éléments / niv. 3 / Disciplines élémentaires |  | hors SRD |  | nom, description (164 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 112 | Moine : Voie de l'âme solaire / niv. 3 / Rayon d'âme solaire |  | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.08 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 113 | Moine : Voie de l'astre intérieur / niv. 3 / Bras de l'astral |  | hors SRD |  | nom, description (181 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 114 | Moine : Voie de la miséricorde / niv. 3 / Mains de miséricorde |  | hors SRD |  | nom, description (137 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 115 | Moine : Voie du dragon ascendant / niv. 3 / Souffle du dragon ascendant |  | hors SRD |  | nom, description (140 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 116 | Moine : Voie du kensei / niv. 3 / Armes du kensei |  | hors SRD |  | nom, description (146 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 117 | Moine : Voie du maître ivre / niv. 3 / Technique du maître ivre |  | hors SRD |  | nom, description (159 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 118 | Occultiste : Archifée / niv. 1 / Présence féerique |  | hors SRD |  | nom, description (105 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 119 | Occultiste : Grand Ancien / niv. 1 / Esprit éveillé |  | hors SRD |  | nom, description (118 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 120 | Occultiste : Céleste / niv. 1 / Lumière curative |  | hors SRD |  | nom, description (114 car.) | reformulation maison | 0.20 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 121 | Occultiste : Génie - Dao / niv. 1 / Vase du génie |  | hors SRD |  | nom, description (160 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 122 | Occultiste : Génie - Djinn / niv. 1 / Vase du génie |  | hors SRD |  | nom, description (160 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 123 | Occultiste : Génie - Éfrit / niv. 1 / Vase du génie |  | hors SRD |  | nom, description (166 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 124 | Occultiste : Génie - Maride / niv. 1 / Vase du génie |  | hors SRD |  | nom, description (162 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 125 | Occultiste : Insondable / niv. 1 / Tentacule des profondeurs |  | hors SRD |  | nom, description (97 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 126 | Occultiste : Lame maudite / niv. 1 / Malédiction de la lame maudite |  | hors SRD |  | nom, description (149 car.) | reformulation maison | 0.05 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 127 | Occultiste : Mort-vivant / niv. 1 / Parmi les morts |  | hors SRD |  | nom, description (144 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 128 | Paladin : Serment de dévotion / niv. 3 / Arme sacrée |  | SRD mais texte non conforme | SRD 5.1 | nom, description (139 car.) | traduction/reformulation non officielle | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 129 | Paladin : Serment de vengeance / niv. 3 / Vœu d'inimitié |  | hors SRD |  | nom, description (116 car.) | reformulation maison | 0.13 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 130 | Paladin : Serment de conquête / niv. 3 / Présence conquérante |  | hors SRD |  | nom, description (103 car.) | reformulation maison | 0.08 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 131 | Paladin : Serment de gloire / niv. 3 / Athlète accompli |  | hors SRD |  | nom, description (130 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 132 | Paladin : Serment des guetteurs / niv. 3 / Volonté du guetteur |  | hors SRD |  | nom, description (143 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 133 | Paladin : Serment de rédemption / niv. 3 / Émissaire de la paix |  | hors SRD |  | nom, description (118 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 134 | Rôdeur : Maître des bêtes / niv. 3 / Compagnon animal |  | hors SRD |  | nom, description (112 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 135 | Rôdeur : Arpenteur de l'horizon / niv. 3 / Guerrier planaire |  | hors SRD |  | nom, description (175 car.) | reformulation maison | 0.11 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 136 | Rôdeur : Gardien de drake / niv. 3 / Compagnon drake |  | hors SRD |  | nom, description (108 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 137 | Rôdeur : Gardien des nuées / niv. 3 / Nuée rassemblée |  | hors SRD |  | nom, description (166 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 138 | Rôdeur : Traqueur des ténèbres / niv. 3 / Embusqueur redoutable |  | hors SRD |  | nom, description (152 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 139 | Rôdeur : Tueur de monstres / niv. 3 / Sens du chasseur de monstres |  | hors SRD |  | nom, description (118 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 140 | Rôdeur : Vagabond féerique / niv. 3 / Frappes funestes |  | hors SRD |  | nom, description (167 car.) | reformulation maison | 0.17 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 141 | Roublard : Assassin / niv. 3 / Assassinat |  | hors SRD |  | nom, description (189 car.) | reformulation maison | 0.14 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 142 | Roublard : Escroc arcanique / niv. 3 / Ruse de la main magique |  | hors SRD |  | nom, description (147 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 143 | Roublard : Âme acérée / niv. 3 / Lames psychiques |  | hors SRD |  | nom, description (122 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 144 | Roublard : Bretteur / niv. 3 / Audace effrontée |  | hors SRD |  | nom, description (203 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 145 | Roublard : Conspirateur / niv. 3 / Maître des tactiques |  | hors SRD |  | nom, description (121 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 146 | Roublard : Éclaireur / niv. 3 / Instinct d'éclaireur |  | hors SRD |  | nom, description (142 car.) | reformulation maison | 0.05 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 147 | Roublard : Enquêteur / niv. 3 / Œil du détail |  | hors SRD |  | nom, description (123 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 148 | Roublard : Phantôme / niv. 3 / Murmures des morts |  | hors SRD |  | nom, description (169 car.) | reformulation maison | 0.00 | phase 1 / lot 3 (aptitude « signature », reformulée) |
| 315 | Barbare : Voie du Berserker / niv. 6 / Rage aveugle |  | SRD mais texte non conforme | SRD 5.1 | nom, description (201 car.) | traduction/reformulation non officielle | 0.33 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 316 | Barbare : Voie du Berserker / niv. 10 / Présence intimidante |  | SRD mais texte non conforme | SRD 5.1 | nom, description (819 car.) | traduction/reformulation non officielle | 0.29 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 317 | Barbare : Voie du Berserker / niv. 14 / Représailles |  | SRD mais texte non conforme | SRD 5.1 | nom, description (216 car.) | traduction/reformulation non officielle | 0.43 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 318 | Barde : Collège du Savoir / niv. 3 / Maîtrises supplémentaires |  | SRD mais texte non conforme | SRD 5.1 | nom, description (117 car.) | traduction/reformulation non officielle | 0.50 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 319 | Barde : Collège du Savoir / niv. 6 / Secrets magiques supplémentaires |  | SRD mais texte non conforme | SRD 5.1 | nom, description (334 car.) | traduction/reformulation non officielle | 0.26 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 320 | Barde : Collège du Savoir / niv. 14 / Compétence hors-pair |  | SRD mais texte non conforme | SRD 5.1 | nom, description (378 car.) | traduction/reformulation non officielle | 0.31 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 321 | Clerc : Domaine de la Vie / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (56 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 322 | Clerc : Domaine de la Vie / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (78 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 323 | Clerc : Domaine de la Vie / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (69 car.) | traduction/reformulation non officielle | 0.38 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 324 | Clerc : Domaine de la Vie / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (82 car.) | traduction/reformulation non officielle | 0.44 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 325 | Clerc : Domaine de la Vie / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (70 car.) | traduction/reformulation non officielle | 0.38 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 326 | Clerc : Domaine de la Vie / niv. 1 / Maîtrise supplémentaire |  | SRD mais texte non conforme | SRD 5.1 | nom, description (93 car.) | traduction/reformulation non officielle | 0.27 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 327 | Clerc : Domaine de la Vie / niv. 2 / Conduit divin : préservation de la vie |  | SRD mais texte non conforme | SRD 5.1 | nom, description (534 car.) | traduction/reformulation non officielle | 0.20 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 328 | Clerc : Domaine de la Vie / niv. 6 / Guérisseur béni |  | SRD mais texte non conforme | SRD 5.1 | nom, description (289 car.) | traduction/reformulation non officielle | 0.49 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 329 | Clerc : Domaine de la Vie / niv. 8 / Frappe divine |  | SRD mais texte non conforme | SRD 5.1 | nom, description (314 car.) | traduction/reformulation non officielle | 0.45 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 330 | Clerc : Domaine de la Vie / niv. 17 / Guérison suprême |  | SRD mais texte non conforme | SRD 5.1 | nom, description (262 car.) | traduction/reformulation non officielle | 0.19 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 331 | Druide : Cercle de la Terre / niv. 2 / Sort mineur supplémentaire |  | SRD mais texte non conforme | SRD 5.1 | nom, description (208 car.) | traduction/reformulation non officielle | 0.44 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 332 | Druide : Cercle de la Terre / niv. 2 / Récupération naturelle |  | SRD mais texte non conforme | SRD 5.1 | nom, description (741 car.) | traduction/reformulation non officielle | 0.37 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 333 | Druide : Cercle de la Terre / niv. 3 / Sorts de cercle - Terrain : Arctique (Niveau de druide 3) |  | SRD 5.1 | SRD 5.1 | nom, description (48 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 334 | Druide : Cercle de la Terre / niv. 5 / Sorts de cercle - Terrain : Arctique (Niveau de druide 5) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (26 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 335 | Druide : Cercle de la Terre / niv. 7 / Sorts de cercle - Terrain : Arctique (Niveau de druide 7) |  | SRD 5.1 | SRD 5.1 | nom, description (39 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 336 | Druide : Cercle de la Terre / niv. 9 / Sorts de cercle - Terrain : Arctique (Niveau de druide 9) |  | SRD 5.1 | SRD 5.1 | nom, description (40 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 337 | Druide : Cercle de la Terre / niv. 3 / Sorts de cercle - Terrain : Désert (Niveau de druide 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (14 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 338 | Druide : Cercle de la Terre / niv. 5 / Sorts de cercle - Terrain : Désert (Niveau de druide 5) |  | SRD 5.1 | SRD 5.1 | nom, description (63 car.) | proche du SRD FR officiel | 0.67 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 339 | Druide : Cercle de la Terre / niv. 7 / Sorts de cercle - Terrain : Désert (Niveau de druide 7) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (38 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 340 | Druide : Cercle de la Terre / niv. 9 / Sorts de cercle - Terrain : Désert (Niveau de druide 9) |  | SRD 5.1 | SRD 5.1 | nom, description (32 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 341 | Druide : Cercle de la Terre / niv. 3 / Sorts de cercle - Terrain : Forêt (Niveau de druide 3) |  | SRD 5.1 | SRD 5.1 | nom, description (33 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 342 | Druide : Cercle de la Terre / niv. 5 / Sorts de cercle - Terrain : Forêt (Niveau de druide 5) |  | SRD 5.1 | SRD 5.1 | nom, description (40 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 343 | Druide : Cercle de la Terre / niv. 7 / Sorts de cercle - Terrain : Forêt (Niveau de druide 7) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (33 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 344 | Druide : Cercle de la Terre / niv. 9 / Sorts de cercle - Terrain : Forêt (Niveau de druide 9) |  | SRD 5.1 | SRD 5.1 | nom, description (49 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 345 | Druide : Cercle de la Terre / niv. 3 / Sorts de cercle - Terrain : Littoral (Niveau de druide 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (30 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 346 | Druide : Cercle de la Terre / niv. 5 / Sorts de cercle - Terrain : Littoral (Niveau de druide 5) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (40 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 347 | Druide : Cercle de la Terre / niv. 7 / Sorts de cercle - Terrain : Littoral (Niveau de druide 7) |  | SRD 5.1 | SRD 5.1 | nom, description (40 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 348 | Druide : Cercle de la Terre / niv. 9 / Sorts de cercle - Terrain : Littoral (Niveau de druide 9) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (37 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 349 | Druide : Cercle de la Terre / niv. 3 / Sorts de cercle - Terrain : Marais (Niveau de druide 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (31 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 350 | Druide : Cercle de la Terre / niv. 5 / Sorts de cercle - Terrain : Marais (Niveau de druide 5) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (35 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 351 | Druide : Cercle de la Terre / niv. 7 / Sorts de cercle - Terrain : Marais (Niveau de druide 7) |  | SRD 5.1 | SRD 5.1 | nom, description (47 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 352 | Druide : Cercle de la Terre / niv. 9 / Sorts de cercle - Terrain : Marais (Niveau de druide 9) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (29 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 353 | Druide : Cercle de la Terre / niv. 3 / Sorts de cercle - Terrain : Montagne (Niveau de druide 3) |  | SRD 5.1 | SRD 5.1 | nom, description (39 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 354 | Druide : Cercle de la Terre / niv. 5 / Sorts de cercle - Terrain : Montagne (Niveau de druide 5) |  | SRD 5.1 | SRD 5.1 | nom, description (30 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 355 | Druide : Cercle de la Terre / niv. 7 / Sorts de cercle - Terrain : Montagne (Niveau de druide 7) |  | SRD 5.1 | SRD 5.1 | nom, description (39 car.) | proche du SRD FR officiel | 1.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 356 | Druide : Cercle de la Terre / niv. 9 / Sorts de cercle - Terrain : Montagne (Niveau de druide 9) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (30 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 357 | Druide : Cercle de la Terre / niv. 3 / Sorts de cercle - Terrain : Outreterre (Niveau de druide 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (36 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 358 | Druide : Cercle de la Terre / niv. 5 / Sorts de cercle - Terrain : Outreterre (Niveau de druide 5) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (32 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 359 | Druide : Cercle de la Terre / niv. 7 / Sorts de cercle - Terrain : Outreterre (Niveau de druide 7) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (48 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 360 | Druide : Cercle de la Terre / niv. 9 / Sorts de cercle - Terrain : Outreterre (Niveau de druide 9) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (33 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 361 | Druide : Cercle de la Terre / niv. 3 / Sorts de cercle - Terrain : Plaine (Niveau de druide 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (33 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 362 | Druide : Cercle de la Terre / niv. 5 / Sorts de cercle - Terrain : Plaine (Niveau de druide 5) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (22 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 363 | Druide : Cercle de la Terre / niv. 7 / Sorts de cercle - Terrain : Plaine (Niveau de druide 7) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (33 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 364 | Druide : Cercle de la Terre / niv. 9 / Sorts de cercle - Terrain : Plaine (Niveau de druide 9) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (24 car.) | traduction/reformulation non officielle |  | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 365 | Druide : Cercle de la Terre / niv. 6 / Foulée tellurique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (500 car.) | traduction/reformulation non officielle | 0.38 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 366 | Druide : Cercle de la Terre / niv. 10 / Protégé de dame Nature |  | SRD mais texte non conforme | SRD 5.1 | nom, description (171 car.) | traduction/reformulation non officielle | 0.35 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 367 | Druide : Cercle de la Terre / niv. 14 / Sanctuaire de dame Nature |  | SRD mais texte non conforme | SRD 5.1 | nom, description (577 car.) | traduction/reformulation non officielle | 0.37 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 368 | Ensorceleur : Lignage draconique / niv. 1 / Ancêtre draconique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (524 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 369 | Ensorceleur : Lignage draconique / niv. 6 / Affinité élémentaire |  | SRD 5.1 | SRD 5.1 | nom, description (324 car.) | proche du SRD FR officiel | 0.66 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 370 | Ensorceleur : Lignage draconique / niv. 14 / Ailes draconiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (547 car.) | traduction/reformulation non officielle | 0.20 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 371 | Ensorceleur : Lignage draconique / niv. 18 / Présence draconique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (778 car.) | traduction/reformulation non officielle | 0.34 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 372 | Guerrier : Champion / niv. 7 / Athlète accompli |  | SRD mais texte non conforme | SRD 5.1 | nom, description (374 car.) | traduction/reformulation non officielle | 0.32 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 373 | Guerrier : Champion / niv. 10 / Style de combat supplémentaire |  | SRD mais texte non conforme | SRD 5.1 | nom, description (90 car.) | traduction/reformulation non officielle | 0.17 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 374 | Guerrier : Champion / niv. 15 / Critique supérieur |  | SRD mais texte non conforme | SRD 5.1 | nom, description (126 car.) | traduction/reformulation non officielle | 0.19 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 375 | Guerrier : Champion / niv. 18 / Survivant |  | SRD mais texte non conforme | SRD 5.1 | nom, description (278 car.) | traduction/reformulation non officielle | 0.58 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 376 | Magicien : École de l'évocation / niv. 2 / Évocateur érudit |  | SRD mais texte non conforme | SRD 5.1 | nom, description (127 car.) | traduction/reformulation non officielle | 0.10 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 377 | Magicien : École de l'évocation / niv. 6 / Sort mineur puissant |  | SRD mais texte non conforme | SRD 5.1 | nom, description (317 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 378 | Magicien : École de l'évocation / niv. 10 / Évocation améliorée |  | SRD mais texte non conforme | SRD 5.1 | nom, description (157 car.) | traduction/reformulation non officielle | 0.36 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 379 | Magicien : École de l'évocation / niv. 14 / Surcharge magique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (703 car.) | traduction/reformulation non officielle | 0.47 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 380 | Moine : Voie de la Main Ouverte / niv. 6 / Plénitude physique |  | SRD mais texte non conforme | SRD 5.1 | nom, description (256 car.) | traduction/reformulation non officielle | 0.39 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 381 | Moine : Voie de la Main Ouverte / niv. 11 / Tranquillité |  | SRD mais texte non conforme | SRD 5.1 | nom, description (408 car.) | traduction/reformulation non officielle | 0.51 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 382 | Moine : Voie de la Main Ouverte / niv. 17 / Paume frémissante |  | SRD mais texte non conforme | SRD 5.1 | nom, description (875 car.) | traduction/reformulation non officielle | 0.28 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 383 | Occultiste : Protecteur Fiélon / niv. 1 / Liste de sorts étendue (Niveau de sort 1) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (160 car.) | traduction/reformulation non officielle | 0.05 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 384 | Occultiste : Protecteur Fiélon / niv. 3 / Liste de sorts étendue (Niveau de sort 2) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (161 car.) | traduction/reformulation non officielle | 0.04 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 385 | Occultiste : Protecteur Fiélon / niv. 5 / Liste de sorts étendue (Niveau de sort 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (163 car.) | traduction/reformulation non officielle | 0.08 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 386 | Occultiste : Protecteur Fiélon / niv. 7 / Liste de sorts étendue (Niveau de sort 4) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (160 car.) | traduction/reformulation non officielle | 0.12 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 387 | Occultiste : Protecteur Fiélon / niv. 9 / Liste de sorts étendue (Niveau de sort 5) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (166 car.) | traduction/reformulation non officielle | 0.04 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 388 | Occultiste : Protecteur Fiélon / niv. 6 / Chance du ténébreux |  | SRD mais texte non conforme | SRD 5.1 | nom, description (502 car.) | traduction/reformulation non officielle | 0.32 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 389 | Occultiste : Protecteur Fiélon / niv. 10 / Résistance fiélonne |  | SRD mais texte non conforme | SRD 5.1 | nom, description (317 car.) | traduction/reformulation non officielle | 0.54 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 390 | Occultiste : Protecteur Fiélon / niv. 14 / Traversée des enfers |  | SRD mais texte non conforme | SRD 5.1 | nom, description (608 car.) | traduction/reformulation non officielle | 0.39 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 391 | Paladin : Serment de dévotion / niv. 3 / Préceptes de dévotion |  | SRD mais texte non conforme | SRD 5.1 | nom, description (732 car.) | traduction/reformulation non officielle | 0.01 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 392 | Paladin : Serment de dévotion / niv. 3 / Sorts de serment (Niveau de paladin 3) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (85 car.) | traduction/reformulation non officielle | 0.44 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 393 | Paladin : Serment de dévotion / niv. 5 / Sorts de serment (Niveau de paladin 5) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (76 car.) | traduction/reformulation non officielle | 0.17 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 394 | Paladin : Serment de dévotion / niv. 9 / Sorts de serment (Niveau de paladin 9) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (77 car.) | traduction/reformulation non officielle | 0.38 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 395 | Paladin : Serment de dévotion / niv. 13 / Sorts de serment (Niveau de paladin 13) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (77 car.) | traduction/reformulation non officielle | 0.38 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 396 | Paladin : Serment de dévotion / niv. 17 / Sorts de serment (Niveau de paladin 17) |  | SRD mais texte non conforme | SRD 5.1 | nom, description (66 car.) | traduction/reformulation non officielle | 0.00 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 397 | Paladin : Serment de dévotion / niv. 3 / Conduit divin |  | SRD mais texte non conforme | SRD 5.1 | nom, description (1542 car.) | traduction/reformulation non officielle | 0.21 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 398 | Paladin : Serment de dévotion / niv. 7 / Aura de dévotion |  | SRD mais texte non conforme | SRD 5.1 | nom, description (189 car.) | traduction/reformulation non officielle | 0.18 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 399 | Paladin : Serment de dévotion / niv. 15 / Pureté de l'esprit |  | SRD mais texte non conforme | SRD 5.1 | nom, description (110 car.) | traduction/reformulation non officielle | 0.37 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 400 | Paladin : Serment de dévotion / niv. 20 / Nimbe sacré |  | SRD mais texte non conforme | SRD 5.1 | nom, description (598 car.) | traduction/reformulation non officielle | 0.26 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 401 | Rôdeur : Chasseur / niv. 7 / Tactiques défensives |  | SRD mais texte non conforme | SRD 5.1 | nom, description (467 car.) | traduction/reformulation non officielle | 0.34 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 402 | Rôdeur : Chasseur / niv. 11 / Attaques multiples |  | SRD mais texte non conforme | SRD 5.1 | nom, description (616 car.) | traduction/reformulation non officielle | 0.14 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 403 | Rôdeur : Chasseur / niv. 15 / Défense du chasseur supérieure |  | SRD mais texte non conforme | SRD 5.1 | nom, description (933 car.) | traduction/reformulation non officielle | 0.25 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 404 | Roublard : Voleur / niv. 3 / Monte-en-l'air |  | SRD mais texte non conforme | SRD 5.1 | nom, description (306 car.) | traduction/reformulation non officielle | 0.19 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 405 | Roublard : Voleur / niv. 9 / Discrétion suprême |  | SRD mais texte non conforme | SRD 5.1 | nom, description (173 car.) | traduction/reformulation non officielle | 0.50 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 406 | Roublard : Voleur / niv. 13 / Utilisation d'objets magiques |  | SRD mais texte non conforme | SRD 5.1 | nom, description (246 car.) | traduction/reformulation non officielle | 0.39 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 407 | Roublard : Voleur / niv. 17 / Réflexes de voleur |  | SRD mais texte non conforme | SRD 5.1 | nom, description (267 car.) | traduction/reformulation non officielle | 0.38 | fichier croisé aidedd / 5e-bits / Open5e, licence « srd_cc_by » |
| 408 | Barbare : Guerrier totem / niv. 3 / Quêteur spirituel |  | hors SRD |  | nom, description (123 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 409 | Barbare : Guerrier totem / niv. 3 / Esprit totem |  | hors SRD |  | nom, description (348 car.) | reformulation maison | 0.14 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 410 | Barbare : Guerrier totem / niv. 6 / Aspect de la bête |  | hors SRD |  | nom, description (378 car.) | reformulation maison | 0.07 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 411 | Barbare : Guerrier totem / niv. 10 / Marcheur spirituel |  | hors SRD |  | nom, description (192 car.) | reformulation maison | 0.03 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 412 | Barbare : Guerrier totem / niv. 14 / Lien totémique |  | hors SRD |  | nom, description (305 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 413 | Barbare : Magie sauvage / niv. 3 / Sens de la magie |  | hors SRD |  | nom, description (138 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 414 | Barbare : Magie sauvage / niv. 3 / Sursaut sauvage |  | hors SRD |  | nom, description (171 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 415 | Barbare : Magie sauvage / niv. 6 / Réserve de magie |  | hors SRD |  | nom, description (170 car.) | reformulation maison | 0.07 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 416 | Barbare : Magie sauvage / niv. 10 / Réaction instable |  | hors SRD |  | nom, description (169 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 417 | Barbare : Magie sauvage / niv. 14 / Sursaut contrôlé |  | hors SRD |  | nom, description (115 car.) | reformulation maison | 0.06 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 418 | Barde : Collège de la vaillance / niv. 3 / Maîtrises supplémentaires |  | hors SRD |  | nom, description (89 car.) | reformulation maison | 0.10 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 419 | Barde : Collège de la vaillance / niv. 3 / Inspiration martiale |  | hors SRD |  | nom, description (150 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 420 | Barde : Collège de la vaillance / niv. 6 / Attaque supplémentaire |  | hors SRD |  | nom, description (109 car.) | reformulation maison | 0.56 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 421 | Barde : Collège de la vaillance / niv. 14 / Magie de combat |  | hors SRD |  | nom, description (127 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 422 | Clerc : Duperie / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (66 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 423 | Clerc : Duperie / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (70 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 424 | Clerc : Duperie / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (75 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 425 | Clerc : Duperie / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (72 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 426 | Clerc : Duperie / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (85 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 427 | Clerc : Duperie / niv. 1 / Bénédiction de l'escroc |  | hors SRD |  | nom, description (205 car.) | reformulation maison | 0.14 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 428 | Clerc : Duperie / niv. 2 / Conduit divin : invocation de réplique |  | hors SRD |  | nom, description (142 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 429 | Clerc : Duperie / niv. 6 / Conduit divin : linceul d'ombre |  | hors SRD |  | nom, description (171 car.) | reformulation maison | 0.28 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 430 | Clerc : Duperie / niv. 8 / Frappe divine |  | hors SRD |  | nom, description (110 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 431 | Clerc : Duperie / niv. 17 / Réplique améliorée |  | hors SRD |  | nom, description (167 car.) | reformulation maison | 0.05 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 432 | Clerc : Guerre / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (71 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 433 | Clerc : Guerre / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (68 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 434 | Clerc : Guerre / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (70 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 435 | Clerc : Guerre / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (74 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 436 | Clerc : Guerre / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (82 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 437 | Clerc : Guerre / niv. 1 / Maîtrises supplémentaires |  | hors SRD |  | nom, description (67 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 438 | Clerc : Guerre / niv. 1 / Prêtre de guerre |  | hors SRD |  | nom, description (205 car.) | reformulation maison | 0.34 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 439 | Clerc : Guerre / niv. 2 / Conduit divin : frappe guidée |  | hors SRD |  | nom, description (161 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 440 | Clerc : Guerre / niv. 6 / Conduit divin : bénédiction du dieu de la guerre |  | hors SRD |  | nom, description (142 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 441 | Clerc : Guerre / niv. 8 / Frappe divine |  | hors SRD |  | nom, description (128 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 442 | Clerc : Guerre / niv. 17 / Avatar de bataille |  | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.36 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 443 | Clerc : Lumière / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (65 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 444 | Clerc : Lumière / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (65 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 445 | Clerc : Lumière / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (67 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 446 | Clerc : Lumière / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (67 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 447 | Clerc : Lumière / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (67 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 448 | Clerc : Lumière / niv. 1 / Sort mineur supplémentaire |  | hors SRD |  | nom, description (87 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 449 | Clerc : Lumière / niv. 1 / Illumination protectrice |  | hors SRD |  | nom, description (126 car.) | reformulation maison | 0.10 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 450 | Clerc : Lumière / niv. 2 / Conduit divin : radiance de l'aube |  | hors SRD |  | nom, description (189 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 451 | Clerc : Lumière / niv. 6 / Illumination améliorée |  | hors SRD |  | nom, description (109 car.) | reformulation maison | 0.15 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 452 | Clerc : Lumière / niv. 8 / Incantation puissante |  | hors SRD |  | nom, description (89 car.) | reformulation maison | 0.40 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 453 | Clerc : Lumière / niv. 17 / Halo de lumière |  | hors SRD |  | nom, description (142 car.) | reformulation maison | 0.24 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 454 | Clerc : Nature / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (86 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 455 | Clerc : Nature / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (72 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 456 | Clerc : Nature / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (70 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 457 | Clerc : Nature / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (69 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 458 | Clerc : Nature / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (78 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 459 | Clerc : Nature / niv. 1 / Maîtrise supplémentaire |  | hors SRD |  | nom, description (44 car.) | reformulation maison | 0.33 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 460 | Clerc : Nature / niv. 2 / Conduit divin : charme des animaux et des plantes |  | hors SRD |  | nom, description (187 car.) | reformulation maison | 0.18 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 461 | Clerc : Nature / niv. 6 / Atténuation des éléments |  | hors SRD |  | nom, description (121 car.) | reformulation maison | 0.18 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 462 | Clerc : Nature / niv. 8 / Frappe divine |  | hors SRD |  | nom, description (162 car.) | reformulation maison | 0.08 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 463 | Clerc : Nature / niv. 17 / Maître de la nature |  | hors SRD |  | nom, description (177 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 464 | Clerc : Savoir / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (64 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 465 | Clerc : Savoir / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (56 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 466 | Clerc : Savoir / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (81 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 467 | Clerc : Savoir / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (61 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 468 | Clerc : Savoir / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (68 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 469 | Clerc : Savoir / niv. 1 / Bénédictions du savoir |  | hors SRD |  | nom, description (150 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 470 | Clerc : Savoir / niv. 2 / Conduit divin : savoir ancestral |  | hors SRD |  | nom, description (168 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 471 | Clerc : Savoir / niv. 6 / Conduit divin : lecture des pensées |  | hors SRD |  | nom, description (215 car.) | reformulation maison | 0.07 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 472 | Clerc : Savoir / niv. 8 / Incantation puissante |  | hors SRD |  | nom, description (89 car.) | reformulation maison | 0.40 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 473 | Clerc : Savoir / niv. 17 / Visions du passé |  | hors SRD |  | nom, description (141 car.) | reformulation maison | 0.14 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 474 | Clerc : Tempête / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (73 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 475 | Clerc : Tempête / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (62 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 476 | Clerc : Tempête / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (74 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 477 | Clerc : Tempête / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (73 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 478 | Clerc : Tempête / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (74 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 479 | Clerc : Tempête / niv. 1 / Maîtrises supplémentaires |  | hors SRD |  | nom, description (67 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 480 | Clerc : Tempête / niv. 1 / Fureur de l'ouragan |  | hors SRD |  | nom, description (134 car.) | reformulation maison | 0.28 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 481 | Clerc : Tempête / niv. 2 / Conduit divin : fureur destructrice |  | hors SRD |  | nom, description (125 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 482 | Clerc : Tempête / niv. 6 / Frappe de l'éclair |  | hors SRD |  | nom, description (138 car.) | reformulation maison | 0.26 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 483 | Clerc : Tempête / niv. 8 / Frappe divine |  | hors SRD |  | nom, description (112 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 484 | Clerc : Tempête / niv. 17 / Enfant de la tempête |  | hors SRD |  | nom, description (155 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 485 | Clerc : Forge / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (73 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 486 | Clerc : Forge / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (65 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 487 | Clerc : Forge / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (85 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 488 | Clerc : Forge / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (61 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 489 | Clerc : Forge / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (66 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 490 | Clerc : Forge / niv. 1 / Maîtrises supplémentaires |  | hors SRD |  | nom, description (70 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 491 | Clerc : Forge / niv. 2 / Conduit divin : bénédiction de l'artisan |  | hors SRD |  | nom, description (161 car.) | reformulation maison | 0.24 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 492 | Clerc : Forge / niv. 6 / Âme de la forge |  | hors SRD |  | nom, description (191 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 493 | Clerc : Forge / niv. 8 / Frappe divine |  | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 494 | Clerc : Forge / niv. 17 / Saint de la forge et du feu |  | hors SRD |  | nom, description (146 car.) | reformulation maison | 0.26 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 495 | Druide : Cercle de la lune / niv. 2 / Formes du cercle |  | hors SRD |  | nom, description (163 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 496 | Druide : Cercle de la lune / niv. 6 / Frappe primitive |  | hors SRD |  | nom, description (152 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 497 | Druide : Cercle de la lune / niv. 10 / Forme sauvage élémentaire |  | hors SRD |  | nom, description (120 car.) | reformulation maison | 0.06 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 498 | Druide : Cercle de la lune / niv. 14 / Mille formes |  | hors SRD |  | nom, description (97 car.) | reformulation maison | 0.42 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 499 | Ensorceleur : Magie sauvage / niv. 1 / Pic de magie sauvage |  | hors SRD |  | nom, description (173 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 500 | Ensorceleur : Magie sauvage / niv. 1 / Marée du chaos |  | hors SRD |  | nom, description (155 car.) | reformulation maison | 0.08 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 501 | Ensorceleur : Magie sauvage / niv. 6 / Chance forcée |  | hors SRD |  | nom, description (164 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 502 | Ensorceleur : Magie sauvage / niv. 14 / Chaos contrôlé |  | hors SRD |  | nom, description (125 car.) | reformulation maison | 0.06 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 503 | Ensorceleur : Magie sauvage / niv. 18 / Bombardement de sort |  | hors SRD |  | nom, description (201 car.) | reformulation maison | 0.03 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 504 | Guerrier : Maître de guerre / niv. 3 / Disciple martial |  | hors SRD |  | nom, description (112 car.) | reformulation maison | 0.07 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 505 | Guerrier : Maître de guerre / niv. 3 / Supériorité martiale |  | hors SRD |  | nom, description (168 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 506 | Guerrier : Maître de guerre / niv. 7 / Observation de l’ennemi |  | hors SRD |  | nom, description (208 car.) | reformulation maison | 0.08 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 507 | Guerrier : Maître de guerre / niv. 10 / Supériorité martiale améliorée |  | hors SRD |  | nom, description (64 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 508 | Guerrier : Maître de guerre / niv. 15 / Implacable |  | hors SRD |  | nom, description (144 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 509 | Guerrier : Maître de guerre / niv. 3 / Manœuvres |  | hors SRD |  | nom, description (253 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 510 | Guerrier : Chevalier occulte / niv. 3 / Incantation |  | hors SRD |  | nom, description (231 car.) | reformulation maison | 0.06 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 511 | Guerrier : Chevalier occulte / niv. 3 / Lien avec une arme |  | hors SRD |  | nom, description (203 car.) | reformulation maison | 0.21 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 512 | Guerrier : Chevalier occulte / niv. 7 / Magie de guerre |  | hors SRD |  | nom, description (121 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 513 | Guerrier : Chevalier occulte / niv. 10 / Frappe occulte |  | hors SRD |  | nom, description (234 car.) | reformulation maison | 0.33 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 514 | Guerrier : Chevalier occulte / niv. 15 / Charge arcanique |  | hors SRD |  | nom, description (155 car.) | reformulation maison | 0.10 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 515 | Guerrier : Chevalier occulte / niv. 18 / Magie de guerre améliorée |  | hors SRD |  | nom, description (130 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 516 | Magicien : Abjuration / niv. 2 / Abjurateur érudit |  | hors SRD |  | nom, description (105 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 517 | Magicien : Abjuration / niv. 2 / Protection arcanique |  | hors SRD |  | nom, description (204 car.) | reformulation maison | 0.09 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 518 | Magicien : Abjuration / niv. 6 / Protection projetée |  | hors SRD |  | nom, description (153 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 519 | Magicien : Abjuration / niv. 10 / Abjuration améliorée |  | hors SRD |  | nom, description (180 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 520 | Magicien : Abjuration / niv. 14 / Résistance aux sorts |  | hors SRD |  | nom, description (140 car.) | reformulation maison | 0.40 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 521 | Magicien : Divination / niv. 2 / Devin érudit |  | hors SRD |  | nom, description (106 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 522 | Magicien : Divination / niv. 6 / Divination experte |  | hors SRD |  | nom, description (146 car.) | reformulation maison | 0.24 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 523 | Magicien : Divination / niv. 10 / Troisième œil |  | hors SRD |  | nom, description (184 car.) | reformulation maison | 0.14 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 524 | Magicien : Divination / niv. 14 / Présage supérieur |  | hors SRD |  | nom, description (109 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 525 | Magicien : Enchantement / niv. 2 / Enchanteur érudit |  | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 526 | Magicien : Enchantement / niv. 6 / Charme instinctif |  | hors SRD |  | nom, description (180 car.) | reformulation maison | 0.03 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 527 | Magicien : Enchantement / niv. 10 / Partage d'enchantement |  | hors SRD |  | nom, description (136 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 528 | Magicien : Enchantement / niv. 14 / Altération mémorielle |  | hors SRD |  | nom, description (115 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 529 | Magicien : Illusion / niv. 2 / Illusionniste érudit |  | hors SRD |  | nom, description (103 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 530 | Magicien : Illusion / niv. 6 / Illusions malléables |  | hors SRD |  | nom, description (125 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 531 | Magicien : Illusion / niv. 10 / Double illusoire |  | hors SRD |  | nom, description (169 car.) | reformulation maison | 0.07 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 532 | Magicien : Illusion / niv. 14 / Réalité illusoire |  | hors SRD |  | nom, description (121 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 533 | Magicien : Invocation / niv. 2 / Invocateur érudit |  | hors SRD |  | nom, description (105 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 534 | Magicien : Invocation / niv. 6 / Permutation |  | hors SRD |  | nom, description (159 car.) | reformulation maison | 0.08 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 535 | Magicien : Invocation / niv. 10 / Invocation consciencieuse |  | hors SRD |  | nom, description (120 car.) | reformulation maison | 0.18 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 536 | Magicien : Invocation / niv. 14 / Convocations coriaces |  | hors SRD |  | nom, description (117 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 537 | Magicien : Nécromancie / niv. 2 / Nécromancien érudit |  | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 538 | Magicien : Nécromancie / niv. 2 / Sinistre moisson |  | hors SRD |  | nom, description (197 car.) | reformulation maison | 0.18 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 539 | Magicien : Nécromancie / niv. 6 / Serviteurs morts-vivants |  | hors SRD |  | nom, description (166 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 540 | Magicien : Nécromancie / niv. 10 / Insensibilité à la non-vie |  | hors SRD |  | nom, description (138 car.) | reformulation maison | 0.25 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 541 | Magicien : Nécromancie / niv. 14 / Contrôle des morts-vivants |  | hors SRD |  | nom, description (164 car.) | reformulation maison | 0.18 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 542 | Magicien : Transmutation / niv. 2 / Transmutateur érudit |  | hors SRD |  | nom, description (109 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 543 | Magicien : Transmutation / niv. 2 / Alchimie mineure |  | hors SRD |  | nom, description (135 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 544 | Magicien : Transmutation / niv. 6 / Pierre du transmutateur |  | hors SRD |  | nom, description (186 car.) | reformulation maison | 0.18 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 545 | Magicien : Transmutation / niv. 10 / Métamorphe |  | hors SRD |  | nom, description (129 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 546 | Magicien : Transmutation / niv. 14 / Maître transmutateur |  | hors SRD |  | nom, description (165 car.) | reformulation maison | 0.14 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 547 | Moine : Voie de l'ombre / niv. 3 / Arts des ombres |  | hors SRD |  | nom, description (140 car.) | reformulation maison | 0.16 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 548 | Moine : Voie de l'ombre / niv. 6 / Foulée d'ombre |  | hors SRD |  | nom, description (163 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 549 | Moine : Voie de l'ombre / niv. 11 / Linceul d'ombre |  | hors SRD |  | nom, description (147 car.) | reformulation maison | 0.32 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 550 | Moine : Voie de l'ombre / niv. 17 / Opportuniste |  | hors SRD |  | nom, description (151 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 551 | Moine : Voie des quatre éléments / niv. 3 / Disciple des éléments |  | hors SRD |  | nom, description (199 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 552 | Moine : Voie des quatre éléments / niv. 17 / Disciplines élémentaires |  | hors SRD |  | nom, description (193 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 553 | Occultiste : Archifée / niv. 1 / Liste de sorts étendue (Niveau de sort 1) |  | hors SRD |  | nom, description (152 car.) | reformulation maison | 0.05 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 554 | Occultiste : Archifée / niv. 3 / Liste de sorts étendue (Niveau de sort 2) |  | hors SRD |  | nom, description (179 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 555 | Occultiste : Archifée / niv. 5 / Liste de sorts étendue (Niveau de sort 3) |  | hors SRD |  | nom, description (166 car.) | reformulation maison | 0.05 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 556 | Occultiste : Archifée / niv. 7 / Liste de sorts étendue (Niveau de sort 4) |  | hors SRD |  | nom, description (176 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 557 | Occultiste : Archifée / niv. 9 / Liste de sorts étendue (Niveau de sort 5) |  | hors SRD |  | nom, description (176 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 558 | Occultiste : Archifée / niv. 6 / Échappatoire brumeuse |  | hors SRD |  | nom, description (155 car.) | reformulation maison | 0.24 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 559 | Occultiste : Archifée / niv. 10 / Défenses captivantes |  | hors SRD |  | nom, description (197 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 560 | Occultiste : Archifée / niv. 14 / Sombre délire |  | hors SRD |  | nom, description (138 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 561 | Occultiste : Grand Ancien / niv. 1 / Liste de sorts étendue (Niveau de sort 1) |  | hors SRD |  | nom, description (174 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 562 | Occultiste : Grand Ancien / niv. 3 / Liste de sorts étendue (Niveau de sort 2) |  | hors SRD |  | nom, description (177 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 563 | Occultiste : Grand Ancien / niv. 5 / Liste de sorts étendue (Niveau de sort 3) |  | hors SRD |  | nom, description (171 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 564 | Occultiste : Grand Ancien / niv. 7 / Liste de sorts étendue (Niveau de sort 4) |  | hors SRD |  | nom, description (177 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 565 | Occultiste : Grand Ancien / niv. 9 / Liste de sorts étendue (Niveau de sort 5) |  | hors SRD |  | nom, description (168 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 566 | Occultiste : Grand Ancien / niv. 6 / Protection entropique |  | hors SRD |  | nom, description (176 car.) | reformulation maison | 0.08 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 567 | Occultiste : Grand Ancien / niv. 10 / Bouclier mental |  | hors SRD |  | nom, description (174 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 568 | Occultiste : Grand Ancien / niv. 14 / Asservissement |  | hors SRD |  | nom, description (161 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 569 | Occultiste : Génie - Dao / niv. 1 / Liste de sorts étendue (Niveau de sort 1) |  | hors SRD |  | nom, description (172 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 570 | Occultiste : Génie - Djinn / niv. 1 / Liste de sorts étendue (Niveau de sort 1) |  | hors SRD |  | nom, description (176 car.) | reformulation maison | 0.15 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 571 | Occultiste : Génie - Éfrit / niv. 1 / Liste de sorts étendue (Niveau de sort 1) |  | hors SRD |  | nom, description (177 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 572 | Occultiste : Génie - Maride / niv. 1 / Liste de sorts étendue (Niveau de sort 1) |  | hors SRD |  | nom, description (181 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 573 | Occultiste : Génie - Dao / niv. 3 / Liste de sorts étendue (Niveau de sort 2) |  | hors SRD |  | nom, description (175 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 574 | Occultiste : Génie - Djinn / niv. 3 / Liste de sorts étendue (Niveau de sort 2) |  | hors SRD |  | nom, description (166 car.) | reformulation maison | 0.05 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 575 | Occultiste : Génie - Éfrit / niv. 3 / Liste de sorts étendue (Niveau de sort 2) |  | hors SRD |  | nom, description (168 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 576 | Occultiste : Génie - Maride / niv. 3 / Liste de sorts étendue (Niveau de sort 2) |  | hors SRD |  | nom, description (160 car.) | reformulation maison | 0.05 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 577 | Occultiste : Génie - Dao / niv. 5 / Liste de sorts étendue (Niveau de sort 3) |  | hors SRD |  | nom, description (187 car.) | reformulation maison | 0.10 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 578 | Occultiste : Génie - Djinn / niv. 5 / Liste de sorts étendue (Niveau de sort 3) |  | hors SRD |  | nom, description (177 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 579 | Occultiste : Génie - Éfrit / niv. 5 / Liste de sorts étendue (Niveau de sort 3) |  | hors SRD |  | nom, description (178 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 580 | Occultiste : Génie - Maride / niv. 5 / Liste de sorts étendue (Niveau de sort 3) |  | hors SRD |  | nom, description (182 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 581 | Occultiste : Génie - Dao / niv. 7 / Liste de sorts étendue (Niveau de sort 4) |  | hors SRD |  | nom, description (176 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 582 | Occultiste : Génie - Djinn / niv. 7 / Liste de sorts étendue (Niveau de sort 4) |  | hors SRD |  | nom, description (177 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 583 | Occultiste : Génie - Éfrit / niv. 7 / Liste de sorts étendue (Niveau de sort 4) |  | hors SRD |  | nom, description (169 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 584 | Occultiste : Génie - Maride / niv. 7 / Liste de sorts étendue (Niveau de sort 4) |  | hors SRD |  | nom, description (171 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 585 | Occultiste : Génie - Dao / niv. 9 / Liste de sorts étendue (Niveau de sort 5) |  | hors SRD |  | nom, description (156 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 586 | Occultiste : Génie - Djinn / niv. 9 / Liste de sorts étendue (Niveau de sort 5) |  | hors SRD |  | nom, description (162 car.) | reformulation maison | 0.05 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 587 | Occultiste : Génie - Éfrit / niv. 9 / Liste de sorts étendue (Niveau de sort 5) |  | hors SRD |  | nom, description (160 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 588 | Occultiste : Génie - Maride / niv. 9 / Liste de sorts étendue (Niveau de sort 5) |  | hors SRD |  | nom, description (156 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 589 | Occultiste : Génie - Dao / niv. 17 / Liste de sorts étendue (Niveau de sort 9) |  | hors SRD |  | nom, description (93 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 590 | Occultiste : Génie - Djinn / niv. 17 / Liste de sorts étendue (Niveau de sort 9) |  | hors SRD |  | nom, description (93 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 591 | Occultiste : Génie - Éfrit / niv. 17 / Liste de sorts étendue (Niveau de sort 9) |  | hors SRD |  | nom, description (93 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 592 | Occultiste : Génie - Maride / niv. 17 / Liste de sorts étendue (Niveau de sort 9) |  | hors SRD |  | nom, description (93 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 593 | Occultiste : Génie - Dao / niv. 1 / Catalyseur de Génie |  | hors SRD |  | nom, description (198 car.) | reformulation maison | 0.03 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 594 | Occultiste : Génie - Djinn / niv. 1 / Catalyseur de Génie |  | hors SRD |  | nom, description (198 car.) | reformulation maison | 0.03 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 595 | Occultiste : Génie - Éfrit / niv. 1 / Catalyseur de Génie |  | hors SRD |  | nom, description (198 car.) | reformulation maison | 0.03 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 596 | Occultiste : Génie - Maride / niv. 1 / Catalyseur de Génie |  | hors SRD |  | nom, description (198 car.) | reformulation maison | 0.03 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 597 | Occultiste : Génie - Dao / niv. 6 / Présent élémentaire |  | hors SRD |  | nom, description (149 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 598 | Occultiste : Génie - Djinn / niv. 6 / Présent élémentaire |  | hors SRD |  | nom, description (149 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 599 | Occultiste : Génie - Éfrit / niv. 6 / Présent élémentaire |  | hors SRD |  | nom, description (149 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 600 | Occultiste : Génie - Maride / niv. 6 / Présent élémentaire |  | hors SRD |  | nom, description (149 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 601 | Occultiste : Génie - Dao / niv. 10 / Sanctuaire du génie |  | hors SRD |  | nom, description (136 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 602 | Occultiste : Génie - Djinn / niv. 10 / Sanctuaire du génie |  | hors SRD |  | nom, description (136 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 603 | Occultiste : Génie - Éfrit / niv. 10 / Sanctuaire du génie |  | hors SRD |  | nom, description (136 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 604 | Occultiste : Génie - Maride / niv. 10 / Sanctuaire du génie |  | hors SRD |  | nom, description (136 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 605 | Occultiste : Génie - Dao / niv. 14 / Souhait limité |  | hors SRD |  | nom, description (118 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 606 | Occultiste : Génie - Djinn / niv. 14 / Souhait limité |  | hors SRD |  | nom, description (118 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 607 | Occultiste : Génie - Éfrit / niv. 14 / Souhait limité |  | hors SRD |  | nom, description (118 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 608 | Occultiste : Génie - Maride / niv. 14 / Souhait limité |  | hors SRD |  | nom, description (118 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 609 | Paladin : Serment des Anciens / niv. 3 / Préceptes des anciens |  | hors SRD |  | nom, description (133 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 610 | Paladin : Serment des Anciens / niv. 3 / Sorts de serment (Niveau de paladin 3) |  | hors SRD |  | nom, description (78 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 611 | Paladin : Serment des Anciens / niv. 5 / Sorts de serment (Niveau de paladin 5) |  | hors SRD |  | nom, description (68 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 612 | Paladin : Serment des Anciens / niv. 9 / Sorts de serment (Niveau de paladin 9) |  | hors SRD |  | nom, description (88 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 613 | Paladin : Serment des Anciens / niv. 13 / Sorts de serment (Niveau de paladin 13) |  | hors SRD |  | nom, description (70 car.) | reformulation maison | 0.29 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 614 | Paladin : Serment des Anciens / niv. 17 / Sorts de serment (Niveau de paladin 17) |  | hors SRD |  | nom, description (86 car.) | reformulation maison | 0.44 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 615 | Paladin : Serment des Anciens / niv. 3 / Conduit divin |  | hors SRD |  | nom, description (253 car.) | reformulation maison | 0.10 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 616 | Paladin : Serment des Anciens / niv. 7 / Aura de garde |  | hors SRD |  | nom, description (94 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 617 | Paladin : Serment des Anciens / niv. 15 / Sentinelle immortelle |  | hors SRD |  | nom, description (165 car.) | reformulation maison | 0.30 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 618 | Paladin : Serment des Anciens / niv. 20 / Champion antique |  | hors SRD |  | nom, description (172 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 619 | Paladin : Serment de vengeance / niv. 3 / Préceptes de vengeance |  | hors SRD |  | nom, description (120 car.) | reformulation maison | 0.06 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 620 | Paladin : Serment de vengeance / niv. 3 / Sorts de serment (Niveau de paladin 3) |  | hors SRD |  | nom, description (69 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 621 | Paladin : Serment de vengeance / niv. 5 / Sorts de serment (Niveau de paladin 5) |  | hors SRD |  | nom, description (81 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 622 | Paladin : Serment de vengeance / niv. 9 / Sorts de serment (Niveau de paladin 9) |  | hors SRD |  | nom, description (73 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 623 | Paladin : Serment de vengeance / niv. 13 / Sorts de serment (Niveau de paladin 13) |  | hors SRD |  | nom, description (72 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 624 | Paladin : Serment de vengeance / niv. 17 / Sorts de serment (Niveau de paladin 17) |  | hors SRD |  | nom, description (75 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 625 | Paladin : Serment de vengeance / niv. 3 / Conduit divin |  | hors SRD |  | nom, description (266 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 626 | Paladin : Serment de vengeance / niv. 7 / Vengeur implacable |  | hors SRD |  | nom, description (220 car.) | reformulation maison | 0.06 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 627 | Paladin : Serment de vengeance / niv. 15 / Âme vengeresse |  | hors SRD |  | nom, description (171 car.) | reformulation maison | 0.29 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 628 | Paladin : Serment de vengeance / niv. 20 / Ange de la vengeance |  | hors SRD |  | nom, description (200 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 629 | Rôdeur : Maître des bêtes / niv. 3 / Compagnon du rôdeur |  | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 630 | Rôdeur : Maître des bêtes / niv. 7 / Entraînement exceptionnel |  | hors SRD |  | nom, description (151 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 631 | Rôdeur : Maître des bêtes / niv. 11 / Fureur bestiale |  | hors SRD |  | nom, description (117 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 632 | Rôdeur : Maître des bêtes / niv. 15 / Partage des sorts |  | hors SRD |  | nom, description (115 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 633 | Rôdeur : Gardien de drake / niv. 3 / Don draconique |  | hors SRD |  | nom, description (153 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 634 | Rôdeur : Gardien de drake / niv. 7 / Lien du croc et d'écailles |  | hors SRD |  | nom, description (132 car.) | reformulation maison | 0.09 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 635 | Rôdeur : Gardien de drake / niv. 11 / Souffle de drake |  | hors SRD |  | nom, description (179 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 636 | Rôdeur : Gardien de drake / niv. 15 / Lien parfait |  | hors SRD |  | nom, description (152 car.) | reformulation maison | 0.05 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 637 | Roublard : Assassin / niv. 3 / Maîtrises supplémentaires |  | hors SRD |  | nom, description (79 car.) | reformulation maison | 0.11 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 638 | Roublard : Assassin / niv. 9 / Expert en infiltration |  | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 639 | Roublard : Assassin / niv. 13 / Imposteur |  | hors SRD |  | nom, description (125 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 640 | Roublard : Assassin / niv. 17 / Frappe meurtrière |  | hors SRD |  | nom, description (210 car.) | reformulation maison | 0.30 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 641 | Roublard : Escroc arcanique / niv. 3 / Incantation |  | hors SRD |  | nom, description (222 car.) | reformulation maison | 0.07 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 642 | Roublard : Escroc arcanique / niv. 3 / Escamotage et main de mage |  | hors SRD |  | nom, description (170 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 643 | Roublard : Escroc arcanique / niv. 9 / Embuscade magique |  | hors SRD |  | nom, description (137 car.) | reformulation maison | 0.19 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 644 | Roublard : Escroc arcanique / niv. 13 / Escroc polyvalent |  | hors SRD |  | nom, description (145 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 645 | Roublard : Escroc arcanique / niv. 17 / Voleur de sort |  | hors SRD |  | nom, description (201 car.) | reformulation maison | 0.15 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 646 | Roublard : Conspirateur / niv. 3 / Maître des intrigues |  | hors SRD |  | nom, description (165 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 647 | Roublard : Conspirateur / niv. 9 / Manipulateur perspicace |  | hors SRD |  | nom, description (165 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 648 | Roublard : Conspirateur / niv. 13 / Redirection |  | hors SRD |  | nom, description (183 car.) | reformulation maison | 0.03 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 649 | Roublard : Conspirateur / niv. 17 / Âme de trompeur |  | hors SRD |  | nom, description (183 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 650 | Clerc : Arcanes / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (79 car.) | reformulation maison | 0.29 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 651 | Clerc : Arcanes / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (74 car.) | reformulation maison | 0.14 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 652 | Clerc : Arcanes / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (77 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 653 | Clerc : Arcanes / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (76 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 654 | Clerc : Arcanes / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (70 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 655 | Clerc : Arcanes / niv. 1 / Initié des arcanes |  | hors SRD |  | nom, description (166 car.) | reformulation maison | 0.21 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 656 | Clerc : Arcanes / niv. 2 / Conduit divin : abjuration arcanique |  | hors SRD |  | nom, description (418 car.) | reformulation maison | 0.28 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 657 | Clerc : Arcanes / niv. 6 / Briseur de sorts |  | hors SRD |  | nom, description (234 car.) | reformulation maison | 0.18 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 658 | Clerc : Arcanes / niv. 8 / Incantation puissante |  | hors SRD |  | nom, description (94 car.) | reformulation maison | 0.36 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 659 | Clerc : Arcanes / niv. 17 / Maîtrise des arcanes |  | hors SRD |  | nom, description (188 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 660 | Clerc : Mort / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (72 car.) | reformulation maison | 0.17 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 661 | Clerc : Mort / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (73 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 662 | Clerc : Mort / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (77 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 663 | Clerc : Mort / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (78 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 664 | Clerc : Mort / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (70 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 665 | Clerc : Mort / niv. 1 / Maîtrises supplémentaires |  | hors SRD |  | nom, description (44 car.) | reformulation maison | 0.50 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 666 | Clerc : Mort / niv. 1 / Faucheur |  | hors SRD |  | nom, description (265 car.) | reformulation maison | 0.15 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 667 | Clerc : Mort / niv. 2 / Conduit divin : toucher de la mort |  | hors SRD |  | nom, description (201 car.) | reformulation maison | 0.26 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 668 | Clerc : Mort / niv. 6 / Destruction inéluctable |  | hors SRD |  | nom, description (128 car.) | reformulation maison | 0.06 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 669 | Clerc : Mort / niv. 8 / Frappe divine |  | hors SRD |  | nom, description (112 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 670 | Clerc : Mort / niv. 17 / Faucheur amélioré |  | hors SRD |  | nom, description (247 car.) | reformulation maison | 0.22 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 671 | Clerc : Ordre / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (59 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 672 | Clerc : Ordre / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (80 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 673 | Clerc : Ordre / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (72 car.) | reformulation maison | 0.14 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 674 | Clerc : Ordre / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (74 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 675 | Clerc : Ordre / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (71 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 676 | Clerc : Ordre / niv. 1 / Maîtrises supplémentaires |  | hors SRD |  | nom, description (116 car.) | reformulation maison | 0.07 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 677 | Clerc : Ordre / niv. 1 / Voix de l'autorité |  | hors SRD |  | nom, description (210 car.) | reformulation maison | 0.20 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 678 | Clerc : Ordre / niv. 2 / Conduit divin : exigence de l'ordre |  | hors SRD |  | nom, description (374 car.) | reformulation maison | 0.29 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 679 | Clerc : Ordre / niv. 6 / Incarnation de la loi |  | hors SRD |  | nom, description (255 car.) | reformulation maison | 0.43 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 680 | Clerc : Ordre / niv. 8 / Frappe divine |  | hors SRD |  | nom, description (111 car.) | reformulation maison | 0.12 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 681 | Clerc : Ordre / niv. 17 / Courroux de l'ordre |  | hors SRD |  | nom, description (290 car.) | reformulation maison | 0.09 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 682 | Clerc : Paix / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (59 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 683 | Clerc : Paix / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (62 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 684 | Clerc : Paix / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (78 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 685 | Clerc : Paix / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (81 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 686 | Clerc : Paix / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (88 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 687 | Clerc : Paix / niv. 1 / Instrument de paix |  | hors SRD |  | nom, description (92 car.) | reformulation maison | 0.33 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 688 | Clerc : Paix / niv. 1 / Lien d'encouragement |  | hors SRD |  | nom, description (413 car.) | reformulation maison | 0.22 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 689 | Clerc : Paix / niv. 2 / Conduit divin : baume de paix |  | hors SRD |  | nom, description (309 car.) | reformulation maison | 0.10 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 690 | Clerc : Paix / niv. 6 / Lien protecteur |  | hors SRD |  | nom, description (212 car.) | reformulation maison | 0.08 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 691 | Clerc : Paix / niv. 8 / Incantation puissante |  | hors SRD |  | nom, description (94 car.) | reformulation maison | 0.36 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 692 | Clerc : Paix / niv. 17 / Lien étendu |  | hors SRD |  | nom, description (196 car.) | reformulation maison | 0.06 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 693 | Clerc : Crépuscule / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (57 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 694 | Clerc : Crépuscule / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (69 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 695 | Clerc : Crépuscule / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (79 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 696 | Clerc : Crépuscule / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (74 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 697 | Clerc : Crépuscule / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (73 car.) | reformulation maison | 0.00 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 698 | Clerc : Crépuscule / niv. 1 / Maîtrises supplémentaires |  | hors SRD |  | nom, description (67 car.) | reformulation maison | 0.38 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 699 | Clerc : Crépuscule / niv. 1 / Bénédiction vigilante |  | hors SRD |  | nom, description (168 car.) | reformulation maison | 0.04 | brouillon de reformulation (lot 4) ou domaines de clerc |
| 700 | Clerc : Crépuscule / niv. 2 / Conduit divin : sanctuaire crépusculaire |  | hors SRD |  | nom, description (385 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 701 | Clerc : Crépuscule / niv. 6 / Pas de la nuit |  | hors SRD |  | nom, description (244 car.) | reformulation maison | 0.34 | lot 5 (sous-classes, reformulé) |
| 702 | Clerc : Crépuscule / niv. 8 / Frappe divine |  | hors SRD |  | nom, description (109 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 703 | Clerc : Crépuscule / niv. 17 / Linceul crépusculaire |  | hors SRD |  | nom, description (124 car.) | reformulation maison | 0.41 | lot 5 (sous-classes, reformulé) |
| 704 | Clerc : Tombe / niv. 1 / Sorts de domaine (Niveau de clerc 1) |  | hors SRD |  | nom, description (67 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 705 | Clerc : Tombe / niv. 3 / Sorts de domaine (Niveau de clerc 3) |  | hors SRD |  | nom, description (81 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 706 | Clerc : Tombe / niv. 5 / Sorts de domaine (Niveau de clerc 5) |  | hors SRD |  | nom, description (73 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 707 | Clerc : Tombe / niv. 7 / Sorts de domaine (Niveau de clerc 7) |  | hors SRD |  | nom, description (78 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 708 | Clerc : Tombe / niv. 9 / Sorts de domaine (Niveau de clerc 9) |  | hors SRD |  | nom, description (71 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 709 | Clerc : Tombe / niv. 1 / Yeux de la tombe |  | hors SRD |  | nom, description (286 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 710 | Clerc : Tombe / niv. 2 / Conduit divin : chemin vers la tombe |  | hors SRD |  | nom, description (300 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 711 | Clerc : Tombe / niv. 6 / Sentinelle au seuil de la mort |  | hors SRD |  | nom, description (233 car.) | reformulation maison | 0.34 | lot 5 (sous-classes, reformulé) |
| 712 | Clerc : Tombe / niv. 8 / Incantation puissante |  | hors SRD |  | nom, description (94 car.) | reformulation maison | 0.36 | lot 5 (sous-classes, reformulé) |
| 713 | Clerc : Tombe / niv. 17 / Gardien des âmes |  | hors SRD |  | nom, description (268 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 714 | Barbare : Bête / niv. 6 / Âme bestiale | Bestial Soul | hors SRD |  | nom, description (404 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 715 | Barbare : Bête / niv. 10 / Fureur contagieuse | Infectious Fury | hors SRD |  | nom, description (402 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 716 | Barbare : Bête / niv. 14 / Appel de la chasse | Call the Hunt | hors SRD |  | nom, description (380 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 717 | Barbare : Gardien ancestral / niv. 6 / Bouclier spirituel | Spirit Shield | hors SRD |  | nom, description (181 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 718 | Barbare : Gardien ancestral / niv. 10 / Consulter les esprits | Consult the Spirits | hors SRD |  | nom, description (172 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 719 | Barbare : Gardien ancestral / niv. 14 / Ancêtres vengeurs | Vengeful Ancestors | hors SRD |  | nom, description (114 car.) | reformulation maison | 0.14 | lot 5 (sous-classes, reformulé) |
| 720 | Barbare : Géant / niv. 3 / Puissance du géant | Giant's Power | hors SRD |  | nom, description (132 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 721 | Barbare : Géant / niv. 6 / Tranchant élémentaire | Elemental Cleaver | hors SRD |  | nom, description (277 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 722 | Barbare : Géant / niv. 10 / Propulsion puissante | Mighty Impel | hors SRD |  | nom, description (283 car.) | reformulation maison | 0.28 | lot 5 (sous-classes, reformulé) |
| 723 | Barbare : Géant / niv. 14 / Colosse démiurgique | Demiurgic Colossus | hors SRD |  | nom, description (148 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 724 | Barbare : Héraut des tempêtes / niv. 6 / Âme de la tempête | Storm Soul | hors SRD |  | nom, description (361 car.) | reformulation maison | 0.02 | lot 5 (sous-classes, reformulé) |
| 725 | Barbare : Héraut des tempêtes / niv. 10 / Tempête protectrice | Shielding Storm | hors SRD |  | nom, description (111 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 726 | Barbare : Héraut des tempêtes / niv. 14 / Tempête déchaînée | Raging Storm | hors SRD |  | nom, description (533 car.) | reformulation maison | 0.22 | lot 5 (sous-classes, reformulé) |
| 727 | Barbare : Zélote / niv. 3 / Guerrier des dieux | Warrior of the Gods | hors SRD |  | nom, description (126 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 728 | Barbare : Zélote / niv. 6 / Concentration fanatique | Fanatical Focus | hors SRD |  | nom, description (115 car.) | reformulation maison | 0.35 | lot 5 (sous-classes, reformulé) |
| 729 | Barbare : Zélote / niv. 10 / Présence zélée | Zealous Presence | hors SRD |  | nom, description (189 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 730 | Barbare : Zélote / niv. 14 / Rage au-delà de la mort | Rage Beyond Death | hors SRD |  | nom, description (201 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 731 | Barde : Collège de l'éloquence / niv. 3 / Paroles troublantes | Unsettling Words | hors SRD |  | nom, description (231 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 732 | Barde : Collège de l'éloquence / niv. 6 / Inspiration infaillible | Unfailing Inspiration | hors SRD |  | nom, description (99 car.) | reformulation maison | 0.14 | lot 5 (sous-classes, reformulé) |
| 733 | Barde : Collège de l'éloquence / niv. 6 / Discours universel | Universal Speech | hors SRD |  | nom, description (220 car.) | reformulation maison | 0.14 | lot 5 (sous-classes, reformulé) |
| 734 | Barde : Collège de l'éloquence / niv. 14 / Inspiration contagieuse | Infectious Inspiration | hors SRD |  | nom, description (297 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 735 | Barde : Collège de la création / niv. 3 / Parcelle de potentiel | Mote of Potential | hors SRD |  | nom, description (486 car.) | reformulation maison | 0.18 | lot 5 (sous-classes, reformulé) |
| 736 | Barde : Collège de la création / niv. 6 / Performance animatrice | Animating Performance | hors SRD |  | nom, description (293 car.) | reformulation maison | 0.10 | lot 5 (sous-classes, reformulé) |
| 737 | Barde : Collège de la création / niv. 14 / Crescendo créatif | Creative Crescendo | hors SRD |  | nom, description (216 car.) | reformulation maison | 0.11 | lot 5 (sous-classes, reformulé) |
| 738 | Barde : Collège de la séduction / niv. 3 / Performance envoûtante | Enthralling Performance | hors SRD |  | nom, description (276 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 739 | Barde : Collège de la séduction / niv. 6 / Manteau de majesté | Mantle of Majesty | hors SRD |  | nom, description (251 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 740 | Barde : Collège de la séduction / niv. 14 / Majesté inébranlable | Unbreakable Majesty | hors SRD |  | nom, description (347 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 741 | Barde : Collège des épées / niv. 3 / Maîtrises supplémentaires | Bonus Proficiencies | hors SRD |  | nom, description (154 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 742 | Barde : Collège des épées / niv. 3 / Style de combat | Fighting Style | hors SRD |  | nom, description (50 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 743 | Barde : Collège des épées / niv. 6 / Attaque supplémentaire | Extra Attack | hors SRD |  | nom, description (104 car.) | reformulation maison | 0.64 | lot 5 (sous-classes, reformulé) |
| 744 | Barde : Collège des épées / niv. 14 / Fioriture de maître | Master's Flourish | hors SRD |  | nom, description (133 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 745 | Barde : Collège des esprits / niv. 3 / Murmures guides | Guiding Whispers | hors SRD |  | nom, description (69 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 746 | Barde : Collège des esprits / niv. 3 / Focaliseur spirituel | Spiritual Focus | hors SRD |  | nom, description (282 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 747 | Barde : Collège des esprits / niv. 6 / Séance spirite | Spirit Session | hors SRD |  | nom, description (322 car.) | reformulation maison | 0.02 | lot 5 (sous-classes, reformulé) |
| 748 | Barde : Collège des esprits / niv. 14 / Connexion mystique | Mystical Connection | hors SRD |  | nom, description (106 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 749 | Barde : Collège des murmures / niv. 3 / Mots de terreur | Words of Terror | hors SRD |  | nom, description (249 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 750 | Barde : Collège des murmures / niv. 6 / Manteau de murmures | Mantle of Whispers | hors SRD |  | nom, description (375 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 751 | Barde : Collège des murmures / niv. 14 / Savoir des ombres | Shadow Lore | hors SRD |  | nom, description (288 car.) | reformulation maison | 0.14 | lot 5 (sous-classes, reformulé) |
| 752 | Druide : Cercle des astres / niv. 2 / Carte stellaire | Star Map | hors SRD |  | nom, description (248 car.) | reformulation maison | 0.26 | lot 5 (sous-classes, reformulé) |
| 753 | Druide : Cercle des astres / niv. 6 / Présage cosmique | Cosmic Omen | hors SRD |  | nom, description (301 car.) | reformulation maison | 0.10 | lot 5 (sous-classes, reformulé) |
| 754 | Druide : Cercle des astres / niv. 10 / Constellations scintillantes | Twinkling Constellations | hors SRD |  | nom, description (231 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 755 | Druide : Cercle des astres / niv. 14 / Plein d'étoiles | Full of Stars | hors SRD |  | nom, description (120 car.) | reformulation maison | 0.36 | lot 5 (sous-classes, reformulé) |
| 756 | Druide : Cercle du berger / niv. 2 / Langage des bois | Speech of the Woods | hors SRD |  | nom, description (122 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 757 | Druide : Cercle du berger / niv. 6 / Invocateur puissant | Mighty Summoner | hors SRD |  | nom, description (164 car.) | reformulation maison | 0.04 | lot 5 (sous-classes, reformulé) |
| 758 | Druide : Cercle du berger / niv. 10 / Esprit gardien | Guardian Spirit | hors SRD |  | nom, description (172 car.) | reformulation maison | 0.37 | lot 5 (sous-classes, reformulé) |
| 759 | Druide : Cercle du berger / niv. 14 / Invocations fidèles | Faithful Summons | hors SRD |  | nom, description (256 car.) | reformulation maison | 0.14 | lot 5 (sous-classes, reformulé) |
| 760 | Druide : Cercle des fournaises / niv. 2 / Sorts du cercle des fournaises | Circle Spells | hors SRD |  | nom, description (235 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 761 | Druide : Cercle des fournaises / niv. 6 / Lien renforcé | Enhanced Bond | hors SRD |  | nom, description (242 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 762 | Druide : Cercle des fournaises / niv. 10 / Flammes cautérisantes | Cauterizing Flames | hors SRD |  | nom, description (416 car.) | reformulation maison | 0.10 | lot 5 (sous-classes, reformulé) |
| 763 | Druide : Cercle des fournaises / niv. 14 / Renaissance ardente | Blazing Revival | hors SRD |  | nom, description (212 car.) | reformulation maison | 0.39 | lot 5 (sous-classes, reformulé) |
| 764 | Druide : Cercle des rêves / niv. 6 / Foyer de lune et d'ombre | Hearth of Moonlight and Shadow | hors SRD |  | nom, description (233 car.) | reformulation maison | 0.30 | lot 5 (sous-classes, reformulé) |
| 765 | Druide : Cercle des rêves / niv. 10 / Chemins cachés | Hidden Paths | hors SRD |  | nom, description (272 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 766 | Druide : Cercle des rêves / niv. 14 / Marcheur des rêves | Walker in Dreams | hors SRD |  | nom, description (239 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 767 | Druide : Cercle des spores / niv. 2 / Sorts du cercle des spores | Circle Spells | hors SRD |  | nom, description (243 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 768 | Druide : Cercle des spores / niv. 2 / Halo de spores | Halo of Spores | hors SRD |  | nom, description (246 car.) | reformulation maison | 0.30 | lot 5 (sous-classes, reformulé) |
| 769 | Druide : Cercle des spores / niv. 6 / Infestation fongique | Fungal Infestation | hors SRD |  | nom, description (264 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 770 | Druide : Cercle des spores / niv. 10 / Propagation des spores | Spreading Spores | hors SRD |  | nom, description (268 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 771 | Druide : Cercle des spores / niv. 14 / Corps fongique | Fungal Body | hors SRD |  | nom, description (160 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 772 | Ensorceleur : Âme divine / niv. 1 / Magie divine | Divine Magic | hors SRD |  | nom, description (231 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 773 | Ensorceleur : Âme divine / niv. 6 / Guérison renforcée | Empowered Healing | hors SRD |  | nom, description (180 car.) | reformulation maison | 0.30 | lot 5 (sous-classes, reformulé) |
| 774 | Ensorceleur : Âme divine / niv. 14 / Forme angélique | Otherworldly Wings | hors SRD |  | nom, description (152 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 775 | Ensorceleur : Âme divine / niv. 18 / Rétablissement surnaturel | Unearthly Recovery | hors SRD |  | nom, description (165 car.) | reformulation maison | 0.25 | lot 5 (sous-classes, reformulé) |
| 776 | Ensorceleur : Âme mécanique / niv. 1 / Magie mécanique | Clockwork Magic | hors SRD |  | nom, description (424 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 777 | Ensorceleur : Âme mécanique / niv. 6 / Bastion de la loi | Bastion of Law | hors SRD |  | nom, description (280 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 778 | Ensorceleur : Âme mécanique / niv. 14 / Transe de l'ordre | Trance of Order | hors SRD |  | nom, description (256 car.) | reformulation maison | 0.02 | lot 5 (sous-classes, reformulé) |
| 779 | Ensorceleur : Âme mécanique / niv. 18 / Cavalcade mécanique | Clockwork Cavalcade | hors SRD |  | nom, description (297 car.) | reformulation maison | 0.10 | lot 5 (sous-classes, reformulé) |
| 780 | Ensorceleur : Aberrance / niv. 1 / Sorts psioniques | Psionic Spells | hors SRD |  | nom, description (436 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 781 | Ensorceleur : Aberrance / niv. 6 / Sorcellerie psionique | Psionic Sorcery | hors SRD |  | nom, description (178 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 782 | Ensorceleur : Aberrance / niv. 6 / Défenses psychiques | Psychic Defenses | hors SRD |  | nom, description (118 car.) | reformulation maison | 0.50 | lot 5 (sous-classes, reformulé) |
| 783 | Ensorceleur : Aberrance / niv. 14 / Révélation dans la chair | Revelation in Flesh | hors SRD |  | nom, description (342 car.) | reformulation maison | 0.11 | lot 5 (sous-classes, reformulé) |
| 784 | Ensorceleur : Aberrance / niv. 18 / Implosion déformante | Warping Implosion | hors SRD |  | nom, description (304 car.) | reformulation maison | 0.25 | lot 5 (sous-classes, reformulé) |
| 785 | Ensorceleur : Magie des ombres / niv. 1 / Force de la tombe | Strength of the Grave | hors SRD |  | nom, description (256 car.) | reformulation maison | 0.31 | lot 5 (sous-classes, reformulé) |
| 786 | Ensorceleur : Magie des ombres / niv. 6 / Molosse de mauvais augure | Hound of Ill Omen | hors SRD |  | nom, description (269 car.) | reformulation maison | 0.27 | lot 5 (sous-classes, reformulé) |
| 787 | Ensorceleur : Magie des ombres / niv. 14 / Marche des ombres | Shadow Walk | hors SRD |  | nom, description (191 car.) | reformulation maison | 0.23 | lot 5 (sous-classes, reformulé) |
| 788 | Ensorceleur : Magie des ombres / niv. 18 / Forme obscure | Umbral Form | hors SRD |  | nom, description (273 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 789 | Ensorceleur : Sorcellerie des tempêtes / niv. 1 / Voix du vent | Wind Speaker | hors SRD |  | nom, description (98 car.) | reformulation maison | 0.18 | lot 5 (sous-classes, reformulé) |
| 790 | Ensorceleur : Sorcellerie des tempêtes / niv. 6 / Cœur de la tempête | Heart of the Storm | hors SRD |  | nom, description (279 car.) | reformulation maison | 0.29 | lot 5 (sous-classes, reformulé) |
| 791 | Ensorceleur : Sorcellerie des tempêtes / niv. 6 / Guide des tempêtes | Storm Guide | hors SRD |  | nom, description (204 car.) | reformulation maison | 0.22 | lot 5 (sous-classes, reformulé) |
| 792 | Ensorceleur : Sorcellerie des tempêtes / niv. 14 / Furie de la tempête | Storm's Fury | hors SRD |  | nom, description (215 car.) | reformulation maison | 0.22 | lot 5 (sous-classes, reformulé) |
| 793 | Ensorceleur : Sorcellerie des tempêtes / niv. 18 / Âme du vent | Wind Soul | hors SRD |  | nom, description (307 car.) | reformulation maison | 0.17 | lot 5 (sous-classes, reformulé) |
| 794 | Guerrier : Archer arcanique / niv. 3 / Savoir de l'archer arcanique | Arcane Archer Lore | hors SRD |  | nom, description (111 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 795 | Guerrier : Archer arcanique / niv. 7 / Flèche magique | Magic Arrow | hors SRD |  | nom, description (126 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 796 | Guerrier : Archer arcanique / niv. 7 / Tir incurvé | Curving Shot | hors SRD |  | nom, description (186 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 797 | Guerrier : Archer arcanique / niv. 15 / Tir toujours prêt | Ever-Ready Shot | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.33 | lot 5 (sous-classes, reformulé) |
| 798 | Guerrier : Archer arcanique / niv. 18 / Tirs arcaniques améliorés | Arcane Shot Options | hors SRD |  | nom, description (113 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 799 | Guerrier : Cavalier / niv. 3 / Maîtrise supplémentaire | Bonus Proficiency | hors SRD |  | nom, description (132 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 800 | Guerrier : Cavalier / niv. 3 / Né en selle | Born to the Saddle | hors SRD |  | nom, description (210 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 801 | Guerrier : Cavalier / niv. 7 / Manœuvre protectrice | Warding Maneuver | hors SRD |  | nom, description (292 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 802 | Guerrier : Cavalier / niv. 10 / Tenir la ligne | Hold the Line | hors SRD |  | nom, description (185 car.) | reformulation maison | 0.26 | lot 5 (sous-classes, reformulé) |
| 803 | Guerrier : Cavalier / niv. 15 / Chargeur féroce | Ferocious Charger | hors SRD |  | nom, description (169 car.) | reformulation maison | 0.37 | lot 5 (sous-classes, reformulé) |
| 804 | Guerrier : Cavalier / niv. 18 / Défenseur vigilant | Vigilant Defender | hors SRD |  | nom, description (134 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 805 | Guerrier : Chevalier runique / niv. 3 / Maîtrises supplémentaires | Bonus Proficiencies | hors SRD |  | nom, description (71 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 806 | Guerrier : Chevalier runique / niv. 3 / Puissance du géant | Giant's Might | hors SRD |  | nom, description (296 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 807 | Guerrier : Chevalier runique / niv. 7 / Bouclier runique | Runic Shield | hors SRD |  | nom, description (253 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 808 | Guerrier : Chevalier runique / niv. 10 / Grande stature | Great Stature | hors SRD |  | nom, description (104 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 809 | Guerrier : Chevalier runique / niv. 15 / Maître des runes | Master of Runes | hors SRD |  | nom, description (76 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 810 | Guerrier : Chevalier runique / niv. 18 / Colosse runique | Runic Juggernaut | hors SRD |  | nom, description (128 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 811 | Guerrier : Samouraï / niv. 3 / Maîtrise supplémentaire | Bonus Proficiency | hors SRD |  | nom, description (122 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 812 | Guerrier : Samouraï / niv. 7 / Courtisan élégant | Elegant Courtier | hors SRD |  | nom, description (184 car.) | reformulation maison | 0.23 | lot 5 (sous-classes, reformulé) |
| 813 | Guerrier : Samouraï / niv. 10 / Esprit inépuisable | Tireless Spirit | hors SRD |  | nom, description (108 car.) | reformulation maison | 0.27 | lot 5 (sous-classes, reformulé) |
| 814 | Guerrier : Samouraï / niv. 15 / Frappe rapide | Rapid Strike | hors SRD |  | nom, description (195 car.) | reformulation maison | 0.44 | lot 5 (sous-classes, reformulé) |
| 815 | Guerrier : Samouraï / niv. 18 / Force avant la mort | Strength before Death | hors SRD |  | nom, description (231 car.) | reformulation maison | 0.23 | lot 5 (sous-classes, reformulé) |
| 816 | Guerrier : Soldat psi / niv. 7 / Adepte télékinétique | Telekinetic Adept | hors SRD |  | nom, description (373 car.) | reformulation maison | 0.22 | lot 5 (sous-classes, reformulé) |
| 817 | Guerrier : Soldat psi / niv. 10 / Esprit protégé | Guarded Mind | hors SRD |  | nom, description (183 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 818 | Guerrier : Soldat psi / niv. 15 / Rempart de force | Bulwark of Force | hors SRD |  | nom, description (219 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 819 | Guerrier : Soldat psi / niv. 18 / Maître télékinétique | Telekinetic Master | hors SRD |  | nom, description (274 car.) | reformulation maison | 0.17 | lot 5 (sous-classes, reformulé) |
| 820 | Magicien : Chantelames / niv. 2 / Entraînement à la guerre et au chant | Training in War and Song | hors SRD |  | nom, description (126 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 821 | Magicien : Chantelames / niv. 6 / Attaque supplémentaire | Extra Attack | hors SRD |  | nom, description (134 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 822 | Magicien : Chantelames / niv. 10 / Chant de défense | Song of Defense | hors SRD |  | nom, description (211 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 823 | Magicien : Chantelames / niv. 14 / Chant de victoire | Song of Victory | hors SRD |  | nom, description (153 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 824 | Magicien : Magie de guerre / niv. 2 / Esprit tactique | Tactical Wit | hors SRD |  | nom, description (71 car.) | reformulation maison | 0.14 | lot 5 (sous-classes, reformulé) |
| 825 | Magicien : Magie de guerre / niv. 6 / Afflux de puissance | Power Surge | hors SRD |  | nom, description (447 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 826 | Magicien : Magie de guerre / niv. 10 / Magie durable | Durable Magic | hors SRD |  | nom, description (117 car.) | reformulation maison | 0.52 | lot 5 (sous-classes, reformulé) |
| 827 | Magicien : Magie de guerre / niv. 14 / Linceul déflecteur | Deflecting Shroud | hors SRD |  | nom, description (174 car.) | reformulation maison | 0.41 | lot 5 (sous-classes, reformulé) |
| 828 | Magicien : Scribes / niv. 2 / Plume magique | Wizardly Quill | hors SRD |  | nom, description (258 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 829 | Magicien : Scribes / niv. 6 / Esprit manifesté | Manifest Mind | hors SRD |  | nom, description (347 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 830 | Magicien : Scribes / niv. 10 / Maître scribe | Master Scrivener | hors SRD |  | nom, description (299 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 831 | Magicien : Scribes / niv. 14 / Un avec le verbe | One with the Word | hors SRD |  | nom, description (408 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 832 | Moine : Voie de l'âme solaire / niv. 6 / Frappe en arc ardente | Searing Arc Strike | hors SRD |  | nom, description (252 car.) | reformulation maison | 0.31 | lot 5 (sous-classes, reformulé) |
| 833 | Moine : Voie de l'âme solaire / niv. 11 / Explosion solaire ardente | Searing Sunburst | hors SRD |  | nom, description (305 car.) | reformulation maison | 0.25 | lot 5 (sous-classes, reformulé) |
| 834 | Moine : Voie de l'âme solaire / niv. 17 / Bouclier solaire | Sun Shield | hors SRD |  | nom, description (279 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 835 | Moine : Voie de l'astre intérieur / niv. 6 / Visage du moi astral | Visage of the Astral Self | hors SRD |  | nom, description (283 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 836 | Moine : Voie de l'astre intérieur / niv. 11 / Corps du moi astral | Body of the Astral Self | hors SRD |  | nom, description (341 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 837 | Moine : Voie de l'astre intérieur / niv. 17 / Moi astral éveillé | Awakened Astral Self | hors SRD |  | nom, description (196 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 838 | Moine : Voie de la miséricorde / niv. 3 / Instruments de miséricorde | Implements of Mercy | hors SRD |  | nom, description (150 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 839 | Moine : Voie de la miséricorde / niv. 6 / Toucher du médecin | Physician's Touch | hors SRD |  | nom, description (235 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 840 | Moine : Voie de la miséricorde / niv. 11 / Déluge de soins et de souffrances | Flurry of Healing and Harm | hors SRD |  | nom, description (326 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 841 | Moine : Voie de la miséricorde / niv. 17 / Main de miséricorde ultime | Hand of Ultimate Mercy | hors SRD |  | nom, description (280 car.) | reformulation maison | 0.04 | lot 5 (sous-classes, reformulé) |
| 842 | Moine : Voie du dragon ascendant / niv. 3 / Disciple draconique | Draconic Disciple | hors SRD |  | nom, description (253 car.) | reformulation maison | 0.25 | lot 5 (sous-classes, reformulé) |
| 843 | Moine : Voie du dragon ascendant / niv. 6 / Ailes déployées | Wings Unfurled | hors SRD |  | nom, description (230 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 844 | Moine : Voie du dragon ascendant / niv. 11 / Aspect du wyrm | Aspect of the Wyrm | hors SRD |  | nom, description (425 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 845 | Moine : Voie du dragon ascendant / niv. 17 / Aspect ascendant | Ascendant Aspect | hors SRD |  | nom, description (496 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 846 | Moine : Voie du kensei / niv. 6 / Un avec la lame | One with the Blade | hors SRD |  | nom, description (225 car.) | reformulation maison | 0.11 | lot 5 (sous-classes, reformulé) |
| 847 | Moine : Voie du kensei / niv. 11 / Aiguiser la lame | Sharpen the Blade | hors SRD |  | nom, description (231 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 848 | Moine : Voie du kensei / niv. 17 / Précision infaillible | Unerring Accuracy | hors SRD |  | nom, description (111 car.) | reformulation maison | 0.58 | lot 5 (sous-classes, reformulé) |
| 849 | Moine : Voie du maître ivre / niv. 3 / Maîtrises supplémentaires | Bonus Proficiencies | hors SRD |  | nom, description (59 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 850 | Moine : Voie du maître ivre / niv. 6 / Démarche vacillante | Tipsy Sway | hors SRD |  | nom, description (267 car.) | reformulation maison | 0.23 | lot 5 (sous-classes, reformulé) |
| 851 | Moine : Voie du maître ivre / niv. 11 / Chance de l'ivrogne | Drunkard's Luck | hors SRD |  | nom, description (137 car.) | reformulation maison | 0.61 | lot 5 (sous-classes, reformulé) |
| 852 | Moine : Voie du maître ivre / niv. 17 / Frénésie éthylique | Intoxicated Frenzy | hors SRD |  | nom, description (148 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 853 | Occultiste : Céleste / niv. 1 / Liste de sorts étendue | Expanded Spell List | hors SRD |  | nom, description (271 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 854 | Occultiste : Céleste / niv. 1 / Sorts mineurs supplémentaires | Bonus Cantrips | hors SRD |  | nom, description (120 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 855 | Occultiste : Céleste / niv. 6 / Âme radieuse | Radiant Soul | hors SRD |  | nom, description (207 car.) | reformulation maison | 0.58 | lot 5 (sous-classes, reformulé) |
| 856 | Occultiste : Céleste / niv. 10 / Résistance céleste | Celestial Resilience | hors SRD |  | nom, description (256 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 857 | Occultiste : Céleste / niv. 14 / Vengeance ardente | Searing Vengeance | hors SRD |  | nom, description (302 car.) | reformulation maison | 0.23 | lot 5 (sous-classes, reformulé) |
| 858 | Occultiste : Insondable / niv. 1 / Liste de sorts étendue | Expanded Spell List | hors SRD |  | nom, description (313 car.) | reformulation maison | 0.02 | lot 5 (sous-classes, reformulé) |
| 859 | Occultiste : Insondable / niv. 1 / Don de la mer | Gift of the Sea | hors SRD |  | nom, description (71 car.) | reformulation maison | 0.55 | lot 5 (sous-classes, reformulé) |
| 860 | Occultiste : Insondable / niv. 6 / Âme océanique | Oceanic Soul | hors SRD |  | nom, description (178 car.) | reformulation maison | 0.17 | lot 5 (sous-classes, reformulé) |
| 861 | Occultiste : Insondable / niv. 6 / Anneau protecteur | Guardian Coil | hors SRD |  | nom, description (185 car.) | reformulation maison | 0.17 | lot 5 (sous-classes, reformulé) |
| 862 | Occultiste : Insondable / niv. 10 / Tentacules agrippants | Grasping Tentacles | hors SRD |  | nom, description (289 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 863 | Occultiste : Insondable / niv. 14 / Plongeon insondable | Fathomless Plunge | hors SRD |  | nom, description (232 car.) | reformulation maison | 0.04 | lot 5 (sous-classes, reformulé) |
| 864 | Occultiste : Lame maudite / niv. 1 / Liste de sorts étendue | Expanded Spell List | hors SRD |  | nom, description (277 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 865 | Occultiste : Lame maudite / niv. 1 / Guerrier maléfique | Hex Warrior | hors SRD |  | nom, description (330 car.) | reformulation maison | 0.11 | lot 5 (sous-classes, reformulé) |
| 866 | Occultiste : Lame maudite / niv. 6 / Spectre maudit | Accursed Specter | hors SRD |  | nom, description (285 car.) | reformulation maison | 0.26 | lot 5 (sous-classes, reformulé) |
| 867 | Occultiste : Lame maudite / niv. 10 / Armure de maléfices | Armor of Hexes | hors SRD |  | nom, description (170 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 868 | Occultiste : Lame maudite / niv. 14 / Maître des maléfices | Master of Hexes | hors SRD |  | nom, description (197 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 869 | Occultiste : Mort-vivant / niv. 1 / Liste de sorts étendue | Expanded Spell List | hors SRD |  | nom, description (300 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 870 | Occultiste : Mort-vivant / niv. 1 / Forme d'effroi | Form of Dread | hors SRD |  | nom, description (415 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 871 | Occultiste : Mort-vivant / niv. 6 / Touché par la tombe | Grave Touched | hors SRD |  | nom, description (247 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 872 | Occultiste : Mort-vivant / niv. 10 / Carcasse nécrotique | Necrotic Husk | hors SRD |  | nom, description (340 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 873 | Occultiste : Mort-vivant / niv. 14 / Projection spirituelle | Spirit Projection | hors SRD |  | nom, description (349 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 874 | Paladin : Serment de conquête / niv. 3 / Sorts de serment de conquête | Oath Spells | hors SRD |  | nom, description (254 car.) | reformulation maison | 0.03 | lot 5 (sous-classes, reformulé) |
| 875 | Paladin : Serment de conquête / niv. 3 / Frappe guidée | Guided Strike | hors SRD |  | nom, description (194 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 876 | Paladin : Serment de conquête / niv. 7 / Aura de conquête | Aura of Conquest | hors SRD |  | nom, description (203 car.) | reformulation maison | 0.25 | lot 5 (sous-classes, reformulé) |
| 877 | Paladin : Serment de conquête / niv. 15 / Réprimande méprisante | Scornful Rebuke | hors SRD |  | nom, description (156 car.) | reformulation maison | 0.32 | lot 5 (sous-classes, reformulé) |
| 878 | Paladin : Serment de conquête / niv. 20 / Conquérant invincible | Invincible Conqueror | hors SRD |  | nom, description (211 car.) | reformulation maison | 0.03 | lot 5 (sous-classes, reformulé) |
| 879 | Paladin : Serment de gloire / niv. 3 / Sorts de serment de gloire | Oath Spells | hors SRD |  | nom, description (260 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 880 | Paladin : Serment de gloire / niv. 3 / Châtiment inspirant | Inspiring Smite | hors SRD |  | nom, description (216 car.) | reformulation maison | 0.23 | lot 5 (sous-classes, reformulé) |
| 881 | Paladin : Serment de gloire / niv. 7 / Aura d'alacrité | Aura of Alacrity | hors SRD |  | nom, description (154 car.) | reformulation maison | 0.30 | lot 5 (sous-classes, reformulé) |
| 882 | Paladin : Serment de gloire / niv. 15 / Défense glorieuse | Glorious Defense | hors SRD |  | nom, description (327 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 883 | Paladin : Serment de gloire / niv. 20 / Légende vivante | Living Legend | hors SRD |  | nom, description (280 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 884 | Paladin : Serment des guetteurs / niv. 3 / Sorts de serment des guetteurs | Oath Spells | hors SRD |  | nom, description (251 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 885 | Paladin : Serment des guetteurs / niv. 3 / Abjuration des extraplanaires | Abjure the Extraplanar | hors SRD |  | nom, description (227 car.) | reformulation maison | 0.25 | lot 5 (sous-classes, reformulé) |
| 886 | Paladin : Serment des guetteurs / niv. 7 / Aura de la sentinelle | Aura of the Sentinel | hors SRD |  | nom, description (135 car.) | reformulation maison | 0.28 | lot 5 (sous-classes, reformulé) |
| 887 | Paladin : Serment des guetteurs / niv. 15 / Réprimande vigilante | Vigilant Rebuke | hors SRD |  | nom, description (246 car.) | reformulation maison | 0.29 | lot 5 (sous-classes, reformulé) |
| 888 | Paladin : Serment des guetteurs / niv. 20 / Rempart des mortels | Mortal Bulwark | hors SRD |  | nom, description (349 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 889 | Paladin : Serment de rédemption / niv. 3 / Sorts de serment de rédemption | Oath Spells | hors SRD |  | nom, description (270 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 890 | Paladin : Serment de rédemption / niv. 3 / Réprimande des violents | Rebuke the Violent | hors SRD |  | nom, description (264 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 891 | Paladin : Serment de rédemption / niv. 7 / Aura du gardien | Aura of the Guardian | hors SRD |  | nom, description (168 car.) | reformulation maison | 0.10 | lot 5 (sous-classes, reformulé) |
| 892 | Paladin : Serment de rédemption / niv. 15 / Esprit protecteur | Protective Spirit | hors SRD |  | nom, description (184 car.) | reformulation maison | 0.44 | lot 5 (sous-classes, reformulé) |
| 893 | Paladin : Serment de rédemption / niv. 20 / Émissaire de la rédemption | Emissary of Redemption | hors SRD |  | nom, description (288 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 894 | Rôdeur : Arpenteur de l'horizon / niv. 3 / Magie de l'arpenteur de l'horizon | Horizon Walker Magic | hors SRD |  | nom, description (179 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 895 | Rôdeur : Arpenteur de l'horizon / niv. 7 / Pas éthéré | Ethereal Step | hors SRD |  | nom, description (117 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 896 | Rôdeur : Arpenteur de l'horizon / niv. 11 / Frappe lointaine | Distant Strike | hors SRD |  | nom, description (256 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 897 | Rôdeur : Arpenteur de l'horizon / niv. 15 / Défense spectrale | Spectral Defense | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 898 | Rôdeur : Gardien des nuées / niv. 3 / Magie du gardien des nuées | Swarmkeeper Magic | hors SRD |  | nom, description (211 car.) | reformulation maison | 0.03 | lot 5 (sous-classes, reformulé) |
| 899 | Rôdeur : Gardien des nuées / niv. 7 / Marée grouillante | Writhing Tide | hors SRD |  | nom, description (188 car.) | reformulation maison | 0.18 | lot 5 (sous-classes, reformulé) |
| 900 | Rôdeur : Gardien des nuées / niv. 11 / Nuée puissante | Mighty Swarm | hors SRD |  | nom, description (242 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 901 | Rôdeur : Gardien des nuées / niv. 15 / Dispersion de la nuée | Swarming Dispersal | hors SRD |  | nom, description (240 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 902 | Rôdeur : Traqueur des ténèbres / niv. 3 / Magie du traqueur des ténèbres | Gloom Stalker Magic | hors SRD |  | nom, description (169 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 903 | Rôdeur : Traqueur des ténèbres / niv. 3 / Vision des ombres | Umbral Sight | hors SRD |  | nom, description (188 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 904 | Rôdeur : Traqueur des ténèbres / niv. 7 / Esprit d'acier | Iron Mind | hors SRD |  | nom, description (105 car.) | reformulation maison | 0.29 | lot 5 (sous-classes, reformulé) |
| 905 | Rôdeur : Traqueur des ténèbres / niv. 11 / Déluge du traqueur | Stalker's Flurry | hors SRD |  | nom, description (145 car.) | reformulation maison | 0.35 | lot 5 (sous-classes, reformulé) |
| 906 | Rôdeur : Traqueur des ténèbres / niv. 15 / Esquive ténébreuse | Shadowy Dodge | hors SRD |  | nom, description (114 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 907 | Rôdeur : Tueur de monstres / niv. 3 / Magie du tueur de monstres | Monster Slayer Magic | hors SRD |  | nom, description (194 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 908 | Rôdeur : Tueur de monstres / niv. 3 / Proie du tueur | Slayer's Prey | hors SRD |  | nom, description (286 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 909 | Rôdeur : Tueur de monstres / niv. 7 / Défense surnaturelle | Supernatural Defense | hors SRD |  | nom, description (146 car.) | reformulation maison | 0.17 | lot 5 (sous-classes, reformulé) |
| 910 | Rôdeur : Tueur de monstres / niv. 11 / Némésis des lanceurs de sorts | Magic-User's Nemesis | hors SRD |  | nom, description (248 car.) | reformulation maison | 0.26 | lot 5 (sous-classes, reformulé) |
| 911 | Rôdeur : Tueur de monstres / niv. 15 / Riposte du tueur | Slayer's Counter | hors SRD |  | nom, description (239 car.) | reformulation maison | 0.17 | lot 5 (sous-classes, reformulé) |
| 912 | Rôdeur : Vagabond féerique / niv. 3 / Magie du vagabond féerique | Fey Wanderer Magic | hors SRD |  | nom, description (181 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 913 | Rôdeur : Vagabond féerique / niv. 3 / Glamour de l'autre monde | Otherworldly Glamour | hors SRD |  | nom, description (167 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 914 | Rôdeur : Vagabond féerique / niv. 7 / Retournement ensorcelant | Beguiling Twist | hors SRD |  | nom, description (310 car.) | reformulation maison | 0.33 | lot 5 (sous-classes, reformulé) |
| 915 | Rôdeur : Vagabond féerique / niv. 11 / Renforts féeriques | Fey Reinforcements | hors SRD |  | nom, description (218 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 916 | Rôdeur : Vagabond féerique / niv. 15 / Vagabond des brumes | Misty Wanderer | hors SRD |  | nom, description (212 car.) | reformulation maison | 0.30 | lot 5 (sous-classes, reformulé) |
| 917 | Roublard : Âme acérée / niv. 3 / Énergie psionique | Psionic Power | hors SRD |  | nom, description (437 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 918 | Roublard : Âme acérée / niv. 9 / Lames de l'âme | Soul Blades | hors SRD |  | nom, description (262 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 919 | Roublard : Âme acérée / niv. 13 / Voile psychique | Psychic Veil | hors SRD |  | nom, description (197 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 920 | Roublard : Âme acérée / niv. 17 / Déchirer l'esprit | Rend Mind | hors SRD |  | nom, description (323 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 921 | Roublard : Bretteur / niv. 9 / Panache | Panache | hors SRD |  | nom, description (251 car.) | reformulation maison | 0.17 | lot 5 (sous-classes, reformulé) |
| 922 | Roublard : Bretteur / niv. 13 / Manœuvre élégante | Elegant Maneuver | hors SRD |  | nom, description (130 car.) | reformulation maison | 0.29 | lot 5 (sous-classes, reformulé) |
| 923 | Roublard : Bretteur / niv. 17 / Maître duelliste | Master Duelist | hors SRD |  | nom, description (111 car.) | reformulation maison | 0.18 | lot 5 (sous-classes, reformulé) |
| 924 | Roublard : Éclaireur / niv. 3 / Survivaliste | Survivalist | hors SRD |  | nom, description (107 car.) | reformulation maison | 0.13 | lot 5 (sous-classes, reformulé) |
| 925 | Roublard : Éclaireur / niv. 9 / Mobilité supérieure | Superior Mobility | hors SRD |  | nom, description (99 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 926 | Roublard : Éclaireur / niv. 13 / Maître de l'embuscade | Ambush Master | hors SRD |  | nom, description (223 car.) | reformulation maison | 0.17 | lot 5 (sous-classes, reformulé) |
| 927 | Roublard : Éclaireur / niv. 17 / Frappe soudaine | Sudden Strike | hors SRD |  | nom, description (227 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 928 | Roublard : Enquêteur / niv. 3 / Oreille pour le mensonge | Ear for Deceit | hors SRD |  | nom, description (130 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 929 | Roublard : Enquêteur / niv. 3 / Combat perspicace | Insightful Fighting | hors SRD |  | nom, description (264 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 930 | Roublard : Enquêteur / niv. 9 / Regard assuré | Steady Eye | hors SRD |  | nom, description (176 car.) | reformulation maison | 0.58 | lot 5 (sous-classes, reformulé) |
| 931 | Roublard : Enquêteur / niv. 13 / Œil infaillible | Unerring Eye | hors SRD |  | nom, description (217 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 932 | Roublard : Enquêteur / niv. 17 / Œil pour la faiblesse | Eye for Weakness | hors SRD |  | nom, description (131 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 933 | Roublard : Phantôme / niv. 3 / Lamentations d'outre-tombe | Wails from the Grave | hors SRD |  | nom, description (274 car.) | reformulation maison | 0.14 | lot 5 (sous-classes, reformulé) |
| 934 | Roublard : Phantôme / niv. 9 / Souvenirs des défunts | Tokens of the Departed | hors SRD |  | nom, description (389 car.) | reformulation maison | 0.11 | lot 5 (sous-classes, reformulé) |
| 935 | Roublard : Phantôme / niv. 13 / Marche fantomatique | Ghost Walk | hors SRD |  | nom, description (274 car.) | reformulation maison | 0.02 | lot 5 (sous-classes, reformulé) |
| 936 | Roublard : Phantôme / niv. 17 / Ami de la mort | Death's Friend | hors SRD |  | nom, description (189 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 937 | Barbare : Berserker ancestral / niv. 3 / Restriction : nains uniquement | Restriction: Dwarves Only | hors SRD |  | nom, description (113 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 938 | Barbare : Berserker ancestral / niv. 3 / Armure hérissée | Battlerager Armor | hors SRD |  | nom, description (263 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 939 | Barbare : Berserker ancestral / niv. 6 / Abandon téméraire | Reckless Abandon | hors SRD |  | nom, description (157 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 940 | Barbare : Berserker ancestral / niv. 10 / Charge du berserker ancestral | Battlerager Charge | hors SRD |  | nom, description (68 car.) | reformulation maison | 0.50 | lot 5 (sous-classes, reformulé) |
| 941 | Barbare : Berserker ancestral / niv. 14 / Représailles hérissées | Spiked Retribution | hors SRD |  | nom, description (153 car.) | reformulation maison | 0.18 | lot 5 (sous-classes, reformulé) |
| 942 | Moine : Voie de la longue mort / niv. 3 / Toucher de la mort | Touch of Death | hors SRD |  | nom, description (192 car.) | reformulation maison | 0.34 | lot 5 (sous-classes, reformulé) |
| 943 | Moine : Voie de la longue mort / niv. 6 / Heure de la moisson | Hour of Reaping | hors SRD |  | nom, description (175 car.) | reformulation maison | 0.39 | lot 5 (sous-classes, reformulé) |
| 944 | Moine : Voie de la longue mort / niv. 11 / Maîtrise de la mort | Mastery of Death | hors SRD |  | nom, description (113 car.) | reformulation maison | 0.57 | lot 5 (sous-classes, reformulé) |
| 945 | Moine : Voie de la longue mort / niv. 17 / Toucher de la longue mort | Touch of the Long Death | hors SRD |  | nom, description (228 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 946 | Occultiste : Immortel / niv. 1 / Liste de sorts étendue | Expanded Spell List | hors SRD |  | nom, description (277 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 947 | Occultiste : Immortel / niv. 1 / Parmi les morts | Among the Dead | hors SRD |  | nom, description (309 car.) | reformulation maison | 0.26 | lot 5 (sous-classes, reformulé) |
| 948 | Occultiste : Immortel / niv. 6 / Défier la mort | Defy Death | hors SRD |  | nom, description (222 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 949 | Occultiste : Immortel / niv. 10 / Nature immortelle | Undying Nature | hors SRD |  | nom, description (224 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 950 | Occultiste : Immortel / niv. 14 / Vie indestructible | Indestructible Life | hors SRD |  | nom, description (190 car.) | reformulation maison | 0.10 | lot 5 (sous-classes, reformulé) |
| 951 | Guerrier : Chevalier dragon pourpre / niv. 3 / Cri de ralliement | Rallying Cry | hors SRD |  | nom, description (176 car.) | reformulation maison | 0.18 | lot 5 (sous-classes, reformulé) |
| 952 | Guerrier : Chevalier dragon pourpre / niv. 7 / Envoyé royal | Royal Envoy | hors SRD |  | nom, description (194 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 953 | Guerrier : Chevalier dragon pourpre / niv. 10 / Élan inspirant | Inspiring Surge | hors SRD |  | nom, description (187 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 954 | Guerrier : Chevalier dragon pourpre / niv. 15 / Rempart | Bulwark | hors SRD |  | nom, description (204 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 955 | Paladin : Serment de la couronne / niv. 3 / Sorts de serment de la couronne | Oath Spells | hors SRD |  | nom, description (235 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 956 | Paladin : Serment de la couronne / niv. 3 / Défi du champion | Champion Challenge | hors SRD |  | nom, description (241 car.) | reformulation maison | 0.33 | lot 5 (sous-classes, reformulé) |
| 957 | Paladin : Serment de la couronne / niv. 3 / Renverser le cours | Turn the Tide | hors SRD |  | nom, description (205 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 958 | Paladin : Serment de la couronne / niv. 7 / Allégeance divine | Divine Allegiance | hors SRD |  | nom, description (140 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 959 | Paladin : Serment de la couronne / niv. 15 / Saint inébranlable | Unyielding Saint | hors SRD |  | nom, description (83 car.) | reformulation maison | 0.55 | lot 5 (sous-classes, reformulé) |
| 960 | Paladin : Serment de la couronne / niv. 20 / Champion exalté | Exalted Champion | hors SRD |  | nom, description (310 car.) | reformulation maison | 0.29 | lot 5 (sous-classes, reformulé) |
| 961 | Paladin : Parjure / niv. 3 / Sorts du parjure | Oathbreaker Spells | hors SRD |  | nom, description (241 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 962 | Paladin : Parjure / niv. 3 / Contrôle des morts-vivants | Control Undead | hors SRD |  | nom, description (189 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 963 | Paladin : Parjure / niv. 3 / Aspect terrifiant | Dreadful Aspect | hors SRD |  | nom, description (239 car.) | reformulation maison | 0.32 | lot 5 (sous-classes, reformulé) |
| 964 | Paladin : Parjure / niv. 7 / Aura de haine | Aura of Hate | hors SRD |  | nom, description (188 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 965 | Paladin : Parjure / niv. 15 / Résistance surnaturelle | Supernatural Resistance | hors SRD |  | nom, description (96 car.) | reformulation maison | 0.60 | lot 5 (sous-classes, reformulé) |
| 966 | Paladin : Parjure / niv. 20 / Seigneur de l'effroi | Dread Lord | hors SRD |  | nom, description (463 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 967 | Ensorceleur : Sorcellerie lunaire / niv. 1 / Incarnation lunaire | Lunar Embodiment | hors SRD |  | nom, description (557 car.) | reformulation maison | 0.01 | lot 5 (sous-classes, reformulé) |
| 968 | Ensorceleur : Sorcellerie lunaire / niv. 1 / Feu lunaire | Moon Fire | hors SRD |  | nom, description (124 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 969 | Ensorceleur : Sorcellerie lunaire / niv. 6 / Bienfaits lunaires | Lunar Boons | hors SRD |  | nom, description (332 car.) | reformulation maison | 0.02 | lot 5 (sous-classes, reformulé) |
| 970 | Ensorceleur : Sorcellerie lunaire / niv. 6 / Croissance et déclin | Waxing and Waning | hors SRD |  | nom, description (222 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 971 | Ensorceleur : Sorcellerie lunaire / niv. 14 / Puissance lunaire | Lunar Empowerment | hors SRD |  | nom, description (380 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 972 | Ensorceleur : Sorcellerie lunaire / niv. 18 / Phénomène lunaire | Lunar Phenomenon | hors SRD |  | nom, description (754 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 973 | Magicien : Chronurgie / niv. 2 / Glissement temporel | Chronal Shift | hors SRD |  | nom, description (215 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 974 | Magicien : Chronurgie / niv. 2 / Conscience temporelle | Temporal Awareness | hors SRD |  | nom, description (71 car.) | reformulation maison | 0.14 | lot 5 (sous-classes, reformulé) |
| 975 | Magicien : Chronurgie / niv. 6 / Stase momentanée | Momentary Stasis | hors SRD |  | nom, description (335 car.) | reformulation maison | 0.25 | lot 5 (sous-classes, reformulé) |
| 976 | Magicien : Chronurgie / niv. 10 / Suspension arcanique | Arcane Abeyance | hors SRD |  | nom, description (261 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 977 | Magicien : Chronurgie / niv. 14 / Avenir convergent | Convergent Future | hors SRD |  | nom, description (244 car.) | reformulation maison | 0.18 | lot 5 (sous-classes, reformulé) |
| 978 | Magicien : Graviturgie / niv. 2 / Ajustement de densité | Adjust Density | hors SRD |  | nom, description (315 car.) | reformulation maison | 0.16 | lot 5 (sous-classes, reformulé) |
| 979 | Magicien : Graviturgie / niv. 6 / Puits gravitationnel | Gravity Well | hors SRD |  | nom, description (190 car.) | reformulation maison | 0.21 | lot 5 (sous-classes, reformulé) |
| 980 | Magicien : Graviturgie / niv. 10 / Attraction violente | Violent Attraction | hors SRD |  | nom, description (335 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 981 | Magicien : Graviturgie / niv. 14 / Horizon des événements | Event Horizon | hors SRD |  | nom, description (400 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 982 | Guerrier : Chevalier de l'écho / niv. 3 / Écho manifesté | Manifest Echo | hors SRD |  | nom, description (348 car.) | reformulation maison | 0.08 | lot 5 (sous-classes, reformulé) |
| 983 | Guerrier : Chevalier de l'écho / niv. 3 / Incarnation déchaînée | Unleash Incarnation | hors SRD |  | nom, description (212 car.) | reformulation maison | 0.10 | lot 5 (sous-classes, reformulé) |
| 984 | Guerrier : Chevalier de l'écho / niv. 7 / Avatar de l'écho | Echo Avatar | hors SRD |  | nom, description (155 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 985 | Guerrier : Chevalier de l'écho / niv. 10 / Martyr d'ombre | Shadow Martyr | hors SRD |  | nom, description (170 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 986 | Guerrier : Chevalier de l'écho / niv. 15 / Récupération du potentiel | Reclaim Potential | hors SRD |  | nom, description (244 car.) | reformulation maison | 0.09 | lot 5 (sous-classes, reformulé) |
| 987 | Guerrier : Chevalier de l'écho / niv. 18 / Légion à moi seul | Legion of One | hors SRD |  | nom, description (187 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 1005 | Artificier : Alchimiste / niv. 3 / Maîtrise d'outil | Tool Proficiency | hors SRD |  | nom, description (100 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 1006 | Artificier : Alchimiste / niv. 3 / Sorts d'alchimiste | Alchemist Spells | hors SRD |  | nom, description (269 car.) | reformulation maison | 0.03 | lot 5 (sous-classes, reformulé) |
| 1007 | Artificier : Alchimiste / niv. 3 / Élixir expérimental | Experimental Elixir | hors SRD |  | nom, description (373 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 1008 | Artificier : Alchimiste / niv. 5 / Savant en alchimie | Alchemical Savant | hors SRD |  | nom, description (216 car.) | reformulation maison | 0.12 | lot 5 (sous-classes, reformulé) |
| 1009 | Artificier : Alchimiste / niv. 9 / Réactifs restaurateurs | Restorative Reagents | hors SRD |  | nom, description (301 car.) | reformulation maison | 0.18 | lot 5 (sous-classes, reformulé) |
| 1010 | Artificier : Alchimiste / niv. 15 / Maîtrise chimique | Chemical Mastery | hors SRD |  | nom, description (275 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 1011 | Artificier : Armurier / niv. 3 / Outils du métier | Tools of the Trade | hors SRD |  | nom, description (122 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 1012 | Artificier : Armurier / niv. 3 / Sorts d'armurier | Armorer Spells | hors SRD |  | nom, description (242 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 1013 | Artificier : Armurier / niv. 3 / Armure arcanique | Arcane Armor | hors SRD |  | nom, description (305 car.) | reformulation maison | 0.05 | lot 5 (sous-classes, reformulé) |
| 1014 | Artificier : Armurier / niv. 3 / Modèle d'armure | Armor Model | hors SRD |  | nom, description (447 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 1015 | Artificier : Armurier / niv. 5 / Attaque supplémentaire | Extra Attack | hors SRD |  | nom, description (90 car.) | reformulation maison | 0.30 | lot 5 (sous-classes, reformulé) |
| 1016 | Artificier : Armurier / niv. 9 / Modifications d'armure | Armor Modifications | hors SRD |  | nom, description (204 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 1017 | Artificier : Armurier / niv. 15 / Armure perfectionnée | Perfected Armor | hors SRD |  | nom, description (481 car.) | reformulation maison | 0.11 | lot 5 (sous-classes, reformulé) |
| 1018 | Artificier : Artilleur / niv. 3 / Maîtrise d'outil | Tool Proficiency | hors SRD |  | nom, description (109 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 1019 | Artificier : Artilleur / niv. 3 / Sorts d'artilleur | Artillerist Spells | hors SRD |  | nom, description (220 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 1020 | Artificier : Artilleur / niv. 3 / Canon occulte | Eldritch Cannon | hors SRD |  | nom, description (517 car.) | reformulation maison | 0.07 | lot 5 (sous-classes, reformulé) |
| 1021 | Artificier : Artilleur / niv. 5 / Arme à feu arcanique | Arcane Firearm | hors SRD |  | nom, description (227 car.) | reformulation maison | 0.03 | lot 5 (sous-classes, reformulé) |
| 1022 | Artificier : Artilleur / niv. 9 / Canon explosif | Explosive Cannon | hors SRD |  | nom, description (236 car.) | reformulation maison | 0.20 | lot 5 (sous-classes, reformulé) |
| 1023 | Artificier : Artilleur / niv. 15 / Position fortifiée | Fortified Position | hors SRD |  | nom, description (197 car.) | reformulation maison | 0.19 | lot 5 (sous-classes, reformulé) |
| 1024 | Artificier : Forgeron de guerre / niv. 3 / Maîtrise d'outil | Tool Proficiency | hors SRD |  | nom, description (99 car.) | reformulation maison | 0.06 | lot 5 (sous-classes, reformulé) |
| 1025 | Artificier : Forgeron de guerre / niv. 3 / Sorts de forgeron de guerre | Battle Smith Spells | hors SRD |  | nom, description (264 car.) | reformulation maison | 0.00 | lot 5 (sous-classes, reformulé) |
| 1026 | Artificier : Forgeron de guerre / niv. 3 / Prêt au combat | Battle Ready | hors SRD |  | nom, description (148 car.) | reformulation maison | 0.24 | lot 5 (sous-classes, reformulé) |
| 1027 | Artificier : Forgeron de guerre / niv. 3 / Défenseur d'acier | Steel Defender | hors SRD |  | nom, description (350 car.) | reformulation maison | 0.15 | lot 5 (sous-classes, reformulé) |
| 1028 | Artificier : Forgeron de guerre / niv. 5 / Attaque supplémentaire | Extra Attack | hors SRD |  | nom, description (90 car.) | reformulation maison | 0.30 | lot 5 (sous-classes, reformulé) |
| 1029 | Artificier : Forgeron de guerre / niv. 9 / Décharge arcanique | Arcane Jolt | hors SRD |  | nom, description (307 car.) | reformulation maison | 0.32 | lot 5 (sous-classes, reformulé) |
| 1030 | Artificier : Forgeron de guerre / niv. 15 / Défenseur amélioré | Improved Defender | hors SRD |  | nom, description (198 car.) | reformulation maison | 0.03 | lot 5 (sous-classes, reformulé) |

</details>

### 2.8 Options de classe (styles, métamagie, pactes, manœuvres...) (97)

SRD 5.1 : les 6 styles de combat du Manuel des Joueurs, les 8 options de métamagie, les 3 faveurs de pacte. SRD 5.2 (homonymes, texte Tasha 2014 en base) : Sort guidé, Sort transmuté, Guerrier béni, Guerrier druidique. Manœuvres, disciplines élémentaires, infusions, tirs arcaniques, runes, styles de Tasha, Pacte du talisman : hors SRD. Texte « reformulé (PHB, Xanathar, Tasha) » d'après la migration. Nexus stocke le **nom** choisi dans `character_class_options.chosen_value` (et `chaine`/`lame`/`grimoire` pour le pacte).

Répartition : SRD mais texte non conforme 21, hors SRD 76.

<details><summary>Tableau complet (97 lignes)</summary>

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | manoeuvre : Embuscade | Ambush | Chaudron de Tasha | hors SRD |  | nom, description (176 car.) | reformulé d'après le livre | 0.11 |
| 2 | manoeuvre : Échange de position | Bait and Switch | Chaudron de Tasha | hors SRD |  | nom, description (208 car.) | reformulé d'après le livre | 0.18 |
| 3 | manoeuvre : Parade préparée | Brace | Chaudron de Tasha | hors SRD |  | nom, description (176 car.) | reformulé d'après le livre | 0.07 |
| 4 | manoeuvre : Frappe du commandant | Commander's Strike | Manuel des Joueurs | hors SRD |  | nom, description (219 car.) | reformulé d'après le livre | 0.08 |
| 5 | manoeuvre : Présence imposante | Commanding Presence | Chaudron de Tasha | hors SRD |  | nom, description (138 car.) | reformulé d'après le livre | 0.06 |
| 6 | manoeuvre : Attaque désarmante | Disarming Attack | Manuel des Joueurs | hors SRD |  | nom, description (198 car.) | reformulé d'après le livre | 0.26 |
| 7 | manoeuvre : Frappe distrayante | Distracting Strike | Manuel des Joueurs | hors SRD |  | nom, description (197 car.) | reformulé d'après le livre | 0.10 |
| 8 | manoeuvre : Jeu de jambes évasif | Evasive Footwork | Manuel des Joueurs | hors SRD |  | nom, description (118 car.) | reformulé d'après le livre | 0.16 |
| 9 | manoeuvre : Feinte | Feinting Attack | Manuel des Joueurs | hors SRD |  | nom, description (189 car.) | reformulé d'après le livre | 0.09 |
| 10 | manoeuvre : Attaque provocante | Goading Attack | Manuel des Joueurs | hors SRD |  | nom, description (236 car.) | reformulé d'après le livre | 0.28 |
| 11 | manoeuvre : Frappe agrippante | Grappling Strike | Chaudron de Tasha | hors SRD |  | nom, description (186 car.) | reformulé d'après le livre | 0.24 |
| 12 | manoeuvre : Attaque en fente | Lunging Attack | Manuel des Joueurs | hors SRD |  | nom, description (164 car.) | reformulé d'après le livre | 0.07 |
| 13 | manoeuvre : Attaque manœuvrante | Maneuvering Attack | Manuel des Joueurs | hors SRD |  | nom, description (238 car.) | reformulé d'après le livre | 0.23 |
| 14 | manoeuvre : Attaque menaçante | Menacing Attack | Manuel des Joueurs | hors SRD |  | nom, description (193 car.) | reformulé d'après le livre | 0.41 |
| 15 | manoeuvre : Parade | Parry | Manuel des Joueurs | hors SRD |  | nom, description (168 car.) | reformulé d'après le livre | 0.12 |
| 16 | manoeuvre : Attaque précise | Precision Attack | Manuel des Joueurs | hors SRD |  | nom, description (157 car.) | reformulé d'après le livre | 0.00 |
| 17 | manoeuvre : Attaque repoussante | Pushing Attack | Manuel des Joueurs | hors SRD |  | nom, description (199 car.) | reformulé d'après le livre | 0.43 |
| 18 | manoeuvre : Lancer rapide | Quick Toss | Chaudron de Tasha | hors SRD |  | nom, description (161 car.) | reformulé d'après le livre | 0.04 |
| 19 | manoeuvre : Ralliement | Rally | Manuel des Joueurs | hors SRD |  | nom, description (169 car.) | reformulé d'après le livre | 0.24 |
| 20 | manoeuvre : Riposte | Riposte | Manuel des Joueurs | hors SRD |  | nom, description (179 car.) | reformulé d'après le livre | 0.07 |
| 21 | manoeuvre : Attaque circulaire | Sweeping Attack | Manuel des Joueurs | hors SRD |  | nom, description (233 car.) | reformulé d'après le livre | 0.14 |
| 22 | manoeuvre : Évaluation tactique | Tactical Assessment | Chaudron de Tasha | hors SRD |  | nom, description (150 car.) | reformulé d'après le livre | 0.05 |
| 23 | manoeuvre : Croc-en-jambe | Trip Attack | Manuel des Joueurs | hors SRD |  | nom, description (184 car.) | reformulé d'après le livre | 0.45 |
| 24 | metamagie : Sort prudent | Careful Spell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (158 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.10 |
| 25 | metamagie : Sort distant | Distant Spell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (99 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.05 |
| 26 | metamagie : Sort renforcé | Empowered Spell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (152 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.33 |
| 27 | metamagie : Sort prolongé | Extended Spell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (84 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.33 |
| 28 | metamagie : Sort intensifié | Heightened Spell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (83 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.18 |
| 29 | metamagie : Sort accéléré | Quickened Spell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (81 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.17 |
| 30 | metamagie : Sort guidé | Seeking Spell | Chaudron de Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (178 car.) | texte Tasha 2014 reformulé ; homonyme 2024 au SRD 5.2 | 0.14 |
| 31 | metamagie : Sort subtil | Subtle Spell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (60 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.20 |
| 32 | metamagie : Sort transmuté | Transmuted Spell | Chaudron de Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (140 car.) | texte Tasha 2014 reformulé ; homonyme 2024 au SRD 5.2 | 0.21 |
| 33 | metamagie : Sort jumeau | Twinned Spell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (112 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.28 |
| 34 | style_combat : Archerie | Archery | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (72 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.45 |
| 35 | style_combat : Combat en aveugle | Blind Fighting | Chaudron de Tasha | hors SRD |  | nom, description (198 car.) | reformulé d'après le livre | 0.03 |
| 36 | style_combat : Défense | Defense | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (68 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.55 |
| 37 | style_combat : Duel | Dueling | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (141 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.48 |
| 38 | style_combat : Armes à deux mains | Great Weapon Fighting | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (185 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.26 |
| 39 | style_combat : Interception | Interception | Chaudron de Tasha | hors SRD |  | nom, description (217 car.) | reformulé d'après le livre | 0.22 |
| 40 | style_combat : Protection | Protection | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (166 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.25 |
| 41 | style_combat : Technique supérieure | Superior Technique | Chaudron de Tasha | hors SRD |  | nom, description (122 car.) | reformulé d'après le livre | 0.11 |
| 42 | style_combat : Combat aux armes de jet | Thrown Weapon Fighting | Chaudron de Tasha | hors SRD |  | nom, description (146 car.) | reformulé d'après le livre | 0.19 |
| 43 | style_combat : Combat à deux armes | Two-Weapon Fighting | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (121 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.50 |
| 44 | style_combat : Combat à mains nues | Unarmed Fighting | Chaudron de Tasha | hors SRD |  | nom, description (223 car.) | reformulé d'après le livre | 0.21 |
| 45 | style_combat : Guerrier béni | Blessed Warrior | Chaudron de Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (146 car.) | texte Tasha 2014 reformulé ; homonyme 2024 au SRD 5.2 | 0.42 |
| 46 | style_combat : Guerrier druidique | Druidic Warrior | Chaudron de Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (145 car.) | texte Tasha 2014 reformulé ; homonyme 2024 au SRD 5.2 | 0.32 |
| 47 | discipline_elementaire : Harmonie élémentaire | Elemental Attunement | Manuel des Joueurs | hors SRD |  | nom, description (258 car.) | reformulé d'après le livre | 0.00 |
| 48 | discipline_elementaire : Crocs du serpent de feu | Fangs of the Fire Snake | Manuel des Joueurs | hors SRD |  | nom, description (201 car.) | reformulé d'après le livre | 0.09 |
| 49 | discipline_elementaire : Poing des quatre tonnerres | Fist of Four Thunders | Manuel des Joueurs | hors SRD |  | nom, description (27 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) |  |
| 50 | discipline_elementaire : Poing de l'air invaincu | Fist of Unbroken Air | Manuel des Joueurs | hors SRD |  | nom, description (210 car.) | reformulé d'après le livre | 0.17 |
| 51 | discipline_elementaire : Ruée des esprits du vent | Rush of the Gale Spirits | Manuel des Joueurs | hors SRD |  | nom, description (23 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) |  |
| 52 | discipline_elementaire : Façonner le fleuve | Shape the Flowing River | Manuel des Joueurs | hors SRD |  | nom, description (192 car.) | reformulé d'après le livre | 0.14 |
| 53 | discipline_elementaire : Frappe des cendres ardentes | Sweeping Cinder Strike | Manuel des Joueurs | hors SRD |  | nom, description (28 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) |  |
| 54 | discipline_elementaire : Fouet d'eau | Water Whip | Manuel des Joueurs | hors SRD |  | nom, description (233 car.) | reformulé d'après le livre | 0.20 |
| 55 | discipline_elementaire : Étreinte du vent du nord | Clench of the North Wind | Manuel des Joueurs | hors SRD |  | nom, description (39 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) | 0.00 |
| 56 | discipline_elementaire : Gong du sommet | Gong of the Summit | Manuel des Joueurs | hors SRD |  | nom, description (25 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) |  |
| 57 | discipline_elementaire : Défense de la montagne éternelle | Eternal Mountain Defense | Manuel des Joueurs | hors SRD |  | nom, description (41 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) | 0.00 |
| 58 | discipline_elementaire : Flammes du phénix | Flames of the Phoenix | Manuel des Joueurs | hors SRD |  | nom, description (25 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) | 1.00 |
| 59 | discipline_elementaire : Posture de brume | Mist Stance | Manuel des Joueurs | hors SRD |  | nom, description (40 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) | 0.00 |
| 60 | discipline_elementaire : Chevaucher le vent | Ride the Wind | Manuel des Joueurs | hors SRD |  | nom, description (30 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) | 0.00 |
| 61 | discipline_elementaire : Souffle de l'hiver | Breath of Winter | Manuel des Joueurs | hors SRD |  | nom, description (26 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) | 0.00 |
| 62 | discipline_elementaire : Rivière de flammes affamées | River of Hungry Flame | Manuel des Joueurs | hors SRD |  | nom, description (23 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) | 0.00 |
| 63 | discipline_elementaire : Vague de terre déferlante | Wave of Rolling Earth | Manuel des Joueurs | hors SRD |  | nom, description (26 car.) | reformulé d'après le livre ; quasi nom seul (renvoi à un sort) | 0.00 |
| 64 | pacte : Pacte de la chaîne | Pact of the Chain | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (290 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.13 |
| 65 | pacte : Pacte de la lame | Pact of the Blade | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (204 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.08 |
| 66 | pacte : Pacte du grimoire | Pact of the Tome | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description (186 car.) | reformulé d'après le Manuel des Joueurs (en-tête de migration) | 0.07 |
| 67 | pacte : Pacte du talisman | Pact of the Talisman | Chaudron de Tasha | hors SRD |  | nom, description (171 car.) | reformulé d'après le livre | 0.23 |
| 68 | infusion : Armure à propulsion arcanique | Arcane Propulsion Armor | Chaudron de Tasha | hors SRD |  | nom, description (217 car.) | reformulé d'après le livre | 0.00 |
| 69 | infusion : Armure de force magique | Armor of Magical Strength | Chaudron de Tasha | hors SRD |  | nom, description (219 car.) | reformulé d'après le livre | 0.24 |
| 70 | infusion : Bottes du chemin sinueux | Boots of the Winding Path | Chaudron de Tasha | hors SRD |  | nom, description (144 car.) | reformulé d'après le livre | 0.29 |
| 71 | infusion : Focaliseur arcanique amélioré | Enhanced Arcane Focus | Chaudron de Tasha | hors SRD |  | nom, description (126 car.) | reformulé d'après le livre | 0.17 |
| 72 | infusion : Défense améliorée | Enhanced Defense | Chaudron de Tasha | hors SRD |  | nom, description (73 car.) | reformulé d'après le livre | 0.23 |
| 73 | infusion : Arme améliorée | Enhanced Weapon | Chaudron de Tasha | hors SRD |  | nom, description (85 car.) | reformulé d'après le livre | 0.29 |
| 74 | infusion : Heaume de vigilance | Helm of Awareness | Chaudron de Tasha | hors SRD |  | nom, description (128 car.) | reformulé d'après le livre | 0.47 |
| 75 | infusion : Serviteur homoncule | Homunculus Servant | Chaudron de Tasha | hors SRD |  | nom, description (153 car.) | reformulé d'après le livre | 0.00 |
| 76 | infusion : Aiguiseur d'esprit | Mind Sharpener | Chaudron de Tasha | hors SRD |  | nom, description (166 car.) | reformulé d'après le livre | 0.16 |
| 77 | infusion : Arme radieuse | Radiant Weapon | Chaudron de Tasha | hors SRD |  | nom, description (237 car.) | reformulé d'après le livre | 0.08 |
| 78 | infusion : Tir répété | Repeating Shot | Chaudron de Tasha | hors SRD |  | nom, description (101 car.) | reformulé d'après le livre | 0.00 |
| 79 | infusion : Réplique d'objet magique | Replicate Magic Item | Chaudron de Tasha | hors SRD |  | nom, description (211 car.) | reformulé d'après le livre | 0.03 |
| 80 | infusion : Bouclier de répulsion | Repulsion Shield | Chaudron de Tasha | hors SRD |  | nom, description (171 car.) | reformulé d'après le livre | 0.14 |
| 81 | infusion : Armure résistante | Resistant Armor | Chaudron de Tasha | hors SRD |  | nom, description (176 car.) | reformulé d'après le livre | 0.14 |
| 82 | infusion : Arme boomerang | Returning Weapon | Chaudron de Tasha | hors SRD |  | nom, description (65 car.) | reformulé d'après le livre | 0.00 |
| 83 | infusion : Anneau de recharge de sort | Spell-Refueling Ring | Chaudron de Tasha | hors SRD |  | nom, description (123 car.) | reformulé d'après le livre | 0.06 |
| 84 | tir_arcanique : Flèche de bannissement | Banishing Arrow | Guide de Xanathar | hors SRD |  | nom, description (187 car.) | reformulé d'après le livre | 0.29 |
| 85 | tir_arcanique : Flèche charmeuse | Beguiling Arrow | Guide de Xanathar | hors SRD |  | nom, description (215 car.) | reformulé d'après le livre | 0.24 |
| 86 | tir_arcanique : Flèche explosive | Bursting Arrow | Guide de Xanathar | hors SRD |  | nom, description (110 car.) | reformulé d'après le livre | 0.06 |
| 87 | tir_arcanique : Flèche débilitante | Enfeebling Arrow | Guide de Xanathar | hors SRD |  | nom, description (224 car.) | reformulé d'après le livre | 0.44 |
| 88 | tir_arcanique : Flèche agrippante | Grasping Arrow | Guide de Xanathar | hors SRD |  | nom, description (252 car.) | reformulé d'après le livre | 0.14 |
| 89 | tir_arcanique : Flèche perforante | Piercing Arrow | Guide de Xanathar | hors SRD |  | nom, description (239 car.) | reformulé d'après le livre | 0.25 |
| 90 | tir_arcanique : Flèche chercheuse | Seeking Arrow | Guide de Xanathar | hors SRD |  | nom, description (299 car.) | reformulé d'après le livre | 0.18 |
| 91 | tir_arcanique : Flèche d'ombre | Shadow Arrow | Guide de Xanathar | hors SRD |  | nom, description (197 car.) | reformulé d'après le livre | 0.30 |
| 92 | rune : Rune du nuage | Cloud Rune | Chaudron de Tasha | hors SRD |  | nom, description (237 car.) | reformulé d'après le livre | 0.08 |
| 93 | rune : Rune du feu | Fire Rune | Chaudron de Tasha | hors SRD |  | nom, description (283 car.) | reformulé d'après le livre | 0.34 |
| 94 | rune : Rune du givre | Frost Rune | Chaudron de Tasha | hors SRD |  | nom, description (200 car.) | reformulé d'après le livre | 0.17 |
| 95 | rune : Rune de pierre | Stone Rune | Chaudron de Tasha | hors SRD |  | nom, description (252 car.) | reformulé d'après le livre | 0.20 |
| 96 | rune : Rune de la colline | Hill Rune | Chaudron de Tasha | hors SRD |  | nom, description (201 car.) | reformulé d'après le livre | 0.35 |
| 97 | rune : Rune de la tempête | Storm Rune | Chaudron de Tasha | hors SRD |  | nom, description (295 car.) | reformulé d'après le livre | 0.15 |

</details>

### 2.9 Dons (116)

Colonnes `source`, `edition`, `category` (migration `20261112120000`). SRD 5.1 : Empoignade seulement. SRD 5.2 : Alerte, Initié à la magie, Frappeur sauvage, Qualifié, Amélioration de caractéristique, Empoignade (2024), 4 styles de combat, 7 faveurs épiques ; en base, les 4 dons d'origine portent le texte 2014.

Répartition : SRD 5.1 1, SRD 5.2 8, SRD mais texte non conforme 4, hors SRD 103.

<details><summary>Tableau complet (116 lignes)</summary>

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Acteur |  | PHB14 (2014, general) | hors SRD |  | nom, description (333 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.05 |
| 2 | Alerte |  | PHB14 (2014, origin) | SRD mais texte non conforme | SRD 5.2 | nom, description (258 car.), prérequis, bonus de caractéristique | texte 2014 reformulé ; homonyme don d'origine 2024 au SRD 5.2 | 0.07 |
| 3 | Athlète |  | PHB14 (2014, general) | hors SRD |  | nom, description (281 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.06 |
| 4 | Chargeur |  | PHB14 (2014, general) | hors SRD |  | nom, description (288 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.02 |
| 5 | Expert des armes à distance |  | PHB14 (2014, general) | hors SRD |  | nom, description (290 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.09 |
| 6 | Frappeur à deux armes |  | PHB14 (2014, general) | hors SRD |  | nom, description (263 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.11 |
| 7 | Explorateur de donjon |  | PHB14 (2014, legacy) | hors SRD |  | nom, description (323 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.15 |
| 8 | Endurant |  | PHB14 (2014, general) | hors SRD |  | nom, description (189 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.28 |
| 9 | Maître d'armes lourdes |  | PHB14 (2014, general) | hors SRD |  | nom, description (364 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.17 |
| 10 | Guérisseur |  | PHB14 (2014, origin) | hors SRD |  | nom, description (373 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.02 |
| 11 | Pourfendeur de mages |  | PHB14 (2014, general) | hors SRD |  | nom, description (398 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.14 |
| 12 | Initié à la magie |  | PHB14 (2014, origin) | SRD mais texte non conforme | SRD 5.2 | nom, description (446 car.), prérequis, bonus de caractéristique | texte 2014 reformulé ; homonyme don d'origine 2024 au SRD 5.2 | 0.04 |
| 13 | Adepte martial |  | PHB14 (2014, legacy) | hors SRD |  | nom, description (169 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.00 |
| 14 | Mobile |  | PHB14 (2014, legacy) | hors SRD |  | nom, description (337 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.09 |
| 15 | Cavalier hors pair |  | PHB14 (2014, general) | hors SRD |  | nom, description (349 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.14 |
| 16 | Maître de la hallebarde |  | PHB14 (2014, general) | hors SRD |  | nom, description (362 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.00 |
| 17 | Robuste |  | PHB14 (2014, general) | hors SRD |  | nom, description (170 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.12 |
| 18 | Frappeur sauvage |  | PHB14 (2014, origin) | SRD mais texte non conforme | SRD 5.2 | nom, description (185 car.), prérequis, bonus de caractéristique | texte 2014 reformulé ; homonyme don d'origine 2024 au SRD 5.2 | 0.52 |
| 19 | Sentinelle |  | PHB14 (2014, general) | hors SRD |  | nom, description (351 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.05 |
| 20 | Tireur d'élite |  | PHB14 (2014, general) | hors SRD |  | nom, description (330 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.02 |
| 21 | Maître du bouclier |  | PHB14 (2014, general) | hors SRD |  | nom, description (415 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.14 |
| 22 | Qualifié |  | PHB14 (2014, origin) | SRD mais texte non conforme | SRD 5.2 | nom, description (70 car.), prérequis, bonus de caractéristique | texte 2014 reformulé ; homonyme don d'origine 2024 au SRD 5.2 | 0.25 |
| 23 | Bagarreur de taverne |  | PHB14 (2014, origin) | hors SRD |  | nom, description (305 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.06 |
| 24 | Robuste physiquement |  | PHB14 (2014, origin) | hors SRD |  | nom, description (152 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.09 |
| 25 | Maître d'armes |  | PHB14 (2014, legacy) | hors SRD |  | nom, description (105 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.12 |
| 26 | Armure légère |  | PHB14 (2014, general) | hors SRD |  | nom, description (94 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.15 |
| 27 | Duelliste défensif |  | PHB14 (2014, general) | hors SRD |  | nom, description (246 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.13 |
| 28 | Sournois |  | PHB14 (2014, general) | hors SRD |  | nom, description (234 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.00 |
| 29 | Meneur inspirant |  | PHB14 (2014, general) | hors SRD |  | nom, description (310 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.18 |
| 30 | Observateur |  | PHB14 (2014, general) | hors SRD |  | nom, description (258 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.05 |
| 31 | Armure lourde |  | PHB14 (2014, general) | hors SRD |  | nom, description (81 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.09 |
| 32 | Maître de l'armure intermédiaire |  | PHB14 (2014, general) | hors SRD |  | nom, description (233 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.11 |
| 33 | Armure intermédiaire |  | PHB14 (2014, general) | hors SRD |  | nom, description (125 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.12 |
| 34 | Maître de l'armure lourde |  | PHB14 (2014, general) | hors SRD |  | nom, description (182 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.15 |
| 35 | Adepte élémentaire |  | PHB14 (2014, general) | hors SRD |  | nom, description (319 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.05 |
| 36 | Tireur d'élite occulte |  | PHB14 (2014, general) | hors SRD |  | nom, description (385 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.11 |
| 37 | Guerrier-sorcier |  | PHB14 (2014, general) | hors SRD |  | nom, description (347 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.25 |
| 38 | Rituels magiques |  | PHB14 (2014, general) | hors SRD |  | nom, description (456 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.04 |
| 39 | Linguiste |  | PHB14 (2014, legacy) | hors SRD |  | nom, description (312 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.04 |
| 40 | Esprit vif |  | PHB14 (2014, general) | hors SRD |  | nom, description (281 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.02 |
| 41 | Chanceux |  | PHB14 (2014, origin) | hors SRD |  | nom, description (360 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.10 |
| 42 | Empoignade |  | PHB14 (2014, general) | SRD 5.1 | SRD 5.1 | nom, description (476 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.32 |
| 43 | Faveur de prouesse martiale | Boon of Combat Prowess | SRD52 (2024, epic_boon) | SRD 5.2 | SRD 5.2 | nom, description (281 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.2 anglais | 0.38 |
| 44 | Faveur de voyage dimensionnel | Boon of Dimensional Travel | SRD52 (2024, epic_boon) | SRD 5.2 | SRD 5.2 | nom, description (252 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.2 anglais | 0.45 |
| 45 | Faveur du destin | Boon of Fate | SRD52 (2024, epic_boon) | SRD 5.2 | SRD 5.2 | nom, description (418 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.2 anglais | 0.34 |
| 46 | Faveur d'offensive irrésistible | Boon of Irresistible Offense | SRD52 (2024, epic_boon) | SRD 5.2 | SRD 5.2 | nom, description (409 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.2 anglais | 0.39 |
| 47 | Faveur de rappel des sorts | Boon of Spell Recall | SRD52 (2024, epic_boon) | SRD 5.2 | SRD 5.2 | nom, description (267 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.2 anglais | 0.50 |
| 48 | Faveur de l'esprit nocturne | Boon of the Night Spirit | SRD52 (2024, epic_boon) | SRD 5.2 | SRD 5.2 | nom, description (434 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.2 anglais | 0.37 |
| 49 | Faveur de vision véritable | Boon of Truesight | SRD52 (2024, epic_boon) | SRD 5.2 | SRD 5.2 | nom, description (163 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.2 anglais | 0.38 |
| 50 | Faveur de résistance énergétique | Boon of Energy Resistance | PHB24 (2024, epic_boon) | hors SRD |  | nom, description (621 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.18 |
| 51 | Faveur de robustesse | Boon of Fortitude | PHB24 (2024, epic_boon) | hors SRD |  | nom, description (383 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.30 |
| 52 | Faveur de récupération | Boon of Recovery | PHB24 (2024, epic_boon) | hors SRD |  | nom, description (526 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.31 |
| 53 | Faveur de compétence | Boon of Skill | PHB24 (2024, epic_boon) | hors SRD |  | nom, description (279 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.25 |
| 54 | Faveur de célérité | Boon of Speed | PHB24 (2024, epic_boon) | hors SRD |  | nom, description (354 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.26 |
| 55 | Chance généreuse | Bountiful Luck | XGtE (2014, legacy) | hors SRD |  | nom, description (361 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.28 |
| 56 | Terreur draconique | Dragon Fear | XGtE (2014, legacy) | hors SRD |  | nom, description (413 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.23 |
| 57 | Peau de dragon | Dragon Hide | XGtE (2014, legacy) | hors SRD |  | nom, description (343 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.19 |
| 58 | Haute magie drow | Drow High Magic | XGtE (2014, legacy) | hors SRD |  | nom, description (348 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.41 |
| 59 | Robustesse naine | Dwarven Fortitude | XGtE (2014, legacy) | hors SRD |  | nom, description (225 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.35 |
| 60 | Précision elfique | Elven Accuracy | XGtE (2014, legacy) | hors SRD |  | nom, description (216 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.29 |
| 61 | Évanescence | Fade Away | XGtE (2014, legacy) | hors SRD |  | nom, description (361 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.19 |
| 62 | Téléportation féerique | Fey Teleportation | XGtE (2014, legacy) | hors SRD |  | nom, description (295 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.20 |
| 63 | Flammes de Phlégéthos | Flames of Phlegethos | XGtE (2014, legacy) | hors SRD |  | nom, description (457 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.22 |
| 64 | Constitution infernale | Infernal Constitution | XGtE (2014, legacy) | hors SRD |  | nom, description (160 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.46 |
| 65 | Fureur orque | Orcish Fury | XGtE (2014, legacy) | hors SRD |  | nom, description (394 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.17 |
| 66 | Prodige | Prodigy | XGtE (2014, legacy) | hors SRD |  | nom, description (246 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.16 |
| 67 | Seconde chance | Second Chance | XGtE (2014, legacy) | hors SRD |  | nom, description (290 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.34 |
| 68 | Agilité trapue | Squat Nimbleness | XGtE (2014, legacy) | hors SRD |  | nom, description (253 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.28 |
| 69 | Magie des elfes sylvains | Wood Elf Magic | XGtE (2014, legacy) | hors SRD |  | nom, description (301 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.26 |
| 70 | Initié artificier | Artificer Initiate | TCoE (2014, legacy) | hors SRD |  | nom, description (419 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.28 |
| 71 | Chef | Chef | TCoE (2014, general) | hors SRD |  | nom, description (511 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.20 |
| 72 | Écraseur | Crusher | TCoE (2014, general) | hors SRD |  | nom, description (442 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.22 |
| 73 | Adepte occulte | Eldritch Adept | TCoE (2014, legacy) | hors SRD |  | nom, description (253 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.15 |
| 74 | Touché par les fées | Fey Touched | TCoE (2014, general) | hors SRD |  | nom, description (368 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.16 |
| 75 | Initié au combat | Fighting Initiate | TCoE (2014, legacy) | hors SRD |  | nom, description (271 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.15 |
| 76 | Artilleur | Gunner | TCoE (2014, legacy) | hors SRD |  | nom, description (227 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.15 |
| 77 | Adepte de la métamagie | Metamagic Adept | TCoE (2014, legacy) | hors SRD |  | nom, description (466 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.16 |
| 78 | Perforateur | Piercer | TCoE (2014, general) | hors SRD |  | nom, description (335 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.26 |
| 79 | Empoisonneur | Poisoner | TCoE (2014, general) | hors SRD |  | nom, description (520 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.18 |
| 80 | Touché par l'ombre | Shadow Touched | TCoE (2014, general) | hors SRD |  | nom, description (366 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.17 |
| 81 | Expert en compétences | Skill Expert | TCoE (2014, general) | hors SRD |  | nom, description (258 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.25 |
| 82 | Trancheur | Slasher | TCoE (2014, general) | hors SRD |  | nom, description (381 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.44 |
| 83 | Télékinésiste | Telekinetic | TCoE (2014, general) | hors SRD |  | nom, description (490 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.19 |
| 84 | Télépathe | Telepathic | TCoE (2014, general) | hors SRD |  | nom, description (487 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.09 |
| 85 | Amélioration de caractéristique | Ability Score Improvement | SRD52 (2024, general) | SRD 5.2 | SRD 5.2 | nom, description (243 car.), prérequis, bonus de caractéristique | traduction non officielle du SRD 5.2 anglais | 0.17 |
| 86 | Artisan | Crafter | PHB24 (2024, origin) | hors SRD |  | nom, description (409 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.14 |
| 87 | Musicien | Musician | PHB24 (2024, origin) | hors SRD |  | nom, description (323 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.18 |
| 88 | Entraînement aux armes de guerre | Martial Weapon Training | PHB24 (2024, general) | hors SRD |  | nom, description (188 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.07 |
| 89 | Véloce | Speedy | PHB24 (2024, general) | hors SRD |  | nom, description (283 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.15 |
| 90 | Don du dragon chromatique | Gift of the Chromatic Dragon | FToD (2014, legacy) | hors SRD |  | nom, description (630 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.25 |
| 91 | Don du dragon de gemme | Gift of the Gem Dragon | FToD (2014, legacy) | hors SRD |  | nom, description (589 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.21 |
| 92 | Don du dragon métallique | Gift of the Metallic Dragon | FToD (2014, legacy) | hors SRD |  | nom, description (681 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.23 |
| 93 | Frappe des géants | Strike of the Giants | BGG (2014, legacy) | hors SRD |  | nom, description (1245 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.23 |
| 94 | Braise du géant du feu | Ember of the Fire Giant | BGG (2014, legacy) | hors SRD |  | nom, description (770 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.28 |
| 95 | Fureur du géant du givre | Fury of the Frost Giant | BGG (2014, legacy) | hors SRD |  | nom, description (670 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.22 |
| 96 | Ruse du géant des nuages | Guile of the Cloud Giant | BGG (2014, legacy) | hors SRD |  | nom, description (391 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.33 |
| 97 | Acuité du géant des pierres | Keenness of the Stone Giant | BGG (2014, legacy) | hors SRD |  | nom, description (623 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.22 |
| 98 | Âme du géant des tempêtes | Soul of the Storm Giant | BGG (2014, legacy) | hors SRD |  | nom, description (754 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.25 |
| 99 | Vigueur du géant des collines | Vigor of the Hill Giant | BGG (2014, legacy) | hors SRD |  | nom, description (467 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.19 |
| 100 | Façonneur de runes | Rune Shaper | BGG (2014, legacy) | hors SRD |  | nom, description (1216 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.11 |
| 101 | Rejeton des plans extérieurs | Scion of the Outer Planes | PSAiM (2014, legacy) | hors SRD |  | nom, description (541 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.01 |
| 102 | Agent de l'ordre | Agent of Order | PSAiM (2014, legacy) | hors SRD |  | nom, description (591 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.31 |
| 103 | Rejeton funeste | Baleful Scion | PSAiM (2014, legacy) | hors SRD |  | nom, description (402 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.26 |
| 104 | Cohorte du chaos | Cohort of Chaos | PSAiM (2014, legacy) | hors SRD |  | nom, description (986 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.26 |
| 105 | Émissaire des Terres Extérieures | Outlands Envoy | PSAiM (2014, legacy) | hors SRD |  | nom, description (410 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.05 |
| 106 | Vagabond planaire | Planar Wanderer | PSAiM (2014, legacy) | hors SRD |  | nom, description (860 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.16 |
| 107 | Héritier vertueux | Righteous Heritor | PSAiM (2014, legacy) | hors SRD |  | nom, description (340 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.22 |
| 108 | Initié de la Haute Sorcellerie | Initiate of High Sorcery | DSotDQ (2014, legacy) | hors SRD |  | nom, description (763 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.05 |
| 109 | Adepte des Robes noires | Adept of the Black Robes | DSotDQ (2014, legacy) | hors SRD |  | nom, description (565 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.13 |
| 110 | Adepte des Robes rouges | Adept of the Red Robes | DSotDQ (2014, legacy) | hors SRD |  | nom, description (535 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.17 |
| 111 | Adepte des Robes blanches | Adept of the White Robes | DSotDQ (2014, legacy) | hors SRD |  | nom, description (596 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.17 |
| 112 | Favori divin | Divinely Favored | DSotDQ (2014, legacy) | hors SRD |  | nom, description (606 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.03 |
| 113 | Écuyer de Solamnie | Squire of Solamnia | DSotDQ (2014, legacy) | hors SRD |  | nom, description (421 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.22 |
| 114 | Chevalier de la Couronne | Knight of the Crown | DSotDQ (2014, legacy) | hors SRD |  | nom, description (393 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.14 |
| 115 | Chevalier de la Rose | Knight of the Rose | DSotDQ (2014, legacy) | hors SRD |  | nom, description (430 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.15 |
| 116 | Chevalier de l'Épée | Knight of the Sword | DSotDQ (2014, legacy) | hors SRD |  | nom, description (583 car.), prérequis, bonus de caractéristique | reformulation maison (« entièrement originale » selon la migration) | 0.33 |

</details>

### 2.10 Invocations d'occultiste (54)

Pas de colonne source. Les 32 invocations du Manuel des Joueurs sont toutes au SRD 5.1 (texte : traduction non officielle du SRD anglais). 5 invocations de Xanathar/Tasha ont un homonyme 2024 au SRD 5.2.

Répartition : SRD 5.1 32, SRD mais texte non conforme 5, hors SRD 17.

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Décharge agonisante |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (114 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.31 |
| 2 | Armure des ombres |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (123 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.56 |
| 3 | Pas ascendant |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (119 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.86 |
| 4 | Langage des bêtes |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (90 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.64 |
| 5 | Influence trompeuse |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (64 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.00 |
| 6 | Murmures ensorcelants |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (156 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.36 |
| 7 | Livre des secrets anciens |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (670 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.19 |
| 8 | Chaînes de Carceri |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (271 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.40 |
| 9 | Vision du diable |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (71 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.00 |
| 10 | Parole funeste |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (155 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.41 |
| 11 | Vue occulte |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (88 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 1.00 |
| 12 | Lance occulte |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (66 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.43 |
| 13 | Yeux du gardien des runes |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (43 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.00 |
| 14 | Vigueur fiélonne |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (152 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.45 |
| 15 | Regard des deux esprits |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (370 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.19 |
| 16 | Buveur de vie |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (162 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.62 |
| 17 | Masque aux mille visages |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (78 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 1.00 |
| 18 | Maître des mille formes |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (91 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 1.00 |
| 19 | Serviteurs du chaos |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (171 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.29 |
| 20 | Engluer l'esprit |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (153 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.41 |
| 21 | Visions brumeuses |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (112 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.85 |
| 22 | Un avec les ombres |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (194 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.24 |
| 23 | Bond d'un autre monde |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (113 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.57 |
| 24 | Décharge repoussante |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (115 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.73 |
| 25 | Sculpteur de chair |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (158 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.41 |
| 26 | Signe de mauvais augure |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (157 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.41 |
| 27 | Voleur des cinq destins |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (154 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.27 |
| 28 | Lame assoiffée |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (133 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.33 |
| 29 | Visions des royaumes lointains |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (79 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.44 |
| 30 | Voix du maître de la chaîne |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (246 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.33 |
| 31 | Murmures de la tombe |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (95 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 1.00 |
| 32 | Vision de sorcière |  | (pas de colonne) Manuel des Joueurs | SRD 5.1 | SRD 5.1 (homonyme 2024 au SRD 5.2 pour la plupart) | nom, description (216 car.), prérequis | traduction non officielle du SRD 5.1 anglais (en-tête de migration) | 0.14 |
| 33 | Aspect de la lune | Aspect of the Moon | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (243 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.05 |
| 34 | Manteau de mouches | Cloak of Flies | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (586 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.20 |
| 35 | Châtiment occulte | Eldritch Smite | (pas de colonne) Xanathar / Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (295 car.), prérequis | texte Xanathar/Tasha reformulé ; homonyme 2024 au SRD 5.2 | 0.54 |
| 36 | Regard spectral | Ghostly Gaze | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (354 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.19 |
| 37 | Don des profondeurs | Gift of the Depths | (pas de colonne) Xanathar / Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (245 car.), prérequis | texte Xanathar/Tasha reformulé ; homonyme 2024 au SRD 5.2 | 0.51 |
| 38 | Don des Éternels | Gift of the Ever-Living Ones | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (220 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.17 |
| 39 | Étreinte d'Hadar | Grasp of Hadar | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (139 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.43 |
| 40 | Arme de pacte améliorée | Improved Pact Weapon | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (385 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.20 |
| 41 | Lance de léthargie | Lance of Lethargy | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (158 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.68 |
| 42 | Maléfice affolant | Maddening Hex | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (436 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.23 |
| 43 | Maléfice implacable | Relentless Hex | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (318 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.23 |
| 44 | Voile d'ombre | Shroud of Shadow | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (79 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.50 |
| 45 | Tombe de Levistus | Tomb of Levistus | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (526 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.19 |
| 46 | Évasion du mystificateur | Trickster's Escape | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (155 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.30 |
| 47 | Lien du talisman | Bond of the Talisman | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (399 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.24 |
| 48 | Esprit occulte | Eldritch Mind | (pas de colonne) Xanathar / Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (117 car.), prérequis | texte Xanathar/Tasha reformulé ; homonyme 2024 au SRD 5.2 | 0.64 |
| 49 | Scribe lointain | Far Scribe | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (483 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.17 |
| 50 | Don des protecteurs | Gift of the Protectors | (pas de colonne) Xanathar / Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (514 car.), prérequis | texte Xanathar/Tasha reformulé ; homonyme 2024 au SRD 5.2 | 0.32 |
| 51 | Investiture du maître de la chaîne | Investment of the Chain Master | (pas de colonne) Xanathar / Tasha | SRD mais texte non conforme | SRD 5.2 | nom, description (473 car.), prérequis | texte Xanathar/Tasha reformulé ; homonyme 2024 au SRD 5.2 | 0.12 |
| 52 | Protection du talisman | Protection of the Talisman | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (289 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.23 |
| 53 | Réprimande du talisman | Rebuke of the Talisman | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (261 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.18 |
| 54 | Servitude éternelle | Undying Servitude | (pas de colonne) Xanathar / Tasha | hors SRD |  | nom, description (131 car.), prérequis | reformulation d'après Xanathar/Tasha | 0.37 |

### 2.11 Historiques (71)

Pas de colonne source (la source est rappelée dans le texte pour les historiques ajoutés au lot 7). SRD 5.1 : Acolyte seulement. SRD 5.2 : Acolyte, Criminel, Sage, Soldat, avec une mécanique 2024 différente (dons d'origine, caractéristiques) ; en base, la version 2014.

Répartition : SRD mais texte non conforme 4, hors SRD 67.

<details><summary>Tableau complet (71 lignes)</summary>

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Acolyte |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description, aptitude « Refuge du fidèle » (246 car. au total), maîtrises, équipement | reformulation maison | 0.03 |
| 2 | Charlatan |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Fausse identité » (229 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 3 | Criminel/Espion |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description, aptitude « Contact criminel » (202 car. au total), maîtrises, équipement | version 2014 reformulée ; homonyme 2024 au SRD 5.2 (mécanique différente) | 0.00 |
| 4 | Artiste |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Public conquis » (207 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 5 | Héros du peuple |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Hospitalité rustique » (239 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 6 | Artisan de guilde |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Adhésion à la guilde » (227 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 7 | Ermite |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Découverte » (207 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 8 | Noble |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Position privilégiée » (196 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 9 | Solitaire |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Guide itinérant » (186 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 10 | Sage |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description, aptitude « Chercheur » (205 car. au total), maîtrises, équipement | version 2014 reformulée ; homonyme 2024 au SRD 5.2 (mécanique différente) | 0.00 |
| 11 | Marin |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Passager clandestin » (197 car. au total), maîtrises, équipement | reformulation maison | 0.03 |
| 12 | Soldat |  | (pas de colonne) Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description, aptitude « Grade militaire » (206 car. au total), maîtrises, équipement | version 2014 reformulée ; homonyme 2024 au SRD 5.2 (mécanique différente) | 0.00 |
| 13 | Gamin des rues |  | (pas de colonne) Manuel des Joueurs | hors SRD |  | nom, description, aptitude « Contacts dans la ville » (216 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 14 | Chevalier |  | (pas de colonne) Manuel des Joueurs (SCAG/Chevalier, Pirate) | hors SRD |  | nom, description, aptitude « Retenue » (228 car. au total), maîtrises, équipement | reformulation maison | 0.03 |
| 15 | Pirate |  | (pas de colonne) Manuel des Joueurs (SCAG/Chevalier, Pirate) | hors SRD |  | nom, description, aptitude « Réputation flibustière » (195 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 16 | Garde urbain | City Watch | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Œil du guetteur » (289 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 17 | Artisan de clan | Clan Crafter | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Respect du peuple robuste » (301 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 18 | Érudit cloîtré | Cloistered Scholar | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Accès aux bibliothèques » (300 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 19 | Courtisan | Courtier | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Fonctionnaire de cour » (281 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 20 | Agent de faction | Faction Agent | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Refuge sûr » (369 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 21 | Héritier | Inheritor | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Héritage » (281 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 22 | Chevalier d'un ordre | Knight of the Order | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Considération chevaleresque » (258 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 23 | Vétéran mercenaire | Mercenary Veteran | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Vie de mercenaire » (281 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 24 | Chasseur de primes urbain | Urban Bounty Hunter | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « À l'écoute de la rue » (284 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 25 | Membre d'une tribu uthgardt | Uthgardt Tribe Member | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Héritage uthgardt » (355 car. au total), maîtrises, équipement | reformulation maison | 0.07 |
| 26 | Noble de Waterdeep | Waterdhavian Noble | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Train de vie assuré » (304 car. au total), maîtrises, équipement | reformulation maison | 0.02 |
| 27 | Anthropologue | Anthropologist | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Linguiste adepte » (290 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 28 | Archéologue | Archaeologist | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Connaissances historiques » (269 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 29 | Athlète | Athlete | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Échos de victoire » (332 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 30 | Sans-visage | Faceless | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Double personnalité » (324 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 31 | Égaré féerique | Feylost | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Lien avec la Féerie » (284 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 32 | Main du Carnaval | Witchlight Hand | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Pilier du carnaval » (301 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 33 | Pêcheur | Fisher | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Récolter les eaux » (268 car. au total), maîtrises, équipement | reformulation maison | 0.05 |
| 34 | Soldat de marine | Marine | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Stoïque » (315 car. au total), maîtrises, équipement | reformulation maison | 0.02 |
| 35 | Charpentier de marine | Shipwright | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Je vais le colmater ! » (304 car. au total), maîtrises, équipement | reformulation maison | 0.02 |
| 36 | Contrebandier | Smuggler | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Profil bas » (272 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 37 | Enfant trouvé des géants | Giant Foundling | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Frappe des géants » (410 car. au total), maîtrises, équipement | reformulation maison | 0.08 |
| 38 | Graveur de runes | Rune Carver | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Façonneur de runes » (381 car. au total), maîtrises, équipement | reformulation maison | 0.08 |
| 39 | Hanté | Haunted One | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Cœur de ténèbres » (318 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 40 | Agent d'une maison | House Agent | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Relations de la maison » (274 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 41 | Enquêteur | Investigator | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Enquête officielle » (315 car. au total), maîtrises, équipement | reformulation maison | 0.02 |
| 42 | Récompensé | Rewarded | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Faveur du destin » (323 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 43 | Déchu | Ruined | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Toujours debout » (362 car. au total), maîtrises, équipement | reformulation maison | 0.23 |
| 44 | Rejeton d'aventuriers célèbres | Celebrity Adventurer's Scion | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Faire jouer ses relations » (279 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 45 | Marchand ruiné | Failed Merchant | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Chaîne d'approvisionnement » (247 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 46 | Joueur | Gambler | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Ne me parlez pas des probabilités » (252 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 47 | Plaignant | Plaintiff | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Jargon juridique » (299 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 48 | Stagiaire rival | Rival Intern | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Informateur interne » (245 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 49 | Chevalier de Solamnie | Knight of Solamnia | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Écuyer de Solamnie » (324 car. au total), maîtrises, équipement | reformulation maison | 0.10 |
| 50 | Mage de la haute sorcellerie | Mage of High Sorcery | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Initié de la haute sorcellerie » (340 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 51 | Gardien de portail | Gate Warden | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Infusion planaire » (283 car. au total), maîtrises, équipement | reformulation maison | 0.07 |
| 52 | Philosophe planaire | Planar Philosopher | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Conviction » (315 car. au total), maîtrises, équipement | reformulation maison | 0.06 |
| 53 | Fonctionnaire azorius | Azorius Functionary | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Autorité légale » (332 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 54 | Légionnaire boros | Boros Legionnaire | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Poste de la Légion » (326 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 55 | Agent dimir | Dimir Operative | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Fausse identité » (247 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 56 | Agent golgari | Golgari Agent | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Chemins de la sous-cité » (323 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 57 | Anarchiste gruul | Gruul Anarch | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Refuge des Friches » (276 car. au total), maîtrises, équipement | reformulation maison | 0.02 |
| 58 | Ingénieur izzet | Izzet Engineer | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Infrastructures urbaines » (287 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 59 | Représentant orzhov | Orzhov Representative | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Influence » (293 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 60 | Cultiste rakdos | Rakdos Cultist | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Réputation effrayante » (301 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 61 | Initié selesnya | Selesnya Initiate | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Abri du Conclave » (277 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 62 | Scientifique simic | Simic Scientist | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Chercheur » (305 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 63 | Étudiant de Lorehold | Lorehold Student | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Initié de Lorehold » (328 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 64 | Étudiant de Prismari | Prismari Student | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Initié de Prismari » (332 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 65 | Étudiant de Quandrix | Quandrix Student | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Initié de Quandrix » (329 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 66 | Étudiant de Silverquill | Silverquill Student | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Initié de Silverquill » (330 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 67 | Étudiant de Witherbloom | Witherbloom Student | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Initié de Witherbloom » (336 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 68 | Rieur | Grinner | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Ballade du bouffon souriant » (300 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 69 | Agent volstrucker | Volstrucker Agent | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Réseau de l'ombre » (273 car. au total), maîtrises, équipement | reformulation maison | 0.00 |
| 70 | Vagabond astral | Astral Drifter | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Contact divin » (288 car. au total), maîtrises, équipement | reformulation maison | 0.05 |
| 71 | Spatien | Wildspacer | (pas de colonne) supplément (rappelé en fin de description) | hors SRD |  | nom, description, aptitude « Adaptation à l'espace sauvage » (298 car. au total), maîtrises, équipement | reformulation maison | 0.00 |

</details>

### 2.12 Sorts (514)

Deux textes par sort : description française (affichée) et description anglaise (non affichée, mais lisible par `anon`). « Nom EN » = nom du sort SRD rapproché. Pour les sorts SRD 5.1, le texte anglais est celui du SRD (conforme) mais le texte français affiché ne l'est pas, d'où le classement « SRD mais texte non conforme ».

Répartition : SRD 5.2 6, SRD mais texte non conforme 334, hors SRD 174.

<details><summary>Tableau complet (514 lignes)</summary>

| id | Élément | Nom EN | Source déclarée | Classification | Réf. SRD | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|---|
| 1 | Acide fusant | Acid Splash | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (183 car.), description EN (344 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.78) | 0.15 |
| 2 | Assistance | Guidance | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (160 car.), description EN (229 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.20 |
| 3 | Aspersion empoisonnée | Poison Spray | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (145 car.), description EN (312 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.55 |
| 4 | Avertissement occulte | True Strike | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (148 car.), description EN (250 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.10 |
| 5 | Baguette d'illusion | Minor Illusion | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (1070 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 6 | Contact glacial | Chill Touch | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (156 car.), description EN (549 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.14 |
| 7 | Création de flamme | Produce Flame | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (112 car.), description EN (656 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 8 | Décharge occulte | Eldritch Blast | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (142 car.), description EN (417 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.23 |
| 10 | Druidisme | Druidcraft | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (136 car.), description EN (90 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 11 | Épargner les mourants | Spare the Dying | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (96 car.), description EN (129 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.15 |
| 12 | Flamme sacrée | Sacred Flame | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (143 car.), description EN (324 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.59 |
| 13 | Fouet d'épines |  | Manuel des Joueurs | hors SRD |  | nom, description FR (118 car.), description EN (419 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 14 | Lame acérée | Shocking Grasp | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (184 car.), description EN (433 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 15 | Lueurs dansantes | Dancing Lights | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (128 car.), description EN (543 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.25 |
| 16 | Lumière | Light | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (491 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.30 |
| 17 | Main du mage | Mage Hand | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (143 car.), description EN (583 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.14 |
| 18 | Message | Message | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (119 car.), description EN (518 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 19 | Mot moqueur | Vicious Mockery | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (154 car.), description EN (432 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.05 |
| 20 | Prestidigitation | Prestidigitation | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (150 car.), description EN (305 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.82) | 0.00 |
| 21 | Rayon de givre | Ray of Frost | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (173 car.), description EN (336 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.11 |
| 22 | Réparation | Mending | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (395 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.06 |
| 23 | Résistance | Resistance | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (121 car.), description EN (227 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.26 |
| 24 | Thaumaturgie | Thaumaturgy | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (119 car.), description EN (290 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.82) | 0.00 |
| 25 | Trait de feu | Fire Bolt | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (177 car.), description EN (347 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.25 |
| 26 | Trique noueuse | Shillelagh | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (194 car.), description EN (389 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.30 |
| 27 | Alarme | Alarm | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (132 car.), description EN (606 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 28 | Armure de mage | Mage Armor | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (148 car.), description EN (259 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.14 |
| 29 | Bénédiction | Bless | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (115 car.), description EN (366 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.31 |
| 30 | Bouclier | Shield | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (174 car.), description EN (209 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.37 |
| 31 | Bouclier de la foi | Shield of Faith | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (136 car.), description EN (127 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.23 |
| 32 | Charme-personne | Charm Person | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (141 car.), description EN (630 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.64 |
| 33 | Compréhension des langues | Comprehend Languages | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (134 car.), description EN (393 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.15 |
| 34 | Déguisement | Disguise Self | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (137 car.), description EN (999 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.43 |
| 35 | Détection de la magie | Detect Magic | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (102 car.), description EN (410 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.25 |
| 36 | Détection du mal et du bien | Detect Evil and Good | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (200 car.), description EN (436 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.03 |
| 37 | Feu follet | Faerie Fire | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (150 car.), description EN (468 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.32 |
| 38 | Flétrissure | Bane | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (443 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.18 |
| 39 | Identification | Identify | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (514 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.06 |
| 40 | Chute plume | Feather Fall | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (141 car.), description EN (271 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.22 |
| 41 | Marque du chasseur | Hunter's Mark | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (133 car.), description EN (684 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 42 | Mot de guérison | Healing Word | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (143 car.), description EN (304 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.32 |
| 43 | Murmures dissonants | Dissonant Whispers | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (167 car.), description EN (675 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.04 |
| 44 | Parole avec les animaux | Speak with Animals | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (114 car.), description EN (423 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.20 |
| 45 | Projectile magique | Magic Missile | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (159 car.), description EN (394 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.20 |
| 46 | Protection contre le mal et le bien | Protection from Evil and Good | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (137 car.), description EN (508 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 47 | Rire hideux de Tasha | Hideous Laughter | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (167 car.), description EN (568 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.40 |
| 48 | Sanctuaire | Sanctuary | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (170 car.), description EN (508 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.85) | 0.33 |
| 49 | Serviteur invisible | Unseen Servant | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (904 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 50 | Soins | Cure Wounds | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (134 car.), description EN (281 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.44 |
| 51 | Sommeil | Sleep | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (184 car.), description EN (941 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.13 |
| 52 | Vague tonnerre | Thunderwave | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (158 car.), description EN (648 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.00 |
| 53 | Vaillance | Heroism | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (155 car.), description EN (456 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.30 |
| 54 | Vitesse supérieure | Longstrider | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (86 car.), description EN (222 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.15 |
| 55 | Écriture illusoire | Illusory Script | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (154 car.), description EN (743 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.04 |
| 56 | Image silencieuse | Silent Image | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (956 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.64 |
| 57 | Bond | Jump | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (85 car.), description EN (83 car.), méta (niveau, école, portée...) | FR : traduction maison phase 1 ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 58 | Absorption des éléments |  | Guide de Xanathar | hors SRD |  | nom, description FR (121 car.), description EN (486 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 59 | Agrandissement/Rapetissement | Enlarge/Reduce | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (79 car.), description EN (1463 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.00 |
| 60 | Aide | Aid | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (75 car.), description EN (339 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 61 | Allié planaire | Planar Ally | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (121 car.), description EN (2229 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.19 |
| 62 | Amélioration de caractéristique | Enhance Ability | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (117 car.), description EN (774 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.80) | 0.07 |
| 63 | Amélioration de compétences |  | Guide de Xanathar | hors SRD |  | nom, description FR (58 car.), description EN (430 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.17 |
| 64 | Amis |  | Manuel des Joueurs | hors SRD |  | nom, description FR (106 car.), description EN (427 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.07 |
| 65 | Amitié avec les animaux | Animal Friendship | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (93 car.), description EN (504 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.00 |
| 66 | Animation d'objets | Animate Objects | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (93 car.), description EN (2135 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 67 | Animation des morts | Animate Dead | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (122 car.), description EN (1598 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.00 |
| 68 | Antidétection | Nondetection | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (74 car.), description EN (274 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.25 |
| 69 | Apaisement des émotions | Calm Emotions | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (828 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.91) | 0.21 |
| 70 | Apparence d'Outremonde de Tasha |  | Chaudron de Tasha | hors SRD |  | nom, description FR (122 car.), description EN (173 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 71 | Apparence trompeuse | Seeming | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (80 car.), description EN (1321 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 72 | Appel de destrier | Find Steed | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (96 car.), description EN (1417 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.08 |
| 73 | Appel de destrier supérieur |  | Guide de Xanathar | hors SRD |  | nom, description FR (99 car.), description EN (1462 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.08 |
| 74 | Appel de familier | Find Familiar | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (101 car.), description EN (2126 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.82) | 0.00 |
| 75 | Appel de la foudre | Call Lightning | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (1122 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.23 |
| 76 | Arme élémentaire |  | Manuel des Joueurs | hors SRD |  | nom, description FR (118 car.), description EN (521 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.10 |
| 77 | Arme magique | Magic Weapon | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (89 car.), description EN (310 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 78 | Arme sacrée |  | Guide de Xanathar | hors SRD |  | nom, description FR (124 car.), description EN (840 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 79 | Arme spirituelle | Spiritual Weapon | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (128 car.), description EN (801 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 80 | Armure d'Agathys |  | Manuel des Joueurs | hors SRD |  | nom, description FR (128 car.), description EN (428 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 81 | Arrêt du temps | Time Stop | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (75 car.), description EN (511 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.09 |
| 82 | Assassin imaginaire | Phantasmal Killer | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (575 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.91) | 0.11 |
| 83 | Assignation infernale |  | Guide de Xanathar | hors SRD |  | nom, description FR (41 car.), description EN (2129 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 84 | Attraction terrestre |  | Guide de Xanathar | hors SRD |  | nom, description FR (104 car.), description EN (359 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.19 |
| 85 | Aube |  | Guide de Xanathar | hors SRD |  | nom, description FR (104 car.), description EN (555 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 86 | Augure | Augury | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (128 car.), description EN (694 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.82) | 0.06 |
| 87 | Aura de pureté |  | Manuel des Joueurs | hors SRD |  | nom, description FR (118 car.), description EN (410 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.21 |
| 88 | Aura de vie | Aura of Life | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (126 car.), description EN (388 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.30 |
| 89 | Aura de vitalité |  | Manuel des Joueurs | hors SRD |  | nom, description FR (46 car.), description EN (233 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.43 |
| 90 | Aura du croisé |  | Manuel des Joueurs | hors SRD |  | nom, description FR (118 car.), description EN (309 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.12 |
| 91 | Aura magique de Nystul | Arcanist's Magic Aura | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (113 car.), description EN (1226 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.28 |
| 92 | Aura sacrée | Holy Aura | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (544 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.89) | 0.10 |
| 93 | Aversion/Attirance | Antipathy/Sympathy | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (120 car.), description EN (2267 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.10 |
| 94 | Bagou | Glibness | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (83 car.), description EN (233 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 95 | Baies nourricières | Goodberry | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (90 car.), description EN (353 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 96 | Bannissement | Banishment | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (102 car.), description EN (967 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.07 |
| 97 | Barrière de lames | Blade Barrier | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (662 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.91) | 0.00 |
| 98 | Blessure | Inflict Wounds | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (72 car.), description EN (237 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.78) | 0.00 |
| 99 | Bosquet des druides |  | Guide de Xanathar | hors SRD |  | nom, description FR (102 car.), description EN (2434 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 100 | Bouche magique | Magic Mouth | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (113 car.), description EN (1221 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.07 |
| 101 | Bouclier de feu | Fire Shield | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (601 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.10 |
| 102 | Boule de feu | Fireball | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (106 car.), description EN (577 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.86) | 0.22 |
| 103 | Boule de feu à retardement | Delayed Blast Fireball | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (1287 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.05 |
| 104 | Bourrasque | Gust of Wind | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (100 car.), description EN (740 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 105 | Brassage caustique de Tasha |  | Chaudron de Tasha | hors SRD |  | nom, description FR (124 car.), description EN (521 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 106 | Brume mortelle | Cloudkill | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (120 car.), description EN (928 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.86) | 0.25 |
| 107 | Cage de force | Forcecage | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (1240 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 108 | Cage des âmes |  | Guide de Xanathar | hors SRD |  | nom, description FR (121 car.), description EN (1725 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 109 | Carquois magique |  | Manuel des Joueurs | hors SRD |  | nom, description FR (117 car.), description EN (573 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 110 | Catapulte |  | Guide de Xanathar | hors SRD |  | nom, description FR (116 car.), description EN (724 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.04 |
| 111 | Cécité/Surdité | Blindness/Deafness | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (88 car.), description EN (454 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.08 |
| 112 | Cercle de mort | Circle of Death | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (384 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.79) | 0.26 |
| 113 | Cercle de pouvoir |  | Manuel des Joueurs | hors SRD |  | nom, description FR (110 car.), description EN (536 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.47 |
| 114 | Cercle de téléportation | Teleportation Circle | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (110 car.), description EN (1238 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 115 | Cercle magique | Magic Circle | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (113 car.), description EN (732 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.89) | 0.06 |
| 116 | Cérémonie |  | Guide de Xanathar | hors SRD |  | nom, description FR (102 car.), description EN (1271 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 117 | Chaîne d'éclairs | Chain Lightning | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (106 car.), description EN (633 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 118 | Champ antimagie | Antimagic Field | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (100 car.), description EN (2507 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.20 |
| 119 | Changement de forme | Shapechange | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (97 car.), description EN (2352 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.99) | 0.17 |
| 120 | Changement de plan | Plane Shift | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (1241 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.11 |
| 121 | Charme-monstre | Charm Monster | Guide de Xanathar | SRD mais texte non conforme | SRD 5.2 | nom, description FR (86 car.), description EN (613 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Guide de Xanathar) | 0.08 |
| 122 | Châtiment aveuglant |  | Manuel des Joueurs | hors SRD |  | nom, description FR (112 car.), description EN (450 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.12 |
| 123 | Châtiment calcinant | Searing Smite | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (87 car.), description EN (777 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.00 |
| 124 | Châtiment courroucé |  | Manuel des Joueurs | hors SRD |  | nom, description FR (114 car.), description EN (368 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.12 |
| 125 | Châtiment débilitant |  | Manuel des Joueurs | hors SRD |  | nom, description FR (121 car.), description EN (369 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 126 | Châtiment du ban |  | Manuel des Joueurs | hors SRD |  | nom, description FR (117 car.), description EN (694 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 127 | Châtiment révélateur | Branding Smite | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (128 car.), description EN (465 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.83) | 0.10 |
| 128 | Châtiment tonitruant |  | Manuel des Joueurs | hors SRD |  | nom, description FR (117 car.), description EN (354 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 129 | Chien de garde de Mordenkainen | Faithful Hound | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (111 car.), description EN (802 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 130 | Clairvoyance | Clairvoyance | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (690 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 131 | Clignotement | Blink | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (119 car.), description EN (1020 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.00 |
| 132 | Clone | Clone | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (128 car.), description EN (825 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.91) | 0.11 |
| 133 | Coffre secret de Léomund | Secret Chest | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (69 car.), description EN (869 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.17 |
| 134 | Collet |  | Guide de Xanathar | hors SRD |  | nom, description FR (87 car.), description EN (1061 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 135 | Colonne de flamme | Flame Strike | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (500 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.83) | 0.05 |
| 136 | Communication à distance | Sending | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (116 car.), description EN (531 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.86) | 0.11 |
| 137 | Communication avec les morts | Speak with Dead | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (115 car.), description EN (829 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.11 |
| 138 | Communication avec les plantes | Speak with Plants | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (1097 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 139 | Communion | Commune | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (77 car.), description EN (726 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.85) | 0.00 |
| 140 | Communion avec la nature | Commune with Nature | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (111 car.), description EN (656 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 141 | Compulsion | Compulsion | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (91 car.), description EN (772 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.07 |
| 142 | Cône de froid | Cone of Cold | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (108 car.), description EN (410 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.81) | 0.11 |
| 143 | Confusion | Confusion | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (688 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.89) | 0.23 |
| 144 | Contact avec un autre plan | Contact Other Plane | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (119 car.), description EN (909 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.00 |
| 145 | Contagion | Contagion | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (102 car.), description EN (1675 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.61) | 0.00 |
| 146 | Contamination | Harm | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (109 car.), description EN (526 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.06 |
| 147 | Contrat | Planar Binding | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (108 car.), description EN (1455 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.13 |
| 148 | Contresort | Counterspell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (546 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 149 | Contrôle de l'eau | Control Water | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (113 car.), description EN (2852 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.12 |
| 150 | Contrôle des flammes |  | Guide de Xanathar | hors SRD |  | nom, description FR (115 car.), description EN (309 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 151 | Contrôle des vents |  | Guide de Xanathar | hors SRD |  | nom, description FR (91 car.), description EN (1474 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.08 |
| 152 | Contrôle du climat | Control Weather | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (110 car.), description EN (749 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 153 | Convocation d'aberration |  | Chaudron de Tasha | hors SRD |  | nom, description FR (100 car.), description EN (847 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 154 | Convocation d'artificiel |  | Chaudron de Tasha | hors SRD |  | nom, description FR (97 car.), description EN (890 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 155 | Convocation d'élémentaire |  | Chaudron de Tasha | hors SRD |  | nom, description FR (85 car.), description EN (873 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 156 | Convocation de bête |  | Chaudron de Tasha | hors SRD |  | nom, description FR (74 car.), description EN (885 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 157 | Convocation de céleste |  | Chaudron de Tasha | hors SRD |  | nom, description FR (80 car.), description EN (815 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 158 | Convocation de démon majeur |  | Guide de Xanathar | hors SRD |  | nom, description FR (68 car.), description EN (1707 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 159 | Convocation de démons mineurs |  | Guide de Xanathar | hors SRD |  | nom, description FR (76 car.), description EN (1106 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 160 | Convocation de fée |  | Chaudron de Tasha | hors SRD |  | nom, description FR (79 car.), description EN (871 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 161 | Convocation de fiélon |  | Chaudron de Tasha | hors SRD |  | nom, description FR (84 car.), description EN (838 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 162 | Convocation de mort-vivant |  | Chaudron de Tasha | hors SRD |  | nom, description FR (101 car.), description EN (870 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 163 | Convocation de rejeton d'ombre |  | Chaudron de Tasha | hors SRD |  | nom, description FR (93 car.), description EN (864 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 164 | Convocations instantanées de Drawmij | Instant Summons | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (128 car.), description EN (834 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.04 |
| 165 | Coquille antivie | Antilife Shell | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (107 car.), description EN (480 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.23 |
| 166 | Corde enchantée | Rope Trick | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (780 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 167 | Cordon de flèches |  | Manuel des Joueurs | hors SRD |  | nom, description FR (100 car.), description EN (767 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.21 |
| 168 | Couleurs dansantes | Color Spray | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (90 car.), description EN (817 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.84) | 0.08 |
| 169 | Coup de tonnerre |  | Guide de Xanathar | hors SRD |  | nom, description FR (111 car.), description EN (296 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.28 |
| 170 | Couronne d'étoiles |  | Guide de Xanathar | hors SRD |  | nom, description FR (96 car.), description EN (739 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 171 | Couronne du dément |  | Manuel des Joueurs | hors SRD |  | nom, description FR (113 car.), description EN (743 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 172 | Couteau de glace | Ice Knife | Guide de Xanathar | SRD mais texte non conforme | SRD 5.2 | nom, description FR (124 car.), description EN (450 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Guide de Xanathar) | 0.00 |
| 173 | Création | Creation | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (740 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.18 |
| 174 | Création d'homoncule |  | Guide de Xanathar | hors SRD |  | nom, description FR (103 car.), description EN (1128 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.07 |
| 175 | Création de mort-vivant | Create Undead | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (1605 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.81) | 0.00 |
| 176 | Création de nourriture et d'eau | Create Food and Water | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (96 car.), description EN (279 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.21 |
| 177 | Création ou destruction d'eau | Create or Destroy Water | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (57 car.), description EN (563 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.81) | 0.25 |
| 178 | Croissance d'épines | Spike Growth | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (121 car.), description EN (520 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.29 |
| 179 | Croissance végétale | Plant Growth | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (717 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.06 |
| 180 | Danse irrésistible d'Otto | Irresistible Dance | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (92 car.), description EN (588 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.07 |
| 181 | Danse macabre |  | Guide de Xanathar | hors SRD |  | nom, description FR (117 car.), description EN (1205 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.05 |
| 182 | Déblocage | Knock | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (651 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 183 | Dédale | Maze | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (107 car.), description EN (491 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.07 |
| 184 | Délivrance des malédictions | Remove Curse | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (70 car.), description EN (213 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.89) | 0.12 |
| 185 | Déluge d'énergie négative |  | Guide de Xanathar | hors SRD |  | nom, description FR (105 car.), description EN (605 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.07 |
| 186 | Demi-plan | Demiplane | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (796 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.05 |
| 187 | Désintégration | Disintegrate | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (120 car.), description EN (1035 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.82) | 0.15 |
| 188 | Détection des pensées | Detect Thoughts | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (1929 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.15 |
| 189 | Détection du poison et des maladies | Detect Poison and Disease | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (85 car.), description EN (360 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 190 | Discours captivant | Enthrall | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (571 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 191 | Dispersion |  | Guide de Xanathar | hors SRD |  | nom, description FR (93 car.), description EN (317 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.21 |
| 192 | Disque flottant de Tenser | Floating Disk | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (99 car.), description EN (913 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.06 |
| 193 | Dissimulation | Sequester | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (116 car.), description EN (700 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.08 |
| 194 | Dissipation de la magie | Dispel Magic | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (509 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 195 | Dissipation du mal et du bien | Dispel Evil and Good | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (107 car.), description EN (967 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.06 |
| 196 | Divination | Divination | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (110 car.), description EN (651 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.06 |
| 197 | Doigt de mort | Finger of Death | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (433 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.06 |
| 198 | Domination de bête | Dominate Beast | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (91 car.), description EN (1538 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.06 |
| 199 | Domination de monstre | Dominate Monster | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (85 car.), description EN (1363 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.08 |
| 200 | Domination de personne | Dominate Person | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (88 car.), description EN (1542 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 201 | Don des langues | Tongues | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (69 car.), description EN (226 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.00 |
| 202 | Double illusoire | Mislead | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (637 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 203 | Dragon illusoire |  | Guide de Xanathar | hors SRD |  | nom, description FR (120 car.), description EN (1536 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 204 | Duel forcé |  | Manuel des Joueurs | hors SRD |  | nom, description FR (123 car.), description EN (780 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.20 |
| 205 | Éclair | Lightning Bolt | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (117 car.), description EN (491 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.00 |
| 206 | Éclair de chaos |  | Guide de Xanathar | hors SRD |  | nom, description FR (96 car.), description EN (779 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 207 | Éclair traçant | Guiding Bolt | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (120 car.), description EN (461 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.84) | 0.11 |
| 208 | Éclat du soleil | Sunburst | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (121 car.), description EN (611 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.20 |
| 209 | Embrasement |  | Guide de Xanathar | hors SRD |  | nom, description FR (108 car.), description EN (578 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.16 |
| 210 | Emprisonnement | Imprisonment | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (111 car.), description EN (2845 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.05 |
| 211 | Enchevêtrement | Entangle | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (104 car.), description EN (530 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.13 |
| 212 | Énervation |  | Guide de Xanathar | hors SRD |  | nom, description FR (95 car.), description EN (841 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.07 |
| 213 | Ennemi subconscient | Weird | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (121 car.), description EN (600 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.20 |
| 214 | Ennemis à foison |  | Guide de Xanathar | hors SRD |  | nom, description FR (116 car.), description EN (759 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 215 | Épée de Mordenkainen | Arcane Sword | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (88 car.), description EN (446 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 216 | Épine mentale | Mind Spike | Guide de Xanathar | SRD mais texte non conforme | SRD 5.2 | nom, description FR (81 car.), description EN (622 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Guide de Xanathar) | 0.09 |
| 217 | Éruption de terre |  | Guide de Xanathar | hors SRD |  | nom, description FR (124 car.), description EN (599 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 218 | Esprit désorienté |  | Chaudron de Tasha | hors SRD |  | nom, description FR (117 car.), description EN (400 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 219 | Esprit faible | Feeblemind | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (115 car.), description EN (684 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.17 |
| 220 | Esprit guérisseur |  | Guide de Xanathar | hors SRD |  | nom, description FR (74 car.), description EN (876 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 221 | Esprit impénétrable | Mind Blank | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (336 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.19 |
| 222 | Esprits gardiens | Spirit Guardians | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (830 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.15 |
| 223 | Éveil | Awaken | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (112 car.), description EN (860 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 224 | Explosion de lames |  | Chaudron de Tasha | hors SRD |  | nom, description FR (104 car.), description EN (289 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.28 |
| 225 | Fabrication | Fabricate | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (93 car.), description EN (964 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.91) | 0.17 |
| 226 | Façonnage de l'eau |  | Guide de Xanathar | hors SRD |  | nom, description FR (124 car.), description EN (311 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 227 | Façonnage de la pierre | Stone Shape | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (92 car.), description EN (501 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.12 |
| 228 | Façonnage de la terre |  | Guide de Xanathar | hors SRD |  | nom, description FR (107 car.), description EN (321 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 229 | Faveur divine | Divine Favor | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (71 car.), description EN (131 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.12 |
| 230 | Festin des héros | Heroes' Feast | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (117 car.), description EN (591 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 231 | Flambée d'Aganazzar |  | Guide de Xanathar | hors SRD |  | nom, description FR (113 car.), description EN (382 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 232 | Flamme éternelle | Continual Flame | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (108 car.), description EN (250 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.13 |
| 233 | Fléau d'insectes | Insect Plague | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (122 car.), description EN (685 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.83) | 0.26 |
| 234 | Fléau élémentaire |  | Guide de Xanathar | hors SRD |  | nom, description FR (109 car.), description EN (658 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 235 | Flèche acide de Melf | Acid Arrow | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (116 car.), description EN (533 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.33 |
| 236 | Flèche de foudre |  | Manuel des Joueurs | hors SRD |  | nom, description FR (127 car.), description EN (783 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.05 |
| 237 | Flèches enflammées |  | Guide de Xanathar | hors SRD |  | nom, description FR (73 car.), description EN (527 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 238 | Flétrissement | Blight | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (82 car.), description EN (735 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.09 |
| 239 | Flétrissure épouvantable d'Abi-Dalzim |  | Guide de Xanathar | hors SRD |  | nom, description FR (119 car.), description EN (489 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 240 | Flou | Blur | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (113 car.), description EN (284 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.12 |
| 241 | Force fantasmagorique | Phantasmal Force | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (116 car.), description EN (1813 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.11 |
| 242 | Forme éthérée | Etherealness | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (68 car.), description EN (1598 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 243 | Forme gazeuse | Gaseous Form | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (102 car.), description EN (959 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.18 |
| 244 | Formes animales | Animal Shapes | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (76 car.), description EN (1262 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 245 | Forteresse d'intellect |  | Chaudron de Tasha | hors SRD |  | nom, description FR (125 car.), description EN (390 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 246 | Forteresse majestueuse |  | Guide de Xanathar | hors SRD |  | nom, description FR (83 car.), description EN (2257 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 247 | Fouet foudroyant |  | Chaudron de Tasha | hors SRD |  | nom, description FR (103 car.), description EN (405 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 248 | Fouet mental de Tasha |  | Chaudron de Tasha | hors SRD |  | nom, description FR (125 car.), description EN (679 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.05 |
| 249 | Foulée brumeuse | Misty Step | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (42 car.), description EN (103 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 250 | Foulée dimensionnelle |  | Guide de Xanathar | hors SRD |  | nom, description FR (64 car.), description EN (165 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 251 | Foulée tonitruante |  | Guide de Xanathar | hors SRD |  | nom, description FR (126 car.), description EN (914 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.19 |
| 252 | Fracassement | Shatter | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (122 car.), description EN (640 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.84) | 0.25 |
| 253 | Frappe du vent d'acier |  | Guide de Xanathar | hors SRD |  | nom, description FR (107 car.), description EN (342 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 254 | Frappe du zéphyr |  | Guide de Xanathar | hors SRD |  | nom, description FR (127 car.), description EN (344 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.04 |
| 255 | Frappe piégeuse | Ensnaring Strike | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (98 car.), description EN (787 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.07 |
| 256 | Frayeur |  | Guide de Xanathar | hors SRD |  | nom, description FR (75 car.), description EN (562 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.09 |
| 257 | Fureur de la nature |  | Guide de Xanathar | hors SRD |  | nom, description FR (63 car.), description EN (1160 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 258 | Fusion dans la pierre | Meld into Stone | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (40 car.), description EN (1125 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.00 |
| 259 | Gardien de la foi | Guardian of Faith | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (576 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.20 |
| 260 | Gardien de la nature |  | Guide de Xanathar | hors SRD |  | nom, description FR (128 car.), description EN (398 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 261 | Gelure |  | Guide de Xanathar | hors SRD |  | nom, description FR (115 car.), description EN (386 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.05 |
| 262 | Glas |  | Guide de Xanathar | hors SRD |  | nom, description FR (90 car.), description EN (424 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.08 |
| 263 | Globe d'invulnérabilité | Globe of Invulnerability | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (75 car.), description EN (630 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.17 |
| 264 | Glyphe de protection | Glyph of Warding | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (2923 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.89) | 0.13 |
| 265 | Graisse | Grease | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (105 car.), description EN (370 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.91) | 0.06 |
| 266 | Grêle d'épines |  | Manuel des Joueurs | hors SRD |  | nom, description FR (114 car.), description EN (568 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.28 |
| 267 | Guérison | Heal | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (101 car.), description EN (407 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.85) | 0.00 |
| 268 | Guérison de groupe | Mass Heal | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (114 car.), description EN (352 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 269 | Hâte | Haste | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (120 car.), description EN (484 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.18 |
| 270 | Hurlement psychique |  | Guide de Xanathar | hors SRD |  | nom, description FR (83 car.), description EN (611 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 271 | Illusion programmée | Programmed Illusion | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (98 car.), description EN (1432 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.06 |
| 272 | Image majeure | Major Image | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (95 car.), description EN (1568 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.07 |
| 273 | Image miroir | Mirror Image | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (1080 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 274 | Immobilisation de monstre | Hold Monster | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (73 car.), description EN (505 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.10 |
| 275 | Immobilisation de personne | Hold Person | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (73 car.), description EN (469 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.10 |
| 276 | Immolation |  | Guide de Xanathar | hors SRD |  | nom, description FR (105 car.), description EN (641 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.10 |
| 277 | Infestation |  | Guide de Xanathar | hors SRD |  | nom, description FR (115 car.), description EN (587 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.14 |
| 278 | Injonction | Command | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (1238 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.85) | 0.06 |
| 279 | Insecte géant | Giant Insect | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (115 car.), description EN (773 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 280 | Interdiction | Forbiddance | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (1220 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.19 |
| 281 | Inversion de la gravité | Reverse Gravity | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (49 car.), description EN (740 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.43 |
| 282 | Invisibilité | Invisibility | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (100 car.), description EN (355 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.44 |
| 283 | Invisibilité supérieure | Greater Invisibility | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (43 car.), description EN (164 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 284 | Invocation d'animaux | Conjure Animals | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (73 car.), description EN (927 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.81) | 0.00 |
| 285 | Invocation d'élémentaire | Conjure Elemental | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (46 car.), description EN (1228 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 286 | Invocation d'élémentaires mineurs | Conjure Minor Elementals | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (86 car.), description EN (851 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.79) | 0.00 |
| 287 | Invocation d'êtres sylvestres | Conjure Woodland Beings | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (71 car.), description EN (840 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.82) | 0.00 |
| 288 | Invocation de céleste | Conjure Celestial | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (42 car.), description EN (724 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.89) | 0.00 |
| 289 | Invocation de fée | Conjure Fey | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (39 car.), description EN (1139 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 290 | Invocation de projectiles |  | Manuel des Joueurs | hors SRD |  | nom, description FR (117 car.), description EN (409 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.10 |
| 291 | Invocation de volée |  | Manuel des Joueurs | hors SRD |  | nom, description FR (124 car.), description EN (507 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.05 |
| 292 | Invulnérabilité |  | Guide de Xanathar | hors SRD |  | nom, description FR (46 car.), description EN (50 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 293 | Lame aux flammes vertes |  | Chaudron de Tasha | hors SRD |  | nom, description FR (126 car.), description EN (742 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.10 |
| 294 | Lame d'ombres |  | Guide de Xanathar | hors SRD |  | nom, description FR (107 car.), description EN (882 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 295 | Lame de feu | Flame Blade | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (128 car.), description EN (576 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.04 |
| 296 | Lame du désastre |  | Chaudron de Tasha | hors SRD |  | nom, description FR (128 car.), description EN (771 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 297 | Lame tonnante |  | Chaudron de Tasha | hors SRD |  | nom, description FR (99 car.), description EN (697 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.29 |
| 298 | Lenteur | Slow | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (926 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 299 | Lévitation | Levitate | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (96 car.), description EN (809 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.06 |
| 300 | Liane avide |  | Manuel des Joueurs | hors SRD |  | nom, description FR (72 car.), description EN (469 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.08 |
| 301 | Libellé aérien |  | Guide de Xanathar | hors SRD |  | nom, description FR (37 car.), description EN (254 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 302 | Liberté de mouvement | Freedom of Movement | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (94 car.), description EN (467 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.13 |
| 303 | Lien avec une bête |  | Guide de Xanathar | hors SRD |  | nom, description FR (75 car.), description EN (553 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 304 | Lien de protection | Warding Bond | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (109 car.), description EN (551 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.11 |
| 305 | Lien télépathique de Rary | Telepathic Bond | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (95 car.), description EN (470 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.47 |
| 306 | Localisation d'animaux ou de plantes | Locate Animals or Plants | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (108 car.), description EN (229 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.20 |
| 307 | Localisation d'objet | Locate Object | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (95 car.), description EN (620 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.29 |
| 308 | Localisation de créature | Locate Creature | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (102 car.), description EN (719 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.29 |
| 309 | Lueur d'espoir | Beacon of Hope | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (247 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 310 | Lumière du jour | Daylight | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (98 car.), description EN (562 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.33 |
| 311 | Maelström |  | Guide de Xanathar | hors SRD |  | nom, description FR (128 car.), description EN (375 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.19 |
| 312 | Main de Bigby | Arcane Hand | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (2346 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.05 |
| 313 | Mains brûlantes | Burning Hands | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (108 car.), description EN (512 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.84) | 0.16 |
| 314 | Malédiction | Bestow Curse | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (856 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.05 |
| 315 | Maléfice | Hex | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (110 car.), description EN (752 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.00 |
| 316 | Manoir somptueux de Mordenkainen | Magnificent Mansion | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (110 car.), description EN (1549 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 317 | Marche sur l'eau | Water Walk | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (448 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.05 |
| 318 | Marche sur le vent | Wind Walk | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (782 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.16 |
| 319 | Mauvais oeil | Eyebite | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (120 car.), description EN (1088 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.30 |
| 320 | Messager animal | Animal Messenger | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (78 car.), description EN (1101 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.07 |
| 321 | Métal brûlant | Heat Metal | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (88 car.), description EN (789 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.00 |
| 322 | Métamorphose | Polymorph | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (102 car.), description EN (1335 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 323 | Métamorphose de groupe |  | Guide de Xanathar | hors SRD |  | nom, description FR (112 car.), description EN (1391 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 324 | Métamorphose suprême | True Polymorph | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (122 car.), description EN (2645 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.05 |
| 325 | Minuscules météores de Melf |  | Guide de Xanathar | hors SRD |  | nom, description FR (127 car.), description EN (748 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 326 | Mirage | Mirage Arcane | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (91 car.), description EN (1135 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 327 | Modification d'apparence | Alter Self | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (117 car.), description EN (1396 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 328 | Modification de mémoire | Modify Memory | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (106 car.), description EN (2036 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.07 |
| 329 | Monture fantôme | Phantom Steed | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (103 car.), description EN (717 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 330 | Mort simulée |  | Manuel des Joueurs | hors SRD |  | nom, description FR (105 car.), description EN (618 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 331 | Mot de guérison de groupe | Mass Healing Word | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (62 car.), description EN (350 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 332 | Mot de pouvoir douloureux |  | Guide de Xanathar | hors SRD |  | nom, description FR (124 car.), description EN (792 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 333 | Mot de pouvoir étourdissant | Power Word Stun | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (78 car.), description EN (353 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.08 |
| 334 | Mot de pouvoir guérisseur | Power Word Heal | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (104 car.), description EN (295 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.43 |
| 335 | Mot de pouvoir mortel | Power Word Kill | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (29 car.), description EN (198 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 336 | Mot de radiance |  | Guide de Xanathar | hors SRD |  | nom, description FR (111 car.), description EN (302 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.28 |
| 337 | Mot de retour | Word of Recall | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (97 car.), description EN (614 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 338 | Motif hypnotique | Hypnotic Pattern | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (515 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.09 |
| 339 | Mur d'eau |  | Guide de Xanathar | hors SRD |  | nom, description FR (116 car.), description EN (843 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 340 | Mur d'épines | Wall of Thorns | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (1068 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.00 |
| 341 | Mur de feu | Wall of Fire | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (128 car.), description EN (895 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 342 | Mur de force | Wall of Force | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (108 car.), description EN (915 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 343 | Mur de glace | Wall of Ice | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (1335 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.00 |
| 344 | Mur de lumière |  | Guide de Xanathar | hors SRD |  | nom, description FR (119 car.), description EN (1367 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 345 | Mur de pierre | Wall of Stone | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (81 car.), description EN (1628 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 346 | Mur de sable |  | Guide de Xanathar | hors SRD |  | nom, description FR (88 car.), description EN (354 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 347 | Mur de vent | Wind Wall | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (81 car.), description EN (939 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.06 |
| 348 | Mur prismatique | Prismatic Wall | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (97 car.), description EN (3671 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.00 |
| 349 | Mythes et légendes | Legend Lore | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (110 car.), description EN (882 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.19 |
| 350 | Nappe de brouillard | Fog Cloud | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (68 car.), description EN (401 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.79) | 0.36 |
| 351 | Nuage incendiaire | Incendiary Cloud | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (105 car.), description EN (722 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.28 |
| 352 | Nuage nauséabond | Stinking Cloud | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (678 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.24 |
| 353 | Nuée de boules de neige de Snilloc |  | Guide de Xanathar | hors SRD |  | nom, description FR (122 car.), description EN (394 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.29 |
| 354 | Nuée de dagues |  | Manuel des Joueurs | hors SRD |  | nom, description FR (98 car.), description EN (366 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.25 |
| 355 | Nuée de météores | Meteor Swarm | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (122 car.), description EN (542 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.40 |
| 356 | Oeil magique | Arcane Eye | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (103 car.), description EN (528 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 357 | Ombre d'égarement |  | Guide de Xanathar | hors SRD |  | nom, description FR (119 car.), description EN (433 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 358 | Orbe chromatique | Chromatic Orb | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (100 car.), description EN (436 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.00 |
| 359 | Ossements de la Terre |  | Guide de Xanathar | hors SRD |  | nom, description FR (122 car.), description EN (1392 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 360 | Parole divine | Divine Word | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (119 car.), description EN (555 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 361 | Passage par les arbres | Tree Stride | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (116 car.), description EN (737 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 362 | Passage sans trace | Pass without Trace | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (361 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.05 |
| 363 | Passe-muraille | Passwall | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (83 car.), description EN (525 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.06 |
| 364 | Pattes d'araignée | Spider Climb | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (246 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.06 |
| 365 | Peau d'écorce | Barkskin | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (38 car.), description EN (195 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.85) | 0.00 |
| 366 | Peau de pierre | Stoneskin | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (93 car.), description EN (182 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 367 | Perturbations synaptiques |  | Guide de Xanathar | hors SRD |  | nom, description FR (96 car.), description EN (728 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.27 |
| 368 | Petite hutte de Léomund | Tiny Hut | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (98 car.), description EN (840 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.99) | 0.06 |
| 369 | Pétrification | Flesh to Stone | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (93 car.), description EN (977 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.07 |
| 370 | Peur | Fear | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (567 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.10 |
| 371 | Pierre magique |  | Guide de Xanathar | hors SRD |  | nom, description FR (100 car.), description EN (621 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 372 | Poigne terreuse de Maximilien |  | Guide de Xanathar | hors SRD |  | nom, description FR (86 car.), description EN (930 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.08 |
| 373 | Portail | Gate | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (89 car.), description EN (1176 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.08 |
| 374 | Portail magique |  | Manuel des Joueurs | hors SRD |  | nom, description FR (99 car.), description EN (970 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 375 | Porte dimensionnelle | Dimension Door | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (91 car.), description EN (783 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.00 |
| 376 | Prémonition | Foresight | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (385 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.10 |
| 377 | Préservation des morts | Gentle Repose | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (65 car.), description EN (318 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 378 | Prévoyance | Contingency | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (87 car.), description EN (1021 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 379 | Prière de guérison | Prayer of Healing | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (62 car.), description EN (317 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.83) | 0.00 |
| 380 | Prison mentale |  | Guide de Xanathar | hors SRD |  | nom, description FR (121 car.), description EN (898 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.05 |
| 381 | Projection astrale | Astral Projection | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (68 car.), description EN (2150 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 382 | Projection d'image | Project Image | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (121 car.), description EN (1188 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.00 |
| 383 | Protection contre la mort | Death Ward | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (93 car.), description EN (419 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 384 | Protection contre le poison | Protection from Poison | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (322 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.11 |
| 385 | Protection contre une énergie | Protection from Energy | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (91 car.), description EN (139 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.25 |
| 386 | Protection primordiale |  | Guide de Xanathar | hors SRD |  | nom, description FR (125 car.), description EN (373 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.14 |
| 387 | Protections et sceaux | Guards and Wards | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (1751 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.06 |
| 388 | Purification de nourriture et d'eau | Purify Food and Drink | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (117 car.), description EN (160 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.78) | 0.50 |
| 389 | Pyrotechnie |  | Guide de Xanathar | hors SRD |  | nom, description FR (121 car.), description EN (596 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 390 | Quête | Geas | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (117 car.), description EN (1024 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.11 |
| 391 | Rappel à la vie | Raise Dead | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (114 car.), description EN (1012 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 392 | Rayon affaiblissant | Ray of Enfeeblement | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (373 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.23 |
| 393 | Rayon ardent | Scorching Ray | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (85 car.), description EN (328 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 394 | Rayon de lune | Moonbeam | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (117 car.), description EN (896 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.05 |
| 395 | Rayon de soleil | Sunbeam | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (114 car.), description EN (650 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.10 |
| 396 | Rayon empoisonné | Ray of Sickness | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (110 car.), description EN (411 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.00 |
| 397 | Rayonnement écoeurant |  | Guide de Xanathar | hors SRD |  | nom, description FR (122 car.), description EN (620 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.20 |
| 398 | Rayons prismatiques | Prismatic Spray | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (117 car.), description EN (1668 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.10 |
| 399 | Raz-de-marée |  | Guide de Xanathar | hors SRD |  | nom, description FR (124 car.), description EN (537 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 400 | Régénération | Regenerate | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (85 car.), description EN (455 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.08 |
| 401 | Réincarnation | Reincarnate | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (107 car.), description EN (752 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.00 |
| 402 | Repli expéditif | Expeditious Retreat | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (72 car.), description EN (179 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 403 | Représailles infernales | Hellish Rebuke | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (78 car.), description EN (367 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.86) | 0.08 |
| 404 | Respiration aquatique | Water Breathing | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (67 car.), description EN (191 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.12 |
| 405 | Restauration partielle | Lesser Restoration | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (94 car.), description EN (147 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 406 | Restauration supérieure | Greater Restoration | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (186 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 407 | Résurrection | Resurrection | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (1028 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 408 | Résurrection suprême | True Resurrection | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (677 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.87) | 0.00 |
| 409 | Retour à la vie | Revivify | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (76 car.), description EN (218 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 410 | Rêve du voile bleu |  | Chaudron de Tasha | hors SRD |  | nom, description FR (122 car.), description EN (1143 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 411 | Sacre de la glace |  | Guide de Xanathar | hors SRD |  | nom, description FR (121 car.), description EN (79 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.15 |
| 412 | Sacre de la pierre |  | Guide de Xanathar | hors SRD |  | nom, description FR (128 car.), description EN (96 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.24 |
| 413 | Sacre des flammes |  | Guide de Xanathar | hors SRD |  | nom, description FR (120 car.), description EN (219 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.10 |
| 414 | Sacre du vent |  | Guide de Xanathar | hors SRD |  | nom, description FR (122 car.), description EN (82 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.14 |
| 415 | Sanctification | Hallow | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (126 car.), description EN (2275 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.88) | 0.31 |
| 416 | Sanctuaire privé de Mordenkainen | Private Sanctum | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (100 car.), description EN (681 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.00 |
| 417 | Saute de vent |  | Guide de Xanathar | hors SRD |  | nom, description FR (121 car.), description EN (107 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 418 | Sauvagerie primitive |  | Guide de Xanathar | hors SRD |  | nom, description FR (92 car.), description EN (406 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.14 |
| 419 | Scrutation | Scrying | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (112 car.), description EN (984 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.00 |
| 420 | Secousse sismique |  | Guide de Xanathar | hors SRD |  | nom, description FR (128 car.), description EN (508 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.10 |
| 421 | Sens animal |  | Manuel des Joueurs | hors SRD |  | nom, description FR (79 car.), description EN (397 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 422 | Sens de l'orientation | Find the Path | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (99 car.), description EN (733 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.97) | 0.00 |
| 423 | Sens des pièges | Find Traps | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (92 car.), description EN (658 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.14 |
| 424 | Serviteur miniature |  | Guide de Xanathar | hors SRD |  | nom, description FR (106 car.), description EN (1216 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 425 | Sieste |  | Guide de Xanathar | hors SRD |  | nom, description FR (96 car.), description EN (579 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 426 | Silence | Silence | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (52 car.), description EN (335 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.00 |
| 427 | Simulacre | Simulacrum | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (106 car.), description EN (1212 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.18 |
| 428 | Simulacre de vie | False Life | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (50 car.), description EN (256 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.00 |
| 429 | Soins de groupe | Mass Cure Wounds | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (66 car.), description EN (416 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.80) | 0.00 |
| 430 | Songe | Dream | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (115 car.), description EN (1668 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.20 |
| 431 | Souffle du dragon | Dragon's Breath | Guide de Xanathar | SRD mais texte non conforme | SRD 5.2 | nom, description FR (128 car.), description EN (563 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Guide de Xanathar) | 0.12 |
| 432 | Souhait | Wish | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (105 car.), description EN (1806 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 433 | Sphère aqueuse |  | Guide de Xanathar | hors SRD |  | nom, description FR (119 car.), description EN (1573 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.13 |
| 434 | Sphère de feu | Flaming Sphere | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (919 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.91) | 0.17 |
| 435 | Sphère de tempête |  | Guide de Xanathar | hors SRD |  | nom, description FR (122 car.), description EN (945 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.26 |
| 436 | Sphère de vitriol | Vitriolic Sphere | Guide de Xanathar | SRD mais texte non conforme | SRD 5.2 | nom, description FR (128 car.), description EN (558 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Guide de Xanathar) | 0.09 |
| 437 | Sphère glaciale d'Otiluke | Freezing Sphere | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (121 car.), description EN (1376 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.25 |
| 438 | Sphère résiliente d'Otiluke | Resilient Sphere | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (105 car.), description EN (952 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.06 |
| 439 | Suggestion | Suggestion | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (109 car.), description EN (1119 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.06 |
| 440 | Suggestion de groupe | Mass Suggestion | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (111 car.), description EN (1454 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 441 | Symbole | Symbol | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (124 car.), description EN (3432 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.00 |
| 442 | Télékinésie | Telekinesis | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (114 car.), description EN (1709 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 443 | Télépathie |  | Manuel des Joueurs | hors SRD |  | nom, description FR (95 car.), description EN (631 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.18 |
| 444 | Téléportation | Teleport | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (127 car.), description EN (2956 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.00 |
| 445 | Tempête de feu | Fire Storm | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (95 car.), description EN (579 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.00 |
| 446 | Tempête de grêle | Ice Storm | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (123 car.), description EN (549 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.80) | 0.05 |
| 447 | Tempête de neige | Sleet Storm | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (111 car.), description EN (661 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.72) | 0.06 |
| 448 | Tempête vengeresse | Storm of Vengeance | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (120 car.), description EN (1513 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.89) | 0.16 |
| 449 | Temple des dieux |  | Guide de Xanathar | hors SRD |  | nom, description FR (83 car.), description EN (2185 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.13 |
| 450 | Ténèbres | Darkness | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (59 car.), description EN (671 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.50 |
| 451 | Ténèbres oppressantes |  | Guide de Xanathar | hors SRD |  | nom, description FR (121 car.), description EN (561 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 452 | Tentacules de Hadar |  | Manuel des Joueurs | hors SRD |  | nom, description FR (111 car.), description EN (506 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.24 |
| 453 | Tentacules noirs d'Evard | Black Tentacles | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (116 car.), description EN (700 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.96) | 0.17 |
| 454 | Terraformage | Move Earth | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (121 car.), description EN (1165 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.94) | 0.14 |
| 455 | Terrain hallucinatoire | Hallucinatory Terrain | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (110 car.), description EN (888 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.91) | 0.00 |
| 456 | Toile d'araignée | Web | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (120 car.), description EN (1016 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.95) | 0.06 |
| 457 | Toucher du vampire | Vampiric Touch | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (116 car.), description EN (498 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.84) | 0.00 |
| 458 | Tourbillon |  | Guide de Xanathar | hors SRD |  | nom, description FR (106 car.), description EN (1365 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.06 |
| 459 | Tourbillon de poussière |  | Guide de Xanathar | hors SRD |  | nom, description FR (114 car.), description EN (903 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.28 |
| 460 | Trait ensorcelé |  | Manuel des Joueurs | hors SRD |  | nom, description FR (92 car.), description EN (666 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 461 | Transfert de vie |  | Guide de Xanathar | hors SRD |  | nom, description FR (103 car.), description EN (401 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 462 | Transformation de Tenser |  | Guide de Xanathar | hors SRD |  | nom, description FR (127 car.), description EN (276 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.11 |
| 463 | Transmutation de la pierre |  | Guide de Xanathar | hors SRD |  | nom, description FR (64 car.), description EN (1651 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.09 |
| 464 | Tremblement de terre | Earthquake | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (118 car.), description EN (2067 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.90) | 0.21 |
| 465 | Tsunami | Tsunami | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.2 | nom, description FR (110 car.), description EN (1239 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral 2014 du livre (Manuel des Joueurs) | 0.00 |
| 466 | Urne magique | Magic Jar | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (116 car.), description EN (2248 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.98) | 0.00 |
| 467 | Vague destructrice |  | Manuel des Joueurs | hors SRD |  | nom, description FR (119 car.), description EN (381 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.10 |
| 468 | Vent protecteur |  | Guide de Xanathar | hors SRD |  | nom, description FR (122 car.), description EN (195 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.10 |
| 469 | Verrou magique | Arcane Lock | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (125 car.), description EN (605 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.06 |
| 470 | Vision dans le noir | Darkvision | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (44 car.), description EN (146 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.17 |
| 471 | Vision suprême | True Seeing | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (92 car.), description EN (248 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 472 | Voie végétale | Transport via Plants | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (100 car.), description EN (357 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 473 | Voile spirituel |  | Chaudron de Tasha | hors SRD |  | nom, description FR (128 car.), description EN (721 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.00 |
| 474 | Voir l'invisible | See Invisibility | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (75 car.), description EN (186 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 1.00) | 0.00 |
| 475 | Vol | Fly | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (67 car.), description EN (318 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.93) | 0.22 |
| 476 | Voracité de Hadar |  | Manuel des Joueurs | hors SRD |  | nom, description FR (124 car.), description EN (743 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte intégral du livre (dnd5e-card-generator) | 0.23 |
| 477 | Zone de vérité | Zone of Truth | Manuel des Joueurs | SRD mais texte non conforme | SRD 5.1 | nom, description FR (105 car.), description EN (664 car.), méta (niveau, école, portée...) | FR : résumé repris de la table aidedd (miroir Tapouweb) ; EN : texte du SRD 5.1 (recouvrement 0.92) | 0.33 |
| 478 | Élémentalisme | Elementalism | Manuel des Joueurs (2024) | SRD 5.2 | SRD 5.2 | nom, description FR (1426 car.), description EN (1178 car.), méta (niveau, école, portée...) | FR : traduction non officielle du SRD 5.2 anglais ; EN : texte du SRD 5.2 (recouvrement 1.00) | 0.19 |
| 479 | Explosion ensorcelée | Sorcerous Burst | Manuel des Joueurs (2024) | SRD 5.2 | SRD 5.2 | nom, description FR (606 car.), description EN (543 car.), méta (niveau, école, portée...) | FR : traduction non officielle du SRD 5.2 anglais ; EN : texte du SRD 5.2 (recouvrement 0.96) | 0.38 |
| 480 | Volute étoilée | Starry Wisp | Manuel des Joueurs (2024) | SRD 5.2 | SRD 5.2 | nom, description FR (435 car.), description EN (370 car.), méta (niveau, école, portée...) | FR : traduction non officielle du SRD 5.2 anglais ; EN : texte du SRD 5.2 (recouvrement 0.94) | 0.43 |
| 481 | Châtiment divin | Divine Smite | Manuel des Joueurs (2024) | SRD 5.2 | SRD 5.2 | nom, description FR (258 car.), description EN (194 car.), méta (niveau, école, portée...) | FR : traduction non officielle du SRD 5.2 anglais ; EN : texte du SRD 5.2 (recouvrement 0.88) | 0.32 |
| 482 | Châtiment radieux | Shining Smite | Manuel des Joueurs (2024) | SRD 5.2 | SRD 5.2 | nom, description FR (394 car.), description EN (308 car.), méta (niveau, école, portée...) | FR : traduction non officielle du SRD 5.2 anglais ; EN : texte du SRD 5.2 (recouvrement 0.92) | 0.45 |
| 483 | Convocation de dragon | Summon Dragon | Manuel des Joueurs (2024) | SRD 5.2 | SRD 5.2 | nom, description FR (817 car.), description EN (697 car.), méta (niveau, école, portée...) | FR : traduction non officielle du SRD 5.2 anglais ; EN : texte du SRD 5.2 (recouvrement 0.89) | 0.17 |
| 484 | Encoder les pensées |  | Guide des guildes de Ravnica | hors SRD |  | nom, description FR (286 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.00 |
| 485 | Altération de valeur |  | Acquisitions Incorporated | hors SRD |  | nom, description FR (267 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.05 |
| 486 | Doigts de givre |  | Icewind Dale : Rime of the Frostmaiden | hors SRD |  | nom, description FR (277 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.24 |
| 487 | Projectile magique de Jim |  | Acquisitions Incorporated | hors SRD |  | nom, description FR (387 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.05 |
| 488 | Barbes argentées |  | Strixhaven : un programme de chaos | hors SRD |  | nom, description FR (244 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.15 |
| 489 | Bulle d'air |  | Spelljammer : Aventures dans l'espace | hors SRD |  | nom, description FR (191 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.03 |
| 490 | Savoir emprunté |  | Strixhaven : un programme de chaos | hors SRD |  | nom, description FR (172 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.04 |
| 491 | Nuée de familiers |  | Le laboratoire perdu de Kwalish | hors SRD |  | nom, description FR (360 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.00 |
| 492 | Don de la parole |  | Acquisitions Incorporated | hors SRD |  | nom, description FR (225 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.11 |
| 493 | Pièce lumineuse de Jim |  | Acquisitions Incorporated | hors SRD |  | nom, description FR (303 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.20 |
| 494 | Bond cinétique |  | Strixhaven : un programme de chaos | hors SRD |  | nom, description FR (316 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.18 |
| 495 | Espièglerie de Nathair |  | Le trésor draconique de Fizban | hors SRD |  | nom, description FR (396 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.10 |
| 496 | Glace entravante de Rime |  | Le trésor draconique de Fizban | hors SRD |  | nom, description FR (340 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.33 |
| 497 | Jet de cartes |  | Le livre des choses innombrables | hors SRD |  | nom, description FR (286 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.25 |
| 498 | Distorsion tourbillonnante |  | Strixhaven : un programme de chaos | hors SRD |  | nom, description FR (298 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.33 |
| 499 | Sens des distorsions |  | Planescape : aventures dans le Multivers | hors SRD |  | nom, description FR (321 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.31 |
| 500 | Flétrir et fleurir |  | Strixhaven : un programme de chaos | hors SRD |  | nom, description FR (417 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.24 |
| 501 | Provocation |  | Le livre des choses innombrables | hors SRD |  | nom, description FR (350 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.15 |
| 502 | Foulée d'Ashardalon |  | Le trésor draconique de Fizban | hors SRD |  | nom, description FR (267 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.10 |
| 503 | Amis rapides |  | Acquisitions Incorporated | hors SRD |  | nom, description FR (354 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.13 |
| 504 | Tour de Galder |  | Le laboratoire perdu de Kwalish | hors SRD |  | nom, description FR (395 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.00 |
| 505 | Susciter la cupidité |  | Acquisitions Incorporated | hors SRD |  | nom, description FR (300 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.11 |
| 506 | Discours motivant |  | Acquisitions Incorporated | hors SRD |  | nom, description FR (362 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.17 |
| 507 | Coursier rapide de Galder |  | Le laboratoire perdu de Kwalish | hors SRD |  | nom, description FR (420 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.05 |
| 508 | Scellement de portail |  | Planescape : aventures dans le Multivers | hors SRD |  | nom, description FR (301 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.00 |
| 509 | Lance psychique de Raulothim |  | Le trésor draconique de Fizban | hors SRD |  | nom, description FR (326 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.16 |
| 510 | Esprit de la mort |  | Le livre des choses innombrables | hors SRD |  | nom, description FR (294 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.09 |
| 511 | Création de heaume spatial |  | Spelljammer : Aventures dans l'espace | hors SRD |  | nom, description FR (173 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.08 |
| 512 | Invocation d'esprit draconique |  | Le trésor draconique de Fizban | hors SRD |  | nom, description FR (305 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.02 |
| 513 | Bouclier de platine de Fizban |  | Le trésor draconique de Fizban | hors SRD |  | nom, description FR (324 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.11 |
| 514 | Création de magen |  | Icewind Dale : Rime of the Frostmaiden | hors SRD |  | nom, description FR (336 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.06 |
| 515 | Transformation draconique |  | Le trésor draconique de Fizban | hors SRD |  | nom, description FR (304 car.), méta (niveau, école, portée...) | FR : résumé maison ; EN : aucun | 0.12 |

</details>

### 2.13 Objets (454)

Réglé pour les objets 2014 (PR #60). Les objets 2024 sont tous au SRD 5.2 (24 écarts d'écriture du nom seulement : « Armure +3 » pour « Armor, +1, +2, or +3 », jeux et instruments listés en variantes) ; texte = traduction non officielle du SRD 5.2 anglais, déjà déclarée dans les mentions de Grimoire. Les 6 armes naturelles (source « Trait racial ») n'ont qu'un nom (décision 78).

Répartition : SRD 5.1 95, SRD 5.2 353, hors SRD 6.

<details><summary>Tableau complet (454 lignes)</summary>

| id | Élément | Nom EN | Source déclarée | Classification | Champs | Nature du texte | Recouvr. |
|---|---|---|---|---|---|---|---|
| 1 | Gourdin | Club | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 2 | Dague | Dagger | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 3 | Gourdin à deux mains | Greatclub | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 4 | Hachette | Handaxe | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 5 | Javeline | Javelin | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 6 | Marteau léger | Light hammer | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 7 | Masse d'armes | Mace | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 8 | Faucille | Sickle | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 9 | Épieu | Spear | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 10 | Bâton de combat | Quarterstaff | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (31 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 11 | Arc court | Shortbow | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (25 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 12 | Arbalète légère | Crossbow, light | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (25 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 13 | Dard | Dart | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (25 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 14 | Fronde | Sling | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (25 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 15 | Hache d'armes | Battleaxe | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 16 | Fléau d'armes | Flail | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 17 | Glaive | Glaive | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 18 | Grande hache | Greataxe | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 19 | Épée à deux mains | Greatsword | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 20 | Hallebarde | Halberd | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 21 | Lance de cavalerie | Lance | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 22 | Épée longue | Longsword | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 23 | Maillet | Maul | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 24 | Morgenstern | Morningstar | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 25 | Pique | Pike | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 26 | Rapière | Rapier | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 27 | Cimeterre | Scimitar | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 28 | Épée courte | Shortsword | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 29 | Trident | Trident | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 30 | Pic de guerre | War pick | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 31 | Marteau de guerre | Warhammer | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 32 | Fouet | Whip | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (32 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 33 | Sarbacane | Blowgun | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (26 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.00 |
| 34 | Arbalète de poing | Crossbow, hand | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (26 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.00 |
| 35 | Arbalète lourde | Crossbow, heavy | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (26 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.00 |
| 36 | Arc long | Longbow | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (26 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.00 |
| 37 | Filet | Net | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (26 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.00 |
| 38 | Armure rembourrée | Padded | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (14 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 39 | Armure de cuir | Leather | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (14 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 40 | Armure de cuir clouté | Studded leather | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (14 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 41 | Armure de peau | Hide | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (21 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 42 | Chemise de mailles | Chain shirt | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (21 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 43 | Armure d'écailles | Scale mail | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (21 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 44 | Cuirasse | Breastplate | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (21 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 45 | Demi-plate | Half plate | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (21 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 46 | Cotte à anneaux | Ring mail | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (14 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 47 | Cotte de mailles | Chain mail | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (14 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 48 | Harnois à lattes | Splint | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (14 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 49 | Armure complète | Plate | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (14 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 50 | Bouclier | Shield | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (179 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 51 | Sac à dos | Backpack | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (142 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.79 |
| 52 | Corde en chanvre (15 mètres) | Rope, hempen (50 feet) | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (117 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 53 | Torche | Torch | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (250 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.87 |
| 54 | Silex et briquet | Tinderbox | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (298 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 55 | Rations de voyage (1 jour) | Rations (1 day) | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (147 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 56 | Outre | Waterskin | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (33 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.00 |
| 57 | Couverture | Blanket | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 58 | Sac de couchage | Bedroll | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 59 | Grappin | Grappling hook | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 60 | Lanterne à capote | Lantern, hooded | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (319 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 61 | Lanterne sourde | Lantern, bullseye | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (194 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 62 | Flacon d'huile | Oil (flask) | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 63 | Bougie | Candle | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (125 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 64 | Parchemin (feuille) | Parchment (one sheet) | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 65 | Papier (feuille) | Paper (one sheet) | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 66 | Flacon d'encre | Ink (1 ounce bottle) | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 67 | Plume | Ink pen | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 68 | Sacoche à composants | Component pouch | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (322 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 69 | Symbole sacré | Holy symbol | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (481 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.95 |
| 70 | Focaliseur druidique | Druidic focus | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (305 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 71 | Focaliseur arcanique | Arcane focus | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (345 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.92 |
| 72 | Kit de soins | Healer's kit | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (276 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 73 | Miroir en acier poli | Mirror, steel | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 74 | Gamelle | Mess kit | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 75 | Pied-de-biche | Crowbar | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (115 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 1.00 |
| 76 | Marteau | Hammer | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 77 | Piton | Piton | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 78 | Cadenas | Lock | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 79 | Sac (grand) | Sack | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (40 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.75 |
| 80 | Sifflet | Signal whistle | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 81 | Tente (deux personnes) | Tent, two-person | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 82 | Vêtements communs | Clothes, common | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 83 | Vêtements de voyage | Clothes, traveler's | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 84 | Vêtements fins | Clothes, fine | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 85 | Costume de déguisement | Clothes, costume | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 86 | Bourse | Pouch | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, description (154 car.), stats | texte du SRD 5.1 FR (PR DeepCore #60) | 0.81 |
| 87 | Armure d'adamantium | Adamantine Armor | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (177 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.15 |
| 88 | Munition tueuse | Ammunition of Slaying | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (765 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.23 |
| 89 | Munition +1 | Ammunition, +1 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (338 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.18 |
| 90 | Munition +2 | Ammunition, +2 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (332 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.19 |
| 91 | Munition +3 | Ammunition, +3 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (337 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.18 |
| 92 | Amulette de santé | Amulet of Health | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (142 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.39 |
| 93 | Amulette d'antidétection | Amulet of Proof against Detection and Location | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (183 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.24 |
| 94 | Amulette des plans | Amulet of the Planes | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (912 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 95 | Bouclier animé | Animated Shield | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (460 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 96 | Appareil de Kwalish | Apparatus of the Crab | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (2025 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.13 |
| 97 | Armure éthérée | Armor of Etherealness | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (319 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.33 |
| 98 | Armure d'invulnérabilité | Armor of Invulnerability | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (351 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.41 |
| 99 | Armure de résistance | Armor of Resistance | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (239 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.36 |
| 100 | Armure de vulnérabilité | Armor of Vulnerability | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (608 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.21 |
| 101 | Armure +1 | Armor, +1 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (119 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.55 |
| 102 | Armure +2 | Armor, +2 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (119 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.55 |
| 103 | Armure +3 | Armor, +3 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (119 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 104 | Bouclier attrape-flèches | Arrow-Catching Shield | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (348 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.46 |
| 105 | Sac à haricots | Bag of Beans | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (2797 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 106 | Sac dévoreur | Bag of Devouring | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1095 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.21 |
| 107 | Sac sans fond | Bag of Holding | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1041 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.40 |
| 108 | Sac à malice | Bag of Tricks | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1072 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.31 |
| 109 | Perle de force | Bead of Force | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (957 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 110 | Ceinturon des nains | Belt of Dwarvenkind | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (737 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.34 |
| 111 | Ceinturon de force de géant | Belt of Giant Strength | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (394 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.04 |
| 112 | Hache du berserker | Berserker Axe | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1157 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 113 | Bottes elfiques | Boots of Elvenkind | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (153 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.48 |
| 114 | Bottes de lévitation | Boots of Levitation | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (77 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.75 |
| 115 | Bottes de rapidité | Boots of Speed | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (399 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.22 |
| 116 | Bottes de sept lieues | Boots of Striding and Springing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (309 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.36 |
| 117 | Bottes des terres gelées | Boots of the Winterlands | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (335 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.17 |
| 118 | Bol de contrôle des élémentaires de l'eau | Bowl of Commanding Water Elementals | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (559 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 119 | Bracelets d'archerie | Bracers of Archery | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (158 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.56 |
| 120 | Bracelets de défense | Bracers of Defense | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (138 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.48 |
| 121 | Brasero de contrôle des élémentaires du feu | Brazier of Commanding Fire Elementals | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (442 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.33 |
| 122 | Broche de défense | Brooch of Shielding | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (131 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.47 |
| 123 | Balai volant | Broom of Flying | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (633 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.12 |
| 124 | Cierge d'invocation | Candle of Invocation | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (968 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.08 |
| 125 | Cape du charlatan | Cape of the Mountebank | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (372 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.33 |
| 126 | Tapis volant | Carpet of Flying | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (550 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.13 |
| 127 | Encensoir de contrôle des élémentaires de l'air | Censer of Controlling Air Elementals | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (435 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.32 |
| 128 | Carillon d'ouverture | Chime of Opening | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (312 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.21 |
| 129 | Diadème de destruction | Circlet of Blasting | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (144 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.39 |
| 130 | Cape de l'araignée | Cloak of Arachnida | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (638 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 131 | Cape de déplacement | Cloak of Displacement | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (347 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.39 |
| 132 | Cape elfique | Cloak of Elvenkind | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (167 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.48 |
| 133 | Cape de protection | Cloak of Protection | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (99 car.), stats | traduction non officielle du SRD 5.2 anglais | 1.00 |
| 134 | Cape de la chauve-souris | Cloak of the Bat | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (579 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.32 |
| 135 | Cape de la raie manta | Cloak of the Manta Ray | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (106 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.67 |
| 136 | Boule de cristal | Crystal Ball | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (90 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.75 |
| 137 | Boule de cristal de lecture des pensées | Crystal Ball of Mind Reading | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (344 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.39 |
| 138 | Boule de cristal de télépathie | Crystal Ball of Telepathy | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (443 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.32 |
| 139 | Boule de cristal de vision véritable | Crystal Ball of True Seeing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (164 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.33 |
| 140 | Cube de force | Cube of Force | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (414 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.03 |
| 141 | Cube portail | Cubic Gate | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (586 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.14 |
| 142 | Dague venimeuse | Dagger of Venom | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (424 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.43 |
| 143 | Épée dansante | Dancing Sword | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (806 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 144 | Carafe intarissable | Decanter of Endless Water | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (705 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.12 |
| 145 | Jeu de cartes illusoires | Deck of Illusions | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1739 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.09 |
| 146 | Défenseur | Defender | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (429 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.48 |
| 147 | Armure démoniaque | Demon Armor | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (622 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.46 |
| 148 | Menottes dimensionnelles | Dimensional Shackles | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (588 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.31 |
| 149 | Orbe draconique | Dragon Orb | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1476 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.23 |
| 150 | Armure d'écailles de dragon | Dragon Scale Mail | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (700 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.17 |
| 151 | Tueuse de dragons | Dragon Slayer | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (184 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.81 |
| 152 | Poudre de disparition | Dust of Disappearance | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (408 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 153 | Poudre dessiccative | Dust of Dryness | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (678 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.22 |
| 154 | Poudre d'éternuement et d'étouffement | Dust of Sneezing and Choking | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (679 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.21 |
| 155 | Harnois nain | Dwarven Plate | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (229 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.28 |
| 156 | Lanceur nain | Dwarven Thrower | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (427 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.44 |
| 157 | Carquois d'Ehlonna | Efficient Quiver | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (432 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.31 |
| 158 | Bouteille d'éfrit | Efreeti Bottle | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (853 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.22 |
| 159 | Gemme élémentaire | Elemental Gem | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (558 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 160 | Cotte de mailles elfique | Elven Chain | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (160 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.62 |
| 161 | Bouteille fumigène | Eversmoking Bottle | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (424 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.06 |
| 162 | Lentilles de charme | Eyes of Charming | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (317 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.19 |
| 163 | Lentilles de vision minutieuse | Eyes of Minute Seeing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (273 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.68 |
| 164 | Lentilles d'aigle | Eyes of the Eagle | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (266 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.45 |
| 165 | Plume de Quaal | Feather Token | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (2292 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.13 |
| 166 | Figurine merveilleuse | Figurine of Wondrous Power | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1557 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.08 |
| 167 | Langue de feu | Flame Tongue | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (495 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.52 |
| 168 | Bateau pliable | Folding Boat | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (714 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.11 |
| 169 | Lame de givre | Frost Brand | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (466 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.50 |
| 170 | Gantelets de puissance d'ogre | Gauntlets of Ogre Power | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (127 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 171 | Gemme de lumière | Gem of Brightness | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (945 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.32 |
| 172 | Gemme de vision | Gem of Seeing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (231 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.22 |
| 173 | Tueuse de géants | Giant Slayer | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (249 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.80 |
| 174 | Cuir clouté enchanté | Glamoured Studded Leather | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (393 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.55 |
| 175 | Gants attrape-projectiles | Gloves of Missile Snaring | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (381 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.41 |
| 176 | Gants de nage et d'escalade | Gloves of Swimming and Climbing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (204 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.53 |
| 177 | Lunettes de nuit | Goggles of Night | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (132 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 178 | Marteau de tonnerre | Hammer of Thunderbolts | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1120 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.28 |
| 179 | Havresac magique | Handy Haversack | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1248 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.27 |
| 180 | Chapeau de déguisement | Hat of Disguise | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (118 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.59 |
| 181 | Bandeau d'intelligence | Headband of Intellect | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (135 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.39 |
| 182 | Heaume de brillance | Helm of Brilliance | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1637 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 183 | Heaume de compréhension des langues | Helm of Comprehending Languages | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (86 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.80 |
| 184 | Heaume de télépathie | Helm of Telepathy | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (226 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.20 |
| 185 | Heaume de téléportation | Helm of Teleportation | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (165 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.48 |
| 186 | Vengeresse sacrée | Holy Avenger | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (536 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.50 |
| 187 | Cor de dévastation | Horn of Blasting | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (581 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 188 | Cor du Valhalla | Horn of Valhalla | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (988 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 189 | Fers du zéphyr | Horseshoes of a Zephyr | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (581 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.17 |
| 190 | Fers de rapidité | Horseshoes of Speed | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (280 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.15 |
| 191 | Sceptre inamovible | Immovable Rod | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (529 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.09 |
| 192 | Forteresse instantanée | Instant Fortress | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1240 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.13 |
| 193 | Bandes de fer | Iron Bands | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (953 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.28 |
| 194 | Flasque de fer | Iron Flask | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1140 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.27 |
| 195 | Javeline de foudre | Javelin of Lightning | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (631 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.42 |
| 196 | Lanterne de révélation | Lantern of Revealing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (371 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.42 |
| 197 | Lame porte-bonheur | Luck Blade | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (645 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.42 |
| 198 | Masse destructrice | Mace of Disruption | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (427 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.44 |
| 199 | Masse d'anéantissement | Mace of Smiting | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (338 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.43 |
| 200 | Masse terrifiante | Mace of Terror | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (676 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.32 |
| 201 | Manteau de résistance aux sorts | Mantle of Spell Resistance | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (93 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.62 |
| 202 | Manuel de santé | Manual of Bodily Health | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (315 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 203 | Manuel d'exercice physique | Manual of Gainful Exercise | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (292 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 204 | Manuel des golems | Manual of Golems | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (916 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.09 |
| 205 | Manuel de vivacité | Manual of Quickness of Action | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (319 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.27 |
| 206 | Pigments merveilleux | Marvelous Pigments | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1164 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.09 |
| 207 | Médaillon des pensées | Medallion of Thoughts | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (184 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.48 |
| 208 | Miroir d'emprisonnement | Mirror of Life Trapping | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1824 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.13 |
| 209 | Armure de mithral | Mithral Armor | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (264 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.33 |
| 210 | Jeu merveilleux | Mysterious Deck | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (4172 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.09 |
| 211 | Collier d'adaptation | Necklace of Adaptation | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (190 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.70 |
| 212 | Collier de boules de feu | Necklace of Fireballs | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (371 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.15 |
| 213 | Chapelet de prière | Necklace of Prayer Beads | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (869 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.12 |
| 214 | Voleuse de neuf vies | Nine Lives Stealer | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (501 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.28 |
| 215 | Arc du serment | Oathbow | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (811 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.19 |
| 216 | Huile éthérée | Oil of Etherealness | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (366 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.37 |
| 217 | Huile glissante | Oil of Slipperiness | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (511 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.48 |
| 218 | Perle de pouvoir | Pearl of Power | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (247 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 219 | Talisman de santé | Periapt of Health | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (259 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.42 |
| 220 | Talisman d'immunité au poison | Periapt of Proof against Poison | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (188 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.34 |
| 221 | Talisman de cicatrisation | Periapt of Wound Closure | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (358 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.45 |
| 222 | Philtre d'amour | Philter of Love | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (239 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.11 |
| 223 | Flûte d'épouvante | Pipes of Haunting | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (464 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 224 | Flûte des égouts | Pipes of the Sewers | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1145 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 225 | Trou portatif | Portable Hole | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1249 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.21 |
| 226 | Potion d'amitié avec les animaux | Potion of Animal Friendship | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (244 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.12 |
| 227 | Potion de clairvoyance | Potion of Clairvoyance | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (186 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.08 |
| 228 | Potion d'escalade | Potion of Climbing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (300 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.28 |
| 229 | Potion de rapetissement | Potion of Diminution | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (319 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.09 |
| 230 | Potion de vol | Potion of Flying | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (321 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.20 |
| 231 | Potion de forme gazeuse | Potion of Gaseous Form | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (246 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 232 | Potion d'agrandissement | Potion of Growth | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (296 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.10 |
| 233 | Potion d'héroïsme | Potion of Heroism | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (244 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.34 |
| 234 | Potion d'invisibilité | Potion of Invisibility | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (232 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.38 |
| 235 | Potion de lecture des pensées | Potion of Mind Reading | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (192 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.18 |
| 236 | Potion empoisonnée | Potion of Poison | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (356 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.20 |
| 237 | Potion de résistance | Potion of Resistance | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (252 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 238 | Potion de rapidité | Potion of Speed | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (236 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 239 | Potion de respiration aquatique | Potion of Water Breathing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (161 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.37 |
| 240 | Anneau d'influence animale | Ring of Animal Influence | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (253 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.40 |
| 241 | Anneau de convocation de djinn | Ring of Djinni Summoning | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (658 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.40 |
| 242 | Anneau de contrôle élémentaire | Ring of Elemental Command | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1802 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.20 |
| 243 | Anneau d'esquive | Ring of Evasion | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (235 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.38 |
| 244 | Anneau de feuille morte | Ring of Feather Falling | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (121 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.68 |
| 245 | Anneau de liberté d'action | Ring of Free Action | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (190 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.32 |
| 246 | Anneau d'invisibilité | Ring of Invisibility | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (192 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.31 |
| 247 | Anneau de saut | Ring of Jumping | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (95 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.54 |
| 248 | Anneau de barrière mentale | Ring of Mind Shielding | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (710 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 249 | Anneau de protection | Ring of Protection | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (99 car.), stats | traduction non officielle du SRD 5.2 anglais | 1.00 |
| 250 | Anneau de régénération | Ring of Regeneration | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (295 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.46 |
| 251 | Anneau de résistance | Ring of Resistance | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (353 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.23 |
| 252 | Anneau d'étoiles filantes | Ring of Shooting Stars | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1315 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 253 | Anneau de stockage de sorts | Ring of Spell Storing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (735 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.14 |
| 254 | Anneau de renvoi des sorts | Ring of Spell Turning | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (387 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.44 |
| 255 | Anneau de nage | Ring of Swimming | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (70 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.45 |
| 256 | Anneau de télékinésie | Ring of Telekinesis | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (73 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.75 |
| 257 | Anneau du bélier | Ring of the Ram | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (665 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.39 |
| 258 | Anneau des trois souhaits | Ring of Three Wishes | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (169 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 259 | Anneau de chaleur | Ring of Warmth | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (211 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.34 |
| 260 | Anneau de marche sur l'eau | Ring of Water Walking | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (107 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.38 |
| 261 | Anneau de vision aux rayons X | Ring of X-ray Vision | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (520 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 262 | Robe aux yeux | Robe of Eyes | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (578 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.47 |
| 263 | Robe de couleurs scintillantes | Robe of Scintillating Colors | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (607 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.41 |
| 264 | Robe étoilée | Robe of Stars | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (694 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.23 |
| 265 | Robe de l'archimage | Robe of the Archmagi | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (521 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.41 |
| 266 | Robe aux objets utiles | Robe of Useful Items | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1183 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.14 |
| 267 | Sceptre d'absorption | Rod of Absorption | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1003 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.17 |
| 268 | Sceptre de vigilance | Rod of Alertness | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (829 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.42 |
| 269 | Sceptre de puissance seigneuriale | Rod of Lordly Might | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (2351 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 270 | Sceptre de souveraineté | Rod of Rulership | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (437 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.13 |
| 271 | Sceptre de sécurité | Rod of Security | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1085 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.23 |
| 272 | Corde d'escalade | Rope of Climbing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (872 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.19 |
| 273 | Corde d'enchevêtrement | Rope of Entanglement | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (933 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 274 | Scarabée de protection | Scarab of Protection | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (540 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.42 |
| 275 | Cimeterre de rapidité | Scimitar of Speed | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (196 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.76 |
| 276 | Bouclier d'attraction des projectiles | Shield of Missile Attraction | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (475 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.35 |
| 277 | Bouclier +1 | Shield, +1 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (129 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.50 |
| 278 | Bouclier +2 | Shield, +2 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (129 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.45 |
| 279 | Bouclier +3 | Shield, +3 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (129 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.32 |
| 280 | Chaussons de pattes d'araignée | Slippers of Spider Climbing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (276 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 281 | Colle universelle | Sovereign Glue | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (468 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.11 |
| 282 | Bouclier gardesort | Spellguard Shield | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (182 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.90 |
| 283 | Sphère d'annihilation | Sphere of Annihilation | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1529 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.22 |
| 284 | Bâton d'envoûtement | Staff of Charming | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (909 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 285 | Bâton de feu | Staff of Fire | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (485 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.40 |
| 286 | Bâton de givre | Staff of Frost | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (513 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.32 |
| 287 | Bâton de guérison | Staff of Healing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (467 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.28 |
| 288 | Bâton de surpuissance | Staff of Power | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1481 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 289 | Bâton de frappe | Staff of Striking | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (460 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.38 |
| 290 | Bâton des essaims d'insectes | Staff of Swarming Insects | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (789 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.20 |
| 291 | Bâton du mage | Staff of the Magi | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1781 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 292 | Bâton du python | Staff of the Python | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (844 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 293 | Bâton des forêts | Staff of the Woodlands | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1192 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 294 | Bâton de tonnerre et de foudre | Staff of Thunder and Lightning | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1347 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.24 |
| 295 | Bâton de flétrissement | Staff of Withering | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (467 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 296 | Pierre de contrôle des élémentaires de la terre | Stone of Controlling Earth Elementals | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (415 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.24 |
| 297 | Pierre porte-bonheur | Stone of Good Luck | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (129 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.60 |
| 298 | Lame du soleil | Sun Blade | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (827 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.35 |
| 299 | Épée voleuse de vie | Sword of Life Stealing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (264 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.56 |
| 300 | Épée acérée | Sword of Sharpness | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (263 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 301 | Épée meurtrière | Sword of Wounding | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (305 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.56 |
| 302 | Talisman du bien suprême | Talisman of Pure Good | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (994 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 303 | Talisman de la sphère | Talisman of the Sphere | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (363 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.39 |
| 304 | Talisman du mal absolu | Talisman of Ultimate Evil | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (952 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 305 | Traité de perspicacité | Tome of Clear Thought | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (315 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.18 |
| 306 | Traité d'autorité et d'influence | Tome of Leadership and Influence | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (321 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.14 |
| 307 | Traité de compréhension | Tome of Understanding | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (316 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 308 | Trident de domination aquatique | Trident of Fish Command | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (223 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.44 |
| 309 | Solvant universel | Universal Solvent | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (317 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.11 |
| 310 | Arme vicieuse | Vicious Weapon | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (123 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.56 |
| 311 | Épée vorpale | Vorpal Sword | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (711 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.20 |
| 312 | Baguette d'entrave | Wand of Binding | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (330 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 313 | Baguette de détection de l'ennemi | Wand of Enemy Detection | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (516 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 314 | Baguette de terreur | Wand of Fear | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (348 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 315 | Baguette de boules de feu | Wand of Fireballs | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (427 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.38 |
| 316 | Baguette d'éclairs | Wand of Lightning Bolts | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (421 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.36 |
| 317 | Baguette de détection de la magie | Wand of Magic Detection | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (180 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.54 |
| 318 | Baguette de projectiles magiques | Wand of Magic Missiles | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (385 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.40 |
| 319 | Baguette de paralysie | Wand of Paralysis | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (575 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.31 |
| 320 | Baguette de métamorphose | Wand of Polymorph | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (334 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.42 |
| 321 | Baguette des secrets | Wand of Secrets | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (268 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.21 |
| 322 | Baguette du mage de guerre | Wand of the War Mage | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (238 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.24 |
| 323 | Baguette de toiles d'araignée | Wand of Web | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (338 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.44 |
| 324 | Baguette merveilleuse | Wand of Wonder | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (3491 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.18 |
| 325 | Arme d'alerte | Weapon of Warning | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (348 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 326 | Arme +1 | Weapon, +1 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (130 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.71 |
| 327 | Arme +2 | Weapon, +2 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (130 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.71 |
| 328 | Arme +3 | Weapon, +3 | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (130 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.67 |
| 329 | Puits des mondes | Well of Many Worlds | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (579 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.24 |
| 330 | Éventail du vent | Wind Fan | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (249 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 331 | Bottes ailées | Winged Boots | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (310 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.37 |
| 332 | Ailes de vol | Wings of Flying | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (390 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.34 |
| 333 | Potion de soins | Potion of Healing | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (334 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.06 |
| 334 | Potion de force de géant | Potion of Giant Strength | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (460 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.06 |
| 335 | Parchemin de sort | Spell Scroll | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1000 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.18 |
| 336 | Pierre de Ioun | Ioun Stone | Guide du maître (2024) / SRD 5.2 | SRD 5.2 | nom, description (1024 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.02 |
| 337 | Acide (fiole) | Acid | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (314 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.45 |
| 338 | Feu grégeois (flasque) | Alchemist's Fire | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (463 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.48 |
| 339 | Eau bénite (flasque) | Holy Water | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (347 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.43 |
| 340 | Antitoxine (fiole) | Antitoxin | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (166 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.40 |
| 341 | Mousquet | Musket | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (39 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 342 | Pistolet | Pistol | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (39 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 343 | Flèches (20) | Arrows (20) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (92 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 344 | Carreaux (20) | Bolts (20) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (92 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 345 | Balles d'arme à feu (10) | Bullets, Firearm (10) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (87 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 346 | Billes de fronde (20) | Bullets, Sling (20) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (81 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 347 | Aiguilles de sarbacane (50) | Needles (50) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (84 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 348 | Billes (sac de 1 000) | Ball Bearings | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (289 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.21 |
| 349 | Tonneau | Barrel | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (76 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 350 | Panier | Basket | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (58 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.12 |
| 351 | Clochette | Bell | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (73 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 352 | Palan | Block and Tackle | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (83 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.70 |
| 353 | Livre | Book | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (194 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.33 |
| 354 | Bouteille en verre | Bottle, Glass | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (23 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 355 | Seau | Bucket | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (27 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 356 | Chausse-trappes (sac de 20) | Caltrops | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (361 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.31 |
| 357 | Étui à carreaux | Case, Crossbow Bolt | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (29 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 358 | Étui à cartes ou parchemins | Case, Map or Scroll | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (66 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.62 |
| 359 | Chaîne (3 m) | Chain | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (344 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.24 |
| 360 | Coffre | Chest | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (28 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 361 | Fourrage (1 jour) | Feed (per day) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (50 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 362 | Flasque | Flask | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (23 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 363 | Piège à mâchoires | Hunting Trap | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (373 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.23 |
| 364 | Cruche | Jug | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (26 car.), stats | traduction non officielle du SRD 5.2 anglais | 1.00 |
| 365 | Échelle (3 m) | Ladder | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (60 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 366 | Lampe | Lamp | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (107 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.76 |
| 367 | Loupe | Magnifying Glass | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (188 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.13 |
| 368 | Menottes | Manacles | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (351 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 369 | Carte | Map | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (118 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 370 | Parfum (fiole) | Perfume | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (148 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 371 | Poison ordinaire (fiole) | Poison, Basic | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (280 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.57 |
| 372 | Perche (3 m) | Pole | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (157 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.15 |
| 373 | Carquois | Quiver | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (28 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 374 | Bélier portatif | Ram, Portable | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (152 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.26 |
| 375 | Robe | Robe | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (160 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.05 |
| 376 | Selle exotique | Saddle (Exotic) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (69 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 377 | Selle de guerre | Saddle (Military) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (68 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 378 | Selle d'équitation | Saddle (Riding) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (34 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 379 | Pelle | Shovel | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (109 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.35 |
| 380 | Longue-vue | Spyglass | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (77 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 381 | Ficelle (3 m) | String | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (65 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.30 |
| 382 | Fiole | Vial | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (23 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 383 | Kit d'escalade | Climber's Kit | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (224 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.16 |
| 384 | Outils d'alchimiste | Alchemist's Supplies (50 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (180 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.10 |
| 385 | Outils de brasseur | Brewer's Supplies (20 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (140 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.08 |
| 386 | Outils de calligraphe | Calligrapher's Supplies (10 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (132 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 387 | Outils de charpentier | Carpenter's Tools (8 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (195 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.23 |
| 388 | Outils de cartographe | Cartographer's Tools (15 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (100 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 389 | Outils de cordonnier | Cobbler's Tools (5 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (182 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.43 |
| 390 | Ustensiles de cuisinier | Cook's Utensils (1 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (153 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 391 | Kit de déguisement | Disguise Kit | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (81 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 392 | Kit de faussaire | Forgery Kit | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (137 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 393 | Jeu de dés | Gaming Set, Dice | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (97 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 394 | Jeu d'échecs draconiques | Gaming Set, Dragonchess | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (133 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.06 |
| 395 | Jeu de cartes | Gaming Set, Playing Cards | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (129 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.06 |
| 396 | Jeu des trois dragons | Gaming Set, Three-Dragon Ante | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (129 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.06 |
| 397 | Outils de souffleur de verre | Glassblower's Tools (30 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (184 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.09 |
| 398 | Kit d'herboriste | Herbalism Kit | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (114 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 399 | Outils de joaillier | Jeweler's Tools (25 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (130 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.25 |
| 400 | Outils de tanneur | Leatherworker's Tools (5 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (196 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.08 |
| 401 | Outils de maçon | Mason's Tools (10 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (114 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.23 |
| 402 | Cornemuse | Musical Instrument, Bagpipes | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 403 | Tambour | Musical Instrument, Drum | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 404 | Tympanon | Musical Instrument, Dulcimer | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 405 | Flûte | Musical Instrument, Flute | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 406 | Cor | Musical Instrument, Horn | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 407 | Luth | Musical Instrument, Lute | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 408 | Lyre | Musical Instrument, Lyre | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 409 | Flûte de Pan | Musical Instrument, Pan Flute | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 410 | Chalémie | Musical Instrument, Shawm | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 411 | Vielle | Musical Instrument, Viol | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (103 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 412 | Outils de navigateur | Navigator's Tools | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (97 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 413 | Outils de peintre | Painter's Supplies (10 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (162 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.29 |
| 414 | Kit d'empoisonneur | Poisoner's Kit | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (110 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 415 | Outils de potier | Potter's Tools (10 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (157 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.11 |
| 416 | Outils de forgeron | Smith's Tools (20 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (339 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.13 |
| 417 | Outils de voleur | Thieves' Tools | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (101 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.20 |
| 418 | Outils de bricoleur | Tinker's Tools (50 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (266 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.09 |
| 419 | Outils de tisserand | Weaver's Tools (1 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (232 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.11 |
| 420 | Outils de sculpteur sur bois | Woodcarver's Tools (1 GP) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (250 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.10 |
| 421 | Chameau | Camel | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (83 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 422 | Éléphant | Elephant | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (87 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 423 | Cheval de trait | Horse (Draft) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (79 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 424 | Cheval de selle | Horse (Riding) | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (89 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 425 | Molosse | Mastiff | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (96 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 426 | Mule | Mule | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (70 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.14 |
| 427 | Poney | Pony | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (104 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 428 | Cheval de guerre | Warhorse | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (92 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 429 | Carrosse | Carriage | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (83 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 430 | Charrette | Cart | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (87 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 431 | Char | Chariot | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (79 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 432 | Traîneau | Sled | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (53 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 433 | Chariot | Wagon | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (94 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 434 | Galère | Galley | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (101 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 435 | Bateau à quille | Keelboat | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (83 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.08 |
| 436 | Drakkar | Longship | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (97 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 437 | Barque | Rowboat | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (71 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 438 | Voilier | Sailing Ship | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (77 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 439 | Navire de guerre | Warship | Manuel des Joueurs (2024) / SRD 5.2 | SRD 5.2 | nom, description (94 car.), stats | traduction non officielle du SRD 5.2 anglais | 0.00 |
| 440 | Serre | Talons | Trait racial | hors SRD | nom, stats | nom seul (arme naturelle, décision 78) |  |
| 441 | Sabots | Hooves | Trait racial | hors SRD | nom, stats | nom seul (arme naturelle, décision 78) |  |
| 442 | Morsure | Bite | Trait racial | hors SRD | nom, stats | nom seul (arme naturelle, décision 78) |  |
| 443 | Cornes | Horns | Trait racial | hors SRD | nom, stats | nom seul (arme naturelle, décision 78) |  |
| 444 | Griffes félines | Cat's claws | Trait racial | hors SRD | nom, stats | nom seul (arme naturelle, décision 78) |  |
| 445 | Griffes | Claws | Trait racial | hors SRD | nom, stats | nom seul (arme naturelle, décision 78) |  |
| 446 | Cire à sceller | Sealing Wax | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 447 | Savon | Soap | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 448 | Boîte à aumônes | Alms Box | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 449 | Encensoir | Censer | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 450 | Encens (bloc) | Incense (Block) | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 451 | Vêtements sacerdotaux | Vestments | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 452 | Petit couteau | Small Knife | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 453 | Petit sac de sable | Little Bag of Sand | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |
| 454 | Livre de savoir | Book of Lore | SRD 5.1 (Manuel des Joueurs 2014) | SRD 5.1 | nom, stats | texte du SRD 5.1 FR (PR DeepCore #60) |  |

</details>

### 2.14 Noms seuls et données sans texte

Signalés à part, non comptés comme du texte :

| Contenu | Nombre | Statut |
|---|---:|---|
| Langues, compétences, outils, caractéristiques, alignements | 16, 18, 36, 6, 9 | noms, tous présents au SRD 5.1 |
| Paquetages d'équipement | 7 | noms et contenus (listes d'objets), au SRD 5.1 |
| Armes naturelles (objets « Trait racial ») | 6 | noms hors SRD, gardés (décision 78) |
| Noms de créatures | 648 | SRD 5.1 et 5.2 (PR #58, #59) |
| Noms des éléments hors SRD (races, sous-classes, dons, sorts...) | 1 307 | noms de produits Wizards ; souvent des termes descriptifs, mais certains sont distinctifs (« Chevalier runique », noms propres de sorts : Tasha, Mordenkainen, Bigby...) ; question de marque et de droit d'auteur sur les titres à faire valider |
| Listes de sorts par classe (`spell_classes`), sorts de domaine/serment/patron (`subclass_spells`), sorts innés raciaux (`racial_innate_spells`) | 1 392, 320, 36 | données factuelles (sélection tirée des livres pour le hors SRD) ; pas de texte |
| Mécanique structurée (bonus raciaux, vitesse, prérequis, bonus de dons, statistiques d'objets, dés de vie...) | - | faits de règles, pas de texte |
| `racial_innate_spells.unresolved_note` | 1 | note technique |

Les noms de sorts hors SRD (« Rire hideux de Tasha », « Main de Bigby »...) et les noms de sous-classes sont repris
partout (fiche Nexus, Bibliothèque, `group_snapshot` de Grimoire). Leur traitement relève d'un avis séparé.

## 3. Requêtes d'usage (production)

Fichier : `requetes-usage.sql`. SELECT uniquement, à lancer dans une transaction en lecture seule. Elles ne renvoient que
des comptes agrégés et des noms d'éléments du référentiel (déjà publics) : aucun identifiant, aucun nom de personnage ni
de joueur. Jointure par **nom français** et non par identifiant (les identifiants diffèrent entre local et production).
La classification de ce registre y est embarquée (1 088 couples catégorie / parent / nom).

| Requête | Ce qu'elle renvoie |
|---|---|
| Q1 | Pour chaque élément utilisé (race, sous-race, lignée, historique, classe, sous-classe, don, invocation, sort, option de classe) : classification, nombre de personnages distincts, dont actifs (ni archivés ni morts), et pour les sorts le nombre de personnages qui l'ont connu, préparé ou inné. Sous-totaux par catégorie et classification, total général. Une valeur d'option inconnue n'est jamais renvoyée en clair (« (valeur non reconnue) »). |
| Q2 | Par édition (2014, 2024, total) : personnages, actifs, personnages touchant au moins un élément hors SRD, au moins un élément « SRD mais texte non conforme », et personnages sans aucun élément hors SRD. |
| Q3 | Référentiel de production non couvert par l'audit (ébauches d'import XML, ajouts hors migration, renommages) avec le nombre de personnages qui l'utilisent. |
| Q4 | Contenu de `traits_2024` (races, sous-races) : noms des traits et longueur du texte ; Q4 bis : colonnes `*2024*` existantes. |
| Q5 | Aptitudes de classe ou de sous-classe qui alimentent un compteur d'usages (`character_feature_uses`), avec la classification de leur propriétaire et le nombre de personnages. |

Tests sur la pile locale (lecture seule, `default_transaction_read_only=on`) : les cinq requêtes s'exécutent ; Q3 et Q4
renvoient 0 ligne (tout le référentiel local est couvert ; la colonne `traits_2024` n'existe pas en local). La base locale
n'ayant aucun personnage, la logique de comptage de Q1, Q2 et Q5 a été vérifiée en remplaçant les tables personnages par
des CTE fictives (3 personnages, sans aucune écriture) : comptes, sous-totaux, statut des sorts, codes du pacte, libellé
« Combat à deux mains » de Nexus et valeur libre masquée sont corrects.

## 4. Points particuliers

### 4.1 Distinction 2014 / 2024 et `traits_2024`

- Le contenu est **majoritairement 2014** : races et sous-races, classes, aptitudes, sous-classes, dons PHB14, historiques,
  sorts (sauf 6). Le 2024 est représenté par les 24 lignées 2024 (SRD 5.2), 6 sorts 2024, 17 dons 2024 (SRD52/PHB24), les
  objets 2024 et la race Orc ; il y a peu de textes 2024 propres.
- **Piège des homonymes** : le SRD 5.2 contient la version 2024 de nombreux éléments dont DeepCore n'a que le texte 2014
  (15 sorts, 4 dons d'origine, 5 invocations, 4 options de classe, 3 historiques, 3 sous-races en lignées, Goliath,
  les 12 sous-classes). Avoir le nom au SRD ne rend pas libre le texte 2014 : soit on prend le texte 2024 du SRD 5.2
  (règle différente : décision produit, avis `regles-dnd`), soit on garde le texte 2014 comme hors SRD.
- **`traits_2024`** : Nexus lit `races.traits_2024` et `subraces.traits_2024` (commit Nexus `dc0ec2b`, 24/10/2026 :
  « colonne traits_2024 [...] désormais appliquées en base »), mais **aucune migration de DeepCore** ne crée ces
  colonnes (recherche dans tout l'historique Git, toutes branches) et la pile locale ne les a pas. Elles ont donc été
  ajoutées en production hors de l'historique de migrations : contenu non audité, dérive de schéma (règle « un seul
  historique de migrations »). La requête Q4 en fait l'inventaire. D'après Nexus, elles portent les traits 2024 de races
  2024 propres (d'après les commentaires de Nexus : Nain et Halfelin unifiés en 2024, Demi-elfe sans équivalent,
  Orc, Aasimar et Goliath sans `traits_2024`) : texte au SRD 5.2 pour les espèces du SRD, hors SRD sinon.

### 4.2 Textes partiellement libres

- **Sorts du SRD 5.1** : le texte anglais en base est celui du SRD (libre), le texte français affiché est un résumé
  d'aidedd ou une traduction maison. Le même élément mêle donc un texte libre et un texte qui ne l'est pas.
- **Races du SRD 5.1** : traits reformulés, dont certaines phrases reprises presque mot pour mot du SRD français
  (recouvrement 0,56 à 0,88 sur Ascendance féerique, Brave, Ruse gnome, Résistance aux dégâts, Résistance naine...),
  à côté de traits inventés (« Polyvalence » de l'Humain) : mélange libre / maison, sans texte de livre identifié.
- **Aptitudes des 12 classes et des 12 sous-classes SRD** : 17 textes proches du SRD officiel (≥ 0,60), les autres
  partagent des phrases (0,2 à 0,5) : traduction indépendante du SRD anglais, d'origine partiellement aidedd. Libres en
  substance (contenu SRD), non conformes à la lettre.
- **Objets 2024, faveurs épiques, invocations 1 à 32, sorts 2024** : traductions non officielles du SRD anglais ;
  conformes à CC BY à condition de le signaler (« Modifié : traduit de l'anglais »), ce que seul Grimoire fait.
- **Lignées 2024 et ascendances 2014** : résumés mécaniques maison d'un contenu SRD : libres en substance.

### 4.3 Traductions françaises officielles du SRD

| Type | SRD 5.1 FR officiel | SRD 5.2.1 FR officiel | Utilisé en base aujourd'hui |
|---|---|---|---|
| Races / espèces et traits | oui (9 races, 4 sous-races) | oui (9 espèces, lignées) | non (reformulation) |
| Classes et aptitudes | oui (12 classes) | oui (12 classes) | non (traduction non officielle) |
| Sous-classes et aptitudes | oui (1 par classe) | oui (1 par classe) | non |
| Dons | oui (Empoignade) | oui (17 dons) | non (traductions maison) |
| Sorts | oui (319) | oui (339) | **non** (résumés aidedd / maison) |
| Invocations | oui (32) | oui (28) | non (traduction maison) |
| Historiques | oui (Acolyte) | oui (4) | non |
| Options (styles, métamagie, pactes) | oui | oui | non |
| Objets | oui | oui (5.2.1) | 2014 oui (PR #60) ; 2024 non (traduction maison du 5.2 anglais, faite avant la parution du 5.2.1 FR) |
| Monstres | oui | oui (5.2.1) | oui (PR #58, #59) |

Les noms officiels français diffèrent souvent des noms en base (aidedd, traduction maison : « Armure de mage » /
« Armure du mage », « Bond » / « Saut », « Chute plume » / « Feuille morte »...). Le SRD 5.1 français porte un pied de
page « Interdit à la revente [...] usage personnel » (décision 71 : ignoré, à confirmer par un conseil) ; le SRD 5.2.1
français ne l'a pas. Les deux demandent de n'ajouter **aucune autre attribution** à Wizards que la déclaration fournie :
la phrase de marques de l'écran Crédits de Nexus est à faire relire.

### 4.4 Grimoire

- **Embarque** (`server/catalog/trial-extract.json`) : 59 monstres (SRD 5.1 et 5.2) et 35 objets 2024 (SRD 5.2). Aucun
  objet 2014 (décision 74), aucun sort, race, classe, don ni historique.
- **Télécharge** avec un compte Nexus : bestiaire et catalogue d'objets complets (`api_v1.bestiary_*`,
  `api_v1.item_catalog_*`), en **masquant** toute entrée dont `source` ne contient pas « SRD 5.x » (`isSrdSource` :
  armes naturelles et, avant la PR #60, objets 2014). Les objets 2014 réapparaîtront d'eux-mêmes (source changée).
- **Reçoit des noms** du contenu Nexus via `api_v1.group_snapshot` : `race_name`, `class_name`, `subclass_name` des
  personnages d'un groupe, donc des noms hors SRD (Tabaxi, Lame maudite...) dans un produit payant. Aucun texte.
- Mentions CC BY exactes (SRD 5.1, 5.2, 5.2.1) avec lignes « Modifié », toujours visibles près du bestiaire et du
  catalogue. Le guide pour IA renvoie au SRD sans embarquer de règles.
- **Vigilance** : si Grimoire télécharge un jour d'autres catalogues (sorts, races...), le filtre `isSrdSource` ne suffira
  pas tant que `source` reste inexacte (319 sorts SRD étiquetés « Manuel des Joueurs », colonnes absentes ailleurs).

### 4.5 Autres constats

- **Bibliothèque web** : toutes les pages de référentiel sont publiques et sans mention de licence (sauf Créatures). C'est
  la surface la plus exposée après l'API `anon`.
- **Nexus embarque ses propres textes de règles** (hors DeepCore, signalé pour mémoire) : 14 résumés d'états
  (`conditionXxxRule`, SRD), descriptions des 3 pactes (`warlock_pact.dart`), tables d'identifiants aidedd
  (`aidedd_reference_tables.dart`, noms seuls).
- **Ébauches d'import XML** : l'import aidedd crée des lignes `races`, `backgrounds`, `spells` (`is_incomplete`) avec le
  nom saisi dans l'export ; ces lignes sont publiques comme le reste du référentiel (Q3 les liste).
- **Contenu communautaire** (`content_proposals`, Bibliothèque) : texte saisi par les utilisateurs, hors périmètre, mais
  canal possible de copie de texte de livre lors d'une fusion dans le référentiel (modération).

## 5. Options par type, recommandation, effort et impact sur Nexus

### 5.1 Les quatre options

| Option | Principe | Limite |
|---|---|---|
| A. Remplacer par le texte du SRD | texte officiel français du SRD 5.1 (2014) ou 5.2.1 (2024), avec la déclaration d'attribution et une ligne « Modifié » | seulement pour les éléments au SRD ; pour un homonyme 2014 → 2024, change la règle |
| B. Nom + résumé mécanique maison neutre | garder le nom, écrire un résumé factuel des effets (chiffres, portées, durées), sans reprendre l'expression du livre | **incertitude juridique** : mécaniques en principe non protégeables, mais sélection, agencement et noms peuvent l'être ; avis d'un conseil requis |
| C. Retirer du contenu public | retirer la lecture `anon` et la Bibliothèque publique, ou masquer pour les nouveaux personnages (colonne de visibilité), sans supprimer les lignes | ne règle pas la question pour les joueurs connectés ; « supprimer » casse des personnages (5.3) |
| D. Garder | statu quo, risque assumé | à documenter comme décision |

### 5.2 Par type

| Type | Option recommandée | Effort | Remarques |
|---|---|---|---|
| **Sorts, textes EN des 157 sorts non libres** | retirer (C) ; remplacer les 15 homonymes par le texte SRD 5.2 anglais si on adopte la version 2024 | **S** (une migration sur `translations`) | aucun client ne les lit : impact Nexus nul |
| Sorts SRD 5.1 (319) et 2024 (6), texte FR | A (SRD 5.1 FR ; SRD 5.2.1 FR pour les 6) | **M** (extraction du PDF, contrôle `regles-dnd` des écarts, comme la PR #60) | descriptions plus longues (affichage à vérifier) ; noms gardés |
| Sorts hors SRD (174) et 15 homonymes, texte FR | B pour les 141 résumés aidedd (réécriture), B ou C pour le reste, sur avis | **M** (B) | les 32 résumés maison sont déjà de type B |
| Races SRD 5.1 (9), sous-races SRD (4), Orc | A | **S** | `traits` seulement ; Humain : remplacer « Polyvalence » par les traits du SRD |
| Races et sous-races hors SRD (26 + 11, dont Aasimar et Goliath 2014) | B ou C sur avis | B : **M** ; C : **S** | 14 personnages en production, tous sur races MdJ/SRD d'après le chef de projet |
| Lignées SRD (34) | A ou garder (résumés de contenu libre) | **S** | |
| Lignées hors SRD (9) | B (déjà un résumé) ou C | XS | |
| Classes (12) et aptitudes de base (211) | A | **L** (228 aptitudes, découpage par niveau différent du SRD, doublons d'ASI) | aucune incidence sur les calculs (champs structurés) |
| Artificier et ses aptitudes | B ou C sur avis | B : S | nom codé en dur dans Nexus (`infusions_known_progression.dart`) |
| Sous-classes SRD (12) et 105 aptitudes | A ; **corriger l'id 7** (Serment des Anciens n'est pas SRD) | **M** | |
| Sous-classes hors SRD (109) et 697 aptitudes | B (l'existant s'en rapproche) ou C, sur avis | B : **L** (relecture de 697 textes) | 6 noms codés en dur dans Nexus (5.3) |
| Options de classe SRD (17) | A | **S** | `chosen_value` = nom : ne pas renommer |
| Options hors SRD (76) et 4 homonymes | B ou C | S à M | manœuvres, disciplines, runes, tirs, infusions pilotent des progressions Nexus |
| Dons SRD (9) | garder (traduction du SRD) ou A avec le texte 5.1/5.2.1 FR | XS | |
| Dons hors SRD (103) et 4 homonymes | B ou C sur avis | B : **M** | « Robuste physiquement » et « Faveur de robustesse » codés en dur (PV) |
| Invocations SRD (32) | garder ou A | S | |
| Invocations hors SRD (17) et 5 homonymes | B ou C | S | |
| Historiques (Acolyte + 3 homonymes) | A pour Acolyte | XS | |
| Historiques hors SRD (67) | B ou C | B : M | `background_id` passe à NULL si la ligne est supprimée |
| Objets 2024 (353) | garder (traduction du SRD 5.2, déjà attribuée) ou A avec le SRD 5.2.1 FR | M | décision 69 en cours sur les armes 2024 |
| `traits_2024` | auditer (Q4), puis A pour les 9 espèces SRD, B/C pour le reste ; **ajouter la migration manquante** | S | |
| Mentions de licence (Nexus, Bibliothèque) | corriger tout de suite | **S** | texte exact de Wizards + « Modifié » + phrase sur le contenu non SRD |
| Colonnes de licence et `source` | ajouter `licence` (`srd_5_1`, `srd_5_2`, `hors_srd`) partout, corriger `source` | **M** | prérequis de toute option C et du filtre de Grimoire |

Échelle d'effort : XS < 1 h, S ≈ une demi-journée à un jour, M ≈ 2 à 4 jours, L ≈ une à deux semaines (développement,
contrôle `regles-dnd`, tests, sans compter la relecture juridique).

### 5.3 Impact sur Nexus

**Personnages existants.** Les requêtes Q1 et Q2 donnent l'usage réel. Clés étrangères vers le référentiel :

| Si on supprime une ligne de... | Effet en base |
|---|---|
| `races`, `subraces`, `race_lineages`, `backgrounds` | `characters.race_id` / `subrace_id` / `lineage_id` / `background_id` passent **silencieusement à NULL** (`SET NULL`) : perte de donnée joueur ; supprimer une race supprime aussi ses sous-races et lignées (`CASCADE`) |
| `subclasses`, `feats`, `invocations`, `spells`, `class_features`, `items` | suppression **refusée** si un personnage les utilise (`NO ACTION` / `RESTRICT`) ; sinon `CASCADE` sur aptitudes, options, sorts de sous-classe, listes de classe |
| `translations` (texte seul) | aucune contrainte : remplacer un texte ne touche à aucun personnage |

**Calculs.** Nexus n'analyse **jamais** le texte des descriptions (aucune expression régulière ni recherche dans une
description) : les options A et B, qui ne changent que les textes, n'ont aucun effet sur les calculs. Les calculs
s'appuient sur des champs structurés (bonus raciaux, vitesse, `uses_per_rest`, `choice_type`, prérequis, sorts de
sous-classe, sorts innés, bonus de dons, statistiques d'objets) et sur des **noms français codés en dur** :

| Nom codé en dur (Nexus) | Élément | Statut | Rôle |
|---|---|---|---|
| `Lignage draconique` | sous-classe | SRD | CA (Résilience draconique), PV |
| `Défense` | style de combat | SRD | CA +1 |
| `Nain des collines` | sous-race | SRD | PV |
| `Barbare`, `Moine`, `Barde`, `Roublard`, `Ensorceleur`, `Occultiste`, `Commun` | classes, langue | SRD | CA sans armure, expertise, métamagie, sorts de patron, langues |
| `Robuste physiquement` | don (Tough) | hors SRD | PV +2/niveau |
| `Faveur de robustesse` | faveur épique (PHB 2024) | hors SRD | PV +40 |
| `Maître de guerre` | sous-classe | hors SRD | manœuvres, dés de supériorité |
| `Archer arcanique` | sous-classe | hors SRD | tirs arcaniques connus |
| `Voie des quatre éléments` | sous-classe | hors SRD | disciplines connues |
| `Chevalier runique` | sous-classe | hors SRD | runes connues |
| `Lame maudite` | sous-classe | hors SRD | arme de pacte |
| `Artificier` | classe | hors SRD | infusions connues |

Renommer ou retirer l'un de ces éléments casse la progression correspondante. `character_class_options.chosen_value`
stocke le nom de l'option choisie : renommer une option déconnecte les choix déjà faits.

**Import XML aidedd.** Race, sous-race, classe, sous-classe, historique, sorts et invocations sont reconnus par **nom
français** (normalisé). Un élément retiré ou renommé n'est plus reconnu : race, historique et sorts sont recréés en
**ébauche** dans le référentiel partagé (`is_incomplete`, nom seul), sous-classe et invocation restent « non reconnues ».
Les noms d'aidedd suivent la traduction historique (pas toujours celle du SRD français) : garder les noms actuels.

**Création et montée de niveau.** Les listes viennent du référentiel : un élément masqué disparaît des choix (option C).
Un élément sans texte reste choisissable. Le cache hors ligne de Nexus (drift, TTL) propage les nouveaux textes au
prochain rafraîchissement.

**Ce qui casse si un élément disparaît** : fiche (race, historique vides), montée de niveau (progressions par nom),
import XML (ébauches recréées), groupe Grimoire (`race_name`/`subclass_name` nuls), Bibliothèque (pages 404), migrations
bloquées par les clés étrangères. D'où la recommandation de **masquer**, jamais de supprimer.

## 6. Questions à trancher (hors du périmètre de cet audit)

À soumettre à Matthias, et pour les points juridiques à un conseil :

1. « Nom + résumé mécanique maison » suffit-il pour le contenu hors SRD dans une app gratuite (Nexus), dans une
   Bibliothèque publique, et dans un produit payant (Grimoire) ?
2. Les résumés d'aidedd.org (420 sorts) peuvent-ils rester, même pour les sorts du SRD ? Faut-il demander une
   autorisation à aidedd, ou tout réécrire ?
3. Adopte-t-on le texte 2024 du SRD 5.2 pour les homonymes (règle différente), ou garde-t-on le texte 2014 comme hors SRD ?
4. Le pied de page « Interdit à la revente » du SRD 5.1 français (décision 71) et la phrase de marques de l'écran Crédits.
5. Retire-t-on la lecture `anon` du contenu hors SRD (impact : Bibliothèque sans connexion) ?
6. Origine et licence de `CodexArcanum_V2.html` (source des sous-classes et historiques de la phase 5).

## 7. Reproductibilité

Scripts de l'audit (lecture seule, dossier `audit-licence/` du scratchpad) : `load.py` (export JSON des tables de
référence par `psql` en `default_transaction_read_only=on`), `srd.py` (5-grammes et recouvrement), `srd_lists.py`
(listes de sorts des quatre SRD), `a_spells.py` et `a_spells2.py` (rapprochement des sorts), `classify.py`
(classification, `rows.json`), `gen_sql.py` (requêtes), `test_sql.py` (test de logique par CTE fictives),
`gen_report.py` (ce registre).

## Usage relevé en production le 25/11/2026 (chef de projet, lecture seule, agrégats)

- 14 personnages en tout ; races : toutes issues du Manuel des Joueurs ou du SRD (aucune race de supplément).
- Sous-classes utilisées (8 personnages) : Archifée, Domaine de la Vie, Gardien de drake, Lame maudite, Lignage draconique,
  Magie sauvage, Maître de guerre, Phantôme.
- Dons : 1 personnage (« Acteur », PHB 2014).
- Sorts utilisés par source : Manuel des Joueurs 49, Guide de Xanathar 8, Chaudron de Tasha 2, Acquisitions
  Incorporated 1, Manuel des Joueurs (2024) 1 (12 personnages).
- Historiques utilisés (14 personnages) : Acolyte, Ermite, Gamin des rues, Noble, Pêcheur, Rieur, Sage.
- Invocations : 2, 1 personnage.
- `traits_2024` (colonne absente des migrations de DeepCore, présente en production) : 7 races et 5 sous-races,
  4 653 caractères de texte.
