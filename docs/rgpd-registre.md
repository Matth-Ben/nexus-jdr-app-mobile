# Registre RGPD

Registre des écarts RGPD et confidentialité, tenu par la conversation principale à partir des audits de l'agent `rgpd`
(lecture seule, il ne corrige rien). Même logique que `docs/dette-technique.md` : **A** bloque la diffusion,
**B** à corriger rapidement, **C** peut attendre. Quand une entrée est traitée, mettre à jour son état en citant la PR,
sans supprimer la ligne. Avis non juridique : les points de responsabilité et de base légale sont à faire valider par un
conseil.

## Audit du 22/11/2026 : données des joueurs de Nexus copiées dans Grimoire (étape 5)

Contexte : depuis l'étape 5 (PR DeepCore #51, PR Grimoire #8), Grimoire lit l'instantané d'un groupe
(`api_v1.group_snapshot`) et garde en cache local, sur la machine du MJ, le pseudo de chaque joueur et un résumé de fiche
(nom du personnage, portrait, race, classes et niveaux, PV, mort, états, CA), dans `nexus_party`, `nexus_portraits` et
`nexus_hero_group_links`. Ticket Project #7 : « RGPD : données des joueurs de Nexus copiées sur la machine du MJ
(Grimoire, étape 5) ». Points déjà planifiés, non faits : D10 et D11 de `docs/api-refonte/09-base-outil-local.md`,
`FEUILLE-DE-ROUTE.md:282` de Grimoire.

