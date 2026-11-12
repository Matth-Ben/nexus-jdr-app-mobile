# Fiche A — panneau des alertes de synchronisation (spec DA)

Décision de Matthias (12/11/2026) : **fiche A → un panneau** listant les alertes de synchronisation (conflit,
abandon). Défauts DA retenus : feuille modale basse ; liste plate (pas de regroupement) triée du plus récent au
plus ancien ; **pas de ✕ sur le bandeau** (seul le tap vers le panneau) ; pas de nettoyage automatique des
alertes orphelines ; la valeur locale d'un abandon n'est pas stockée (valeur serveur seulement) ; date du
premier conflit conservée (libellé « depuis ») ; les alertes du compte entier dans le panneau (pas de filtre par
personnage).

## 1. Le panneau — `showSyncAlertsSheet(BuildContext)` (`lib/core/widgets/sync_alerts_sheet.dart`)
- Feuille modale basse, `isScrollControlled`, fond `parchment.bg`, `SheetHeaderBar` « ALERTES DE SYNCHRO »,
  hauteur au contenu plafonnée à 85 % de l'écran, contenu défilant, fermeture par X / swipe / retour.
  Appelée depuis le bandeau (liste et fiche) et depuis le Profil. Fonctionne hors ligne (données locales).
- Contenu : texte d'introduction `font.body` 13 `text.secondary` (« Ces messages signalent des modifications faites
  hors ligne qui ont été écrasées ou abandonnées. »), bouton « TOUT ÉCARTER » (`DisplayText` palier control,
  ≥ 44, seulement si N ≥ 2), liste défilante de cartes ; pas de pied fixe.
- Carte (`parchment.card`, bordure 2 px `wood.light`, `radius.md`, `space.sm` entre cartes) : ligne 1 = icône
  (conflit : `Icons.sync_problem` ; abandon : `Icons.cancel_outlined`, `accent.brick`) + étiquette de type
  `font.body` 12 w700 (« Modification concurrente » / « Modification non envoyée ») + date relative à droite
  (formules de `lastSyncLabel`, helper partagé ; conflit : « depuis {when} ») ; ligne 2 = message complet
  `syncAlertMessage(l10n, alert, truncateName: false)` `font.body` 13 w600 `text.primary` (aucune troncature du nom
  dans le panneau) ; ligne 3 (orpheline seulement) ; pied : bouton texte « Écarter » à droite (≥ 44, `font.body`
  13 w700). La ligne 1 passe en `Wrap`/colonne à grande police. Jamais la couleur seule (icône + libellé).
- Tri : `createdAt` décroissant puis `id` décroissant, dans un provider du panneau (pas dans `watchForOwner`,
  utilisé par le moteur du bandeau).
