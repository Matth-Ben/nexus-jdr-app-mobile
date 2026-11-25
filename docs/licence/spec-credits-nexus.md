# Spec : mentions de licence de Nexus (licence étape 1, décision 79)

Rédigée par `direction-artistique` le 25/11/2026 (lecture seule), arbitrages du chef de projet en fin de document.
Ticket : « Licence étape 1 (Nexus) : écran Crédits et mentions de licence exactes ».

**Sources** : `profile_credits_screen.dart`, `profile_help_screen.dart:178`, `profile_legal_screen.dart:56`,
`lib/core/widgets/legal_section_block.dart`, `app_fr.arb` / `app_en.arb`, `10-design-system.md` §1, 3 et accessibilité,
`docs/licence/registre-licence-contenu.md`, contrat DeepCore `docs/api-v1/contrat-bestiaire-catalogue.md` l. 100-160
(lisible dans `H:/Projets/Labo/markdown-editor`, branche `main`). Aucune maquette ne couvre l'écran Crédits : gabarit
« texte légal long » existant. Le module profil **tutoie** ; tous les textes ci-dessous sont impersonnels.

## 1. Écran Crédits, section « Contenu de jeu »

Écran parchemin inchangé (`WoodBackHeader`, corps `color.parchment.bg` défilant), contenu statique (aucun état de
chargement, d'erreur ou hors ligne).

Ordre dans le `SingleChildScrollView` (`padding: AppSpacing.lg`) :

1. `LegalSectionBlock` : titre `profileCreditsGameContentTitle` (inchangé), un paragraphe `profileCreditsGameContentPara1`
   (nouveau texte).
2. `SizedBox(AppSpacing.md)`.
3. Cadre **SRD 5.1**, `SizedBox(AppSpacing.sm)`, cadre **SRD 5.2**. (Pas de cadre SRD 5.2.1 : voir arbitrages.)
4. `SizedBox(AppSpacing.md)`.
5. `Text(profileCreditsNonSrdContent)`, `SizedBox(AppSpacing.sm)`, `Text(profileCreditsGameContentPara2)` (marque), au
   style exact des paragraphes de `LegalSectionBlock` : `AppTypography.body(fontSize: 13, color: AppColors.textPrimary)`.
   Ne pas modifier `LegalSectionBlock` (partagé par trois écrans).
6. Le reste ne change pas (`_SectionDivider`, Polices, Bibliothèques, date).

**Cadre d'attribution** : réutiliser `_LicenseNoticeBox`, renommé par exemple
`_SrdAttributionBox(label, attribution, modified, attributionLocale)`.
- Décoration inchangée : `AppColors.parchmentCardAlt`, bordure 1 px `AppColors.woodLight`
  (`AppBorders.cardEmphasisHalo`), coins `AppRadius.md`, marge intérieure `AppSpacing.md` ; ajouter
  `width: double.infinity` (cadres de même largeur).
- Contenu en `Column(crossAxisAlignment: start)` : libellé en `body` 12 px / 700 `textPrimary` ; `SizedBox(xs)` ;
  déclaration en `body` 12 px / 400 `textSecondary` ; `SizedBox(sm)` ; `Text.rich` = `profileCreditsModifiedPrefix`
  (12 px / 700 `textSecondary`) + ligne « Modifié » (12 px / 400 `textSecondary`).
- Pas de `Material` ni d'`InkWell` (non interactif) ; envelopper dans `Semantics(container: true)`.
- **Jamais `textMuted` dans le cadre** (4,41:1 sur `parchmentCardAlt`, échec AA) ; `textSecondary` = 6,5:1.

**Liens** : URL **non cliquables**, dans le texte officiel recopié mot pour mot (zone de tap < 44 px interdite par le
DS ; CC BY accepte une adresse en clair). Envelopper la `Column` du corps dans un `SelectionArea` (appui long pour copier).

**Langue pour le lecteur d'écran** : une déclaration qui n'est pas dans la langue de l'interface s'affiche avec
`Text.rich(TextSpan(text: …, locale: Locale('en' | 'fr')))`.

**Textes longs** : pas de `maxLines`, pas d'ellipse, pas de hauteur fixe. Vérifier l'absence de débordement à 320 dp de
large avec `textScaler` 2,0 (portrait seulement).

**À supprimer** : la clé `profileCreditsLicenseNotice` (mentionne open5e) des deux .arb et du code. Mettre à jour
`profileCreditsLastUpdated` et `profileLegalLastUpdated` : « 25 novembre 2026 » (format des clés existantes, FR et EN).

## 2. Textes exacts

Les déclarations d'attribution se **recopient mot pour mot depuis le contrat DeepCore**, jamais depuis ce document ni en
les reformulant. Dans chaque `@description` : « texte officiel de Wizards, recopié mot pour mot du contrat DeepCore
`docs/api-v1/contrat-bestiaire-catalogue.md` l. X ; ne jamais traduire ni reformuler ». Dans l'.arb anglais, échapper
les guillemets droits (`\"`) ; les guillemets courbes (“ ”) et les chevrons (« ») ne s'échappent pas.

| Clé | FR | EN |
|---|---|---|
| `profileCreditsGameContentPara1` | Une partie du contenu de règles utilisé par Nexus JDR provient du System Reference Document (SRD), publié sous licence Creative Commons Attribution 4.0 International (CC BY 4.0). Voici les déclarations d'attribution correspondantes et les modifications apportées. | Part of the rules content used by Nexus JDR comes from the System Reference Document (SRD), published under the Creative Commons Attribution 4.0 International license (CC BY 4.0). The corresponding attribution statements and the changes made are listed below. |
| `profileCreditsModifiedPrefix` | `Modifié\u00a0: ` | `Modified: ` |
| `profileCreditsSrd51Label` | SRD 5.1 (règles 2014) | SRD 5.1 (2014 rules) |
| `profileCreditsSrd51Attribution` | contrat l. 108-111 (FR officielle) | contrat l. 115-117 (EN officielle) |
| `profileCreditsSrd51Modified` | textes repris en tout ou en partie du SRD 5.1 français, ou traduits du SRD 5.1 anglais (traduction non officielle) et parfois résumés ; certains noms diffèrent de la traduction officielle ; poids et distances exprimés en kilogrammes et en mètres ; contenu réparti en champs et présentation adaptée à l'application. | text taken in whole or in part from the French SRD 5.1, or translated into French from the English SRD 5.1 (unofficial translation) and sometimes summarized; some names differ from the official French translation; weights and distances given in kilograms and meters; content split into fields and presentation adapted to the app. |
| `profileCreditsSrd52Label` | SRD 5.2 (règles 2024, déclaration en anglais) | SRD 5.2 (2024 rules) |
| `profileCreditsSrd52Attribution` | contrat l. 141-143 (EN, telle quelle, `locale: en`) | contrat l. 141-143 |
| `profileCreditsSrd52Modified` | traduit de l'anglais en français (traduction non officielle), parfois résumé ; distances et poids convertis en mètres et en kilogrammes ; contenu réparti en champs et présentation adaptée à l'application. | translated from English into French (unofficial translation), sometimes summarized; distances and weights converted to meters and kilograms; content split into fields and presentation adapted to the app. |
| `profileCreditsNonSrdContent` **(PROVISOIRE)** | Une partie du contenu de jeu de Nexus JDR ne fait pas partie du SRD (notamment de nombreux sorts, sous-classes, dons, historiques, races et options de classe). Ce contenu n'est pas couvert par la licence Creative Commons Attribution 4.0 citée ci-dessus. | Some of the game content in Nexus JDR is not part of the SRD (including many spells, subclasses, feats, backgrounds, races and class options). This content is not covered by the Creative Commons Attribution 4.0 license cited above. |
| `profileCreditsGameContentPara2` **(PROVISOIRE)** | Donjons & Dragons et D&D sont des marques de Wizards of the Coast LLC. Nexus JDR n'est ni affilié à Wizards of the Coast, ni approuvé par cette société. | Dungeons & Dragons and D&D are trademarks of Wizards of the Coast LLC. Nexus JDR is not affiliated with or endorsed by Wizards of the Coast. |
| `profileHelpAboutFooterNote` | Une partie du contenu de jeu provient du SRD (CC BY 4.0). Détail des sources et des attributions dans « Crédits & licences ». | Part of the game content comes from the SRD (CC BY 4.0). Sources and attributions are detailed in \"Credits & licenses\". |
| `profileLegalIntellectualPropertyPara1` (fin **PROVISOIRE**) | Une partie du contenu de règles de Donjons & Dragons 5e provient du System Reference Document (SRD 5.1 et 5.2), sous licence Creative Commons Attribution 4.0 International (CC BY 4.0) ; le reste du contenu de jeu n'est pas issu du SRD et n'est pas couvert par cette licence. Les déclarations d'attribution et les modifications apportées figurent dans « Crédits & licences ». Le code, le design et la marque « Nexus JDR » appartiennent à l'éditeur de l'application. | Part of the Dungeons & Dragons 5e rules content comes from the System Reference Document (SRD 5.1 and 5.2), under the Creative Commons Attribution 4.0 International license (CC BY 4.0); the rest of the game content is not from the SRD and is not covered by this license. Attribution statements and the changes made are listed in \"Credits & licenses\". The code, design and the \"Nexus JDR\" brand belong to the app's publisher. |

**Tests à mettre à jour** : `test/features/profile/presentation/profile_credits_screen_test.dart:114-139` (la recherche
du cadre par `DecoratedBox` en trouve maintenant deux), `profile_help_screen_test.dart:365` ; vérifier qu'aucun .arb ne
contient plus « open5e » (insensible à la casse).

## 3. Arbitrages du chef de projet (25/11/2026)

1. **SRD 5.2 dans l'app en français** : déclaration anglaise telle quelle (`locale: en`), signalée par le libellé, comme
   Grimoire ; pas de traduction.
2. **SRD 5.2.1** : **pas de cadre pour l'instant**. Nexus n'affiche encore aucun texte issu du SRD 5.2.1 (objets 2024 :
   traduction du 5.2 anglais ; monstres : Grimoire seulement) ; la ligne « Modifié » serait fausse. Le cadre (déclaration
   FR du contrat l. 153-155, ligne « Modifié » adaptée) sera ajouté par la première PR de l'étape 2 qui introduit du texte
   du SRD 5.2.1. Le texte « SRD 5.1 et 5.2 » des mentions légales sera alors complété.
3. **SRD 5.1** : une déclaration par langue de l'interface (FR officielle en français, EN officielle en anglais).
4. **Textes provisoires** (`profileCreditsNonSrdContent`, `profileCreditsGameContentPara2`, fin de
   `profileLegalIntellectualPropertyPara1`) : neutres, à faire valider par Matthias au merge, et par le conseil (dossier
   §6, questions 4 et 6 ; le SRD demande de n'ajouter aucune autre attribution à Wizards que sa déclaration). La phrase de
   marque existe déjà en production ; elle perd seulement la mention des logos.
5. **Lignes « Modifié »** : à relire à chaque PR des étapes 2 et 3 (dette D258).
