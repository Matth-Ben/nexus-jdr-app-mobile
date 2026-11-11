# P2b — Dé 3D animé avec skins (prototype d20) — spec de la direction artistique

Décisions de Matthias (11/11/2026) : dé 3D facetté (aplats, arêtes `woodDark`) accepté malgré
l'univers pixel art ; chiffre du résultat net et à l'endroit, autres faces à 40 % d'opacité
(décoratif, ignoré du lecteur d'écran) ; animation de 1 400 ms avec **saut possible au tap**
(un tap pendant le lancer affiche directement l'état posé) ; animation automatique à l'ouverture
de la feuille, pose immédiate si `MediaQuery.disableAnimationsOf`.

## Principe
- Le résultat est tiré par `DiceRoller` **avant** l'animation (RNG injectable, tests inchangés).
  L'animation est un habillage cosmétique qui converge vers l'orientation dont la face du dessus
  est le résultat (table d'orientation 1..20, face frontale à ≤ 15°, chiffre à l'endroit).
- Icosaèdre dessiné en Dart (12 sommets, 20 faces), `drawVertices` + `FragmentProgram` (un shader
  par skin, chargé une fois, aucun chargement pendant l'animation). Flat shading, 3 à 5 paliers.
- Un seul `CustomPainter` dans un `RepaintBoundary`, `AnimatedBuilder` limité au painter,
  aucune allocation dans `paint`, pas de `saveLayer`/`ShaderMask`.

## Emplacement
- Remplace l'intérieur de `_DieFace` (la #275 a déjà : deux dés en avantage/désavantage, détail,
  dé écarté barré + mot « écarté »). Le texte de formule et la mention « 20/1 naturel » restent
  des `Text` réels sous le dé : ils sont la source de vérité. Le dé est décoratif
  (`ExcludeSemantics`).
- Plateau 160×160 dp dans une boîte de 192 dp de haut (pas de saut de layout), contour
  `parchmentCard` / `cardEmphasis` conservé (bordure `goldEnd` pour 20 naturel, `accentBrick` pour
  1 naturel, `woodLight` sinon), dé clippé dans le plateau. Avantage/désavantage : deux plateaux de
  120×120 côte à côte (gap 8), second lancer décalé de 120 ms.
- Un seul nœud sémantique `liveRegion`, mis à jour **une fois** le dé posé. « Relancer » désactivé
  (ou taps ignorés) pendant le lancer.

## Chronologie (1 400 ms, un `AnimationController`)
| Phase | Intervalle | Contenu | Courbe |
|---|---|---|---|
| Lancer | 0–15 % | entrée par le haut, ~3 tours (2 si gênant) | easeOut |
| Rebonds | 15–70 % | 2 rebonds (100 % puis 35 %), glissement vers le centre | bounceOut / decelerate |
| Pose | 70–100 % | dernier quart de tour vers le quaternion cible, échelle 1,00→1,04→1,00 | easeOutCubic |
| Résultat | fin | formule en fondu 200 ms, halo, annonce | easeOut |
- Ombre ellipse `cardDiffuseShadow` suivant la hauteur du dé.
- 20 naturel : halo radial `goldStart` 35 % + icône pixel étoile 16×16 + mention texte.
  1 naturel : halo `accentBrick` 25 % + tressautement ±4 dp/150 ms (supprimé sous
  `disableAnimations`) + icône pixel 16×16 + mention texte. Jamais la couleur seule.
- Avantage/désavantage : dé retenu normal + étiquette « Retenu » ; dé écarté à 55 %, barré
  (trait `woodDark` 2 dp) + étiquette « Écarté » ; naturel jugé sur le dé retenu uniquement.

## Skins (paramètres seulement, jamais de code utilisateur)
`DieSkin` immuable : `baseColor`, `edgeColor`, `numberColor`, `numberBackdropColor`, `lightTint`,
`shadeSteps` (3–5), `textureId` (liste fermée : `none`, `grain`, `dots`), `textureOpacity`,
`shaderId` (liste fermée), `edgeWidth` (1–2 dp). Textures procédurales dans le shader (pas de bitmap).
- **A « Chêne de taverne » (défaut)** : `woodLight` ombré vers `woodMedium`, lumière `goldStart`
  12 %, arêtes `woodDark` 2 dp, chiffre `textOnWood` sur pastille `woodDark` 70 %, grain 20 %.
- **B « Sceau de laiton »** : `parchmentCardAlt`, ombré vers `woodLight` 35 %, accent d'arête
  `goldEnd`, chiffre `textPrimary` sur pastille `parchmentCard` 80 %, points 15 %.
- Contraste chiffre/pastille ≥ 4,5:1 (visé 7:1 pour les skins livrés) ; contrôle automatique prévu
  pour de futurs skins utilisateur (refus ou remplacement par `textPrimary` sur `parchmentCard`).

## Lisibilité
Chiffre en pastille opaque ≥ 70 %, 28 dp (1 chiffre) / 24 dp (2 chiffres) minimum à l'échelle 1,0,
`font.body` 800 (jamais `font.display`), plafonné à ×1,3 car conteneur de taille fixe. 6/9 (et
16/19) soulignés d'un trait de 2 dp. Autres faces : chiffre à 40 % ≥ 14 dp.

## Accessibilité
`disableAnimationsOf` lu au lancer et dans `didChangeDependencies` : pas de controller, pose
immédiate, pas de rebond d'échelle ni de tressautement. Résultat toujours en texte. Feuille
défilable, formule non plafonnée en police. Étiquettes ≥ 11 px. Plateau tapable ≥ 44×44.
Pas de flash > 3 Hz.

## Performance et repli
Cible ≥ 55 fps moyens, aucune frame > 32 ms (`flutter run --profile`, appareil modeste).
Repli niveau 1 : même géométrie en couleurs de sommets (flat shading Dart) si le shader échoue.
Niveau 2 : `_DieFace` actuel statique si le painter lève une erreur. Erreurs journalisées en debug
seulement, jamais affichées ; le tirage et le texte ne sont jamais bloqués. « Mode léger »
dynamique (5 frames > 24 ms) : à décider ultérieurement (non inclus dans le prototype).

## Hors périmètre du prototype
d4/d6/d8/d10/d12/d100, stockage et partage des skins (Supabase, RGPD), choix de skin par
l'utilisateur, réglage in-app « réduire les animations », jeu d'icônes pixel étoile/crâne à
produire (peut être provisoire dans le prototype).

---

# Addendum (11/11/2026) — dé lancé sur la page entière (couche plein écran)

Demande de Matthias après essai sur émulateur : le dé ne doit plus être lancé dans la feuille mais
**sur toute la page**, comme un dé lancé sur le téléphone. Décisions : le dé **reste visible jusqu'à la
fermeture de la feuille** ; hauteur de la feuille **plafonnée à 62 %** de l'écran ; formule/total **20 sp**
(w800) ; **pose immédiate** aussi sous `accessibleNavigation` (comme `disableAnimations`). Défauts retenus :
entrée par le bas, aucun scrim ajouté (barrière native de la feuille), durée 1 400 ms avec saut au tap
(tap = tout l'écran pendant le vol), tap sur le dé posé = rien, pas d'haptique, pas d'indice de saut,
lancer simultané à l'ouverture de la feuille, trait du dé écarté `parchmentCard` 3 dp cerné `woodDark` 1 dp,
badge d'icône sur le dé supprimé (la mention texte + icône de la feuille suffit).

- **Couche** : `OverlayEntry` inséré par la feuille (`Overlay.of(context, rootOverlay: true)`, post-frame
  dans `initState`), retiré dans `dispose` ; builder constant, seuls les painters écoutent le controller ;
  `ExcludeSemantics` ; aucune reconstruction de la fiche ou de la feuille pendant le vol.
- **Table** : écran moins `MediaQuery.paddingOf`, marge 8 dp ; rebonds contre haut/gauche/droite ; centre
  du dé borné par son rayon. **Point de repos** au-dessus de la feuille (haut de la feuille lu une fois
  via `GlobalKey`, après glissement) : x = W/2, y = milieu de la zone libre.
- **Tailles** : 1 dé 176 dp (tablette ≥ 600 dp : 220) ; 2 dés 136 dp chacun (tablette 168), 16 dp d'écart ;
  échelle de vol `1 + 0,25·h`.
- **Trajectoire** (déterministe, `Random` distinct et injectable) : un `AnimationController` 1 400 ms
  (1 520 ms avec 2 dés, second décalé de 120 ms), polyligne de waypoints : entrée par le bas (0–25 %),
  ≥ 2 contacts de bord (~35 % et ~55 %, rebond 55 % de vitesse conservée, 100 % puis 35 % de hauteur),
  roulis amorti jusqu'au repos (70–100 %), dernière rotation vers le quaternion cible, échelle 1→1,04→1.
  Ombre ellipse sous chaque dé (taille et opacité décroissantes avec la hauteur).
- **Feuille** : garde en-tête, sélecteur de mode, formule/détail, ligne mode, bandeau 20/1 naturel,
  « Relancer ». Le slot de 192 dp est supprimé. Pendant le vol, la zone formule/détail/bandeau est
  invisible **mais garde sa place** (`Visibility(maintainSize/maintainState)` + opacité 0), puis fondu 200 ms
  à la pose. Annonce `liveRegion` + `announcer` **une seule fois à la pose** (à déplacer de `initState`/
  `_reroll` vers la fin du vol). Hauteur de feuille `maxHeight = 62 % H`.
- **Pointeurs** : pendant le vol un `GestureDetector(opaque)` plein écran absorbe tout ; un tap = saut à
  l'état posé (jamais fermeture de la feuille) ; après la pose la couche est `IgnorePointer`.
  **Relancer** : nouveau tirage immédiat, dés posés disparaissent (fondu 100 ms), nouveaux dés partent du
  bas ; formule masquée jusqu'à la pose. Changer de mode ne relance pas.
- **Avantage/désavantage** : deux dés côte à côte au repos, étiquettes « Retenu »/« Écarté » sous chaque dé
  (pastille `parchmentCard` 90 %, `font.body` 12 w700, ≥ 11 px, plafond ×1,3, ExcludeSemantics) ;
  dé écarté à 55 % + trait ; halo (`goldStart` 35 % / `accentBrick` 25 %) derrière le dé retenu ; naturel
  jugé sur le dé retenu. Tressautement du 1 ±4 dp/150 ms (supprimé sous animations coupées).
- **Performance** : un `RepaintBoundary` par dé (boîte × 1,25) et par ombre, translation hors boundary ;
  pas de boundary plein écran, pas d'allocation dans `paint`, pas de `saveLayer`.
- **Repli** : shader KO → couleurs de sommets ; painter qui lève ou pas d'`Overlay` → retirer l'entrée et
  réafficher le slot statique `_DieFace` dans la feuille (`_overlayFailed`) ; changement de métriques en vol
  → saut à l'état posé et recalcul du repos.

---

# Addendum 2 (11/11/2026) — dés plus grands, collisions, lancer plus fluide (simulation précalculée)

Décisions de Matthias : tailles de la spec ; arène = **toute la page** (les dés passent par-dessus la
feuille) ; **haptique activé par défaut** ; **saut au tap = glissement doux de 160 ms** vers la pose.
Défauts retenus : départ simultané des deux dés (tolérance ±40 ms), durées 1,6 s (1 dé) / 1,8 s (2 dés),
traînée **désactivée** (à activer seulement si le profil le permet), dés dimensionnés et reposés avec la
feuille à son plafond de 62 % (sans attendre la mesure `GlobalKey`), le dé retenu/écarté peut finir à
gauche ou à droite (les étiquettes suivent le dé). Cette simulation **remplace** la polyligne de
l'addendum 1 (conservée seulement comme repli niveau 0).

## Tailles (D = diamètre visible, S = D / 0,84 = côté nominal ; boîte de dessin 1,25 × S)
H_f = zone libre au repos = (haut de la feuille à 0,38·H − 8) − (inset haut + 8).
- 1 dé : `D1 = min(0,55·W, H_f − 20, 280)` ; 2 dés : `D2 = min(0,45·W, H_f − 36, 240)`, écart 12 dp ;
  plancher D ≥ 96. Plus de test `W >= 600`. Exemples (D1/D2) : 320×568 → 160/144 ; 360×640 → 183/162 ;
  411×891 → 226/185 ; tablette 768×1024 → 280/240.
- Repos : 1 dé centré dans la zone libre ; 2 dés : groupe dé + étiquette (hauteur D + 24) centré.
  Étiquette Retenu/Écarté ancrée à 4 dp sous le bord du dé (`centre + 0,42·S + 4`), plus d'`Alignment(0, 0,94)`.

## Simulation (classe pure Dart `DiceFlightSimulator`, sans Flutter)
Entrées : paramètres d'arène, `Random` injectable (le `flightRandom`), orientations cibles, points de repos.
Sortie : `DiceFlightTrack` immuable (échantillons `Float32List` à 120 Hz : x, y, h, qw, qx, qy, qz par dé
+ liste `ImpactEvent(t, kind {landing, wall, dieDie}, strength)`), calculée **une fois** à l'ouverture / au
relancer ; coût borné (≤ 8 tentatives × ~190 pas, < 1 ms, pas d'isolate). Le contrôleur est **linéaire**
sur la durée T ; le painter lit les échantillons i et i+1 (position lerp, quaternion nlerp), sans
allocation en `paint`. Plan sol : Euler semi-implicite, traînée `c0 = 2,2 s⁻¹`, murs gauche/droite/haut
restitution 0,60 (tangentielle conservée à 90 %), mur bas actif une fois le dé entré. Axe h normalisé :
`h0 = 1,0 (±5 %)`, `g = 14 /s²`, restitution verticale 0,45, ≤ 4 impacts, arrêt si vitesse de rebond < 0,5 ;
`lift_px = 0,28·D·h`, échelle `1 + 0,20·h`. Rotation : `ω = w_roule(h)·0,8·(ẑ×v)/R + ω_culbute(t)`
(`w_roule = 1 − clamp(h/0,15, 0, 1)`, culbute 14 ± 4 rad/s, décroissance `e^(−2t)`, ×0,7 à chaque impact
sol), intégration quaternion normalisée. **Collision dé-dé** : cercles `Rc = 0,94·R`, condition
`|h1 − h2| < 0,2` et `h1, h2 < 0,45`, masses égales, restitution 0,82, correction de position sans
chevauchement, `Δω_z += 0,5·v_t/R`. **Convergence sans snap** : à partir de 0,85 s ressort critique vers le
point de repos (`k = 60`, poids smoothstep sur 0,30 s) ; tri des dés par x au début du ressort ;
orientation : nlerp vers la cible de 0,80 s à `T − 0,25 s` (pose exactement égale à la cible ensuite) ;
graine retenue = celle qui minimise l'angle entre `q_phys(0,80)` et la cible, rejet si > 110°.
**Lancement** : A part en bas à gauche (x0 ≈ 0,28 W), B en bas à droite (0,72 W), sous le bas de la table ;
point de rencontre M = milieu des repos + jitter, impact excentré `b = ±0,35·D`, `t_c = 0,55 ± 0,08 s`,
`v0 = c0·dist / (1 − e^(−c0·t_c))`. 1 dé : visée vers un mur latéral (≥ 1 rebond de mur).
**Acceptation** (≤ 8 tentatives) : ≥ 1 choc dé-dé de `vrel_n ≥ 1,0·D dp/s` entre 0,3 et 1,0 s, ≤ 4 chocs,
≥ 1 contact de mur, distance dé-dé ≥ 1,88·R après le premier contact, pas de NaN. Repli : tentative
canonique symétrique ; si elle échoue aussi → **repli niveau 0** : ancien `DieFlightPlan` polyligne.

## Polish
- Contrôleur `Curves.linear` ; seules courbes = smoothstep du ressort et de l'orientation.
- Squash à chaque impact sol (amplitude `0,06·|vitesse|/5,3`, ≤ 0,06 ; 40 % sur un mur ; décroissance
  `e^(−t/0,04)`) par `canvas.scale` dans le painter.
- Ombre dynamique : ellipse au sol, largeur `1,7·R·(1 − 0,35·h)`, hauteur `0,4·R·(1 − 0,35·h)`, opacité
  `0,2·(1 − 0,6·h)`, décalage latéral `0,06·D·(1 + h)`, `MaskFilter.blur` (σ ≈ 0,05·D) créé une fois
  (repli bord dur si trop coûteux).
- Pose 0,25 s : échelle `1 + 0,045·sin(π·u)`, ombre × 1,15. Fondu du résultat 200 ms sur les 200 derniers ms.
- Saut au tap : interpolation 160 ms de la pose courante vers la pose posée (position easeOutCubic, slerp
  orientation, h → 0) ; supprimé sous `disableAnimations`/`accessibleNavigation` (pose immédiate).
- **Haptique (activée)** : `lightImpact` au 1er impact sol, `mediumImpact` au choc dé-dé, `selectionClick`
  à la pose ; ≤ 4 événements par lancer, ≥ 80 ms d'intervalle ; déclenchés depuis un listener du
  contrôleur à partir de `ImpactEvent` (pas dans `paint`) ; sous `accessibleNavigation` seulement le
  `selectionClick` de pose ; jamais sous `disableAnimations`. Pas de réglage dédié pour l'instant (le
  réglage système de retour haptique s'applique de lui-même) ; réglage « Retour haptique des dés » à
  ajouter plus tard si demandé.
- Traînée : désactivée (itération 1). « Mode léger » (5 frames > 24 ms : couper traînée puis flou) reporté.

## Invariants à tester sur 1 000 graines
Position finale = repos exact (< 0,01 dp) ; quaternion final = cible ; 2 dés : ≥ 1 choc dé-dé et jamais de
chevauchement (distance ≥ 1,88·R) après le premier contact ; pas de NaN ; même graine → même piste ;
impacts ≤ 4 ; vitesse < 12 dp/s à `T − 0,25 s` ; emplacements au repos à ≥ 2·R + 12 ; dés au repos dans
la zone au-dessus de la feuille.
