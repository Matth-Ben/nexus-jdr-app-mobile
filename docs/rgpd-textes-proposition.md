# Proposition de textes RGPD : copie des données des joueurs dans Grimoire (R1)

Proposition rédigée par le chef de projet le 22/11/2026 (décision 40), à relire et valider par Matthias, et par Florian
pour la partie Grimoire, **avant toute mise en ligne**. Avis non juridique : les passages sur la responsabilité sont à
faire valider par un conseil. Registre : `docs/rgpd-registre.md` (R1, R11). La règle de conservation reprend la décision
38 et sera ajustée mot pour mot sur la règle finale de la PR Grimoire « fix/rgpd-cache-nexus ».

**Point d'honnêteté à garder en tête** : Grimoire ne peut effacer une copie que lorsqu'il est lancé. Les formulations
ci-dessous disent donc « au plus tard à son lancement suivant » et « jamais affichée au-delà de 30 jours », pas « effacée
au bout de 30 jours » (le fichier peut rester sur le disque d'un MJ qui ne relance jamais Grimoire).

## 1. Politique de confidentialité de Nexus (`lib/l10n/app_fr.arb`, écran `profile_privacy_policy_screen.dart`)

### Section 1 (`profilePrivacyPolicySection1Para1`), texte proposé
> Cette politique s'applique à l'application mobile Nexus JDR — Personnages (Android) et à l'application web Nexus JDR
> « Histoires » (nexus-jdr.app), qui partagent le même compte. Elle décrit aussi ce qui arrive à tes données quand le MJ
> de ton groupe utilise Grimoire, l'application de bureau des maîtres du jeu (voir section 5).

### Section 5, nouveau paragraphe après `profilePrivacyPolicySection5Para1` (clé proposée `profilePrivacyPolicySection5ParaGrimoire`)
> Si le MJ d'un groupe que tu rejoins utilise Grimoire, l'application de bureau des maîtres du jeu, une copie de ton
> pseudo et d'un résumé de la fiche du personnage que tu rattaches à ce groupe (nom, portrait, race, classes et niveaux,
> points de vie, états, classe d'armure) est conservée sur l'ordinateur du MJ, pour qu'il puisse préparer et mener ses
> parties même sans connexion. Cette copie ne sert qu'à ce groupe : elle n'est ni envoyée ailleurs, ni transmise à un
> service d'intelligence artificielle, ni incluse dans les exports ou les sauvegardes du MJ. Elle est effacée quand tu
> quittes le groupe, quand le groupe est dissous ou détaché de la campagne du MJ, quand le MJ se déconnecte de son compte,
> et elle n'est plus jamais affichée si Grimoire n'a pas pu la mettre à jour depuis 30 jours ; elle est alors effacée au
> plus tard au lancement suivant de Grimoire.

**Règle finale de Grimoire (PR #9, `fix/rgpd-cache-nexus`), source de ces textes** : « Grimoire garde les données des
joueurs de Nexus (pseudo, résumé de fiche, portrait) au plus 30 jours après sa dernière lecture réussie dans DeepCore, et
seulement pour le compte Nexus qui les a lues ; il les efface aussitôt si le groupe est introuvable ou n'appartient plus
au MJ, à la déconnexion, si la session est révoquée ou le compte supprimé, et ne les copie jamais dans ses sauvegardes ni
dans une base reprise. » Réserve : les sauvegardes créées **avant** cette version ne sont pas réécrites (nettoyage unique
ou bouton à décider).

### Section 6 (`profilePrivacyPolicySection6Para1`), texte proposé
> • Compte, contenu de jeu et photos : tant que ton compte existe. Ils sont supprimés définitivement de nos serveurs dès
> que tu supprimes ton compte. Les copies conservées sur l'ordinateur d'un MJ qui utilise Grimoire (voir section 5) sont
> effacées à sa prochaine connexion à Nexus, et ne sont plus jamais affichées au-delà de 30 jours après la suppression.

### Écran de suppression du compte (`profileDeleteAccountWarningMessage`), ajout proposé avant « Cette action ne peut pas être annulée. »
> • Les copies de tes personnages conservées par le MJ de tes groupes dans Grimoire, effacées à sa prochaine connexion
> (au plus tard sous 30 jours d'affichage)

(À reformuler avec `direction-artistique` pour la longueur ; la description de la clé exige de revalider ce texte avec le
chef de projet.)

**Anglais** : traduire à l'identique dans `app_en.arb` (mêmes clés).

## 2. Politique du site (`markdown-editor/apps/web/app/confidentialite/page.tsx`, lignes 137 et 200)

Reprendre les mêmes paragraphes que les sections 5 et 6 ci-dessus (le site et l'app partagent le compte). Le dépôt web
étant gelé, la modification passe par une PR DeepCore dédiée (`dev-backend-supabase` ou le chef de projet pour du
texte seul).

## 3. Texte d'information pour le MJ dans Grimoire (Florian à valider)

À afficher dans l'encart « Groupe » (lien « Données des joueurs ») et dans les conditions de la licence :

> **Données de vos joueurs.** Quand vous associez une campagne à un groupe Nexus, Grimoire conserve sur cet ordinateur une
> copie du pseudo de vos joueurs et d'un résumé de la fiche de leurs personnages (nom, portrait, race, classes et niveaux,
> points de vie, états, classe d'armure), pour vous permettre de jouer même sans connexion. Cette copie n'est jamais
> exportée ni envoyée à l'assistant d'intelligence artificielle. Elle est effacée quand un joueur quitte le groupe, quand
> vous dissociez la campagne, quand vous vous déconnectez de votre compte Nexus, et dès qu'elle n'a pas pu être mise à jour
> depuis 30 jours. Ces données appartiennent à vos joueurs : ne les copiez pas ailleurs. Si vous utilisez Grimoire dans
> un cadre professionnel (parties payantes, association), vous êtes responsable de leur traitement au sens du RGPD.

## 4. Responsabilités (à écrire entre Matthias et Florian, avis d'un conseil recommandé)

Proposition issue de l'avis `rgpd` (recommandation 7) :
- **Matthias**, éditeur de Nexus et de DeepCore : responsable de la communication des données au MJ via
  `api_v1.group_snapshot` et de l'information des joueurs (textes 1 et 2).
- **Florian**, éditeur de Grimoire : ne reçoit jamais ces données, mais son logiciel fixe leur conservation sur la
  machine du MJ. À formaliser (répartition écrite, éventuellement responsabilité conjointe, article 26 du RGPD).
- **Le MJ** : usage entre amis, probablement exemption domestique (article 2.2.c) ; usage professionnel, responsable
  lui-même (clause dans la licence Grimoire, texte 3).
- **Base légale** : exécution du service (article 6.1.b) ; pas de consentement (son retrait imposerait une purge
  difficile à garantir).
