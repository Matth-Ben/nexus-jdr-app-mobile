# Changelog — Nexus JDR (app mobile)

Toutes les évolutions notables de l'application, version par version.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
versions au format `X.Y.Z+N` de `pubspec.yaml` (`N` = numéro de build Android,
à incrémenter à chaque envoi sur Google Play).

Chaque version comporte un bloc **Notes de version (stores)** prêt à coller
dans la Play Console (« Notes de version », 500 caractères max, balise
`<fr-FR>`), rédigé pour les joueurs — le détail technique est en dessous.

## Publier une nouvelle version

1. Déplacer le contenu de « Non publié » dans une nouvelle section
   `[X.Y.Z] — AAAA-MM-JJ` et rédiger ses notes de version (stores).
2. Monter `version:` dans `pubspec.yaml` (`X.Y.Z+N`, `N` toujours supérieur
   au précédent) via une PR `chore: version X.Y.Z+N`.
3. Une fois la PR mergée, poser le tag annoté `vX.Y.Z` sur le commit de merge
   et le pousser : `release-android.yml` construit l'App Bundle signé et le
   joint à la Release GitHub.
4. Téléverser `app-prod-release.aab` dans la Play Console (piste de test ou
   production) et coller les notes de version.

---

## [Non publié]

_Rien pour l'instant._

---

## [1.0.6] — 2026-10-04 (build 7)

### Notes de version (stores)

```
<fr-FR>
Fiche et création :
• Dé affiché sur chaque sort et arme des listes
• Races groupées par extension (base/extension) + recherche
• Armes de départ équipées par set (1 ou 2 mains)
• Sorts innés raciaux accordés automatiquement (Tieffelin, Génasi, Drow)
• Détail des maîtrises d'armes/armures (touche un chip)
• Listes triées par ordre alphabétique (races, classes, historiques...)
Groupes :
• Solde max mieux affiché dans « S'attribuer de la monnaie »
</fr-FR>
```

### Ajouté
- Onglets Sorts et Inventaire : une icône de dé (d4 à d20, repli en cercle
  pour tout nombre de faces non standard) à côté de chaque sort/arme,
  indiquant le dé de dégâts nécessaire.
- Onglet Compétences : chaque chip de maîtrise d'armes/armures ouvre un
  panneau listant le contenu concret du token (ex. « armes de guerre » liste
  les armes concernées, avec leurs dégâts/propriétés ; « armure
  intermédiaire » liste les armures correspondantes avec CA/bonus de Dex).
- Étape « Race » de la création : les races sont groupées en « RACES DE
  BASE » (Manuel des Joueurs) puis « RACES D'EXTENSION », avec un champ de
  recherche par nom.
- Création de personnage : les armes de départ sont équipées par set (set
  principal, 2 « mains »), en tenant compte du deux mains ou pas — deux
  armes à une main peuvent être équipées ensemble.
