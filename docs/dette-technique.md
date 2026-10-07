# Registre de dette technique

Registre produit par l'agent `dette-technique` le 07/10/2026, sur l'état de `main`
au commit `4d91a16`, puis mis à jour le même jour avec ce qui a été corrigé depuis.

## Comment lire ce registre

**Ce que l'audit a fait.** Lecture du code, `git`, une exécution de `flutter analyze`
(0 problème) et une de `flutter pub outdated`. Aucun test, aucun build, aucun appareil.
Les défauts décrits sont donc **déduits du code, pas reproduits**, sauf mention contraire
dans la colonne « État ».

**Preuve.** **L** = lu dans le code ; **C** = sorti d'une commande ; **R** = repris d'un
constat de session sans vérification par l'audit.

**État.** *Ouvert* ; *En cours* ; *Corrigé* (avec la PR) ; *Partiel* (une partie est
traitée, le reste est décrit).

**Mise à jour.** Quand une entrée est traitée, changer son état et citer la PR plutôt
que supprimer la ligne. Un nouvel audit ajoute ses entrées à la suite, avec sa date.

## Les trois catégories

La dette n'est pas traitée au fil de l'eau : elle est classée, et Matthias choisit.

### A. Bloque la mise en production

| ID | Sujet | Qui |
|---|---|---|
| D06 | Les trois environnements pointent sur le même projet Supabase | Matthias, puis `dev-backend-supabase` |
| D07 | Clé de signature Android déclarée compromise, rotation non faite | Matthias |
| D13 | Aucune remontée de plantage ; erreurs avalées | Décision d'outil, puis `dev-flutter` |
| D18 | Tests d'intégration absents de la chaîne d'intégration | `dev-backend-supabase`, `qa-testeur` |
| D19 | Publication Android sans analyse ni tests préalables | `dev-flutter` |

### B. Fait perdre des données ou donne une règle fausse au joueur

| ID | Sujet | État |
|---|---|---|
| D01 | Repos long d'un multiclassé : emplacements recalculés depuis la classe primaire | Corrigé (PR #78) |
| D02 | PV et XP modifiés hors ligne perdus à la réouverture de la fiche | En cours |
| D05 | Montée de niveau, création et repos non atomiques | Ouvert |
| D09 | Sorts innés supprimés lors d'un changement de classe en édition | Ouvert |
| D10 | Import XML : sorts tous « connus », doublons | Ouvert |
| D03 | Classes à sorts connus obligées de « préparer » | Ouvert, analyse faite |
| D08 | Sorts innés raciaux : emplacement exigé, pas de compteur | Ouvert, analyse faite |
| D14 | Emplacements jamais écrits à la création ni à l'import | Ouvert, à confirmer en base |
| D12 | Aucun délai d'attente réseau | Ouvert |
| D31 | Cache local jamais purgé à la déconnexion | Ouvert |

### C. Peut attendre

D04, D11, D15, D16, D17, D20 à D30, D32, et les constats de session listés plus bas.
D04 (règles indexées sur le nom français des classes) change de catégorie le jour où
la version anglaise démarre : elle devient alors bloquante.

## Registre complet

