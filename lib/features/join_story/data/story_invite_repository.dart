import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/join_story_result.dart';
import '../domain/story_invite_failure.dart';
import '../domain/story_preview.dart';
import 'story_invite_error_mapper.dart';

/// Bucket Storage des couvertures d'histoire (dépôt web,
/// `20260716212008_create_stories.sql`) — lecture publique, écriture
/// restreinte au MJ propriétaire. Jamais écrit depuis ce dépôt (l'app mobile
/// ne fait que consommer une histoire déjà créée côté web), seulement lu via
/// [SupabaseStoryInviteRepository._resolveCoverUrl].
const String _storyCoversBucket = 'story-covers';

/// Passerelle vers les deux edge functions Supabase du flux "Rejoindre une
/// histoire" (`docs/cahier-des-charges/12-partage-et-groupes.md` section 5,
/// `04-fonctionnalites-app-mobile.md` section 7.1) — déjà déployées,
/// testées et stables côté dépôt web, jamais modifiées depuis ce dépôt.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client` — même principe que `CharacterRepository`.
abstract class StoryInviteRepository {
  /// `preview-story-invite` — étape 2/4 : résout [code] en un aperçu pur
  /// (titre + couverture), sans jamais créer de rattachement. Lève une
  /// [StoryInviteFailure] pour tout échec (voir [StoryInviteFailureKind]).
  Future<StoryPreview> previewInvite(String code);

  /// `join-story` — étape 4/4 : crée le rattachement `character_campaigns`
  /// entre [characterId] (déjà vérifié appartenir au joueur connecté côté
  /// serveur) et l'histoire désignée par [code]. Lève une
  /// [StoryInviteFailure] pour tout échec, y compris
  /// [StoryInviteFailureKind.alreadyJoined] (le personnage choisi est déjà
  /// rattaché à cette histoire) — jamais une exception générique pour ce cas
  /// attendu, voir la spec visuelle de l'étape 3/4 (bandeau d'alerte inline).
  Future<JoinStoryResult> joinStory({
    required String code,
    required String characterId,
  });
}

class SupabaseStoryInviteRepository implements StoryInviteRepository {
  SupabaseStoryInviteRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<StoryPreview> previewInvite(String code) async {
    try {
      final response = await _client.functions.invoke(
        'preview-story-invite',
        body: {'code': code},
      );
      final data = _asMap(response.data);
      return StoryPreview(
        title: (data['title'] as String?) ?? '',
        coverUrl: _resolveCoverUrl(data['cover_image_path'] as String?),
      );
    } on FunctionException catch (error) {
      throw mapStoryInviteError(error);
    } on StoryInviteFailure {
      rethrow;
    } catch (_) {
      throw const StoryInviteFailure(StoryInviteFailureKind.generic);
    }
  }

  @override
  Future<JoinStoryResult> joinStory({
    required String code,
    required String characterId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'join-story',
        body: {'code': code, 'character_id': characterId},
      );
      final data = _asMap(response.data);
      final story = _asMap(data['story']);
      return JoinStoryResult(
        characterCampaignId: (data['character_campaign_id'] as String?) ?? '',
        joinedAt: (data['joined_at'] as String?) ?? '',
        characterId: characterId,
        storyId: (story['id'] as String?) ?? '',
        storyTitle: (story['title'] as String?) ?? '',
        storyCoverUrl: _resolveCoverUrl(story['cover_image_path'] as String?),
      );
    } on FunctionException catch (error) {
      throw mapStoryInviteError(error);
    } on StoryInviteFailure {
      rethrow;
    } catch (_) {
      throw const StoryInviteFailure(StoryInviteFailureKind.generic);
    }
  }

  /// `cover_image_path` renvoyé par les deux edge functions est un chemin de
  /// stockage brut (`story-covers/{owner_id}/...`), jamais une URL publique
  /// déjà résolue (vérifié contre `apps/web/app/(dashboard)/page.tsx` du
  /// dépôt web, qui fait le même appel `getPublicUrl` côté Next.js) — à
  /// résoudre ici, même principe que `characters.portrait_url` côté
  /// `CharacterRepository.uploadPortrait`, à la différence que ce bucket
  /// n'est jamais écrit depuis ce dépôt.
  String? _resolveCoverUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return _client.storage.from(_storyCoversBucket).getPublicUrl(path);
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};
}
