import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_adventure.freezed.dart';

/// Une ligne `character_campaigns` résolue pour la carte "Aventures" de
/// l'onglet "Personnage" (`presentation/widgets/character_adventures_card.dart`)
/// — voir `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 7.2, `12-partage-et-groupes.md` section 5.
///
/// **Pas de nom de MJ, alors que la section 7.2 du cahier des charges le
/// liste explicitement** ("nom, couverture, nom du MJ") : même décision
/// produit actée par le chef de projet que pour `StoryPreview`
/// (`features/join_story/domain/story_preview.dart`, étape 2/4 "Confirmation"
/// du flux "Rejoindre une histoire") — aucune notion de profil
/// utilisateur/nom d'affichage n'existe dans le schéma web actuel, donc
/// aucun nom de MJ à résoudre ici non plus, pour exactement la même raison.
/// Volontaire, pas un oubli.
///
/// **Limite RLS connue (signalée au chef de projet, pas de son ressort)** :
/// [storyTitle]/[storyCoverUrl] ne sont résolvables que si la policy select
/// de `stories` autorise le *propriétaire du personnage rattaché* à lire la
/// ligne — vérifié empiriquement (voir le rapport de la tâche) qu'aucune
/// policy de ce type n'existe encore côté dépôt web à ce jour (seul le MJ
/// propriétaire de l'histoire peut la lire). Tant qu'elle n'est pas ajoutée
/// (migration côté dépôt web, hors périmètre de ce dépôt), PostgREST renvoie
/// `stories: null` pour la ligne `character_campaigns` correspondante — une
/// ligne dans ce cas est omise silencieusement par
/// `data/character_detail_row_mapper.dart::parseAdventures` plutôt que
/// d'afficher une aventure sans titre.
@freezed
abstract class CharacterAdventure with _$CharacterAdventure {
  const factory CharacterAdventure({
    required String characterCampaignId,
    required String storyId,
    required String storyTitle,
    String? storyCoverUrl,
  }) = _CharacterAdventure;
}
