# Combat du groupe — spec consolidée et critères d'acceptation

Décisions de Matthias (12/11/2026), après revue du comité (avis détaillés dans `docs/retours-utilisateurs.md`) :
- Le combat est **porté par le groupe** (modèle mobile `groups` / `group_members`) ; le **MJ = propriétaire du groupe** ;
  seul le MJ pilote. Pas de mode combat dans un groupe **sans MJ dans l'app**.
- Monstres/PNJ : **nom + initiative, sans PV**, jamais de PV exposé.
- Emplacement : **bandeau « Combat en cours · round N »** en tête de l'écran Groupe + **écran dédié**
  `/groups/:id/combat` ; bouton MJ « Lancer un combat » dans l'onglet Membres ; pas de 4e onglet.
- Égalités : tri par initiative décroissante, puis PJ avant PNJ, puis ordre d'arrivée ; **le MJ peut réordonner une égalité**.
  Chaque joueur corrige **sa propre** initiative tant que le combat est actif ; le MJ peut éditer n'importe laquelle.
- V1 avec ajout de monstres en lot « ×N » (auto-numérotation « Gobelin 1/2/3 »). Si le MJ quitte ou est retiré en plein
  combat : l'état reste lisible avec « En attente du MJ » ; seul le MJ peut le terminer.
- Hors ligne : **lecture seule** du dernier état (horodaté), aucune file d'écriture ; retour réseau : re-fetch complet.
- Priorité : ce chantier passe **avant** la suite des rituels (P3b), qui le consommera (avertissement de combat, durées
  de sorts en rounds, concentration) mais n'en dépend pas.

## Modèle de données (dépôt web, appliqué par Matthias)
- `combats` : `id`, `group_id` (FK `groups` cascade), `status` (`active|ended`), `round` ≥ 1, `current_participant_id`
  (nullable, FK différée, `on delete set null`), `created_at`, `ended_at` ; **un seul combat actif par groupe** (index unique
  partiel).
- `combat_participants` : `id`, `combat_id` (cascade), `group_id` (dénormalisé pour le filtre Realtime), `character_id`
  (nullable, `on delete set null`), `user_id` (nullable), `name` (1..80, copié à l'insertion), `kind` (`pc|npc`),
  `initiative` (nullable, -20..60), `sort_order`, `status` (`active|removed|waiting`) ; unicité (combat, personnage) ; **aucune
  colonne PV**.
- RLS : lecture = membres du groupe (`is_group_member`) ; écriture combats/participants = propriétaire du groupe
  (`is_group_owner`, helper security definer) ; un joueur écrit son initiative **uniquement par RPC**
  `set_my_initiative` (la RLS ne limite pas les colonnes) ; MJ : RPC atomiques (`start_combat`, `end_combat`,
  `advance_turn` en V2, etc.) ; départ d'un membre : sa ligne participant est retirée ; publication Realtime des deux tables.
- V2 : trigger → edge function `send-push-notification` pour « à toi de jouer » (préférence `push_turn_reminder`), secret
  FCM à vérifier en production.

## Règles de jeu (regles-dnd, 2014)
Aucune règle d'égalité RAW (le MJ tranche) ; la mise en attente est un outil de table, pas une règle (seul « Se tenir
prêt » existe) ; surprise = drapeau décidé par le MJ (hors V1) ; un effet « 1 round » se compte depuis le tour du **lanceur**
(stocker round + participant ancre, V3) ; concentration : rappel de la DD = max(10, moitié des dégâts), jamais automatique.

## UI (direction-artistique, spec visuelle finale à produire avant le développement)
Niveau parchemin. Écran Combat : en-tête « Round N · Tour de X » (font.body), liste défilante de lignes (rang, nom,
initiative, badge « PJ » / « PNJ » + icône ; tour en cours = bordure épaisse + fond + libellé « Tour en cours » + chevron,
jamais la couleur seule) ; sans initiative : « Initiative à saisir » + bouton « Renseigner » sur sa ligne. Bandeau fiche :
une ligne neutre, sticky, tappable, ≥ 44 dp, sous le bandeau hors ligne, sans pulsation. Saisie d'initiative : feuille
avec champ numérique, aide Dex, « Lancer un d20 » (lanceur 3D), résultat modifiable. Ajout de monstre : nom, initiative,
« ×N », « Ajouter et continuer » ; retrait par menu de ligne (pas de balayage seul). États : vide MJ/joueur, en attente des
initiatives (2/4), chargement, erreur avec Réessayer, hors ligne (lecture seule, dernier état à HH:MM), combat terminé
(résumé), MJ absent. A11y : lignes en `Semantics` fusionné, annonce polie à chaque changement de tour, ×2,0/×3,0 sur
320 dp, cibles ≥ 44.

## Critères d'acceptation (qa-testeur)
**V1**
- Seul le MJ voit « Lancer un combat » ; groupe sans MJ : action absente **et** refusée côté serveur.
- Lancer : round = 1, aucun tour actif tant qu'aucune initiative ; terminer : l'état disparaît chez tous les membres ;
  un second « Lancer » alors qu'un combat est actif : refusé (pas de doublon).
- Le joueur saisit/modifie **sa seule** initiative (RPC) ; le MJ ajoute/retire des monstres (nom + initiative) et édite
  n'importe quelle initiative ; aucun champ PV de monstre dans la requête ni le payload Realtime.
- Liste triée décroissante, égalités déterministes (PJ avant PNJ, puis ordre d'arrivée) et réordonnables par le MJ ;
  tour en cours surligné (marque non chromatique) ; bandeau sur la fiche visible seulement si un combat est actif.
- Le tour en cours vient de l'état serveur (jamais calculé côté client).
- Hors ligne : fiche et dernier état consultables, toute écriture désactivée avec message ; retour réseau : re-fetch
  complet + réabonnement ; aucune écriture de combat dans la file de synchro existante.
- MJ absent/retiré : état lisible « En attente du MJ », aucune écriture possible par un joueur.
**V2** : tour suivant (saute retirés/en attente, round+1 au bouclage, idempotent en cas de double tap) ; notification
uniquement au joueur dont c'est le tour (jamais au MJ pour ses monstres) ; mise en attente/retrait sans casser le tour courant.
**V3** : critères à définir avec regles-dnd au moment de la V3.
**RLS** (tests SQL + intégration à 2 clients) : un joueur ne modifie que sa ligne d'initiative via RPC ; un non-membre ne lit
rien ; un membre non-MJ ne peut ni lancer, ni avancer, ni toucher aux monstres ; un ex-membre perd la lecture.

## Phasage
- **PR0 (web)** : migration tables + RLS + helpers + RPC (`start_combat`, `end_combat`, `set_my_initiative`, gestion des
  monstres, ordre) + Realtime + trigger de départ de membre + tests SQL.
- **PR1 (app)** domaine (tri, égalités, avance de tour) + dépôt + providers + abstraction Realtime + tests.
- **PR2 (app)** écran Combat, bandeau Groupe, contrôles MJ, ajout de monstres (×N).
- **PR3 (app)** saisie d'initiative (dé 3D), bandeau fiche joueur, états hors ligne.
- **V2** : PR4 `advance_turn` + UI ; PR5 push « à toi de jouer » (edge function) ; PR6 attente/retrait.
- **V3** : après P3b (chronos de sorts) : avertissement rituel, durées en rounds, concentration, états à durée.
Chaque PR : dev-flutter / dev-backend-supabase → qa-testeur → code-reviewer ; regles-dnd pour toute règle.
Limite de test : 2 comptes QA seulement (MJ + joueur) ; un 3e compte est nécessaire pour tester proprement tour suivant et
notification.