- **Écarter** : suppression immédiate (`SyncAlertStore.dismiss`), sans confirmation, avec `showUndoSnackBar`
  (« Alerte écartée » + « Annuler ») ; annulation = ré-insertion avec le **même id et le même `createdAt`**
  (`SyncAlertStore.restore`; vérifier que la table drift est `AUTOINCREMENT` pour éviter la réutilisation d'id).
  **Tout écarter** : même patron, « N alertes écartées » + « Annuler » restaure toutes ; la feuille reste
  ouverte (état vide). Écarter ne touche jamais aux écritures en attente ni aux données du personnage.
- État vide : icône `check_circle_outline` 32 dp `accent.teal` décorative, « Aucune alerte de synchronisation. »
  (14 w600) + « Les conflits et les modifications non envoyées apparaîtront ici. » (12 `text.muted`), `liveRegion` ;
  erreur du flux : « Impossible d'afficher les alertes. » `accent.brick` + icône d'avertissement, sans Réessayer.
- Orpheline : `characterId` absent de `charactersProvider` **une fois la liste chargée** (jamais de faux positif
  pendant le chargement) : ligne 3 `font.body` 12 `text.muted` + `info_outline` : « Ce personnage n'est plus dans ta
  liste (supprimé ou devenu inaccessible). Cette alerte n'a plus d'objet. » ; nom vide → `syncAlertUnknownCharacter`.

## 2. Le bandeau (`sync_status_banner.dart`, `alert_banner.dart`, `sync_banner_engine.dart`)
- Cas `SyncBannerKind.alert` : libellé court « {N} alerte(s) de synchronisation » + ligne « Voir les alertes »
  (`font.body` 12 w700 `text.primary` souligné) + chevron ; **bandeau entier tappable** (≥ 44) qui ouvre la feuille ;
  **plus de ✕** ; plus de texte de la première alerte ni de « (+N autres) » (supprimer `syncAlertMoreSuffix` et, si
  le ✕ disparaît, `syncBannerDismissTooltip` des deux `.arb`). `AlertBanner` gagne un `onTap` optionnel
  rétrocompatible (les autres usages ne changent pas).
- `SyncBannerState` porte le total (`alertCount`) au lieu de `alert` + `moreAlerts` ; égalité sur le total ; retirer
  `_alertContent`. Précédence inchangée (alerte > synchro en cours > hors ligne > en attente > synchronisé).
  Sémantique : un nœud `Semantics(button, liveRegion)` « {N} alertes de synchronisation. Ouvrir la liste. » (texte
  visible exclu) ; la région live n'est déclenchée qu'à l'**apparition** du bandeau (pas à chaque changement de N).
- Hauteur : `_syncBandMaxHeightFraction` (`character_list_screen.dart:67`) abaissé à **0,2** ; critère
  d'acceptation : à ×2,0 sur 320×568, avec 3 alertes **et** le bandeau de mise à jour, la zone de défilement
  principale mesure **≥ 40 %** de la hauteur de l'écran au repos (cumul alerte + mise à jour plafonné à 30 %, défilement
  interne au-delà, sans retirer l'épinglage de la synchro ni le défilement de la mise à jour) ; à ×3,0 aucune cible
  coupée et la liste reste atteignable. Ceci règle D211.

## 3. Point d'entrée dans le Profil (`profile_screen.dart`)
Nouvelle ligne dans la liste de réglages (icône à gauche, libellé, chevron à droite, ligne entière ≥ 44) :
`Icons.sync` (ou `sync_problem` `accent.brick` si N ≥ 1), « Alertes de synchronisation », badge `accent.brick` avec
le chiffre (texte « {N} », jamais la couleur seule) si N ≥ 1, sinon sous-libellé « Aucune » `text.muted` ; tap =
`showSyncAlertsSheet`, actif hors ligne. La ligne « Dernière synchro » du pied de page reste un texte d'état inchangé.

## 4. Accessibilité
Cartes : `Semantics(container)` type + message complet + date ; bouton « Écarter » `Semantics(button,
label: "Écarter l'alerte : {nom}")` ; après écartement, focus sur la carte suivante ou le titre, puis état vide
annoncé ; cibles ≥ 44 partout ; titre en `DisplayText` palier title, « TOUT ÉCARTER » palier control, tout le reste en
`font.body` libre dans la zone défilante ; plancher 11 px (le plus petit texte est 12) ; contraste AA à vérifier :
`text.muted` sur `parchment.card` (12 px) et le blanc du badge sur `accent.brick` (4,5:1) ; ×2,0 et ×3,0 sur 320 dp sans
mot coupé lettre par lettre (cf. V5-2) ; aucun appel réseau dans le panneau.

## 5. Clés .arb (FR / EN, bloc contigu à la fin)
`syncAlertsSheetTitle` ALERTES DE SYNCHRO / SYNC ALERTS ; `syncAlertsSheetIntro` ; `syncAlertsDismissAll` TOUT
ÉCARTER / DISMISS ALL ; `syncAlertsDismiss` Écarter / Dismiss ; `syncAlertsDismissSemantics(name)` ;
`syncAlertsDismissedSnack` Alerte écartée / Alert dismissed ; `syncAlertsDismissedAllSnack(count)` (pluriel ICU) ;
`syncAlertsDismissedAnnouncement` Alerte écartée. Annuler disponible. / Alert dismissed. Undo available. ;
`syncAlertsEmptyTitle` ; `syncAlertsEmptyBody` ; `syncAlertsLoadError` ; `syncAlertsKindConflict` Modification
concurrente / Concurrent change ; `syncAlertsKindAbandon` Modification non envoyée / Change not sent ;
`syncAlertsSince(when)` ; `syncAlertsOrphan` ; `syncAlertsBannerCount(count)` (pluriel : « 1 alerte de
synchronisation » / « {count} alertes de synchronisation » ; EN « 1 sync alert » / « {count} sync alerts ») ;
`syncAlertsBannerAction` Voir les alertes / View alerts ; `syncAlertsBannerSemantics(count)` ;
`syncAlertsProfileRowLabel` Alertes de synchronisation / Sync alerts ; `syncAlertsProfileRowNone` Aucune / None ;
`syncAlertsProfileRowSemantics(count)`. Les messages d'alerte existants (`syncAlertConflictHp`…) sont inchangés.

## 6. Impacts techniques et tests
Créer `lib/core/widgets/sync_alerts_sheet.dart`, un provider de liste triée (+ ensemble des ids connus pour l'orphelin),
`SyncAlertStore.restore(SyncAlert)` et `dismissAll(ownerId)`. Modifier `sync_status_banner.dart`, `alert_banner.dart`,
`sync_banner_engine.dart` (tests du moteur et du bandeau à adapter), `character_list_screen.dart` (plafond),
`profile_screen.dart`. Aucune nouvelle table ni migration drift. Tests : bandeau ×2,0 sur 320×568 (liste ≥ 40 %),
panneau vide / 1 / N alertes, orpheline, « Écarter » + « Annuler », « Tout écarter » + « Annuler » (id et date
d'origine restaurés), sémantique, ×3,0, hors ligne, ligne du Profil.
Hors périmètre (à tracer en dette) : bandeau « 1 modification en attente d'envoi » persistant en ligne (écriture
orpheline, V5-8) ; valeur locale d'un abandon non stockée ; date du conflit mis à jour sur place.
