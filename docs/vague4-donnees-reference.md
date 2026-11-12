# Vague 4 — données de référence : P12 (paquetages) et P13 (dons)

Source : audit `regles-dnd` du 12/11/2026 (lecture seule, **de mémoire** : 2014 PHB p. 151 confiance haute pour les
contenus, poids dérivés ; 2024 confiance moyenne, **à valider contre le livre par Matthias avant toute migration 2024**).
Décisions de Matthias (12/11/2026) :
- **P13** : catégorie 2024 de l'homonyme avec `edition = 2014` (le texte en base est celui de 2014/Tasha) ; dons sans
  homonyme 2024 = `legacy` ; défaut pour source inconnue = `legacy` ; colonnes `category` + `source` + `edition` ;
  **UI : pastille d'étiquette, sans griser ni masquer** (« Campagne » / « Épopée »).
- **P12** : **corriger et éclater le 2014 maintenant ; le 2024 attend la validation de Matthias** contre son PHB 2024 ;
  modèle : table de lignes `equipment_pack_items` avec FK vers `items` + édition (les noms FR des paquetages restent
  stables : `classes.starting_equipment` les référence par nom).
- Migrations dans le dépôt **web** (`H:/Projets/Labo/markdown-editor/supabase/migrations`), **appliquées par Matthias**
  (jamais par Claude, jamais par un agent) : l'agent n'écrit que le fichier de migration et ouvre une PR.

## État actuel (vérifié par l'audit)
- `equipment_packs(id int identity, contents jsonb)` (`20260825090300…:214`, seed `20260825091000_seed_items_equipment.sql:241-265`) :
  `contents` = `[{"item": <nom FR>, "quantity": n}]` sans FK ; nom FR du paquetage dans `translations`
  (`entity_type = 'equipment_pack'`, locale fr) ; aucune édition ; **aucun code de l'app mobile ne lit cette table**
  (seulement un commentaire dans `background_option.dart:68`). `classes.starting_equipment`
  (`20260930210000_classes_starting_equipment.sql`) référence les paquetages par nom FR (« Paquetage de l'explorateur
  des donjons », « Paquetage d'explorateur », « Paquetage de l'artiste », « Paquetage du cambrioleur »…).
- `feats(id int identity, prerequisites jsonb, ability_increase jsonb)` : ni source, ni édition, ni catégorie. **116 dons**
  (42 `20260905020000_seed_feats.sql` PHB 2014 ; 42 `20260930100000` : 12 faveurs épiques, 15 Xanathar, 15 Tasha ;
  32 `20260930170000` : 5 PHB 2024, 3 Fizban, 7 Géants, 1 Façonneur de runes, 7 Planescape, 9 Dragonlance). **Les ids sont
  générés : le backfill joint sur `translations` (`entity_type = 'feat'`, `field = 'name'`, `locale = 'fr'`).**

## P13 — table de correspondance par nom FR
`category ∈ {origin, general, fighting_style, epic_boon, legacy}` ; `source ∈ {PHB14, PHB24, SRD52, XGtE, TCoE, FToD,
BGG, PSAiM, DSotDQ}` ; `edition` = `2014` pour le texte 2014/Tasha/suppléments, `2024` pour les textes 2024 (SRD 5.2 /
PHB 2024). Tag UI « Épopée » = `epic_boon` ; « Campagne » = dons de suppléments de campagne (Fizban, Géants, Planescape,
Dragonlance) ; pastille seulement.
- **Origine (texte 2014 en base, homonyme 2024)** : Alerte, Guérisseur, Initié à la magie, Frappeur sauvage, Qualifié,
  Bagarreur de taverne, Robuste physiquement, Chanceux → `origin`, `PHB14`, `2014`. Artisan, Musicien → `origin`,
  `PHB24`, `2024`.