| Id | Constat | Proposition | Qui | Cat. | État |
|---|---|---|---|---|---|
| R1 | **Les joueurs ne sont pas informés de la copie.** La politique de Nexus ne couvre que l'app et le site (`lib/l10n/app_fr.arb:708`), dit que le MJ « voit » les personnages sans parler de copie (`:776`) et affirme que tout est « supprimé définitivement dès que tu supprimes ton compte » (`:820`, `:336`), faux pour les copies de Grimoire. Même chose sur le site (`markdown-editor/apps/web/app/confidentialite/page.tsx:137,200`). Grimoire n'a aucun texte de confidentialité. Article 13 (destinataires, durée). | Ajouter « l'app de bureau du MJ (Grimoire) » comme destinataire, avec la liste des données, la durée et le délai d'effacement ; texte d'information pour le MJ dans Grimoire. | chef de projet (textes), puis `dev-flutter`, `dev-grimoire` | A | À faire |
| R2 | **Le cache est visible par un autre compte Nexus.** « Reprendre une base » copie `nexus_party` et `nexus_portraits` sans les purger (`server/start.ts:117`, `adopt.ts:117`) ; `#partyOf` affiche les membres même en `not_owner` (`party.ts:610-615`, `party.test.ts:466-467`) et les portraits sont servis (`party.ts:221-223`) ; en mode web, tout compte connecté est `ready` (`groups.ts:281-285`). Le MJ B voit les pseudos, PV et portraits des joueurs de A. | Purger les tables `nexus_*` à la reprise d'une base ; en `not_owner` et `orphan`, ne rien afficher et purger. | `dev-grimoire` | A | À faire |
| R3 | **Aucune durée de conservation.** Seuls un instantané complet ou une dissociation purgent (`party-cache.ts:36-43`, `group-links.ts:148-152`) ; `group_not_found` et `not_owner` gardent tout (`party.ts:376-391`) ; compte du MJ supprimé : retour à la version d'essai sans purge (`auth.ts:387-393`, D11 non appliquée). Droit à l'effacement non garanti. | Durée limite depuis `checked_at` (recommandation : 30 jours) ; purge immédiate si groupe orphelin, `not_owner` ou session révoquée. | `dev-grimoire` | A | À faire |
| R4 | **Sauvegardes.** La rotation garde 7 fichiers, pas 7 jours (`backups.ts:7,77`) : avec `touchParty` chaque minute, un MJ hebdomadaire garde environ 7 semaines ; les 3 sauvegardes d'avant migration sont gardées sans limite (`:9,78`). | Vider `nexus_party` et `nexus_portraits` dans la copie avant de la renommer (`:128`) : c'est un cache reconstructible. | `dev-grimoire` | B | À faire |
| R5 | **Bucket des portraits peut-être listable** (à vérifier) : la politique SELECT de `20260825090400_create_character_tables.sql:558-560` ne précise aucun rôle sur `storage.objects` ; les dossiers portent les identifiants de compte, et les avatars de profil y sont aussi. Préexistant, aggravé par la copie des URL chez chaque MJ. | Supprimer cette politique (inutile pour lire un bucket public par URL) ; à terme, bucket privé et URL signées (chantier commun Nexus, DeepCore, Grimoire). | `dev-backend-supabase` | B | À faire |
| R6 | Pas de `PRAGMA secure_delete` : les lignes purgées restent physiquement dans le fichier SQLite. | `secure_delete=ON` et checkpoint WAL après chaque purge (gain faible tant que R4 n'est pas fait). | `dev-grimoire` | C | À faire |
| R7 | L'URL du portrait gardée contient l'identifiant du compte du joueur (`portraits.ts:5`, `snapshot.ts:109`), contrairement à `snapshot.ts:59-60` et au `README.md:115` de Grimoire. | Retirer l'identifiant de ce qui est gardé, ou corriger la documentation. | `dev-grimoire` | C | À faire |
| R8 | `nexus_hero_links` abandonnée mais pas vidée (`db.ts:322-328`). | La supprimer par une migration. | `dev-grimoire` | C | À faire |
| R9 | Chaque UPDATE temps réel de `characters` transmet la ligne complète à la mémoire de Grimoire (`party-realtime.ts:49`), même si rien n'en est gardé. | Signal sans contenu (Broadcast), puis relecture de l'instantané. | `dev-backend-supabase` | C | À faire |
| R10 | La désinstallation (NSIS) n'efface pas les données (`electron-builder.yml:36`). | Bouton « Effacer les données Nexus » dans Grimoire. | `dev-grimoire` | C | À faire |
| R11 | Un propriétaire qui a quitté son groupe reçoit encore l'instantané (`contrat-lecture-grimoire.md:20-23`). | Le dire dans les textes (R1). | chef de projet | C | À faire (intégré à la proposition de textes) |
| R13 | Relevé le 22/11/2026 par `dev-backend-supabase` (PR DeepCore #52, R5) : le bucket `character-gallery-photos` est **listable par un anonyme** de la même façon que les portraits (mesuré en local), et les buckets des histoires portent la même politique SELECT publique. Même limite que R5 : un bucket public reste lisible par chemin connu ; seul le listage peut être fermé par la RLS. | Même correction que R5 (lecture réservée au dossier du propriétaire), après vérification des usages de chaque bucket ; à terme, buckets privés. | `dev-backend-supabase` | B | En cours (PR #52 étendue) |
| R12 | Relevé le 22/11/2026 par `rgpd` (revue de la PR Grimoire #9) : les liens héros ↔ personnage (identifiants seulement) d'une base de compte qui n'est plus jamais rouverte (déconnexion définitive, compte du MJ supprimé) ne sont jamais purgés ; la promesse « effacés 30 jours après `seen_at` » est fausse dans ce cas. | Purger les liens des autres bases de compte au démarrage, ou le dire dans les textes. | `dev-grimoire` | C | À faire |

**Suivi du 22/11/2026 (revue de clôture `rgpd` de la PR Grimoire #9)** : R2, R3, R4, R6, R7 et R8 **refermés dans la PR
Grimoire #9** (`fix/rgpd-cache-nexus`, commits `3ac4f5e`, `543c14d`, `7445695`), sous réserve du merge. Règle exacte de
conservation et limites (fichier non relancé, sauvegardes du système, liens R12, tolérance d'un jour) : voir
`docs/rgpd-textes-proposition.md`. **PR Grimoire #9 mergée le 22/11/2026 (`852e24e`)** : R2, R3, R4, R6, R7, R8
corrigés. Restent bloquants pour la diffusion de Grimoire : **R1** (validation et mise en ligne
des textes, nom du responsable) ; puis R5 (B), R9, R10, R11, R12 (C).

**Rien à signaler** : journaux (codes et identifiants de groupe seulement, 1 Mo avec rotation), session chiffrée par le
système, exports `grimoire-mj`, brief envoyé à l'IA, portraits à adresse externe (jamais téléchargés).

### Recommandations de l'agent `rgpd` (à trancher par Matthias, et Florian pour Grimoire)
1. **Durée hors ligne** : 30 jours depuis la dernière lecture réussie, purge immédiate si groupe orphelin, `not_owner`
   ou session révoquée.
2. **Liens héros ↔ personnage** : identifiants seulement, risque faible ; purge après la même durée pour un groupe non
   réassocié ou un personnage manquant.
3. **Sauvegardes** : exclure le cache des sauvegardes (R4) plutôt qu'aligner leur durée.
4. **`secure_delete`** : R6, pas bloquant.
5. **Bucket public** : R5 tout de suite ; bucket privé à planifier.
6. **Information des joueurs** : aucun texte n'en parle (R1).
7. **Rôles et base légale** (avis non juridique) : Matthias, qui décide de communiquer ces données au MJ et fixe le
   contrat, est responsable de cette communication et de l'information des joueurs ; Florian ne reçoit jamais ces données
   mais son code fixe la conservation (répartition à écrire, éventuellement responsabilité conjointe, article 26) ; un MJ
   entre amis relève probablement de l'exemption domestique (article 2.2.c), un MJ professionnel devient responsable
   (clause dans la licence Grimoire). Base légale : exécution du service (article 6.1.b) ; consentement déconseillé.
8. **Droits des joueurs** : effacement immédiat dans DeepCore ; dans Grimoire, au prochain instantané complet (moins
   d'une minute si Grimoire est ouvert et en ligne), jamais aujourd'hui si le MJ reste hors ligne, si le groupe est
   orphelin, si le compte du MJ est supprimé, ni dans les sauvegardes. Avec R3 et R4 corrigés : « au plus tard N jours ».
   Accès et export : couverts par l'export Nexus (la copie en est un sous-ensemble), mais l'existence de la copie doit
   être signalée (R1).