- Sorts innés raciaux (Tieffelin, Génasi, Drow) accordés automatiquement à
  la création et à chaque montée de niveau qui en débloque un nouveau — les
  races dont le sort dépend d'un choix de lignée/ascendance non encore
  proposé au joueur (Drakéide, variantes 2024 d'Elfe/Gnome/Tieffelin)
  restent pour un prochain chantier.

### Modifié
- Tri alphabétique français (accents ignorés) des catalogues de création et
  de montée de niveau : races/sous-races, classes, historiques, outils,
  langues, sous-classes, styles de combat, ennemis jurés — harmonisé avec les
  listes déjà triées (dons, invocations, sorts, catalogue d'objets).
- Fiche personnage : les aptitudes de classe sont triées par ordre
  alphabétique plutôt que par niveau d'acquisition.
- Groupes, « S'attribuer de la monnaie » : le solde maximum disponible
  s'affiche sous le champ de saisie plutôt qu'à côté, plus lisible une fois
  les champs compressés.

### Corrigé
- Création de personnage : l'arme de départ est désormais équipée d'office,
  comme l'armure — auparavant seule l'armure l'était.
- Onglet Compétences : les chips de maîtrise d'armes/armures restent côte à
  côte au lieu de s'empiler chacune sur sa propre ligne (régression
  introduite par le panneau de détail des maîtrises de cette version).

---

## [1.0.5] — 2026-10-01 (build 6)

### Notes de version (stores)

```
<fr-FR>
Groupes :
• Touche le code d'invitation pour le copier
• Touche un membre pour voir sa fiche complète (en lecture seule)
• Butin : sélectionne plusieurs objets du catalogue d'un coup avant de les ajouter
Fiche et création :
• CA corrigée (armure équipée d'office, Défense sans armure, objets magiques)
• Équipement de départ de classe, bonus raciaux au choix, demi-dons
• PV corrigés (Constitution, Nain des collines, don Robuste)
• Import XML : sous-race reconnue, bonus raciaux appliqués
</fr-FR>
```

### Ajouté
- Groupes : la fiche complète d'un autre membre s'ouvre en lecture seule en
  touchant sa carte (sa propre carte ouvre sa fiche modifiable). Nécessite la
  fonction Supabase `get_group_member_character` (migration
  `20260927100000_group_member_character_sheet.sql`, dépôt web) déployée.
- Butin du groupe : sélection multiple dans le catalogue d'objets, avec
  quantité par objet, puis « Ajouter (N) ».

### Modifié
- Groupes : le code d'invitation (onglet Membres et réglages) se copie d'un
  toucher, avec confirmation.
- Onglet Membres : le texte de confidentialité annonce que les membres
  voient la fiche complète des autres, en lecture seule.

### Corrigé
- Classe d'armure : la première armure et le premier bouclier de
  l'équipement de départ sont équipés à la création (sauf pour le Moine) —
  auparavant rien n'était équipé et la CA restait à 10 + Dex.
- Classe d'armure : prise en compte de la Défense sans armure du Barbare
  (10 + Dex + Con) et du Moine (10 + Dex + Sag, sans bouclier), de la
  Résilience draconique (13 + Dex) et du style de combat Défense (+1 en
  armure).
- Caractéristiques : les bonus raciaux au choix se répartissent à l'étape 4
  (Demi-elfe, Forgelier, et les 23 races à bonus flexibles +2/+1 ou
  +1/+1/+1 — Aasimar, Firbolg, Tabaxi, Conil...), qui n'en recevaient aucun.
- Points de vie : une Constitution augmentée à la montée de niveau ajoute
  ses PV rétroactivement ; bonus du Nain des collines (+1/niveau), du don
  Robuste (+2/niveau, rétroactif) et de la Résilience draconique (+1/niveau
  d'Ensorceleur).
- Équipement de départ : l'étape 7 propose l'équipement de classe (règles
  2024 : option A objets + or, option B or seul) en plus de celui de
  l'historique ; l'armure et le bouclier de classe sont équipés d'office et
  l'or de classe s'ajoute au budget d'achat.
- Demi-dons : le +1 à une caractéristique (Athlète, Observateur, Touché
  par les fées, faveurs épiques...) est appliqué à la montée de niveau, avec
  le choix de la caractéristique s'il y en a plusieurs ; don Tough
  (« Robuste physiquement ») et Faveur de robustesse (+40 PV) pris en compte.
- Classe d'armure : armures et boucliers magiques, Armure +N, anneau et
  cape de protection (harmonisés), bracelets de défense et robe de
  l'archimage ; ces objets magiques peuvent désormais être équipés.
- Import XML : la sous-race écrite dans la race (« Haut-elfe », « Nain des
  collines », « Elfe (haut-elfe) ») est reconnue et enregistrée ; les bonus
  raciaux sont ajoutés aux scores de base d'un export aidedd.org (bonus au
  choix à répartir sur l'écran de vérification) et les PV reçoivent leurs
  bonus. L'export XML écrit la sous-race et la sous-classe, et marque ses
  scores comme définitifs pour un réimport exact.

---

## [1.0.4] — 2026-09-26 (build 5)

### Notes de version (stores)

```
<fr-FR>
• Politique de confidentialité et mentions légales complétées dans l'app
• Suppression de l'identifiant publicitaire : l'app n'en utilise aucun
</fr-FR>
```

### Modifié
- Écran « Politique de confidentialité » aligné sur la page publique
  https://nexus-jdr.app/confidentialite (statistiques, notifications, dictée
  vocale, signalements de bug, sous-traitants, droits RGPD) ; éditeur
  renseigné dans les mentions légales.

### Supprimé
- Permissions `AD_ID` et `ACCESS_ADSERVICES_*` ajoutées par Firebase
  Analytics, et collecte de l'identifiant publicitaire désactivée.

---

## [1.0.3] — 2026-09-25 (build 4) — première version sur Google Play

### Notes de version (stores)

```
<fr-FR>
Première version de test : crée tes personnages de JDR 5e pas à pas, gère ta fiche complète (sorts, inventaire, montée de niveau), modifie-les à tout moment et joue avec ton groupe ou ton MJ.
</fr-FR>
```

### Modifié
- Nom de package Android : `com.nexus_jdr` (celui de la fiche Google Play),
  au lieu de `com.nexusjdr.personnages`. Une installation hors Play Store de
  l'ancienne version s'installe à côté comme une app distincte.

---

## [1.0.2] — 2026-09-25 (build 3) — non publiée sur les stores

Refusée par Google Play (ancien nom de package) ; son contenu est inclus
dans la 1.0.3.

### Ajouté
- « Modifier » (menu ⋮ de la fiche) : rouvre l'assistant de création
  pré-rempli ; classe modifiable au niveau 1 uniquement, caractéristiques en
  valeurs finales, équipement non modifié, PV recalculés.
- Clerc, Druide, Paladin : toute la liste de sorts de la classe disponible à
  la préparation ; Magicien : 2 sorts de grimoire par niveau ; sorts mineurs
  supplémentaires aux niveaux 4 et 10.
- Création : bouton ⓘ sur les choix (race, classe, historique, sous-classe,
  sorts), portrait, alignement, sexe/âge/taille/poids/yeux/peau/cheveux.
- Fiche : initiative, aide ⓘ, abréviations (FOR, DEX, CA, INIT., VIT.,
  INSP.), description des aptitudes de classe au toucher.
- Statistiques d'utilisation (Firebase Analytics, PostHog), désactivables
  dans Profil › Confidentialité et données.
- Nouvelle icône d'application ; nom affiché « Nexus JDR ».

### Corrigé
- Recadrage du portrait pendant la création : « Annuler » et retour ne
  fermaient pas l'écran.

---

## [1.0.1] — 2026-09-23 (build 2)

- Version technique (montée de version), non publiée sur les stores.

## [1.0.0] — 2026-09-23 (build 1)

- Première version : compte partagé avec l'app web « Histoires », assistant
  de création en 9 étapes, fiche personnage en 5 onglets, montée de niveau,
  import/export XML aidedd.org, rejoindre une histoire, groupes, profil,
  notifications. Non publiée sur les stores.