- **Général (texte 2014, homonyme 2024)** : Acteur, Athlète, Chargeur, Expert des armes à distance, Frappeur à deux armes,
  Endurant, Maître d'armes lourdes, Pourfendeur de mages, Cavalier hors pair, Maître de la hallebarde, Robuste,
  Sentinelle, Tireur d'élite, Maître du bouclier, Armure légère, Duelliste défensif, Sournois, Meneur inspirant,
  Observateur, Armure lourde, Maître de l'armure intermédiaire, Armure intermédiaire, Maître de l'armure lourde, Adepte
  élémentaire, Tireur d'élite occulte, Guerrier-sorcier, Rituels magiques, Esprit vif, Empoignade → `general`, `PHB14`
  (Empoignade : SRD 5.1), `2014`. Entraînement aux armes de guerre, Véloce, Amélioration de caractéristique →
  `general`, `PHB24`/`SRD52`, `2024`.
- **Legacy (absents du PHB 2024)** : Explorateur de donjon, Adepte martial, Mobile, Maître d'armes, Linguiste →
  `legacy`, `PHB14`, `2014` (retrait en 2024 : confiance ≈ 80 %).
- **Faveurs épiques (niveau 19)** : prouesse martiale, voyage dimensionnel, destin, offensive irrésistible, rappel des
  sorts, esprit nocturne, vision véritable (SRD52) ; résistance énergétique, robustesse, récupération, compétence,
  célérité (PHB24) → `epic_boon`, `2024`, tag « Épopée ».
- **Tasha avec homonyme PHB 2024** (Chef, Écraseur, Perforateur, Empoisonneur, Touché par l'ombre, Touché par les fées,
  Expert en compétences, Trancheur, Télékinésiste, Télépathe) → `general`, `TCoE`, `2014` ; **Tasha sans équivalent 2024**
  (Initié artificier, Adepte occulte, Initié au combat, Artilleur, Adepte de la métamagie) → `legacy`, `TCoE`, `2014`.
- **Xanathar** (15 dons raciaux : Chance généreuse, Terreur draconique, Peau de dragon, Haute magie drow, Robustesse naine,
  Précision elfique, Évanescence, Téléportation féerique, Flammes de Phlégéthos, Constitution infernale, Fureur orque,
  Prodige, Seconde chance, Agilité trapue, Magie des elfes sylvains) → `legacy`, `XGtE`, `2014`.
