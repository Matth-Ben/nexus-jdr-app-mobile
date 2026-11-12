# P3b — rituels, chronos de sorts et échelle de temps (spec consolidée)

Décisions de Matthias (12/11/2026), qui rouvrent P3b (abandonné le même jour avant la demande détaillée) :
- Un **détail « Rituel »** sur les sorts rituels et une action **« Lancer en rituel »** avec un chrono ; à la fin,
  une notification dit que le rituel est lancé. Rituel = **temps réel strict** (incantation normale + 10 min).
- Un **chrono de durée** pour les sorts à durée : à la fin, une notification dit que le sort prend fin.
  Échelle de jeu : **1 min de jeu = 6 min réelles par défaut**, réglable dans le profil sur **1, 3, 6 ou 10** min
  réelles par minute de jeu (réglage par appareil, local).
- **Timer invisible** (aucune durée restante ni heure de fin à l'écran) ; seule la fin normale notifie.
- **Arrêts silencieux** (aucune notification) : repos court, repos long, 20 min **sans interaction avec l'app ouverte**,
  fin ou remplacement de la concentration, annulation manuelle.
- **Concentration liée** : le chrono d'un sort à concentration s'arrête quand la concentration prend fin ou est remplacée.
- Combat : une **ligne fixe** dans la confirmation du rituel (pas de notion de combat dans l'app).
- Permission de notifications refusée : le rituel propose « Lancer quand même » (sans chrono) ; un sort chronométré se
  lance sans chrono et un message le dit. La permission est demandée au premier lancement, par un clic explicite.
- Listes de sorts : PHB 2014 + Xanathar + Tasha, sans les ajouts 2024 ; les 6 sorts exclusivement 2024 sont conservés
  (PR dépôt web, voir ci-dessous).

## Données (dépôt web, appliquées par Matthias)
- Migrations : liens classe↔sort corrigés (rejeu de la source filtrée sur `meta.class` + XGE/TCE), 9 sorts innés raciaux
  reliés, colonnes de durée structurées `duration_kind` (`instant|timed|until_dispelled|special`), `duration_value`,
  `duration_unit` (`round|minute|hour|day|week|year`), durées fausses du socle corrigées.
- `spells.ritual` est déjà correct (33 rituels) ; l'app doit le charger (`CharacterSpellEntry.ritual`).

## Règles de jeu (regles-dnd, 2014)
- Un rituel ne consomme aucun emplacement, ne se lance pas à un niveau supérieur, garde composantes/durée/concentration ;
  incantation = temps normal + 10 min.
- Éligibilité par classe : Magicien (tout sort connu, même non préparé) ; Clerc, Druide, Artificier (sort préparé ou
  toujours préparé) ; Barde (sort connu) ; Occultiste (sort connu, Pacte du Livre) ; Ensorceleur, Paladin, Rôdeur, Barbare,
  Moine, Guerrier, Roublard (dont leurs sous-classes) : non. Le multiclassage se juge par classe (`sourceClassIds`).
  Dons « Rituels magiques », Livre des ombres : hors périmètre (tracé en dette). Spell Mastery n'a aucun rapport.
- Durée du chrono d'un rituel : 10 min si l'incantation est « 1 action/bonus/réaction » ; sinon incantation parsable
  (minutes/heures) + 10 min ; non parsable → 10 min et avertissement. L'échelle de jeu ne s'applique jamais à un rituel.
- Chrono de durée : sorts à durée en rounds/minutes jusqu'à 10 min de jeu inclus ; durée réelle = durée de jeu × échelle
  (round = 6 s de jeu, donc 36 s à ×6). Pas de chrono pour instantané / jusqu'à dissipation / spécial / > 10 min de jeu.

## UI (direction-artistique)
- **Marqueur** : pastille « R » (`Icons.auto_stories`, tokens de `_RowBadge`) à côté de « C » sur la ligne de sort ; ligne
  « Rituel : Oui · +10 min d'incantation » dans le panneau Infos ; visible aussi en lecture seule.
- **Action** : `SecondaryButton` « Lancer en rituel » dans le pied du panneau Infos (sous « Lancer »), absente en lecture
  seule, désactivée avec motif si non éligible ; pied borné à 45 % de l'écran et défilant ; confirmation obligatoire
  (durée, « aucun emplacement consommé », « pas de minuteur affiché », ligne combat, avertissement permission).
- **Retour sans timer** : snackbar « Rituel en cours : {sort}. Tu seras notifié à la fin. » + « Annuler le rituel » ;
  état statique « Rituel en cours » + lien d'annulation dans le panneau du sort ; sorts chronométrés : ligne
  supplémentaire dans le snackbar de lancer (« Rappel de fin de sort dans environ N min ») et « Arrêter le rappel ».
  Annuler le lancer (P9) annule aussi le chrono.
- **Concentration** : nouvel état « concentration active » (personnage, sort), pastille C « active » (fond plein, texte
  + icône, jamais la couleur seule), bannière + bouton « Arrêter la concentration », remplacement RAW avec message
  « Concentration sur {ancien} interrompue ». Fin forcée (étourdissement, 0 PV) hors périmètre.
- **Profil** : ligne « Échelle de temps des sorts » (sous-écran `/profile/spell-time-scale`, 4 `SelectableOptionTile`,
  défaut 6, exemple d'aide qui se met à jour), sauvegarde immédiate, local à l'appareil.
- **Notification locale** : canal Android `spell_timers`, « Sort {sort} terminé » / « Rituel {sort} lancé » + nom du
  personnage, tap → fiche du personnage, onglet Sorts ; au premier plan, snackbar global `liveRegion` à la place ;
  les chronos survivent à un redémarrage (purge des expirés et des personnages supprimés).
- **A11y** : grande police ×2,0/×3,0 sur 320 dp, cibles ≥ 44, textes ≥ 11 px, aucune animation nouvelle.
- Ligne supplémentaire dans le snackbar de repos (« Rappels de sorts arrêtés. ») si au moins un chrono était actif.

## Critères de test (horloge injectée, aucun test en temps réel)
Durée de rituel (1 action → 10, « 1 minute » → 11, « 10 minutes » → 20, « 1 heure » → 70, inconnu → 10 + avertissement) ;
éligibilité une assertion par classe et multiclassage ; éligibilité du chrono et calcul aux 4 échelles ; panneau (lecture
seule, désactivé avec motif, confirmation avant démarrage, aucun emplacement consommé) ; invisibilité du timer (aucun
texte de durée restante) ; arrêts silencieux (notification annulée, rien émis) ; fin normale (titre/corps/payload FR et
EN, snackbar au premier plan) ; profil (défaut 6, persistance, changement sans effet sur un chrono en cours) ; matrice
a11y 320 dp × 1,0/2,0/3,0 ; hors ligne ; redémarrage.

## Phasage
1. Web : migrations listes/innés/durées (PR dépôt web, Matthias applique).
2. App A : chargement `ritual` + durées structurées, marqueur « R », éligibilité rituel (domaine + panneau).
3. App B : socle des chronos (planification locale, plugin de notifications, store persistant, échelle dans le profil,
   inactivité, arrêt au repos).
4. App C : « Lancer en rituel » + chrono de durée + état de concentration liée.
Chaque PR suit dev-flutter → regles-dnd (RAW) → qa → code-reviewer.
