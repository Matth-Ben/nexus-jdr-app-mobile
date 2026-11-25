# Dossier pour un conseil : licence du contenu de jeu de Nexus, Grimoire et la Bibliothèque

Préparé par le chef de projet le 25/11/2026 (décision 81). Document factuel : il ne contient **aucun avis juridique** ; il
expose la situation et les questions à trancher. Détail complet : `docs/licence/registre-licence-contenu.md` (audit en
lecture seule du 25/11/2026, 2 567 éléments).

## 1. Les produits

| Produit | Nature | Public | Modèle économique |
|---|---|---|---|
| **Nexus** | app mobile (Android, iOS à venir) de fiches de personnage pour Donjons & Dragons 5e | joueurs | gratuit |
| **Grimoire** | logiciel de bureau du maître du jeu (MJ) | MJ | version d'essai gratuite, licence payante prévue |
| **Bibliothèque** | site web public de consultation des règles | tout public, **sans connexion** | gratuit |
| **DeepCore** | base de données commune (Supabase) qui sert le contenu aux trois | — | — |

Le contenu de jeu (races, classes, sous-classes, dons, sorts, invocations, historiques, objets, monstres) est stocké dans
DeepCore, en français (et partiellement en anglais), et affiché par les trois produits.

## 2. Le cadre de licence connu

- Wizards of the Coast publie le **System Reference Document** (SRD 5.1, règles 2014, et SRD 5.2 / 5.2.1, règles 2024)
  sous **Creative Commons Attribution 4.0 (CC BY 4.0)**, en anglais et en français : réutilisation, y compris
  commerciale, avec attribution et indication des modifications.
- Le reste du contenu des livres (Manuel des Joueurs complet, Guide de Xanathar, Chaudron de Tasha, Monstres du
  Multivers, Eberron, etc.) **n'est pas sous licence libre**.
- Le PDF du SRD 5.1 français porte la mention CC BY 4.0 en page 1, mais un pied de page « Interdit à la revente… usage
  personnel » (décision 71 : nous nous appuyons sur la page 1).

## 3. Ce qui a déjà été mis en conformité

- **Monstres** : uniquement le SRD 5.1 et le SRD 5.2 (648 monstres), avec attribution et mention « Modifié ».
- **Objets** : textes 2014 remplacés par le SRD 5.1 (25/11/2026) ; objets 2024 issus du SRD 5.2.
- **Grimoire** (produit payant) n'affiche, du contenu non SRD, que des **noms** (race, classe, sous-classe d'un
  personnage) ; son bestiaire et son catalogue sont strictement SRD.
- **En cours (décisions 79-80)** : retrait de 157 textes anglais copiés mot pour mot des livres ; correction des
  mentions de licence ; remplacement par le texte officiel du SRD des éléments présents au SRD.

## 4. Ce qui reste hors SRD (objet de ce dossier)

| Type | Éléments hors SRD | Texte français concerné (caractères) |
|---|---:|---:|
| Races et sous-races (traits) | 26 races, 11 sous-races | 21 886 |
| Lignées | 9 | 3 653 |
| Sous-classes et leurs aptitudes | 109 sous-classes, 697 aptitudes | 125 573 |
| Options de classe (manœuvres, disciplines, runes…) | 76 | 12 346 |
| Dons | 103 | 41 251 |
| Invocations | 17 | 5 162 |
| Historiques | 67 | 19 337 |
| Sorts | 174 | 24 861 |
| **Total** | **1 307 éléments** | **≈ 257 000** |

**Nature des textes** : d'après les en-têtes des migrations, ce sont des **reformulations** des mécaniques (pas des
copies), à l'exception de **420 descriptions françaises de sorts reprises d'aidedd.org** (site tiers : 265 sorts du SRD,
14 homonymes, 141 hors SRD). La source de certaines sous-classes et historiques est un fichier `CodexArcanum_V2.html`
d'origine à préciser. Les **noms** des éléments (« Maître de guerre », « Lame maudite »…) sont ceux des livres.

**Exposition** : lus par Nexus (joueurs connectés), affichés **sans connexion** par la Bibliothèque web, et lisibles par
n'importe qui avec la clé publique de l'API.

**Usage réel** (production, 25/11/2026) : 14 personnages ; 8 utilisent au moins une sous-classe hors SRD ; 1 un don hors
SRD ; 11 sorts hors SRD utilisés ; la plupart des historiques utilisés sont hors SRD. Plusieurs noms hors SRD sont codés
en dur dans Nexus pour des calculs (PV, arme de pacte, dés de supériorité…).

## 5. Options envisagées par l'équipe

| Option | Principe |
|---|---|
| **A. Nom + résumé mécanique neutre** | garder le nom, réécrire chaque texte en un résumé factuel des effets (chiffres, portées, durées), sans reprendre l'expression des livres ni d'aidedd |
| **B. Retrait de la lecture publique** | réserver ce contenu aux joueurs connectés (retirer de la Bibliothèque sans connexion et de l'accès anonyme) |
| **C. Masquage à la création** | conserver ce contenu pour les personnages existants, mais ne plus le proposer aux nouveaux |
| **D. Statu quo** | risque assumé, documenté |

Contrainte technique : aucune ligne utilisée ne peut être supprimée sans casser des personnages ; un masquage est
possible.

## 6. Questions au conseil

1. Un **nom** d'élément de jeu (sous-classe, don, sort, historique) repris d'un livre est-il utilisable librement, seul ?
2. L'option **A** (nom + résumé mécanique neutre, rédigé par nous) suffit-elle pour :
   a) une app gratuite pour joueurs connectés (Nexus) ;
   b) un site public consultable sans connexion (Bibliothèque) ;
   c) un produit payant (Grimoire), s'il venait à afficher ce contenu ?
3. Les **textes actuels**, décrits comme des reformulations, présentent-ils un risque en l'état ? Comment évaluer une
   reformulation « suffisante » ?
4. Les **420 descriptions d'aidedd.org** : faut-il les retirer, les réécrire, ou demander une autorisation à aidedd ?
   (droit d'auteur, droit du producteur de base de données)
5. Le **pied de page** « Interdit à la revente… usage personnel » du SRD 5.1 français remet-il en cause la licence
   CC BY 4.0 de sa page 1 pour un usage commercial (Grimoire) ?
6. Quelle **mention** afficher pour le contenu qui n'est pas issu du SRD (écran Crédits, Bibliothèque) ?
7. Les données de jeu (statistiques, règles) sont-elles protégeables, ou seulement leur expression ? Quelle limite pour
   la **sélection et l'agencement** (une base complète de sous-classes, par exemple) ?

## 7. Ce que nous attendons

Un avis sur les questions 1 à 7, et une recommandation d'option (A, B, C, D ou une combinaison) par type de contenu et
par produit. D'ici là, rien ne change sur le contenu hors SRD (décision 81).