| ID | Titre | Zone | Gravité | Probabilité / échéance | Effort | Correction proposée | Agent | Preuve | État |
|---|---|---|---|---|---|---|---|---|---|
| D01 | Repos long multiclasse : emplacements recalculés depuis la classe primaire seule | `lib/features/characters/data/character_repository.dart` (`applyRest`, `_resetSpellSlots`) | critique | À chaque repos long d'un multiclassé lanceur | petit | `SpellSlotProgression.totalsForClasses` sur toutes les classes | dev-flutter, qa-testeur | L, puis confirmé par tests | Corrigé (PR #78). Tests d'intégration mis à jour mais jamais exécutés. |
| D02 | PV/XP en file hors ligne absents de la fiche relue depuis le cache | `character_repository.dart` (`fetchCharacterDetail`, ajustements PV/XP) ; `lib/core/cache/pending_character_write_queue.dart` ; `lib/features/characters/presentation/character_detail_screen.dart` | critique | Fiche fermée puis rouverte hors ligne, puis nouvel ajustement | moyen | Superposer les écritures en attente à la lecture, ou corriger le cache à la mise en file | dev-flutter, qa-testeur | L | En cours (branche `fix/offline-hp-xp-pending-writes`) |
| D06 | dev, staging et prod sur le même projet Supabase ; un seul projet Firebase | `config/*.json` (ignorés par Git) ; `config/README.md` ; `README.md` « Reste à faire » | haute | Déjà actif (test fermé Play) ; bloquant avant la production | moyen | Projets distincts ; Firebase et PostHog séparés par flavor | dev-backend-supabase | C + L | Ouvert |
| D07 | Keystore Android de production déclaré compromis, rotation non cochée | `README.md` « Reste à faire » ; `.github/workflows/release-android.yml` | haute | Avant la mise en production | petit | Réinitialiser la clé d'import dans la Play Console, mettre à jour les secrets | Matthias | L (état Play non vérifiable) | Ouvert |
| D03 | Les classes à sorts connus doivent « préparer » pour lancer | `lib/features/character_creation/domain/spellcasting_rules.dart` ; `lib/features/characters/domain/spell_status_formatter.dart` ; `character_repository.dart` (select de la fiche) | haute | Tout Barde, Ensorceleur, Occultiste ou Rôdeur | moyen | Dériver « ce sort se prépare-t-il ? » à la lecture, à partir des classes et de `source_class_id` (déjà écrit, jamais relu) ; pas de migration | dev-flutter | L | Ouvert. Analyse faite le 07/10 : faisable sans migration. |
| D04 | Règles de classe indexées sur le libellé français, dispersées dans 19 fichiers | Voir « Détails » | haute | À l'arrivée de l'anglais, ou à toute correction d'un nom de classe en base | gros | Clé stable de classe, registre unique des règles, `enum` pour le statut de sort | dev-flutter, dev-backend-supabase | L + C | Ouvert |
| D05 | Écritures multi-étapes non atomiques | `character_repository.dart` (`applyLevelUp`, `applyRest`) ; `lib/features/character_creation/data/character_creation_repository.dart` ; `lib/features/character_creation/data/character_edit_repository.dart` | haute | Réseau instable pendant une montée de niveau ou une création | gros | Fonctions Postgres transactionnelles (`apply_level_up`, `create_character`, `apply_rest`) | dev-backend-supabase, dev-flutter | L | Ouvert |
| D10 | Import XML : `connu` pour toutes les classes, doublons `inné`/`connu` | `lib/features/xml_import/domain/xml_import_save_data_resolver.dart` ; `lib/features/characters/data/character_spell_row_mapper.dart` ; `character_repository.dart` (`setSpellPrepared`) | haute | Tout import d'un Clerc, Druide, Magicien ou Paladin ; tout sort présent deux fois | moyen | Statut dérivé de la classe à l'import, dédoublonnage, contrainte unique `(character_id, spell_id)` avec migration de nettoyage | dev-flutter, dev-backend-supabase | L | Ouvert |
| D09 | Sorts innés supprimés lors d'un changement de classe en édition | `lib/features/character_creation/domain/character_edit_planner.dart` ; `lib/features/character_creation/domain/character_edit_snapshot.dart` | haute | Personnage doté d'un sort inné qui change de classe | petit | Exclure `inné` de `storedSpells`, ajouter un test | dev-flutter, qa-testeur | L | Ouvert |
| D08 | Sorts innés raciaux : emplacement exigé, pas de compteur d'usage | `lib/features/characters/domain/spell_cast_eligibility.dart` | haute | Toute race à sort inné de niveau 1 ou plus | moyen | Lancer sans emplacement, compteur « une fois par repos long » : colonne `innate_uses_spent` sur `character_spells` (migration côté web) | dev-backend-supabase, direction-artistique, dev-flutter | L | Ouvert. Analyse faite le 07/10 ; Matthias veut le compteur en même temps. |
| D18 | Tests d'intégration hors CI | `test_integration/README.md` ; `.github/workflows/ci.yml` | haute | À chaque migration côté web | moyen | Job CI avec un Supabase éphémère, au moins quotidien | dev-backend-supabase, qa-testeur | L | Ouvert |
| D12 | Aucun délai d'attente réseau ; « connecté » signifie seulement « interface active » | 0 occurrence de `.timeout(` pour 189 appels `.from(` ; `lib/core/network/connectivity_checker.dart` | haute | Wi-Fi sans débit ou signal faible ; durée d'attente réelle non mesurée | moyen | Délai sur le client HTTP ; traiter une expiration comme « hors ligne » pour PV/XP | dev-flutter | C + L | Ouvert |
| D13 | Erreurs avalées, aucune remontée de plantage | 194 `catch (_)` dans `lib/` ; aucun gestionnaire global | haute | Dès maintenant (testeurs Play) | moyen | Remontée de plantages, journalisation dans les `catch` des dépôts | décision d'outil, dev-flutter | C + L | Ouvert |
| D16 | Fichiers trop gros pour être modifiés sans risque | `character_repository.dart` (3933 lignes), `level_up_screen.dart` (3208), `character_detail_screen.dart` (2353), `xml_import_review_screen.dart` (2163), `character_creation_repository.dart` (1539) | haute | Toute évolution du hors ligne ou du multiclassage | gros | Scinder le dépôt par domaine ; factoriser le patron optimiste, recopié dans environ 21 méthodes | dev-flutter | C + L | Ouvert |
| D27 | Copie locale du cahier des charges périmée | `docs/cahier-des-charges/` (fichiers datés du 25/08) ; `CLAUDE.md` | haute (processus) | À chaque tâche qui « relit la spec » | petit | Resynchroniser depuis claude.ai, ajouter les documents 15 et 16 à `CLAUDE.md` | chef de projet | C + L | Ouvert |
| D14 | Emplacements de sorts jamais écrits à la création ni à l'import | `character_repository.dart` ; aucune écriture dans `character_creation_repository.dart` | non estimée | Si aucun déclencheur en base ne compense : un lanceur neuf reste à 0 emplacement jusqu'au premier repos long | petit | Initialiser à la création et à l'import | dev-flutter | L partiel | Ouvert, à confirmer en base |
| D11 | `WriteOutcome.queued` renvoyé par environ 25 méthodes qui ne mettent rien en file | `character_repository.dart` ; `character_detail_screen.dart` | moyenne | Chaque nouvel appelant | moyen | Troisième valeur `offlineRejected` | dev-flutter, décision produit | L | Ouvert |
| D32 | Synchronisation : déclencheurs incomplets, un type inconnu bloque toute la file | `character_write_sync_coordinator.dart` ; `pending_character_write_queue.dart` ; `pending_character_write_syncer.dart` | moyenne | Connexion après le démarrage ; ajout futur d'un type d'écriture | petit | Déclencher aussi à la connexion ; ignorer les lignes de type inconnu | dev-flutter | L | Ouvert |
| D15 | Chargement de la fiche : 26 requêtes en série, relancées après chaque écriture | `character_repository.dart` ; `character_detail_screen.dart` | moyenne | Réseau mobile lent ; latence non mesurée | moyen | Paralléliser, ou une vue ou fonction serveur | dev-flutter, dev-backend-supabase | C | Ouvert |
| D17 | 26 doubles de `CharacterRepository` dans les tests | 26 fichiers de `test/`, dont 5 avec `noSuchMethod` | moyenne | Chaque nouvelle méthode d'interface | moyen | Un double partagé dans `test/support/` | qa-testeur | C | Ouvert |
| D19 | CI et publication | `.github/workflows/ci.yml` ; `.github/workflows/release-android.yml` | moyenne | Prochaine montée de Flutter ou d'AGP ; prochaine version | moyen | Build APK debug en CI ; `analyze` et `test` avant la publication ; vraie comparaison du numéro de build | dev-flutter | L | Ouvert |
| D20 | Configuration native périssable | `android/app/build.gradle.kts` ; `android/gradle.properties` ; `android/settings.gradle.kts` ; `ios/Runner/Info.plist` | moyenne | Prochaine montée de Flutter ou d'AGP ; `targetSdk` 37 ; SDK iOS 27 | moyen | Voir « Détails » | dev-flutter | L, R pour les dépréciations | Partiel (PR #77) : verrou portrait posé, `targetSdk` figé à 36, test de garde. Reste le détail ci-dessous. |
| D22 | Polices téléchargées à l'exécution | `lib/core/theme/app_typography.dart` ; `pubspec.yaml` | moyenne | Premier lancement hors ligne ; mesures de test faussées | petit | Embarquer Press Start 2P et Work Sans, fixer `height` dans `display` | dev-flutter, direction-artistique | L | Ouvert |
| D23 | Accessibilité : libellés et rôles manquants | `lib/core/widgets/sheet_header_bar.dart` ; `lib/features/characters/presentation/character_list_screen.dart` | moyenne | Lecteur d'écran ; non testé avec TalkBack ni VoiceOver | moyen | `Semantics(button, label)` dans les widgets partagés, test de garde | dev-flutter, qa-testeur | C + L | Partiel (PR #75) : bouton de filtre corrigé. Restent la croix des sheets, les boutons Groupes et Profil, et 13 widgets partagés sur 15. |
| D24 | Texte agrandi : aucune règle, débordements signalés | Sheets et en-tête de liste | moyenne | Utilisateurs en grande police | moyen | Règle dans le design system, plafond partagé, matrice de test 320×568 | direction-artistique, dev-flutter, qa-testeur | R, puis mesuré par QA | Partiel (PR #73, #74) : deux plafonds à 2.0, en-tête des sheets. Reste : la règle du design system, cinq sheets qui débordent à 200 %. |
| D26 | Suite de tests : surface en paysage par défaut, attentes peu fiables | `test/flutter_test_config.dart` | moyenne | Tout test de mise en page | moyen | Surface portrait et polices réelles dans `flutter_test_config.dart` ; revue des `warnIfMissed: false` | qa-testeur | C | Partiel (PR #72) : trois tests à attente fixe rendus déterministes, trois masquages retirés. |
| D31 | Cache local jamais purgé | `lib/core/cache/reference_data_cache.dart` ; `lib/core/cache/app_database.dart` | moyenne | Appareil partagé, suppression de compte | petit | Purger à la déconnexion et à la suppression de compte | dev-flutter, décision produit | L | Ouvert |
| D25 | Sheets en `isScrollControlled` sans `useSafeArea` | 44 occurrences, 0 `useSafeArea`, 52 `showModalBottomSheet` | basse à moyenne | Effet visuel non vérifié | petit à moyen | Un helper `showAppSheet` dans `core/widgets` | dev-flutter | C | Ouvert |
| D21 | Dépendances | `pubspec.yaml` | basse | Prochaine montée de version | petit | Voir « Détails » | dev-flutter | C | Ouvert |
| D28 | Commentaires périmés | Voir « Détails » | basse | Induit en erreur le prochain agent | petit | Corriger ou supprimer | dev-flutter | L | Partiel (PR #78) : le commentaire faux d'`applyRest` et la doc de `rest_type.dart` sont corrigés. |
| D29 | Code mort | Voir « Détails » | basse | — | petit | Supprimer | dev-flutter | C + L | Ouvert |
| D30 | Jeton `AppBorders.cardEmphasisHalo` utilisé comme largeur générique | `lib/core/theme/app_spacing.dart` | basse | — | petit | Jeton `hairline` dédié | direction-artistique, dev-flutter | R | Ouvert |

## Détails

**D02.** Le cache de la fiche n'est écrit qu'après un succès réseau. `allForOwner` n'est
lu que par le synchroniseur. L'état optimiste (`_localHpState`) vit dans le widget et
disparaît à la fermeture de la fiche ; `characterDetailProvider` n'est pas `keepAlive`.

**D03.** Un Barde créé reçoit des sorts `connu`, et `canCast` refuse `connu`. Il peut tout
« préparer » sans limite (`PreparedSpellsLimit` renvoie `null` pour lui) : c'est une
friction et une règle fausse, pas un blocage.

**D04.**
- La liste des classes qui préparent existe en trois endroits :
  `lib/features/characters/domain/prepared_spells_limit.dart`,
  `spellcasting_rules.dart` et
  `lib/features/characters/domain/prepared_caster_spell_list.dart` (ce dernier omet
  volontairement le Magicien).
- La liste des lanceurs est elle aussi en trois endroits :
  `spellcasting_class_names.dart`, `spellcasting_rules.dart` et
  `lib/features/characters/domain/spell_slot_progression.dart`.
- La locale est figée : `const _locale = 'fr'` dans `character_repository.dart`.
- Les statuts `'connu'`, `'préparé'`, `'inné'` apparaissent en chaînes dans 15 fichiers.
- La raison donnée pour la duplication (« ne pas coupler `characters` à
  `character_creation` ») ne tient plus : `characters` importe déjà
  `character_creation` 33 fois.

**D05.** `applyLevelUp` enchaîne une dizaine d'écritures côté client ; une nouvelle
tentative après une coupure peut ajouter les PV une seconde fois. `createCharacter`
compte 13 appels avec un nettoyage au mieux. L'édition supprime puis réinsère les scores
de caractéristique.

**D06.** Vérifié sur la machine de développement en comparant les URL des trois fichiers
de configuration, sans afficher les valeurs : elles sont identiques.

**D10.** Les doublons sont volontaires à l'import, mais la lecture les fusionne par
`spell_id` (la dernière ligne gagne, ordre non garanti) et `setSpellPrepared` met à jour
toutes les lignes du sort. Sa séquence « mise à jour puis insertion si rien » peut aussi
créer un doublon sur deux appuis rapprochés.

**D11.** L'interface affiche bien un message honnête pour les écritures non persistées ;
le périmètre réduit de la file (PV et XP) est une décision déclarée. La dette est le nom
trompeur, que 24 sites d'appel doivent chacun interpréter correctement.

**D13.** Dans `fetchCharacterDetail`, le `catch` général sert le cache sur n'importe
quelle erreur, y compris une erreur de lecture des données après un changement de
schéma : le joueur voit une fiche périmée sans signal.

**D19.**
- La CI ne construit rien de natif ; aucune chaîne iOS.
- La publication ne lance ni `analyze` ni `test` avant le build.
- L'étape « Vérifie que le build number a bien été incrémenté » vérifie seulement qu'il
  est lisible.
- Aucun contrôle que le tag correspond à la version de `pubspec.yaml`.
- La version de Flutter est épinglée à la main dans deux workflows.
- Les actions tierces sont référencées par tag majeur dans le job qui manipule le
  keystore.

**D20, ce qui reste après la PR #77.**
- `UIRequiresFullScreen` est dépréciée depuis iPadOS 26 et peut être inopérante avec le
  SDK iOS 27 : le verrou iPad est à valider sur appareil dès le premier build iOS.
- La dérogation Android `PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY` cesse de
  s'appliquer à `targetSdk` 37 ; sur tablette et pliable déplié, l'écran partagé reste
  possible.
- `gradle.properties` demande `-Xmx8G` et 4 Go de métaspace ;
  `kotlin.incremental=false` est un contournement Windows appliqué partout.
- `android.newDsl=false` et `android.builtInKotlin=false` sont des dérogations
  temporaires d'AGP 9, à l'échéance à confirmer.
- Le plugin `google-services` est en 4.3.15 face à AGP 9.1.0.
- iOS n'a qu'un seul schéma, sans flavors, et n'a jamais été construit.

**D21.** Quatre dépendances ont une version majeure de retard : `connectivity_plus`
(6.1.5 → 7.3.2), `file_picker` (12.1.3 → 13.1.0), `google_fonts` (8.2.1 → 9.0.0) et
`cupertino_icons` (1.0.9 → 2.0.0). `cupertino_icons` n'est utilisée nulle part et peut
être retirée. La description de `pubspec.yaml` est encore celle du modèle.

**D23.** 45 fichiers contenant un `InkWell` ou un `GestureDetector` n'ont aucune
sémantique. 13 des 15 widgets interactifs de `lib/core/widgets/` sont dans ce cas, dont
`primary_button`, `secondary_button`, `menu_tile` et `segmented_tab_bar`. Leur texte est
probablement lu, mais le rôle « bouton » manque : supposition, non testée.

**D26.** 118 fichiers de tests de widgets, dont 24 seulement fixent une taille : les
autres tournent sur la surface par défaut de 800×600, en paysage, alors que l'app est en
portrait uniquement. La police de test est plus large que Work Sans, ce qui fausse les
mesures de débordement.

**D27.** Le code renvoie à `15-profil-parametres.md` et à `16-textes-a-rediger.md`,
absents de la copie locale. Les sections « Lancement — Splash », « État vide — Sorts » et
« Fiche — Sorts » manquent dans `09-maquettes-captures.md`, et la barre de tête de sheet
manque dans `10-design-system.md`. La copie de `02-modele-donnees.md` ignore au moins
`character_pact_slots`, `character_race_choices`, `character_photos`,
`character_journal_entries`, `lineage_id`, `is_dead`, `is_archived`, `inspiration`,
`share_token`, `is_favorite`, `weapon_slot`, `is_attuned`, `hit_dice_spent` et
`last_long_rest_at`.

**D28, ce qui reste.**
- `spellcasting_class_names.dart` : « la sous-classe n'est pas relue » (elle l'est), et
  la justification de la duplication est caduque.
- `reference_data_cache.dart` : « dizaines de lignes par catalogue », alors que le README
  annonce 477 sorts.
- `test_integration/README.md` : « aucune pipeline CI ».
- `rest_type.dart`, doc de `RestType.short` : affirme que la dépense de dés de vie n'est
  pas prise en charge, alors qu'`applyRest` la gère.

**D29.**
- `lib/features/characters/presentation/widgets/character_class_choices_card.dart` :
  123 lignes, aucune référence dans `lib/` ni dans `test/`.
- `lib/features/characters/domain/spell_slot_pips_formatter.dart` : utilisé par son seul
  test.
- `groupInvitePreviewProvider` : aucun consommateur.
- La recherche couvre les classes et les providers, pas les méthodes ni les paramètres.

## Constats de session, hors audit

Relevés par les agents de développement, de QA et de revue les 06 et 07/10/2026 en
travaillant sur autre chose. Aucun n'a été traité.

| Sujet | Détail | Source |
|---|---|---|
| Cinq sheets débordent à 200 % sur 320×568 | Changement de mot de passe, changement d'e-mail, export des données, préparation des sorts vide, choix d'emplacement d'arme. Antérieur ; aggravé de 14 à 45 px par la barre de tête plus haute. | Mesuré par QA |
| Croix de fermeture des sheets sans libellé | 31 usages de `SheetHeaderBar`. | Mesuré par QA |
| Boutons Groupes et Profil sans libellé | Même défaut que le bouton de filtre, corrigé lui. | Mesuré par QA |
| En-tête de la liste des personnages | Déborde de 25 px à l'échelle de texte 3, avec la police de test. | Mesuré par QA, à confirmer avec la vraie police |
| Deux demi-lanceurs cumulés | `combinedCasterLevel` additionne puis divise par 2 : Paladin 3 / Rôdeur 3 donne 3, une lecture par classe donnerait 2. Touche aussi la montée de niveau. Règle ambiguë : décision produit. | Lu par QA |
| Tiers-lanceurs non gérés | Chevalier occulte, Escroc arcanique. | Lu par QA |
| Dés de vie sur la seule classe primaire | Repos et export d'un multiclassé. Décision produit. | Lu par l'audit et par dev-flutter |
| Traduction de classe manquante | Classe traitée comme non lanceuse : un total d'emplacements peut baisser sans message au repos long. Rare. Un test « LIMITE CONNUE » épingle le cas. | Testé par QA |
| Paramètre `className` d'`applyRest` redondant | Deux sources pour le nom de la classe primaire. | Revue |
| Montage de test dupliqué | Écran de liste des personnages monté dans deux fichiers de test ; faux client Supabase recopié. | Revue |
| Plafond d'agrandissement en double | Deux constantes privées à 2.0 (`spell_info_panel.dart`, `sheet_header_bar.dart`), à réunir quand le design system aura une règle. | Revue |
| Hauteur de ligne héritée | Les titres en police d'affichage héritent du 1,43 de Material ; `AppTypography.display` ne fixe pas `height`. | Mesuré par dev-flutter |
| Sheet des autorisations et filtre d'inventaire | Quand leur contenu défile (texte agrandi sur petit écran), glisser vers le bas sur le contenu ne ferme plus la sheet. | Testé par QA en test de widgets |
| Splash sur Android 12 et plus | Le médaillon remonte d'environ 61,5 dp au passage du splash système au splash Flutter. Option : le remonter de 44 dp dans l'icône (saut de 17,5 dp). Décision en attente. | Calculé par QA et direction-artistique |
| Script du splash | Télécharge les polices hors dépôt ; repli macOS non testé. | Revue |
| Voile d'appui des boutons | Gris neutre, un peu froid pour la palette. | Direction artistique |

## Décisions en attente

1. Un Barde, Ensorceleur, Occultiste ou Rôdeur doit-il lancer ses sorts connus sans
   préparation ? **Oui, demandé par Matthias le 06/10.** (D03)
2. Les sorts innés raciaux se lancent-ils sans emplacement, avec un compteur par repos
   long ? **Oui, demandé par Matthias le 06/10 ; migration côté web nécessaire.** (D08)
3. Un multiclassé suit-il ses dés de vie par classe ?
4. La limite de sorts préparés doit-elle être bloquante, et non simplement affichée ?
   Aujourd'hui `setSpellPrepared` ne vérifie rien. (D03)
5. Étend-on la file hors ligne au lancer de sort, aux aptitudes et au repos avant la
   production ? (D11)
6. Crée-t-on des projets Supabase distincts pour staging et prod avant la production ?
   (D06)
7. La rotation de la clé d'import Play a-t-elle été faite ? (D07)
8. Accepte-t-on un outil de remontée de plantages, avec mise à jour de la politique de
   confidentialité ? (D13)
9. Fixe-t-on un plafond global d'agrandissement du texte dans le design system ? (D24)
10. Embarque-t-on les deux polices dans l'application ? (D22)
11. Purge-t-on les fiches en cache à la déconnexion et à la suppression de compte ?
    (D31)
12. Passe-t-on les règles de classe sur une clé stable avant la version anglaise ? (D04)
13. Deux demi-lanceurs cumulés : addition puis division, ou moitié par classe ?

## Ce que l'audit n'a pas couvert

- **Comportement réel.** Aucun test ni build lancé pendant l'audit. D02, D09 et D10 sont
  déduits du code et jamais reproduits.
- **Base réelle et dépôt web.** La copie locale du dépôt web s'arrêtait au 25/08
  (19 migrations). Contraintes, déclencheurs (D14), RLS et fonctions edge non vérifiés.
- **Natif.** Aucun build Android ni iOS, aucun appareil, aucun lecteur d'écran.
- **Play Console et secrets GitHub** (D07) : non accessibles.
- **Code mort** : méthodes, paramètres et branches inatteignables non couverts.
- **Qualité des assertions** des 301 fichiers de test : contrôle automatique seulement.
- **Cahier des charges à jour** (claude.ai) : non accessible ; la cohérence entre le
  modèle de données et le code n'a pas pu être vérifiée sérieusement.
