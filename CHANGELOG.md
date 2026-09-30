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

### Notes de version (stores)

```
<fr-FR>
Groupes :
• Touche le code d'invitation pour le copier
• Touche un membre pour voir sa fiche complète (en lecture seule)
• Butin : sélectionne plusieurs objets du catalogue d'un coup avant de les ajouter
Classe d'armure :
• Armure et bouclier de départ équipés automatiquement à la création
• Défense sans armure (Barbare, Moine), Résilience draconique et style Défense pris en compte
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
