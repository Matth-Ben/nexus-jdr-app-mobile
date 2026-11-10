import 'package:flutter/material.dart';

import '../../../../core/widgets/display_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Pastille compacte de statut priorisé sur `_GroupRow`
/// (`group_list_screen.dart`) — vue d'ensemble du groupe directement dans la
/// liste, sans dupliquer la jauge PV individuelle de chaque membre (déjà
/// affichée par `group_members_tab_body.dart::_MemberHpGauge`, qui reste la
/// seule source de vérité "temps réel" pour un membre donné). Alimenté par
/// `GroupSummary.deadCount`/`GroupSummary.lowHpCount` (vue
/// `group_character_status_overview`, voir `GroupRepository.fetchMyGroups`).
///
/// **Priorité stricte, jamais de cumul** (avis direction-artistique du
/// comité de revue F03, `docs/retours-utilisateurs.md`) : un seul badge à la
/// fois — "X mort(s)" si [deadCount] > 0, sinon "X PV bas" si [lowHpCount] >
/// 0, sinon rien (`SizedBox.shrink`).
///
/// **Choix de factorisation** : ce widget reprend volontairement le même
/// gabarit visuel que `group_members_tab_body.dart::_StatusBadge` (mêmes
/// couleurs `alertBannerBackground`/`statusUnconsciousBackground`, même
/// bordure, même `font.display` 11px) plutôt que de réutiliser cette classe
/// directement : `_StatusBadge` est privée à son fichier et pilotée par un
/// seul `CharacterVitalStatus` (texte fixe "MORT"/"INCONSCIENT"), alors que
/// ce badge agrège un *nombre* de personnages par groupe et doit choisir
/// lui-même lequel des deux statuts afficher (ou aucun) — les deux widgets
/// n'ont en commun que l'habillage, jamais la donnée d'entrée ni la logique
/// de décision. Un partage forcé (passer par un paramètre `text`/`icon`
/// générique commun aux deux fichiers) aurait ajouté une indirection pour
/// deux appelants seulement, sans bénéfice réel — même raisonnement que la
/// duplication déjà pratiquée dans ce dépôt pour
/// `_fetchTranslatedNames`/`RaceRowMapper` (voir leur documentation).
///
/// Pas de clé `.arb` : `group_list_screen.dart` n'est pas encore localisé
/// sur `main` (texte français en dur partout sur cet écran) — même
/// convention que le correctif F01 (`docs/retours-utilisateurs.md`,
/// `group_create_screen.dart`/`group_join_screen.dart`). Le pluriel
/// français ("1 mort" / "2 morts") est néanmoins géré correctement en Dart
/// plutôt que de reproduire le bug de `_GroupRow`'s member count ("1
/// membres", toujours au pluriel) — tracé en D171 (`docs/dette-technique.md`)
/// à l'occasion de ce même chantier F03, pas corrigé ici.
class GroupStatusBadge extends StatelessWidget {
  const GroupStatusBadge({
    required this.deadCount,
    required this.lowHpCount,
    super.key,
  });

  final int deadCount;
  final int lowHpCount;

  @override
  Widget build(BuildContext context) {
    if (deadCount <= 0 && lowHpCount <= 0) {
      return const SizedBox.shrink();
    }

    final isDead = deadCount > 0;
    final background = isDead
        ? AppColors.alertBannerBackground
        : AppColors.statusUnconsciousBackground;
    final accent = isDead
        ? AppColors.accentBrick
        : AppColors.statusUnconsciousAccent;
    final label = isDead
        ? (deadCount == 1 ? '1 mort' : '$deadCount morts')
        : '$lowHpCount PV bas';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: accent, width: isDead ? AppBorders.card : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDead) ...[
            Icon(Icons.warning_amber_rounded, size: 14, color: accent),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: DisplayText(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.display(fontSize: 11, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}
