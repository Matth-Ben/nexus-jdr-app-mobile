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

### B. Fait perdre des données ou donne une règle fausse au joueur

| ID | Sujet | État |
|---|---|---|
| D01 | Repos long d'un multiclassé : emplacements recalculés depuis la classe primaire | Corrigé (PR #78) |
| D02 | PV et XP modifiés hors ligne perdus à la réouverture de la fiche | Corrigé (PR #80) |
| D33 | Deux envois simultanés du même type (synchronisation et ajustement en ligne) arrivant dans le désordre | Corrigé (PR #86) |
| D34 | Écriture en attente refusée indéfiniment : reste affichée, jamais retentée ni signalée | Corrigé (PR #86) |
| D35 | Repos ou montée de niveau en ligne avec des PV encore en attente | Corrigé (PR #93) |
| D05 | Montée de niveau, création et repos non atomiques | Corrigé (PR #20, #22, #23, dépôt web) : les 3 fonctions livrées ; branchement côté mobile reste à faire |
| D09 | Sorts innés supprimés lors d'un changement de classe en édition | Corrigé (PR #83) |
| D10 | Import XML : sorts tous « connus », doublons | Partiel (PR #84, #24 dépôt web, #96) : reste la migration de nettoyage des vrais doublons de production avant de pouvoir appliquer la contrainte |
| D03 | Classes à sorts connus obligées de « préparer » | Corrigé (PR #81) |
| D38 | Sort inné transformable en sort « préparé » depuis la sheet de préparation | Corrigé (PR #81) ; lignes déjà abîmées non réparables |
| D08 | Sorts innés raciaux : emplacement exigé, pas de compteur | Corrigé (PR #82, migration web PR #19) |
| D14 | Emplacements jamais écrits à la création ni à l'import | Ouvert, confirmé en base le 08/10 : aucun déclencheur |
| D12 | Aucun délai d'attente réseau | Ouvert |
| D31 | Cache local jamais purgé à la déconnexion | Ouvert |
| D71 | `character_pact_slots` (magie de pacte Occultiste) jamais initialisée à la création ni à l'import, même trou que D14 | Ouvert |

### C. Peut attendre

D04, D11, D13 (reste), D15, D16, D17, D20 à D30, D32, D61, D62, D63, D73, et les constats de
session listés plus bas.
D04 (règles indexées sur le nom français des classes) change de catégorie le jour où
la version anglaise démarre : elle devient alors bloquante.

## Registre complet

| ID | Titre | Zone | Gravité | Probabilité / échéance | Effort | Correction proposée | Agent | Preuve | État |
|---|---|---|---|---|---|---|---|---|---|
| D01 | Repos long multiclasse : emplacements recalculés depuis la classe primaire seule | `lib/features/characters/data/character_repository.dart` (`applyRest`, `_resetSpellSlots`) | critique | À chaque repos long d'un multiclassé lanceur | petit | `SpellSlotProgression.totalsForClasses` sur toutes les classes | dev-flutter, qa-testeur | L, puis confirmé par tests | Corrigé (PR #78). Tests d'intégration mis à jour mais jamais exécutés. |
| D02 | PV/XP en file hors ligne absents de la fiche relue depuis le cache | `character_repository.dart` (`fetchCharacterDetail`, ajustements PV/XP) ; `lib/core/cache/pending_character_write_queue.dart` ; `lib/features/characters/presentation/character_detail_screen.dart` | critique | Fiche fermée puis rouverte hors ligne, puis nouvel ajustement | moyen | Superposer les écritures en attente à la lecture, ou corriger le cache à la mise en file | dev-flutter, qa-testeur | L, puis confirmé par tests | Corrigé (PR #80). Défaut plus large que décrit : six chemins de perte traités. Jamais essayé avec une vraie coupure réseau ni sur appareil. |
| D33 | Deux PATCH du même type en vol, l'un du synchroniseur et l'autre du dépôt, peuvent arriver au serveur dans le désordre | `lib/features/characters/data/pending_character_write_syncer.dart` ; `character_repository.dart` (`updateHp`, `addXp`) | haute | Réseau lent, joueur qui ajuste pendant la synchronisation | moyen | Verrou par `(personnage, type)` partagé entre le synchroniseur et le dépôt | dev-flutter, qa-testeur | L (revue) | Corrigé (PR #86). `PendingCharacterWriteQueue.runExclusive` sérialise par `(characterId, kind)`, confirmé par un test de concurrence réelle avec portillon serveur. |
| D34 | Entrée de file refusée indéfiniment par le serveur : superposée à la fiche sans message, jamais abandonnée | `pending_character_write_syncer.dart` ; `character_write_sync_coordinator.dart` | haute | Contrainte en base, RLS, personnage modifié ailleurs | moyen | Compteur d'échecs, abandon ou signalement après un refus non rejouable ; nouvelle tentative périodique (voir D32) | dev-flutter, décision produit | L (QA, revue) | Corrigé (PR #86). Seuil de 5 échecs non rejouables (SQLSTATE `23xxx`/`22xxx`/`42501`) consécutifs, signalement par SnackBar (même mécanisme que les push), jamais réaffiché. Suites : D61, D62. |
| D35 | Repos ou montée de niveau en ligne avec des PV en file : l'opération part de la valeur serveur, puis la synchronisation réécrit l'ancienne | `character_repository.dart` (`applyRest`, `applyLevelUp`) | moyenne | Repos ou montée de niveau peu après un retour du réseau | moyen | Synchroniser la file avant ces opérations ; la bonne réponse diffère entre repos long, repos court et montée de niveau | décision de conception, puis dev-flutter | L (dev-flutter, QA) | Corrigé (PR #93). Décision validée par Matthias : synchronise la file PV/XP avant `applyRest`/`applyLevelUp`, bloque avec une erreur explicite si des entrées restent en attente. Affiné en revue pour ne bloquer que quand l'opération touche vraiment les PV (`type == RestType.long \|\| appliedGain > 0` pour `applyRest` — un repos court qui ne restaure aucun PV, ex. déjà au maximum, n'écrit jamais `characters` et n'a pas besoin d'être bloqué) ; `applyLevelUp` reste inconditionnel (`hpGain` toujours appliqué). |
| D36 | `queuedAt` sert de numéro de version de l'entrée de file ; clé primaire de la file sans `ownerId` | `lib/core/cache/app_database.dart` ; `lib/core/cache/pending_character_write_queue.dart` | basse | Le jour où une migration du schéma local est de toute façon nécessaire | moyen | Colonne `version` dédiée et `ownerId` dans la clé primaire, avec migration drift testée | dev-flutter | L (revue) | Ouvert, astuce documentée sur la colonne |
| D37 | Le cache de la fiche n'est mis à jour après confirmation que pour les PV et l'XP | `lib/features/characters/data/character_detail_cache.dart` | moyenne | Repos, montée de niveau ou inventaire en ligne suivis d'une relecture en échec, puis fiche rouverte hors ligne | moyen | Étendre le report aux autres écritures, ou relire après écriture avec repli | dev-flutter | L (dev-flutter) | Ouvert |
| D06 | dev, staging et prod sur le même projet Supabase ; un seul projet Firebase | `config/*.json` (ignorés par Git) ; `config/README.md` ; `README.md` « Reste à faire » | haute | Déjà actif (test fermé Play) ; bloquant avant la production | moyen | Projets distincts ; Firebase et PostHog séparés par flavor | dev-backend-supabase | C + L | Ouvert |
| D07 | Keystore Android de production déclaré compromis, rotation non cochée | `README.md` « Reste à faire » ; `.github/workflows/release-android.yml` | haute | Avant la mise en production | petit | Réinitialiser la clé d'import dans la Play Console, mettre à jour les secrets | Matthias | L (état Play non vérifiable) | Ouvert |
| D03 | Les classes à sorts connus doivent « préparer » pour lancer | `lib/features/character_creation/domain/spellcasting_rules.dart` ; `lib/features/characters/domain/spell_status_formatter.dart` ; `character_repository.dart` (select de la fiche) | haute | Tout Barde, Ensorceleur, Occultiste ou Rôdeur | moyen | Dériver « ce sort se prépare-t-il ? » à la lecture, à partir des classes et de `source_class_id` (déjà écrit, jamais relu) ; pas de migration | dev-flutter | L | Ouvert. Analyse faite le 07/10 : faisable sans migration. |
| D04 | Règles de classe indexées sur le libellé français, dispersées dans 19 fichiers | Voir « Détails » | haute | À l'arrivée de l'anglais, ou à toute correction d'un nom de classe en base | gros | Clé stable de classe, registre unique des règles, `enum` pour le statut de sort | dev-flutter, dev-backend-supabase | L + C | Ouvert |
| D05 | Écritures multi-étapes non atomiques | `character_repository.dart` (`applyLevelUp`, `applyRest`) ; `lib/features/character_creation/data/character_creation_repository.dart` ; `lib/features/character_creation/data/character_edit_repository.dart` | haute | Réseau instable pendant une montée de niveau ou une création | gros | Fonctions Postgres transactionnelles (`apply_level_up`, `create_character`, `apply_rest`) | dev-backend-supabase, dev-flutter | L | Corrigé (PR #20, #22, #23, dépôt web). Les 3 fonctions `SECURITY DEFINER` transactionnelles livrées et relues, chacune validée par sa propre suite pgTAP exécutée en réel (privilèges, atomicité sur échec forcé après écriture réelle, entrée malformée — 9, 16 puis 50 tests). `apply_level_up`, jugée au départ trop risquée pour la même PR qu'`apply_rest`, a finalement été livrée en entier sans scission : le risque redouté (comparaison de nom de sous-classe pour les PV) était déjà résolu côté client (`p_hp_gain` déjà sommé avant l'appel). Les 3 fonctions restent non idempotentes (documenté dans leur commentaire SQL, pas résolu) : un retry après succès serveur perdu rejouerait l'écriture. **Reste à faire, hors périmètre de D05** : brancher le client Flutter sur ces 3 RPC (actuellement aucune des trois n'est appelée depuis le mobile — tâche `dev-flutter` séparée). |
| D10 | Import XML : `connu` pour toutes les classes, doublons `inné`/`connu` | `lib/features/xml_import/domain/xml_import_save_data_resolver.dart` ; `lib/features/characters/data/character_spell_row_mapper.dart` ; `character_repository.dart` (`setSpellPrepared`) | haute | Tout import d'un Clerc, Druide, Magicien ou Paladin ; tout sort présent deux fois | moyen | Statut dérivé de la classe à l'import, dédoublonnage, contrainte unique `(character_id, spell_id)` avec migration de nettoyage | dev-flutter, dev-backend-supabase | L, puis vérifié contre les fixtures XML réelles et confirmé par tests | Partiel (PR #84, #24 dépôt web, #96). Deux index uniques partiels posés sur `character_spells` (au plus une ligne `'inné'`, au plus une ligne ordinaire par sort — autorise la coexistence légitime D43), avec détection/échec bruyant des doublons existants plutôt que suppression automatique (vraie donnée de testeurs). Correctif urgent appliqué en parallèle côté client (PR #96) : `applyLevelUp` insérait les sorts initiaux sans vérifier qu'ils n'étaient pas déjà connus (même trou que celui qui existait côté SQL dans `apply_level_up`, corrigé dans la même série) — sans ce correctif, un multiclassage avec recoupement de sorts aurait cassé dès que la contrainte serait posée en base de production. **Reste ouvert avant de pouvoir appliquer la contrainte en production** : nettoyer manuellement les vrais doublons de données de testeurs détectés par la migration (si elle en trouve), aucune suppression automatique prévue. |
| D09 | Sorts innés supprimés lors d'un changement de classe en édition | `lib/features/character_creation/domain/character_edit_planner.dart` ; `lib/features/character_creation/domain/character_edit_snapshot.dart` | haute | Personnage doté d'un sort inné qui change de classe | petit | Exclure `inné` de `storedSpells`, ajouter un test | dev-flutter, qa-testeur | L, puis confirmé par tests (mutation manuelle : retirer le filtre fait échouer 4 tests) | Corrigé (PR #83). Suites : D53 à D56. |
| D08 | Sorts innés raciaux : emplacement exigé, pas de compteur d'usage | `lib/features/characters/domain/spell_cast_eligibility.dart` | haute | Toute race à sort inné de niveau 1 ou plus | moyen | Lancer sans emplacement, compteur « une fois par repos long » : colonne `innate_uses_spent` sur `character_spells` (migration côté web) | dev-backend-supabase, direction-artistique, dev-flutter | L | Corrigé (PR #82 ; colonne et RPC de partage : dépôt web, PR #19). Suites : D43 à D52. |
| D18 | Tests d'intégration hors CI | `test_integration/README.md` ; `.github/workflows/ci.yml` | haute | À chaque migration côté web | moyen | Job CI avec un Supabase éphémère, au moins quotidien | dev-backend-supabase, qa-testeur | L | Corrigé (PR #89). `.github/workflows/integration-tests.yml`, schedule quotidien + `workflow_dispatch`, checkout croisé du dépôt web. Dépend de la PR #21 (dépôt web, D58) pour que `db reset` réussisse — premier run réel à confirmer une fois cette PR fusionnée. |
| D12 | Aucun délai d'attente réseau ; « connecté » signifie seulement « interface active » | 0 occurrence de `.timeout(` pour 189 appels `.from(` ; `lib/core/network/connectivity_checker.dart` | haute | Wi-Fi sans débit ou signal faible ; durée d'attente réelle non mesurée | moyen | Délai sur le client HTTP ; traiter une expiration comme « hors ligne » pour PV/XP | dev-flutter | C + L | Ouvert |
| D13 | Erreurs avalées, aucune remontée de plantage | 194 `catch (_)` dans `lib/` ; aucun gestionnaire global | haute | Dès maintenant (testeurs Play) | moyen | Remontée de plantages, journalisation dans les `catch` des dépôts | décision d'outil, dev-flutter | C + L | Partiel (PR #91). Firebase Crashlytics choisi par Matthias, câblé : `FlutterError.onError`/`PlatformDispatcher.instance.onError` couvrent désormais TOUTE erreur fatale non interceptée (le vrai risque de catégorie A), validé par un build APK réel. 14 `catch` génériques instrumentés sur les écritures multi-tables à risque d'orphelin silencieux (sur ~202 au total). Les ~188 restants (lectures, replis hors ligne intentionnels, écritures mono-table déjà mappées vers une erreur visible côté UI) ne sont pas couverts — hors catégorie A désormais, passé en catégorie C pour la couverture non exhaustive restante. |
| D16 | Fichiers trop gros pour être modifiés sans risque | `character_repository.dart` (3933 lignes), `level_up_screen.dart` (3208), `character_detail_screen.dart` (2353), `xml_import_review_screen.dart` (2163), `character_creation_repository.dart` (1539) | haute | Toute évolution du hors ligne ou du multiclassage | gros | Scinder le dépôt par domaine ; factoriser le patron optimiste, recopié dans environ 21 méthodes | dev-flutter | C + L | Ouvert |
| D27 | Copie locale du cahier des charges périmée | `docs/cahier-des-charges/` (fichiers datés du 25/08) ; `CLAUDE.md` | haute (processus) | À chaque tâche qui « relit la spec » | petit | Resynchroniser depuis claude.ai, ajouter les documents 15 et 16 à `CLAUDE.md` | chef de projet | C + L | Ouvert |
| D14 | Emplacements de sorts jamais écrits à la création ni à l'import | `character_repository.dart` ; aucune écriture dans `character_creation_repository.dart` | non estimée | Si aucun déclencheur en base ne compense : un lanceur neuf reste à 0 emplacement jusqu'au premier repos long | petit | Initialiser à la création et à l'import | dev-flutter | L partiel | Ouvert, à confirmer en base |
| D71 | `character_pact_slots` (magie de pacte Occultiste) jamais initialisée à la création ni à l'import — même trou que D14, mais plus grave : la première charge de pacte est disponible dès le niveau 1, donc un Occultiste neuf ne peut lancer aucun sort avant son premier repos court | `character_repository.dart` (`_upsertPactSlot`/`_resetPactSlot`) ; aucune écriture équivalente dans `character_creation_repository.dart`/`xml_import_repository.dart` | moyenne | Tout Occultiste créé ou importé | petit | Même patron que D14 (`SpellSlotProgression`/table de magie de pacte) à l'initialisation | dev-flutter | L (relevé par qa-testeur en validant D14) | Ouvert |
| D11 | `WriteOutcome.queued` renvoyé par environ 25 méthodes qui ne mettent rien en file | `character_repository.dart` ; `character_detail_screen.dart` | moyenne | Chaque nouvel appelant | moyen | Troisième valeur `offlineRejected` | dev-flutter, décision produit | L | Ouvert |
| D32 | Synchronisation : déclencheurs incomplets, un type inconnu bloque toute la file | `character_write_sync_coordinator.dart` ; `pending_character_write_queue.dart` ; `pending_character_write_syncer.dart` | moyenne | Connexion après le démarrage ; ajout futur d'un type d'écriture | petit | Déclencher aussi à la connexion ; ignorer les lignes de type inconnu | dev-flutter | L | Ouvert |
| D15 | Chargement de la fiche : 26 requêtes en série, relancées après chaque écriture | `character_repository.dart` ; `character_detail_screen.dart` | moyenne | Réseau mobile lent ; latence non mesurée | moyen | Paralléliser, ou une vue ou fonction serveur | dev-flutter, dev-backend-supabase | C | Ouvert |
| D17 | 26 doubles de `CharacterRepository` dans les tests | 26 fichiers de `test/`, dont 5 avec `noSuchMethod` | moyenne | Chaque nouvelle méthode d'interface | moyen | Un double partagé dans `test/support/` | qa-testeur | C | Ouvert |
| D19 | CI et publication | `.github/workflows/ci.yml` ; `.github/workflows/release-android.yml` | moyenne | Prochaine montée de Flutter ou d'AGP ; prochaine version | moyen | Build APK debug en CI ; `analyze` et `test` avant la publication ; vraie comparaison du numéro de build | dev-flutter | L, puis confirmé par reproduction d'une régression simulée | Corrigé (PR #88). Les 3 correctifs livrés ; `qa-testeur` a trouvé un vrai bug dans la première version de la comparaison de build number (un tag `v*` mal formé pouvait se classer "plus haut" par le tri sémantique de Git et masquer une régression), corrigé par un filtrage strict `^v[0-9]+\.[0-9]+\.[0-9]+$` avant le tri. Suite : D64, D65. |
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

**Note (PR #20, dépôt web) :** `create_character` (fonction Postgres transactionnelle,
`SECURITY DEFINER`) couvre l'atomicité de l'échec partiel, mais reste **non idempotente** :
un retry client après un succès serveur dont la réponse HTTP est perdue créerait un
personnage dupliqué — limite déjà présente dans le code séquentiel actuel, pas une
régression introduite par cette PR, à garder en tête par `dev-flutter` lors du
branchement.

**D06.** Vérifié sur la machine de développement en comparant les URL des trois fichiers
de configuration, sans afficher les valeurs : elles sont identiques.

**D10.** Les doublons sont volontaires à l'import. **Mise à jour du 09/10/2026 (PR #84),
corrige une affirmation fausse de l'audit du 07/10** : la fusion à la lecture par
`spell_id` est déterministe depuis la PR #82 pour le cas inné/ordinaire (« ordinaire bat
inné », déjà en place avant même cet audit), et l'est maintenant aussi pour deux lignes
ordinaires en double (`'connu'`/`'préparé'`) via un rang de priorité fixe
(`'préparé' > 'connu' > 'inné'`) — ce n'est plus « la dernière ligne gagne, ordre non
garanti ». `setSpellPrepared` exclut déjà les lignes `'inné'` (`.neq('status', 'inné')`)
et ne met donc à jour que les lignes ordinaires — l'affirmation « met à jour toutes les
lignes du sort » reste vraie pour CES lignes-là uniquement, pas un problème pour le cas
inné/ordinaire. Reste vrai et non corrigé : sa séquence « mise à jour puis insertion si
rien » peut toujours créer un doublon sur deux appuis rapprochés (D42).

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
- Le plugin `google-services` est en 4.4.4 (relevé depuis 4.3.15 pour le plugin
  Crashlytics, D13) face à AGP 9.1.0.
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

## Ajouts du 08/10/2026 (correctif des classes à sorts connus, PR #81)

Vérifié dans le schéma réel de la base ce jour-là : `character_spells.source_class_id`
existe ; aucune contrainte unique sur `(character_id, spell_id)` ; aucun déclencheur sur
`characters`, `character_spells`, `character_spell_slots` ni `character_classes` ; aucune
contrainte `CHECK` sur les PV ; `racial_innate_spells` n'a aucune notion de fréquence
d'usage ; treize classes, toutes nommées en français comme l'app l'attend.

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D03 | Classes à sorts connus obligées de « préparer » | haute | — | Corrigé (PR #81), règle dérivée à la lecture, sans migration |
| D38 | Sort inné transformable en sort « préparé » puis « connu » depuis la sheet de préparation | moyenne | — | Corrigé (PR #81). Les lignes déjà abîmées ne sont pas réparables : rien ne permet de les reconnaître. |
| D39 | Vue partagée : `get_shared_character` ne renvoie pas `source_class_id` sur les sorts ; un multiclassé mixte partagé affiche tous ses sorts « à préparer » | basse | Ajouter la colonne à la RPC (dépôt web) ; le mapper mobile la lit déjà | Corrigé côté base (dépôt web, PR #19), voir plus bas |
| D40 | L'édition d'un personnage écrit `source_class_id` nul sans changement de classe ; `setSpellPrepared` n'écrit pas l'origine à l'insertion | basse | Écrire la classe d'origine sur ces deux chemins | Ouvert |
| D41 | Artificier présent en base et proposé à la création, mais non modélisé : ni lanceur, ni emplacements, ni préparation | moyenne | Décision produit : le modéliser (demi-lanceur qui prépare) ou le retirer du catalogue | Ouvert |
| D42 | `setSpellPrepared` : course entre lecture de contrôle et insertion, faute de contrainte unique | basse | Contrainte unique `(character_id, spell_id)` après nettoyage des doublons (voir D10) | Ouvert |

## Ajouts liés aux sorts innés sans emplacement (PR #82)

Vérifié en base, en lecture seule, le 08/10/2026 (avant la PR #83) : aucune paire
(personnage, sort) ne porte à la fois une ligne `'inné'` et une ligne ordinaire — **cette
affirmation ne tient plus après la PR #83** (voir D53 ci-dessous) : l'assistant de
modification permet désormais de créer ce cas en cochant côté classe un sort déjà inné,
un chemin légitime (pas un bug) qui n'existait pas avant ce correctif. Les politiques RLS de
`character_spells` réservent
l'écriture au propriétaire du personnage (`owns_character(character_id)`) ;
`build_character_sheet_json` renvoie `source_class_id` et `innate_uses_spent`, ce qui
ferme D39 côté base.

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D08 | Sorts innés raciaux : emplacement exigé, pas de compteur | haute | — | Corrigé (PR #82). Lancer sans emplacement, une fois par repos long, compteur `character_spells.innate_uses_spent`. |
| D39 | Vue partagée sans `source_class_id` | basse | — | Corrigé côté base (dépôt web, PR #19) ; jamais contrôlé sur un lien de partage réel |
| D43 | Sort à la fois inné et connu : la ligne ordinaire l'emporte, le lancer gratuit est perdu | moyenne | Règle complète : un lancer gratuit par repos long, plus les emplacements. Décision produit. Depuis la PR #83, un chemin légitime (l'assistant de modification) peut créer ce cas ; aucun cas constaté en base à ce jour, mais ce n'est plus seulement théorique. | Ouvert |
| D44 | Sort inné aussi accordé par une sous-classe : traité comme préparé, donc avec emplacement | basse | À traiter avec D43 | Ouvert |
| D45 | Réaffirmation pendant un repos encore en vol : si un lancer réussit pendant un repos long qui échoue ensuite, l'écran affiche « Épuisé » alors que la base vaut 0. Patron commun aux quatre `_reassert…State` (PV, emplacements, pacte, sorts innés) ; leur `finally` rouvre aussi le verrou de repos trop tôt. | moyenne | Ne réaffirmer qu'une fois le repos en vol terminé | Ouvert, reproduit en revue |
| D46 | La réaffirmation relit une fiche qui peut déjà contenir l'écriture obsolète : un repos long peut être écrasé | basse | Réaffirmer depuis l'état local, pas depuis la fiche relue | Ouvert, lu, non reproduit |
| D47 | Les réaffirmations ignorent une écriture non envoyée (hors ligne), sans message | basse | Traiter `queued` comme un échec affiché | Ouvert |
| D48 | Lancer en vol qui échoue après un repos court : l'emplacement reste affiché dépensé. Corrigé pour les sorts innés, pas pour les emplacements (`_castSpell`). | basse | Même correction que pour les sorts innés | Ouvert, lu, non reproduit |
| D49 | `setInnateSpellUsesSpent` répond « synchronisé » même si aucune ligne n'est modifiée | basse | Relire la ligne écrite et échouer si le résultat est vide | Ouvert |
| D50 | Échec ambigu d'un lancer (délai dépassé après écriture effective) : l'écran revient à « disponible » sans recharger la fiche | basse | Recharger la fiche sur échec inattendu | Ouvert |
| D51 | Vue partagée : un sort en double apparaît deux fois, une fois inné et une fois ordinaire | basse | Aligner sur la règle de la fiche ; à traiter avec D10 | Ouvert |
| D52 | `CharacterSpellEntry` n'est pas `freezed` : copies manuelles de 17 champs, dont une dans `prepare_spells_sheet.dart` qui perd `innateUsesSpent` (sans effet aujourd'hui) | basse | Passer le modèle sous `freezed` | Ouvert |

Constats sans identifiant :

| Sujet | Détail | Source |
|---|---|---|
| Repos long à moitié appliqué | La remise à zéro des sorts innés est placée avant les dés de vie, donc son échec est rejouable. Un échec après les dés de vie ne l'est toujours pas. | Voir D05 |
| Après un repos court, un lancer inné réussi n'affiche pas son message de confirmation | Le compteur est correct. | Lu par dev-flutter |
| Rond doré du marqueur d'usage | Environ 2,4:1 sur le fond de la ligne, pour 3:1 attendu ; identique aux pastilles d'emplacements. L'état épuisé ne repose pas sur la couleur. | Calculé par direction-artistique |
| Pastilles de ligne en 10 px | Le design system fixe 11 px minimum. « INNÉ » s'aligne sur l'existant ; `_PreparationStatus` garde un `10` en dur. | Direction artistique |
| Cible tactile d'une ligne de sort à 32 px | 44 px attendus. Antérieur. | Direction artistique |
| Titre « Niveau N » des groupes de sorts | Déborde à l'échelle 3.0 sur 320 et 390 px avec la police de test ; la ligne innée n'est donc pas testée à 3.0 sur le plus petit écran. | dev-flutter, direction-artistique |
| Maquettes locales | `09-maquettes-captures.md` n'a pas de section pour l'onglet Sorts : copie locale à resynchroniser. | Direction artistique |
| Double tap dans la même frame sur « Lancer » | Ferait deux fermetures de panneau. Antérieur, commun à tous les sorts, non testé. | Lu par QA |
| `get_group_member_character` appelable sans connexion | Sans fuite constatée. | Lu en base |
| `refresh_proposal_counts` appelable sans connexion et par tout compte | Migration à part, avec un test de vote (dépôt web). | Lu en base |
| `build_character_sheet_json` appelable par tous du 27/09 au 08/10 | Fiche complète lisible avec son identifiant. Fermé par la migration `20261007090000` (dépôt web, PR #19). Aucun moyen de savoir si elle a été exploitée. | Lu en base |

## Ajouts liés à la conservation des sorts innés en édition (PR #83)

Constats relevés par `dev-flutter`, `qa-testeur` et `code-reviewer` les 07-08/10/2026 en
corrigeant D09, non traités (sauf D09 lui-même).

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D09 | Sorts innés supprimés lors d'un changement de classe en édition | haute | — | Corrigé (PR #83). `CharacterEditSnapshot.classSpells` exclut les lignes `'inné'` ; planificateur, hydrateur et le `DELETE` du dépôt d'édition ne touchent plus que les lignes ordinaires. |
| D53 | Changer de race en édition est possible, mais les sorts innés de l'ancienne race restent, ceux de la nouvelle n'arrivent pas ; `characters.lineage_id` n'est ni lu ni écrit en édition | moyenne | Décision produit : verrouiller la race en édition, ou gérer l'échange de sorts innés et de `lineage_id` | Ouvert |
| D54 | L'hydrateur d'édition tronque en silence (`take(quota)`) les sorts au-delà du quota, sans message | basse | Signaler la troncature, ou refuser l'édition si le personnage dépasse déjà son quota | Ouvert |
| D55 | `save` de l'édition non transactionnel : un échec entre la suppression et l'insertion des sorts laisse le personnage sans sorts de classe | haute | Rattaché à D05 (fonctions Postgres transactionnelles) | Ouvert |
| D56 | Un index unique partiel sur `(character_id, spell_id)` par nature de ligne (inné/ordinaire) serait à étudier côté base, pour empêcher un doublon accidentel au-delà du cas D43 volontaire | basse | Rattaché à D10 et D42 (contrainte unique après nettoyage des doublons d'import) | Ouvert |

Constat sans identifiant, pour un futur passage de l'audit `dette-technique` :

| Sujet | Détail | Source |
|---|---|---|
| Avertissement `drift` répété en test | `test/features/character_creation/data/character_creation_repository_test.dart` (groupe "TTL cache d'abord si frais") émet « AppDatabase multiple times » à plusieurs reprises. Présent avant la PR #83, tests passants malgré l'avertissement — à vérifier si c'est un artefact des fixtures (base recréée plusieurs fois dans la même suite) ou un pattern qui existe aussi en production. | Lu par qa-testeur |

## Ajouts liés à la fusion déterministe des sorts en double (PR #84)

Constat relevé par `dev-flutter` et confirmé par `qa-testeur`/`code-reviewer` les
08-09/10/2026 en corrigeant D10, non traité.

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D57 | `CharacterSpellRowMapper.parseFavorites` a la même faiblesse de non-déterminisme que l'ancien `parseStatuses` : en cas de lignes en double pour un même sort avec `is_favorite` divergent, la dernière ligne lue l'emporte (ordre PostgREST non garanti). Aucune règle produit tranchée entre « favori gagne »/« non-favori gagne », contrairement au statut (où « préparé l'emporte » découle d'un principe déjà établi : ne jamais dépréparer silencieusement). Aucun test n'existe non plus pour `parseFavorites`, même sur le cas nominal. | basse | Décision produit d'abord (quelle règle de priorité), puis même patron que `_statusRank` ; ajouter la couverture de test manquante dans la foulée | Ouvert |

## Ajouts liés à la fonction transactionnelle create_character (PR #20, dépôt web)

Constats relevés par `dev-backend-supabase` et `code-reviewer` le 07/10/2026 en
préparant et validant `create_character` (point 10 de la partie B). Aucun rapport avec
le dépôt mobile ; tous découverts en rejouant `supabase db reset` en local pour la
première fois (jamais fait avant sur ce dépôt, cohérent avec les en-têtes de
`character_spells_innate_uses_test.sql`/`character_share_token_test.sql` qui le
signalaient déjà).

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D58 | La colonne `is_incomplete` (`spells`, `races`, `backgrounds`) est utilisée par des migrations du dépôt web à partir du 21/09 mais n'est créée par aucune migration — elle n'existe que sur le projet distant, ajoutée hors migration. `supabase db reset` échoue dès `20260921090000_fix_spells_metadata_add_2024_spells.sql` sans elle. | haute | Migration `alter table ... add column if not exists is_incomplete ...` placée chronologiquement avant sa première utilisation | Corrigé (PR #21, dépôt web). Migration `20260920090000_add_reference_is_incomplete.sql` ajoutée avant son premier usage. |
| D59 | `20260930140000_seed_backgrounds_complements.sql` (lot 7) attend au moins 72 historiques complets mais n'en obtient que 71 : une collision de nom fait que le dédoublonnage ignore silencieusement un des 57 historiques à insérer, le prenant pour un historique déjà présent sous un nom proche. | haute | Fiabiliser le dédoublonnage du lot 7 | Corrigé (PR #21, dépôt web). **Correction d'une affirmation fausse de l'audit du 07/10** : il n'y a jamais eu de collision de dédoublonnage. Les 56 tuples du lot 7 sont tous distincts ; le total attendu de 72 comptait à tort sur un placeholder (« Grand voyageur », id 16) qui, comme pour D58, n'existe que sur le projet distant, hors migration — en local, 15+56=71, jamais 72, indépendamment de tout bug. Seuil final corrigé à 71 (72 reste correct sur le distant) ; ajout d'une vraie garde (`v_inserted <> 56`) qui, elle, détecterait une future collision réelle. |
| D60 | 3 fichiers de tests pgTAP déjà en échec, sans rapport avec `create_character` : `bug_reports_rls_test.sql`, `character_share_token_test.sql`, `content_proposals_rls_test.sql`. Jamais réparés car `db reset`/`test db --local` n'avaient apparemment jamais été rejoués en entier en local. | haute | Audit dédié par `dev-backend-supabase` : déterminer pour chacun si l'échec révèle un vrai bug RLS/partage en production, ou seulement un test à corriger | Corrigé (PR #21, dépôt web). Audit fait, **aucun vrai bug RLS/partage trouvé**, les 3 échecs étaient des défauts de test, vérifiés indépendamment par `code-reviewer` (lecture des migrations sources, pas de confiance aveugle) : `bug_reports_rls_test.sql` attendait à tort une exception sur un `UPDATE` sans policy, alors que le `GRANT` + RLS sans policy UPDATE retombe délibérément sur `using (false)` (comportement documenté dans la migration source, pas une faille) — corrigé pour vérifier l'absence réelle d'effet. `character_share_token_test.sql` avait 2 défauts d'écriture (comparaison MVCC dans une seule instruction ; accès direct à `characters` sous le rôle `anon`, qui n'arrive jamais en production puisque le token est reçu par lien, jamais relu en base) plus un vrai écart de contenu légitime (aptitude Barbare « Sens du danger », ajoutée au catalogue après l'écriture du test). `content_proposals_rls_test.sql` était déjà vert une fois D58/D59 corrigés ; le "3/31 en échec" de l'audit du 07/10 était un artefact de l'absence de `db reset` propre à ce moment-là. `supabase test db --local` : 73/73 tests verts, reproduit deux fois indépendamment. Suggestion non bloquante notée par `code-reviewer`, hors périmètre de cette PR : un rapporteur de bug dont l'`UPDATE` est silencieusement refusé par RLS ne reçoit aucun message d'erreur côté client — à voir avec `dev-flutter`/produit si un retour explicite est souhaitable. |

**Why ces trois-là n'ont pas été corrigés sur place** : hors périmètre de la tâche
(ajouter les tests pgTAP de `create_character`), et un correctif sans contexte risquait
de masquer un vrai bug métier plutôt que de le réparer. Les deux contournements
temporaires utilisés pour dérouler `db reset` (colonne ajoutée, exceptions du lot 7
changées en `notice`) ont été annulés avant de commiter ; la PR #20 ne contient que le
nouveau fichier de test.

## Ajouts liés au verrou et au seuil d'abandon de la file hors ligne (PR #86)

Constats relevés par `qa-testeur` et `code-reviewer` les 07-08/10/2026 en corrigeant
D33/D34, non traités (sauf D33/D34 eux-mêmes).

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D61 | Aucun test n'exerce un vrai code SQLSTATE `22xxx` pour `PendingCharacterWriteSyncer._isNonRetryable` (seuls `42501`/`23503` sont couverts en bout en bout) | basse | Ajouter une variante du test D34 « abandon après le seuil » avec un code `22xxx` | Ouvert |
| D62 | Le correctif évitant la perte silencieuse du signalement D34 (`_notifyAbandonedWrites` ne consomme plus les lignes en base si `messenger` est encore `null`) n'a pas de test dédié exerçant ce chemin ; vérifié par lecture de code et raisonnement sur le câblage `main.dart` seulement | basse | Un `ProviderContainer` avec `scaffoldMessengerKeyProvider` surchargé par un `GlobalKey` jamais attaché suffit à le couvrir | Ouvert |

## Ajouts liés à la correction de l'historique des migrations (PR #21, dépôt web)

Constat relevé par `code-reviewer` le 08/10/2026 en validant le correctif D58/D59/D60,
non traité (hors périmètre backend, suggestion produit/UX côté mobile).

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D63 | Un rapporteur de signalement de bug (`bug_reports`) dont l'`UPDATE` est refusé par RLS (délibéré : aucune policy UPDATE, `GRANT` table-level + `using (false)`) ne reçoit aucune erreur côté client — `UPDATE 0` silencieux. Le joueur peut croire avoir modifié son signalement alors que rien n'a changé. | basse | Décision produit : faire remonter un message explicite côté mobile quand une modification de `bug_reports` n'affecte aucune ligne | Ouvert |

## Ajouts liés au durcissement de la CI et de la publication (PR #88)

Constats relevés par `code-reviewer` le 08/10/2026 en validant D19, non traités.

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D64 | Le déclencheur `on.push.tags: "v*"` de `release-android.yml` reste un glob large : un tag mal formé (`vfoobar`, `v1.0.0-rc1`) déclenche quand même le job, et le `BUILD_NUMBER` courant n'est jamais revalidé contre le format `vX.Y.Z` (seul le tag *précédent* utilisé pour la comparaison est filtré, depuis le correctif D19) | basse | Valider aussi le format du tag courant en tout début de job, avant toute étape | Ouvert |
| D65 | Dans `release-android.yml`, les secrets réels (keystore, `key.properties`, `config/prod.json`) sont écrits sur disque avant les étapes `flutter analyze`/`flutter test` ajoutées par D19 — pas un risque actuel (rien n'imprime leur contenu), mais une vigilance pour une future modification de ce fichier (ex. un test qui dumperait l'environnement) | basse | Écrire les secrets sur disque seulement après `analyze`/`test`, juste avant le build signé | Ouvert |

## Ajouts liés au workflow de tests d'intégration (PR #89)

Constat relevé par `qa-testeur` et `code-reviewer` le 08/10/2026 en validant D18, non traité.

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D66 | `.github/workflows/integration-tests.yml` n'a ni bloc `concurrency` ni `timeout-minutes` : un `workflow_dispatch` manuel qui se superpose au cron nocturne lance deux jobs en parallèle (pas de collision réelle, juste des minutes CI redondantes) ; un blocage improbable de `supabase start` consommerait le timeout par défaut (6h) avant d'échouer | basse | Ajouter un bloc `concurrency` (groupe par workflow) et un `timeout-minutes` raisonnable | Ouvert |

## Ajouts liés à apply_rest (PR #22, dépôt web)

Constat relevé par `code-reviewer` le 08/10/2026 en validant `apply_rest`, non traité
(documentation ajoutée dans la migration elle-même, mais le risque reste réel pour la
future tâche de branchement).

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D67 | `apply_rest` attend un paramètre `p_rest_type` avec les valeurs `'court'`/`'long'` — une convention de wire nouvelle, distincte de la convention déjà en base `class_features.uses_per_rest->>'rest_type'` (`'repos_court'`/`'repos_long'`). Le client mobile actuel n'a jamais sérialisé `RestType` ; risque qu'un futur branchement envoie par erreur le mauvais vocabulaire. | basse | Lors du branchement Flutter : mapper explicitement `RestType.short`/`RestType.long` vers `'court'`/`'long'`, ne jamais réutiliser la chaîne `'repos_court'`/`'repos_long'` | Ouvert |

## Ajouts liés à apply_level_up (PR #23, dépôt web)

Constats relevés par `qa-testeur`/`code-reviewer` le 09/10/2026 en validant `apply_level_up`,
non traités.

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D68 | Le plafond ASI à 20 (`character_ability_scores`) n'est testé dans aucun des deux dépôts (ni `test/` mobile, ni la nouvelle suite pgTAP) — le code est correct (vérifié par lecture indépendante deux fois), mais sans filet de régression. | basse | Ajouter un cas de test (Dart et/ou pgTAP) qui dépasse volontairement le plafond de 20 lors d'un ASI | Ouvert |
| D69 | `apply_level_up` attend un paramètre `p_choice` en jsonb (`{"kind": "ability_score_improvement"\|"subclass"\|"fighting_style"\|"favored_enemy"\|"pact", ...}`) — convention de wire nouvelle, le client mobile actuel ne sérialise jamais `LevelUpChoiceSelection`/`LevelUpChoiceKind`. Même risque que D67 : un futur branchement pourrait sérialiser l'enum Dart brut au lieu du vocabulaire attendu. | basse | Lors du branchement Flutter : mapper explicitement chaque `LevelUpChoiceKind` vers la valeur `kind` attendue, ne jamais sérialiser l'enum Dart directement | Ouvert |

## Ajouts liés au correctif urgent de déduplication des sorts initiaux (PR #96)

Constat relevé par `qa-testeur`/`code-reviewer` le 09/10/2026 en validant le correctif
D10 côté client, non traité (limite de couverture actée comme acceptable, pas un bug).

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D70 | Aucun test ne couvre le recoupement croisé entre `initialSpellIds` et `racialInnateSpellIds` au sein du même appel à `applyLevelUp` (un sort inné racial qui coïnciderait avec un sort initial de la nouvelle classe multiclassée). Le comportement correct découle de la lecture du code (deux relectures fraîches séquentielles de `_fetchKnownSpellIds`, pas de cache partagé), mais le double HTTP de test de ce fichier est délibérément stateless (convention reproduite dans plusieurs autres fichiers de test) et ne peut pas représenter ce scénario tel que construit. | basse | Rendre ce double stateful pour ce scénario précis, ou accepter la limite et documenter pourquoi | Ouvert |

## Ajouts liés à l'initialisation des emplacements de sorts (D14)

Constats relevés par `dev-flutter`/`qa-testeur` le 09/10/2026 en validant D14, en lançant
pour la première fois la suite `test_integration/` complète (98 tests, 16 en échec —
confirmés tous préexistants et indépendants de D14, reproduits à l'identique sur le
commit parent).

| ID | Sujet | Gravité | Correction proposée | État |
|---|---|---|---|---|
| D72 | Colonne `character_inventory.weapon_slot` utilisée côté mobile depuis le 22/09 (`lib/features/characters/domain/weapon_slot.dart`) mais absente de toutes les migrations du dépôt web — même défaut que D58 (`is_incomplete`). `supabase db reset` échoue dès qu'une requête touche cette colonne ; 7 des 16 échecs de `test_integration/` lui sont directement imputables. | haute | Migration `alter table character_inventory add column if not exists weapon_slot text check (weapon_slot in ('principal', 'secondaire'))`, placée chronologiquement avant le 22/09 | Corrigé (PR #25, dépôt web). Colonne/contrainte reproduites fidèlement (vérifié par dump en lecture seule du projet distant, deux fois indépendamment) : `text` nullable, `CHECK` sur `'principal'`/`'secondaire'`. Aucune autre colonne orpheline trouvée sur `character_inventory`. |
| D73 | 6 des 16 échecs de `test_integration/` viennent d'un `Worker failed to boot` sur l'edge function `create-group` (`SupabaseGroupRepository.createGroup`) — logs Docker : « failed to bootstrap runtime : failed to determine entrypoint ». Semble être un conteneur `supabase_edge_runtime` local resté actif trop longtemps (infra, pas un bug de code), mais pas vérifié davantage. | basse | Vérifier après un `supabase stop`/`supabase start` propre si l'edge function boote correctement ; si le problème persiste, creuser plus avant de se fier à un futur run de test touchant les groupes | Ouvert |

## Décisions en attente

1. Un Barde, Ensorceleur, Occultiste ou Rôdeur doit-il lancer ses sorts connus sans
   préparation ? **Oui, demandé par Matthias le 06/10.** (D03)
2. Les sorts innés raciaux se lancent-ils sans emplacement, avec un compteur par repos
   long ? **Oui, demandé par Matthias le 06/10 ; fait (PR #82).** (D08)
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
14. Un sort à la fois inné et connu : applique-t-on la règle complète (un lancer gratuit
    par repos long, plus les emplacements) ? Aujourd'hui la ligne ordinaire l'emporte.
    Depuis la PR #83, l'assistant de modification peut créer ce cas pour de vrai (pas
    seulement en théorie) : un joueur qui coche côté classe un sort déjà inné. (D43)
16. Verrouille-t-on la race en édition, ou gère-t-on l'échange des sorts innés et de
    `lineage_id` quand un joueur change de race via l'assistant de modification ? (D53)
15. Faut-il une confirmation avant de lancer un sort inné, puisqu'aucune sheet de choix
    ne s'ouvre ?

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
