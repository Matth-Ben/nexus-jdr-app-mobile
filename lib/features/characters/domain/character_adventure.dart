import 'package:freezed_annotation/freezed_annotation.dart';

part 'character_adventure.freezed.dart';

/// Une ligne `character_campaigns` résolue pour la carte "Aventures" de
/// l'onglet "Personnage" (`presentation/widgets/character_adventures_card.dart`)
/// — voir `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 7.2, `12-partage-et-groupes.md` section 5.
///
/// [gmDisplayName] : nom d'affichage choisi par le MJ, résolu via la colonne
/// calculée PostgREST `stories_gm_display_name` (fonction Postgres
/// `security definer`, migration web
/// `20260906000000_add_stories_gm_display_name.sql`) — `null` tant que le MJ
/// n'a renseigné aucun nom (aucune UI web ne le permet encore à ce jour),
/// jamais une chaîne vide.
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
    String? gmDisplayName,
  }) = _CharacterAdventure;
}
