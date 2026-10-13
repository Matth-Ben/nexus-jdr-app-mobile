import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/prepared_spells_limit.dart';
import '../../domain/spell_preparation_filter.dart';

/// Carte "PRÉPARATION DES SORTS" en tête de l'onglet "Sorts"
/// (`character_spells_tab_body.dart`), affichée dès qu'au moins un sort du
/// personnage se prépare — demande utilisateur du 06/10/2026 : regroupe la
/// note d'explication (icône ⓘ, voir [showSpellPreparationInfoSheet]), le(s)
/// compteur(s) "SORTS PRÉPARÉS X / Y" ([PreparedSpellsCounter], un par
/// classe qui prépare depuis le chantier de blocage RAW du 13/10/2026 — voir
/// [classLimits]) et la bascule de filtre "Tous"/"Préparés"/"Non préparés".
class SpellPreparationCard extends StatelessWidget {
  const SpellPreparationCard({
    required this.filter,
    required this.onFilterChanged,
    required this.classLimits,
    super.key,
  });

  final SpellPreparationFilter filter;
  final ValueChanged<SpellPreparationFilter> onFilterChanged;

  /// Décompte et limite par classe qui prépare (`CharacterDetail
  /// .preparedSpellsByClass`, voir
  /// `domain/prepared_spells_limit.dart::PreparedSpellsLimit.limitsByClass`) :
  /// liste vide masque tout compteur (aucune classe ne prépare) ; un seul
  /// élément affiche EXACTEMENT le rendu historique mono-classe (un seul
  /// [PreparedSpellsCounter], libellé inchangé) ; plusieurs éléments
  /// affichent un [PreparedSpellsCounter] par classe, avec son nom en
  /// libellé — remplace l'ancien masquage total dès que plusieurs classes
  /// préparaient (demande de Matthias du 09/10/2026, précisée le 10/10).
  /// Reste un simple indicateur ici : n'empêche jamais de préparer un sort
  /// au-delà par lui-même (le blocage réel vit côté écriture,
  /// `CharacterRepository.setSpellPrepared`, et côté sélection dans
  /// `prepare_spells_sheet.dart`).
  final List<ClassPreparedSpells> classLimits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PRÉPARATION DES SORTS',
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Comment fonctionne la préparation des sorts ?',
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.accentTeal,
                ),
                onPressed: () => showSpellPreparationInfoSheet(
                  context,
                  classLimits: classLimits,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.md - AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Une seule classe qui prépare : rendu historique
                // inchangé (un seul compteur, libellé générique). Plusieurs
                // classes : un compteur par classe, avec son nom en libellé
                // — remplace l'ancien masquage total, voir la doc de
                // [classLimits].
                if (classLimits.length == 1) ...[
                  PreparedSpellsCounter(
                    count: classLimits.single.preparedCount,
                    limit: classLimits.single.limit,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else if (classLimits.length > 1)
                  for (final classLimit in classLimits) ...[
                    PreparedSpellsCounter(
                      count: classLimit.preparedCount,
                      limit: classLimit.limit,
                      label:
                          'SORTS PRÉPARÉS — '
                          '${classLimit.className.toUpperCase()}',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                SegmentedToggle<SpellPreparationFilter>(
                  options: [
                    for (final option in SpellPreparationFilter.values)
                      SegmentedToggleOption(value: option, label: option.label),
                  ],
                  value: filter,
                  onChanged: onFilterChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compteur "SORTS PRÉPARÉS X / Y" (classes qui préparent leurs sorts) :
/// libellé + décompte, jauge de remplissage, puis une phrase d'état ("Encore
/// N sort(s) à préparer"/"Limite atteinte"/"Limite dépassée de N"). Au-delà
/// de la limite, décompte, jauge et phrase passent en
/// [AppColors.accentBrick] : aucun blocage, simple signal.
class PreparedSpellsCounter extends StatelessWidget {
  const PreparedSpellsCounter({
    required this.count,
    required this.limit,
    this.label = 'SORTS PRÉPARÉS',
    super.key,
  });

  final int count;
  final int limit;

  /// Libellé affiché au-dessus du décompte — `'SORTS PRÉPARÉS'` par défaut
  /// (rendu mono-classe historique, strictement inchangé). Un personnage
  /// multiclassé avec plusieurs classes qui préparent (voir
  /// `SpellPreparationCard.classLimits`) fournit un libellé par classe (ex.
  /// `'SORTS PRÉPARÉS — CLERC'`) pour distinguer les compteurs empilés.
  final String label;

  @override
  Widget build(BuildContext context) {
    final over = count > limit;
    final remaining = limit - count;
    final status = over
        ? 'Limite dépassée de ${-remaining}'
        : remaining == 0
        ? 'Limite atteinte'
        : 'Encore $remaining sort${remaining > 1 ? 's' : ''} à préparer';
    final accent = over ? AppColors.accentBrick : AppColors.textSecondary;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$label : $count sur $limit'
          '${over ? ', limite dépassée' : ''}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, size: 14, color: accent),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.display(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$count / $limit',
                style: AppTypography.body(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: over ? AppColors.accentBrick : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.gaugeTrack,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.gaugeTrackBorder, width: 1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: limit <= 0 ? 1 : (count / limit).clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: over ? AppColors.accentBrick : null,
                  gradient: over ? null : AppColors.primaryButtonGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            status,
            style: AppTypography.body(
              fontSize: 11,
              fontWeight: over ? FontWeight.w700 : FontWeight.w400,
              color: over ? AppColors.accentBrick : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ouvre la note "PRÉPARATION DES SORTS" (icône ⓘ de
/// [SpellPreparationCard]) — gabarit B ([SheetHeaderBar] + contenu
/// scrollable, même patron que `spell_info_panel.dart`) : rappel de la règle
/// 5e et de ce que fait l'app, demande utilisateur du 06/10/2026.
/// [classLimits] : limite(s) actuelle(s) du personnage, rappelée(s) dans la
/// note si non vide — une classe par élément, voir
/// `SpellPreparationCard.classLimits`.
Future<void> showSpellPreparationInfoSheet(
  BuildContext context, {
  List<ClassPreparedSpells> classLimits = const [],
}) {
  final limitsSentence = switch (classLimits) {
    [] => '',
    [final only] => ' Votre limite actuelle : ${only.limit}.',
    _ =>
      ' Vos limites actuelles : '
          '${classLimits.map((c) => '${c.className} ${c.limit}').join(', ')}.',
  };
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: 'PRÉPARATION DES SORTS'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _InfoEntry(
                        icon: Icons.bookmark,
                        title: 'Préparer pour lancer',
                        body:
                            'Seuls les sorts préparés peuvent être lancés. '
                            'Les sorts non préparés restent dans la liste, '
                            'grisés, après les sorts préparés. Touchez un '
                            'sort puis « Préparer ce sort » ou « Ne plus '
                            'préparer ».',
                      ),
                      _InfoEntry(
                        icon: Icons.format_list_numbered,
                        title: 'Combien de sorts ?',
                        body:
                            'Clerc, Druide et Magicien : modificateur de '
                            'caractéristique d\'incantation + niveau de '
                            'classe. Paladin et Artificier (demi-lanceurs) : '
                            'modificateur + moitié du niveau. Minimum 1. '
                            'Multiclassé avec plusieurs classes qui '
                            'préparent : chaque classe a sa propre limite, '
                            'jamais un total commun.'
                            '$limitsSentence Une fois la limite atteinte, '
                            'impossible de préparer un nouveau sort de '
                            'cette classe sans en dé-préparer un autre '
                            'd\'abord.',
                      ),
                      const _InfoEntry(
                        icon: Icons.auto_awesome,
                        title: 'Sans préparation',
                        body:
                            'Les sorts mineurs, les sorts innés et les sorts '
                            'de domaine ou de serment n\'ont jamais à être '
                            'préparés et ne comptent pas dans la limite. Un '
                            'sort inné de niveau 1 ou plus se lance sans '
                            'emplacement, une fois par repos long.',
                      ),
                      const _InfoEntry(
                        icon: Icons.local_fire_department,
                        title: 'Lancer ne dé-prépare pas',
                        body:
                            'Lancer un sort consomme un emplacement, mais le '
                            'sort reste préparé : vous pouvez le relancer '
                            'tant qu\'il vous reste des emplacements.',
                      ),
                      const _InfoEntry(
                        icon: Icons.hotel,
                        title: 'Changer sa liste',
                        body:
                            'La liste de sorts préparés se change après un '
                            'repos long : le repos long vous propose de '
                            'garder votre liste ou de la modifier.',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InfoEntry extends StatelessWidget {
  const _InfoEntry({
    required this.icon,
    required this.title,
    required this.body,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentTeal),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  body,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
