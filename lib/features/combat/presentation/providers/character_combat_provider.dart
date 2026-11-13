import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../groups/presentation/providers/group_providers.dart';
import 'combat_providers.dart';

/// Délai au-delà duquel `ensureFresh` relit les groupes d'un personnage (à
/// l'ouverture de sa fiche). Une fiche rouverte dans ce délai ne fait aucune
/// requête.
const Duration kCharacterGroupIdsStaleAfter = Duration(minutes: 5);

/// Groupes dont un personnage est le personnage courant : **cache mémoire**
/// (jamais persisté) d'une requête `group_members` ciblée sur `character_id`
/// (`GroupRepository.fetchGroupIdsForCharacter`, lecture seule, aucune
/// écriture hors ligne).
///
/// État : `null` tant qu'aucune lecture n'a abouti (aucun groupe connu), puis
/// la dernière liste connue. **Hors ligne ou en erreur, le dernier groupe connu
/// est conservé** (jamais effacé par un échec). Une seule requête au premier
/// accès ; ensuite seulement : [ensureFresh] (ouverture de la fiche, si la
/// dernière lecture date de plus de [kCharacterGroupIdsStaleAfter]), le retour
/// du réseau, ou [refresh]. **Jamais de requête par rebuild.** Purgé au
/// changement d'utilisateur.
final characterGroupIdsProvider =
    NotifierProvider.family<CharacterGroupIdsNotifier, List<String>?, String>(
      CharacterGroupIdsNotifier.new,
    );

class CharacterGroupIdsNotifier extends Notifier<List<String>?> {
  CharacterGroupIdsNotifier(this.characterId);

  final String characterId;

  Future<void>? _inFlight;
  DateTime? _fetchedAt;
  int _epoch = 0;

  @override
  List<String>? build() {
    _epoch++;
    _inFlight = null;
    _fetchedAt = null;
    ref
      ..listen<String?>(currentUserProvider.select((user) => user?.id), (
        previous,
        next,
      ) {
        if (previous != next) ref.invalidateSelf();
      })
      ..listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
        if (previous?.value == false && next.value == true) {
          unawaited(refresh());
        }
      });
    Future.microtask(() {
      if (ref.mounted) unawaited(refresh());
    });
    return null;
  }

  /// Relit les groupes du personnage (un seul appel à la fois).
  Future<void> refresh() {
    final running = _inFlight;
    if (running != null) return running;
    final future = _fetch();
    _inFlight = future;
    return future;
  }

  /// Relit seulement si la dernière lecture est absente ou ancienne.
  Future<void> ensureFresh() {
    final fetchedAt = _fetchedAt;
    if (fetchedAt != null &&
        ref.read(combatClockProvider)().difference(fetchedAt) <
            kCharacterGroupIdsStaleAfter) {
      return Future.value();
    }
    return refresh();
  }

  Future<void> _fetch() async {
    final epoch = _epoch;
    try {
      final ids = await ref
          .read(groupRepositoryProvider)
          .fetchGroupIdsForCharacter(characterId);
      if (!ref.mounted || epoch != _epoch) return;
      _fetchedAt = ref.read(combatClockProvider)();
      state = List.unmodifiable(ids);
    } on Object {
      // Hors ligne ou erreur : on garde le dernier groupe connu.
    } finally {
      if (epoch == _epoch) _inFlight = null;
    }
  }
}

/// Bandeau de combat à afficher sur la fiche d'un personnage.
typedef CharacterCombatBanner = ({String groupId, int round, bool isStale});

/// Bandeau « Combat en cours » de la fiche du personnage [characterId] : le
/// groupe du personnage qui a un combat actif ; **si le personnage est dans
/// plusieurs groupes avec un combat actif, le plus récent** (`created_at` du
/// combat, un combat sans date compte comme le plus ancien, puis l'ordre de la
/// liste). `null` : aucun combat actif (ou groupe encore inconnu).
///
/// **Rebuild ciblé** : seuls les widgets qui observent ce provider
/// (`CharacterStickyBanners`) se reconstruisent, jamais la fiche ; un
/// évènement de combat sans rapport (initiative d'un autre participant) ne
/// change pas le record, donc ne reconstruit rien. `autoDispose` : l'abonnement
/// Realtime des groupes du personnage ne vit que tant que la fiche est ouverte.
final characterCombatBannerProvider = Provider.autoDispose
    .family<CharacterCombatBanner?, String>((ref, characterId) {
      final groupIds = ref.watch(characterGroupIdsProvider(characterId));
      if (groupIds == null || groupIds.isEmpty) return null;
      CharacterCombatBanner? best;
      DateTime? bestStartedAt;
      for (final groupId in groupIds) {
        final info = ref.watch(combatBannerProvider(groupId));
        if (info == null) continue;
        final startedAt = info.startedAt;
        final isMoreRecent =
            best == null ||
            (startedAt != null &&
                (bestStartedAt == null || startedAt.isAfter(bestStartedAt)));
        if (isMoreRecent) {
          best = (groupId: groupId, round: info.round, isStale: info.isStale);
          bestStartedAt = startedAt;
        }
      }
      return best;
    });
