import 'combat_participant.dart';
import 'combat_snapshot.dart';

/// Règles du mode « Réordonner les égalités » (MJ). Elles **ne trient
/// jamais** : l'ordre est celui de [CombatSnapshot.displayParticipants]
/// (`sortedForDisplay`), seul le voisinage est lu ici.

/// `true` s'il existe au moins une égalité d'initiative (deux participants
/// visibles avec la même initiative saisie) : le mode « Réordonner » n'est
/// proposé que dans ce cas. Les participants sans initiative ne comptent pas
/// comme une égalité (rien à départager).
bool hasInitiativeTies(CombatSnapshot snapshot) {
  final seen = <int>{};
  for (final participant in snapshot.displayParticipants) {
    final initiative = participant.initiative;
    if (initiative == null) continue;
    if (!seen.add(initiative)) return true;
  }
  return false;
}

/// Voisin avec lequel [index] peut échanger sa place : le voisin immédiat
/// (au-dessus si [up], en dessous sinon) **à condition d'avoir la même
/// initiative** (non nulle). `null` sinon (« Limite de l'égalité »).
CombatParticipant? reorderNeighbor(
  List<CombatParticipant> displayed,
  int index, {
  required bool up,
}) {
  final neighborIndex = up ? index - 1 : index + 1;
  if (index < 0 ||
      index >= displayed.length ||
      neighborIndex < 0 ||
      neighborIndex >= displayed.length) {
    return null;
  }
  final current = displayed[index];
  final neighbor = displayed[neighborIndex];
  if (current.initiative == null || neighbor.initiative != current.initiative) {
    return null;
  }
  return neighbor;
}

/// Position (`sort_order`) à demander au serveur pour échanger [participant]
/// avec son voisin d'égalité [neighbor] (`reorder_participant`) : il prend la
/// place du voisin, le serveur décale les autres lignes.
int swapSortOrderWith(CombatParticipant neighbor) => neighbor.sortOrder;
