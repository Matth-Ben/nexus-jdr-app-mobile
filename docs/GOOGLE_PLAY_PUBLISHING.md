# Publier sur le Google Play Store

Checklist complète, de zéro jusqu'à la première publication, puis comment
automatiser les publications suivantes via `.github/workflows/release-android.yml`.
Contexte complet dans `docs/cahier-des-charges/13-depot-versioning-publication.md`
section 4.

## 1. Compte développeur Google Play

1. Va sur [play.google.com/console](https://play.google.com/console/) et
   crée un compte développeur (paiement unique, ~25 $).
2. La validation d'identité peut prendre un jour ou deux — à lancer tôt.

## 2. Créer l'app dans la Play Console

1. "Créer une application" → nom "Nexus JDR — Personnages", langue par
   défaut français, catégorie "Jeux de rôle" ou "Outils" selon ce qui
   correspond le mieux.
2. Le **nom de package doit être exactement** `com.nexusjdr.personnages`
   (celui déjà configuré dans `android/app/build.gradle.kts` — irréversible
   une fois le premier .aab uploadé, ne peut jamais changer).

## 3. Ce qu'il faut préparer AVANT de pouvoir soumettre (fiche store)

Play Console bloque la publication tant que ces éléments ne sont pas
renseignés :

- **Icône de l'app** (512×512, PNG) et **image de présentation** (1024×500) —
  pas encore générées à ce stade (`13-depot-versioning-publication.md`
  recommande `flutter_launcher_icons` une fois la maquette validée).
- **Captures d'écran** : au moins 2 par format d'appareil pris en charge
  (téléphone obligatoire, tablette recommandé).
- **Description courte** (80 caractères) et **description complète**
  (4000 caractères).
- **Politique de confidentialité** : obligatoire dès que l'app gère un
  compte utilisateur et des photos (portraits de personnages) — une page
  web publique doit exister et son URL être renseignée dans la fiche.
  **Rien n'existe encore pour ça** — à écrire et héberger (peut être une
  simple page statique sur le domaine `nexus-jdr.app` déjà déployé, ou un
  Google Doc public en dépannage).
- **Formulaire "Data safety"** : liste précise des données collectées
  (email, mot de passe via Supabase Auth, photos de portrait) et pourquoi —
  à préparer en s'appuyant sur `docs/cahier-des-charges/02-modele-donnees.md`
  plutôt qu'à improviser au moment de soumettre.
- **Questionnaire de classification du contenu** (violence, etc. — D&D
  contient de la fantasy violence légère, répondre en conséquence).
- **Catégorie de l'app** et **coordonnées de contact** (email support).

## 4. Premier envoi — manuel, obligatoire

La toute première version doit être uploadée **à la main** via l'interface
web de Play Console (impossible de créer une fiche d'app par API avant
qu'elle existe) :

1. Générer un app bundle signé localement :
   ```bash
   flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json -t lib/main.dart
   ```
   (nécessite `android/key.properties` rempli avec le keystore de
   production — voir section suivante si pas encore fait).
2. Dans Play Console : Production → Créer une version (ou commencer par la
   piste "Test interne", recommandé pour un premier essai) → uploader
   `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.
3. Remplir les notes de version, valider.
4. Une fois cette première version acceptée, le reste peut être automatisé.

## 5. Automatiser les publications suivantes (`release-android.yml`)

Le workflow `.github/workflows/release-android.yml` build déjà un .aab
signé et le joint à une Release GitHub à chaque tag `v*` — il ne l'envoie
**pas encore** à Play Console automatiquement. Pour ajouter cette étape une
fois la fiche créée (section 2-4 ci-dessus faites) :

1. Dans Play Console : Utilisateurs et autorisations → Inviter un nouvel
   utilisateur → créer un **compte de service** ("API access" en bas de
   page renvoie vers Google Cloud Console pour le créer).
2. Dans Google Cloud Console, sur ce compte de service : générer une clé
   JSON, la télécharger.
3. Dans Play Console, donner à ce compte de service la permission
   "Release manager" (ou plus large) sur l'app `com.nexusjdr.personnages`.
4. Ajouter le **contenu entier de ce fichier JSON** comme secret GitHub
   `PLAY_SERVICE_ACCOUNT_JSON` (voir section 6 ci-dessous pour comment
   ajouter un secret).
5. Ajouter à `release-android.yml`, après l'étape "Publie une Release
   GitHub", une étape utilisant l'action
   [`r0adkll/upload-google-play`](https://github.com/r0adkll/upload-google-play) :
   ```yaml
   - name: Upload sur Google Play (piste interne)
     uses: r0adkll/upload-google-play@v1
     with:
       serviceAccountJsonPlainText: ${{ secrets.PLAY_SERVICE_ACCOUNT_JSON }}
       packageName: com.nexusjdr.personnages
       releaseFiles: build/app/outputs/bundle/prodRelease/app-prod-release.aab
       track: internal
   ```
   Passer `track: production` une fois confiant dans le processus (ou
   promouvoir manuellement depuis la Play Console, plus prudent au début).

## 6. Secrets GitHub à configurer pour que `release-android.yml` fonctionne

**Fait le 2026-09-01** — rangés dans un **Environment** GitHub nommé `PROD`
(Settings → Environments → PROD → Environment secrets), pas en secrets de
dépôt classiques. Le job `build-and-release` de `release-android.yml`
déclare `environment: PROD` pour y avoir accès — si tu renommes ou recrées
cet environnement, pense à mettre à jour cette ligne dans le workflow.

Pour PowerShell, générer le contenu de `ANDROID_KEYSTORE_BASE64` (copié
directement dans le presse-papier, jamais collé dans une conversation) :
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("chemin\complet\vers\nexus-jdr-release.jks")) | Set-Clipboard
```

| Secret | Contenu |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Contenu binaire de `android/nexus-jdr-release.jks` encodé en base64 (voir commande PowerShell ci-dessus, ou `base64 -w0 android/nexus-jdr-release.jks` sous Linux/macOS) |
| `ANDROID_KEYSTORE_PASSWORD` | Le mot de passe du keystore (`android/key.properties`, `storePassword`) |
| `ANDROID_KEY_PASSWORD` | Le mot de passe de la clé (`android/key.properties`, `keyPassword`) |
| `PROD_CONFIG_JSON` | Contenu entier de `config/prod.json` (actuellement identique à `config/dev.json`, voir `config/README.md`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | Une fois la section 5 faite : contenu entier de la clé JSON du compte de service |

Sans ces secrets, `release-android.yml` échoue à l'étape de signature —
c'est attendu tant qu'ils ne sont pas configurés, le workflow ne fera rien
de nuisible en leur absence (il échoue proprement).

## État au 2026-09-01

- [x] Keystore Android de production généré et testé (`android/key.properties`
      local, jamais commité).
- [x] Workflows CI (`ci.yml`) et Release Android (`release-android.yml`) en
      place.
- [x] Les 4 secrets Android/Supabase (hors `PLAY_SERVICE_ACCOUNT_JSON`)
      configurés dans l'environnement GitHub `PROD`.
- [ ] Compte développeur Google Play pas encore créé.
- [ ] Fiche store (icône, captures, description, politique de
      confidentialité, data safety) pas encore préparée.
- [ ] Premier upload manuel pas encore fait.
- [ ] Compte de service Play (pour l'automatisation complète) pas encore
      créé — dépend du point précédent.
