import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/checkable_option_tile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/selectable_option_tile.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_list_sort.dart';
import '../../domain/character_status_filter.dart';

/// Sélection courante des filtres et du tri de la liste des personnages —
/// voir [showCharacterListFilterSheet].
typedef CharacterListFilterSelection = ({
  Set<CharacterStatusFilter> statuses,
  Set<String> classNames,
  CharacterListSort sort,
});

/// Sheet "Filtrer et trier" de la liste des personnages (icône entonnoir de la barre
/// de recherche, voir `character_list_screen.dart`) — une section "TRIER
/// PAR" à choix exclusif en tête (P18, [SelectableOptionTile]), puis deux
/// sections à choix multiple via [CheckableOptionTile] : "STATUT" (Vivants/Archivé/Mort,
/// demande utilisateur du 16/09/2026, hors cahier des charges) puis "CLASSE"
/// (déjà existant). Anciennement `character_class_filter_sheet.dart`,
/// renommé en généralisant son contenu plutôt qu'en ajoutant un second bouton
/// filtre à côté de l'entonnoir existant.
///
/// Retourne la nouvelle sélection combinée, ou `null` si la sheet est fermée
/// sans "Appliquer" (croix, tap en dehors) — l'appelant ne doit alors rien
/// changer à son filtre actuel.
Future<CharacterListFilterSelection?> showCharacterListFilterSheet(
  BuildContext context, {
  required List<String> availableClassNames,
  required Set<String> selectedClassNames,
  required Set<CharacterStatusFilter> selectedStatuses,
  CharacterListSort selectedSort = CharacterListSort.defaultOrder,
}) {
  return showModalBottomSheet<CharacterListFilterSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _CharacterListFilterSheetContent(
      availableClassNames: availableClassNames,
      initialClassSelection: selectedClassNames,
      initialStatusSelection: selectedStatuses,
      initialSort: selectedSort,
    ),
  );
}

class _CharacterListFilterSheetContent extends StatefulWidget {
  const _CharacterListFilterSheetContent({
    required this.availableClassNames,
    required this.initialClassSelection,
    required this.initialStatusSelection,
    required this.initialSort,
  });

  final List<String> availableClassNames;
  final Set<String> initialClassSelection;
  final Set<CharacterStatusFilter> initialStatusSelection;
  final CharacterListSort initialSort;

  @override
  State<_CharacterListFilterSheetContent> createState() =>
      _CharacterListFilterSheetContentState();
}

class _CharacterListFilterSheetContentState
    extends State<_CharacterListFilterSheetContent> {
  late Set<String> _classSelection = {...widget.initialClassSelection};
  late Set<CharacterStatusFilter> _statusSelection = {
    ...widget.initialStatusSelection,
  };

  late CharacterListSort _sort = widget.initialSort;

  bool get _hasSelection =>
      _classSelection.isNotEmpty ||
      _statusSelection.isNotEmpty ||
      _sort != CharacterListSort.defaultOrder;

  void _toggleClass(String className) {
    setState(() {
      if (!_classSelection.remove(className)) {
        _classSelection.add(className);
      }
    });
  }

  void _toggleStatus(CharacterStatusFilter status) {
    setState(() {
      if (!_statusSelection.remove(status)) {
        _statusSelection.add(status);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(title: l10n.characterListFilterSheetTitle),
              Expanded(
                child: ListView(
                  // Clé stable pour les tests (`character_list_screen_test.dart`,
                  // `dragUntilVisible`) : sans elle, `find.byType(Scrollable)`
                  // est ambigu tant que la sheet est ouverte par-dessus la
                  // liste des personnages (elle aussi scrollable).
                  key: const Key('characterListFilterOptions'),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _SectionLabel(l10n.characterListFilterSheetSortSection),
                    const SizedBox(height: AppSpacing.sm),
                    for (final mode in CharacterListSort.values) ...[
                      SelectableOptionTile(
                        title: _sortTitle(l10n, mode),
                        subtitle: _sortSubtitle(l10n, mode),
                        subtitleMaxLines: null,
                        selected: _sort == mode,
                        onTap: () => setState(() => _sort = mode),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _SectionLabel(l10n.characterListFilterSheetStatusSection),
                    const SizedBox(height: AppSpacing.sm),
                    for (final status in CharacterStatusFilter.values) ...[
                      CheckableOptionTile(
                        title: _statusLabel(l10n, status),
                        checked: _statusSelection.contains(status),
                        onTap: () => _toggleStatus(status),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (widget.availableClassNames.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _SectionLabel(l10n.characterListFilterSheetClassSection),
                      const SizedBox(height: AppSpacing.sm),
                      for (final className in widget.availableClassNames) ...[
                        CheckableOptionTile(
                          title: className,
                          checked: _classSelection.contains(className),
                          onTap: () => _toggleClass(className),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: l10n.characterListFilterSheetResetButton,
                        surface: SecondaryButtonSurface.parchment,
                        onPressed: _hasSelection
                            ? () => setState(() {
                                _classSelection = {};
                                _statusSelection = {};
                                _sort = CharacterListSort.defaultOrder;
                              })
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: l10n.characterListFilterSheetApplyButton,
                        onPressed: () => Navigator.of(context).pop((
                          statuses: _statusSelection,
                          classNames: _classSelection,
                          sort: _sort,
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortTitle(AppLocalizations l10n, CharacterListSort mode) {
    switch (mode) {
      case CharacterListSort.defaultOrder:
        return l10n.characterListSortDefaultTitle;
      case CharacterListSort.name:
        return l10n.characterListSortNameTitle;
      case CharacterListSort.lastOpened:
        return l10n.characterListSortLastOpenedTitle;
    }
  }

  String _sortSubtitle(AppLocalizations l10n, CharacterListSort mode) {
    switch (mode) {
      case CharacterListSort.defaultOrder:
        return l10n.characterListSortDefaultSubtitle;
      case CharacterListSort.name:
        return l10n.characterListSortNameSubtitle;
      case CharacterListSort.lastOpened:
        return l10n.characterListSortLastOpenedSubtitle;
    }
  }

  /// Résout le libellé localisé d'un [CharacterStatusFilter] — voir la doc de
  /// classe de l'enum (`domain/character_status_filter.dart`), qui ne porte
  /// plus lui-même de texte depuis le chantier "traduction de l'app".
  String _statusLabel(AppLocalizations l10n, CharacterStatusFilter status) {
    switch (status) {
      case CharacterStatusFilter.alive:
        return l10n.characterListFilterSheetStatusAlive;
      case CharacterStatusFilter.archived:
        return l10n.characterListFilterSheetStatusArchived;
      case CharacterStatusFilter.dead:
        return l10n.characterListFilterSheetStatusDead;
    }
  }
}

/// Libellé de section ("STATUT"/"CLASSE") — même style que
/// `group_treasure_tab_body.dart::_SectionLabel` (`font.body` 13px/800
/// `textSecondary`).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.body(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}
