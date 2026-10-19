# Tests d'intégration (`integration_test/`)

## Pourquoi ce dossier existe (et en quoi il diffère de `test_integration/`)

Trois dossiers de tests coexistent dans ce dépôt, volontairement séparés :

- `test/` : tests unitaires/widgets avec doubles factices (`_FakeAuthRepository`...),
  aucun réseau, aucun appareil.
- `test_integration/` : tests **VM purs** (pas d'UI) contre un vrai stack
  Supabase **local** (Postgres/PostgREST/GoTrue via `supabase start` dans le
  dépôt web) — voir `test_integration/README.md`.
- `integration_test/` (ce dossier) : seul dossier qui pilote la **vraie app**
  (`lib/main.dart`) via `WidgetTester`/`IntegrationTestWidgetsFlutterBinding`
  sur un **vrai appareil/émulateur**, contre le projet Supabase **distant**
  partagé dev/staging/prod (pas de stack local séparé pour le contenu de
  référence, voir `config/README.md`). C'est le seul niveau qui détecte une
  régression dans l'assemblage réel écran ↔ provider ↔ repository ↔ Supabase
  distant ↔ rendu, ou un contenu de référence corrigé en base qui ne
  remonte pas correctement jusqu'à l'écran.

## Lancer les tests

```bash
flutter test integration_test/login_screen_test.dart -d emulator-5554 \
  --flavor dev \
  --dart-define-from-file=config/dev.json
```

(ou tout autre appareil retourné par `flutter devices`). `config/dev.json`
pointe vers le projet Supabase distant partagé dev/staging/prod — voir
`config/README.md`. **`--flavor dev` est obligatoire sur Android** (sinon
l'app ne trouve pas sa configuration de flavor au lancement).

### Scénarios authentifiés : compte de test requis

Tout scénario qui a besoin d'une session (fiche personnage, assistant de
création, montée de niveau, multiclassage, races...) a besoin d'un compte
**déjà confirmé** : la confirmation par e-mail est activée sur ce projet
Supabase (voir la doc de classe d'`AuthRepository.signUp`,
`lib/features/auth/data/auth_repository.dart`), donc un `signUp` automatisé
depuis ce dossier ne reçoit jamais de session (personne pour cliquer le lien
de confirmation reçu par e-mail) — contrairement à `test_integration/`, qui
tourne contre un stack **local** où cette confirmation est désactivée
(`supabase/config.toml` côté dépôt web).

Pour débloquer ces scénarios :

1. Créer une fois, manuellement, un compte de test dédié (inscription réelle
   depuis l'app ou le web, puis clic sur le lien de confirmation reçu par
   e-mail) — un e-mail du type `qa-mobile+test@<domaine>` plutôt qu'un
   compte personnel, pour ne pas mélanger les personnages de test avec de
   vraies données.
2. Renseigner ses identifiants dans `config/qa_test_account.json` (**jamais
   committé** — à ajouter à `.gitignore` comme les autres fichiers de
   `config/`) :

   ```json
   {
     "QA_TEST_EMAIL": "...",
     "QA_TEST_PASSWORD": "..."
   }
   ```

3. Lancer avec les deux fichiers de `--dart-define-from-file` :

   ```bash
   flutter test integration_test/<fichier>.dart -d emulator-5554 \
     --dart-define-from-file=config/dev.json \
     --dart-define-from-file=config/qa_test_account.json
   ```

Tant que ce compte n'est pas configuré, les tests qui en dépendent se
`skip`-ent explicitement (voir `integration_test/support/qa_test_account.dart::hasQaTestAccount`)
plutôt que d'échouer avec une erreur réseau opaque.

## Données de test laissées en base

Ce dossier parle au projet Supabase **distant partagé** dev/staging/prod —
contrairement à `test_integration/` (stack local jetable), les données
créées ici persistent réellement :

- `login_screen_test.dart` crée un utilisateur Auth **non confirmé** à
  chaque exécution de son test d'inscription (e-mail `@nexus-jdr.test`,
  horodaté, jamais réutilisé) — jamais de session, donc jamais de
  personnage créé ; seule la ligne `auth.users` reste (nettoyage périodique
  à la charge de `dev-backend-supabase`, même limite que `test_integration/`
  avec la clé anon — pas d'accès à l'API admin GoTrue pour la supprimer
  depuis ici).
- Tout scénario authentifié qui crée un personnage de test doit le
  supprimer en fin de test (`addTearDown`), même règle que
  `test_integration/`.

## Sélecteurs

Toujours par texte/type/clé — **jamais** par coordonnées d'écran
(`tester.tapAt(Offset(...))`). Beaucoup d'écrans de ce dépôt ne posent pas de
`Key` dédiée sur leurs champs (vérifié par lecture du code au moment
d'écrire chaque test) : le sélecteur de repli documenté est alors
`find.byType(...).at(index)`, avec un commentaire renvoyant au fichier
source lu pour établir cet ordre — à re-vérifier si l'écran change de
disposition.

## État de couverture (voir le compte-rendu QA correspondant)

- `login_screen_test.dart` : exécuté avec succès sur `emulator-5554` contre
  le projet distant — écran de connexion (vide/erreurs de validation,
  bascule connexion/inscription, un vrai `signUp` jetable jusqu'à l'état
  "vérifiez vos e-mails").
- Scénarios authentifiés (création des 13 classes, montée de niveau sur le
  contenu corrigé, races, multiclassage) : **non exécutés**, bloqués par
  l'absence d'un compte de test confirmé (voir ci-dessus) — à reprendre une
  fois `config/qa_test_account.json` renseigné.
