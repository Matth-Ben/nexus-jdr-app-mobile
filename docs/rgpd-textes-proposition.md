# Proposition de textes RGPD : copie des données des joueurs dans Grimoire (R1)

Proposition rédigée par le chef de projet le 22/11/2026 (décision 40), corrigée le même jour après la revue de l'agent
`rgpd`. À relire et valider par Matthias, et par Florian pour la partie Grimoire, **avant toute mise en ligne**. Avis non
juridique : les passages sur la responsabilité sont à faire valider par un conseil. Registre : `docs/rgpd-registre.md`.

## Règle de conservation (source de tous les textes, formulation exacte)

Grimoire (PR #9, `fix/rgpd-cache-nexus`) garde les données des joueurs de Nexus (pseudo, résumé de fiche, portrait)
**seulement pour le compte Nexus qui les a lues**. Il **ne les affiche plus jamais au-delà de 30 jours** après sa dernière
lecture réussie dans DeepCore, et les **efface au plus tard au lancement suivant**. Il les efface **dès qu'il constate**,
ouvert et connecté, le départ d'un joueur, la dissolution ou la dissociation du groupe, ou que le groupe n'appartient plus
au MJ ; il les efface aussi à la déconnexion, à la révocation de la session et à la suppression du compte du MJ. Il n'en
garde rien dans **ses** sauvegardes ni dans une base reprise (celles des versions précédentes en sont vidées au démarrage).

Limites à ne pas taire : un fichier reste sur le disque d'un MJ qui ne relance plus Grimoire ou le désinstalle (R10) ; les
sauvegardes du système (Time Machine, profil itinérant) échappent à Grimoire ; les liens héros ↔ personnage
(identifiants) d'une base de compte qui n'est plus jamais rouverte ne sont pas purgés (R12) ; tolérance d'un jour sur
l'horloge.

## 1. Politique de confidentialité de Nexus (`lib/l10n/app_fr.arb`, écran `profile_privacy_policy_screen.dart`)

### Section 1 (`profilePrivacyPolicySection1Para1`)
> Cette politique s'applique à l'application mobile Nexus JDR — Personnages (Android) et à l'application web Nexus JDR
> « Histoires » (nexus-jdr.app), qui partagent le même compte. Elle décrit aussi ce qui arrive à tes données quand le MJ
> de ton groupe utilise Grimoire, l'application de bureau des maîtres du jeu (voir section 5).

### Section 1 (`profilePrivacyPolicySection1Para2`), précision sur le responsable
> Responsable du traitement : Matthias Benoit, éditeur de Nexus JDR, y compris pour la communication de tes données au MJ
> de ton groupe quand celui-ci utilise Grimoire. Contact : support@nexus-jdr.app.

(À confirmer avec le conseil et Florian : répartition des rôles avec l'éditeur de Grimoire, voir section 4 ci-dessous.)

### Section 4 (base légale), ajout au premier point
> … c'est nécessaire à l'exécution du service que tu utilises, y compris la copie décrite en section 5, qui permet à ton
> MJ de mener la partie même sans connexion.

### Section 5, nouveau paragraphe après `profilePrivacyPolicySection5Para1` (clé proposée `profilePrivacyPolicySection5ParaGrimoire`)
> Si le propriétaire d'un groupe que tu rejoins (en général le MJ, même s'il a quitté le groupe) utilise Grimoire,
> l'application de bureau des maîtres du jeu, une copie de ton pseudo et d'un résumé de la fiche du personnage que tu
> rattaches à ce groupe (nom, portrait, race, classes et niveaux, points de vie, état « mort », états, classe d'armure) est
> conservée sur son ordinateur, pour qu'il puisse préparer et mener ses parties même sans connexion. Cette copie ne sert
> qu'à ce groupe : elle n'est ni envoyée ailleurs, ni transmise à un service d'intelligence artificielle, ni incluse dans
> les exports ni dans les sauvegardes de Grimoire. Elle est effacée dès que Grimoire, ouvert et connecté, constate ton
> départ, la dissolution du groupe ou sa dissociation de la campagne, ou quand le MJ se déconnecte de son compte. Elle
> n'est plus jamais affichée si Grimoire n'a pas pu la mettre à jour depuis 30 jours, et elle est alors effacée au plus
> tard au lancement suivant de Grimoire.

### Section 6 (`profilePrivacyPolicySection6Para1`)
> • Compte, contenu de jeu et photos : tant que ton compte existe. Ils sont supprimés définitivement de nos serveurs dès
> que tu supprimes ton compte. Les copies conservées sur l'ordinateur d'un MJ qui utilise Grimoire (voir section 5) sont
> effacées dès la prochaine synchronisation de Grimoire ; elles ne sont jamais affichées plus de 30 jours après et sont
> effacées au plus tard au lancement suivant.

### Section 7 (droits), ajout
> Pour faire effacer la copie conservée par le MJ dans Grimoire, quitte le groupe ou supprime ton compte : elle est effacée
> dans les conditions décrites en section 5.

### Section 8 (sécurité)
À ne pas modifier tant que R5 n'est pas corrigé : la section est aujourd'hui contredite par le bucket des portraits
public et listable. Corriger R5 avant la mise en ligne.

### Écran de suppression du compte (`profileDeleteAccountWarningMessage`), ajout avant « Cette action ne peut pas être annulée. »
> • Les copies de tes personnages conservées par le MJ de tes groupes dans Grimoire, effacées dès sa prochaine
> synchronisation

(À reformuler avec `direction-artistique` pour la longueur ; la description de la clé exige de revalider ce texte avec le
chef de projet.)

**Anglais** : traduire à l'identique dans `app_en.arb` (mêmes clés).

## 2. Politique du site (`markdown-editor/apps/web/app/confidentialite/page.tsx`, lignes 137 et 200)

Reprendre les mêmes ajouts (sections 1, 4, 5, 6, 7). Le dépôt web étant gelé, la modification passe par une PR DeepCore
dédiée (texte seul).

## 3. Texte d'information pour le MJ dans Grimoire (Florian à valider)

À afficher dans l'encart « Groupe » (lien « Données des joueurs ») et dans les conditions de la licence :

> **Données de vos joueurs.** Quand vous associez une campagne à un groupe Nexus, Grimoire conserve sur cet ordinateur une
> copie du pseudo de vos joueurs et d'un résumé de la fiche de leurs personnages (nom, portrait, race, classes et niveaux,
> points de vie, état « mort », états, classe d'armure), pour vous permettre de jouer même sans connexion. Cette copie
> n'est jamais exportée, jamais envoyée à l'assistant d'intelligence artificielle et jamais gardée dans les sauvegardes de
> Grimoire. Elle est effacée à la synchronisation suivante quand un joueur quitte le groupe ou quand le groupe est dissous,
> quand vous dissociez la campagne ou vous déconnectez de votre compte Nexus, et elle n'est plus affichée si elle n'a pas
> pu être mise à jour depuis 30 jours. Désinstaller Grimoire n'efface pas ces données : utilisez la déconnexion avant.
> Ces données appartiennent à vos joueurs : ne les copiez pas ailleurs. Si vous utilisez Grimoire dans un cadre
> professionnel (parties payantes, association), vous êtes responsable de leur traitement au sens du RGPD.

## 4. Responsabilités (à écrire entre Matthias et Florian, avis d'un conseil recommandé)

- **Matthias**, éditeur de Nexus et de DeepCore : responsable de la communication des données au MJ via
  `api_v1.group_snapshot` et de l'information des joueurs (textes 1 et 2). **À nommer dans les textes (bloquant).**
- **Florian**, éditeur de Grimoire : ne reçoit jamais ces données, mais son logiciel fixe leur conservation sur la
  machine du MJ. À formaliser (répartition écrite, éventuellement responsabilité conjointe, article 26 du RGPD).
- **Le MJ** : usage entre amis, probablement exemption domestique (article 2.2.c) ; usage professionnel, responsable
  lui-même (clause dans la licence Grimoire, texte 3).
- **Base légale** : exécution du service (article 6.1.b) ; pas de consentement (son retrait imposerait une purge
  difficile à garantir).
- **À faire valider par le conseil** : un MJ établi hors de l'Union européenne constituerait un transfert hors UE.