- **Campagne** (`legacy`, édition `2014`, tag « Campagne ») : Fizban (3 Dons du dragon chromatique/de gemme/métallique),
  Géants (Frappe des géants, Braise du géant du feu, Fureur du géant du givre, Ruse du géant des nuages, Acuité du géant
  des pierres, Âme du géant des tempêtes, Vigueur du géant des collines ; Façonneur de runes), Planescape (Rejeton des
  plans extérieurs, Agent de l'ordre, Rejeton funeste, Cohorte du chaos, Émissaire des Terres Extérieures, Vagabond
  planaire, Héritier vertueux), Dragonlance (Initié de la Haute Sorcellerie, Adepte des Robes noires/rouges/blanches,
  Favori divin, Écuyer de Solamnie, Chevalier de la Couronne/de la Rose/de l'Épée).
- **Défaut** : tout nom non listé = `legacy`, `edition = '2014'`, `source` inconnue (NULL). Aucun don de style de combat 2024
  n'est seedé (`fighting_style` aura 0 ligne : à signaler, ne pas inventer ; 10 à 12 dons à seeder plus tard) ; le seed
  ne peut pas porter à la fois le texte 2014 et le texte 2024 d'un homonyme (une ligne par nom). Colonnes nullables avec
  CHECK sur les valeurs ; backfill idempotent par jointure sur `translations`, avec un **contrôle de couverture** (les 116
  dons étiquetés, liste des non appariés dans un `RAISE NOTICE`). L'app mobile ne lira les colonnes que plus tard
  (pastille d'étiquette au niveau 4 : tâche dev-flutter distincte, après l'application de la migration par Matthias).

## P12 — contenu RAW 2014 (PHB p. 151) et écarts du seed
Contenus 2014 exacts (hors « rations » = 2 lb/jour) : **Cambrioleur** (16 po) : sac à dos, sac de 1 000 billes, 3 m de
ficelle, clochette, 5 bougies, pied-de-biche, marteau, 10 pitons, lanterne à capote, 2 flacons d'huile, 5 jours de
rations, silex et briquet, outre, corde en chanvre 15 m. **Diplomate** (39 po) : coffre, 2 étuis à cartes/parchemins,
vêtements fins, flacon d'encre, plume, lampe, 2 flacons d'huile, 5 feuilles de papier, fiole de parfum, cire à sceller,
savon. **Explorateur des donjons** (12 po) : sac à dos, pied-de-biche, marteau, 10 pitons, 10 torches, silex et briquet,
10 jours de rations, outre, corde en chanvre 15 m. **Artiste** (40 po) : sac à dos, sac de couchage, 2 costumes, 5
bougies, 5 jours de rations, outre, kit de déguisement. **Explorateur** (10 po) : sac à dos, sac de couchage, gamelle,
silex et briquet, 10 torches, 10 jours de rations, outre, corde en chanvre 15 m. **Ecclésiastique** (19 po) : sac à
dos, couverture, 10 bougies, silex et briquet, boîte à aumônes, 2 blocs d'encens, encensoir, vêtements sacerdotaux, 2
jours de rations, outre. **Érudit** (40 po) : sac à dos, livre de savoir, flacon d'encre, plume, 10 feuilles de
parchemin, petit sac de sable, petit couteau.
**Écarts du seed actuel (règle fausse à corriger)** : Cambrioleur : manquent billes, ficelle, clochette, lanterne à
capote, 2 huiles, et « kit de déguisement » n'y est pas RAW ; Ecclésiastique : manque la boîte à aumônes ; Érudit :
« Lettre d'un collègue » (reste de l'historique Sage) et « Sacoche en cuir » (inventé ; RAW = petit sac de sable) à
retirer, « Papier ×10 » doit être « Parchemin ×10 » ; Diplomate, Explorateur des donjons, Artiste, Explorateur :
contenus conformes, seuls des noms diffèrent du catalogue.
**Mapping catalogue (`items`, par nom FR)** : noms à rapprocher : « Étui à cartes ou à parchemins » (seed) ↔ « Étui à cartes
ou parchemins » ; « Parfum » ↔ « Parfum (fiole) » ; « Malle » ↔ « Coffre » ; « Costume » ↔ « Costume de déguisement » ;
« Miroir » ↔ « Miroir en acier poli ». **Objets à ajouter** : Cire à sceller (0,5 po, poids 0), Savon (0,02 po, poids 0) ;
sans stats RAW (paquetages 2014 seulement) : Boîte à aumônes, Encensoir, Encens (bloc), Vêtements sacerdotaux, Petit
couteau, Petit sac de sable, Livre de savoir : les créer avec poids 0 et coût NULL (choix produit, à signaler), ou les
laisser en lignes libres ; « Livre de savoir » ≈ « Livre » existant (25 po / 5 lb).
**Corrections de poids catalogue** : Marteau 0,5 → 1,4 kg ; Gamelle 0,2 → 0,45 kg ; Sac de couchage 3,4 → 3,2 kg (écart
mineur). Unité hétérogène (seed 2014 à 0,45 kg/lb, lot SRD 5.2 à 0,5 kg/lb) : à signaler dans la PR sans la trancher
(décision produit : une règle de conversion). Corde 15 m : 10 lb en 2014 (4,5 kg), 5 lb en 2024 (2,3 kg).
**Poids totaux 2014 (calculés, hypothèses sur les objets sans stats RAW)** : Cambrioleur 47,5 lb (21,4 kg), Diplomate 36
(16,2), Explorateur des donjons 61,5 (27,7), Artiste 38 (17,1), Explorateur 59 (26,6), Ecclésiastique 24 hypothèse (10,8),
Érudit 10 hypothèse (4,5).
**Modèle (décision de Matthias)** : `equipment_pack_items(pack_id, item_id, quantity, edition)` avec FK vers `items` et
`equipment_packs`, `edition ∈ ('2014','2024')`, CHECK ; seul `2014` est peuplé par cette migration (les 7 paquetages
corrigés, mappés sur `items.id`) ; **ne pas supprimer ni renommer `equipment_packs.contents`** (le laisser, signaler
qu'il est remplacé) et **ne pas renommer les paquetages** (`classes.starting_equipment` y renvoie par nom) ; le
2024 (contenus de mémoire, Burglar/Diplomat/Entertainer incohérents : 42≠44, 36≠39, 9 vs 10 jours de rations ; Priest
refondu 33 po ; Scholar : livre, lampe, 10 huiles, 10 plumes) **n'est pas migré** avant validation par Matthias.
