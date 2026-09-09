import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_detail.dart';
import '../../domain/spell_name_filter.dart';
import '../../domain/spellcasting_class_names.dart';
import '../../domain/spells_by_level_grouper.dart';
import 'character_spells_section.dart';
import 'spell_action_sheet.dart';

/// Contenu de l'onglet "Sorts" de la fiche personnage — scindé de l'onglet
/// "Compétences" (voir `character_skills_tab_body.dart`) pour donner aux
/// sorts leur propre onglet à part entière, spec validée par l'agent
/// `direction-artistique`.
///
/// [onCastSpell]/[actionsDisabled] délégués tels quels à
/// [CharacterSpellsSection] — voir sa documentation de classe.
///
/// `StatefulWidget` (depuis l'ajout du champ de recherche, voir
/// `domain/spell_name_filter.dart`) plutôt qu'un état soulevé chez
/// l'appelant : cette recherche est un pur confort d'affichage local à
/// l'onglet, sans rien à persister ni à partager avec le reste de la fiche —
/// même choix que la recherche de `character_list_screen.dart`.
class CharacterSpellsTabBody extends StatefulWidget {
  const CharacterSpellsTabBody({
    required this.detail,
    required this.onCastSpell,
    required this.onToggleFavorite,
    required this.onTogglePrepared,
    this.actionsDisabled = false,
    super.key,
  });

  final CharacterDetail detail;
  final CastSpellCallback onCastSpell;
  final ToggleSpellFlagCallback onToggleFavorite;
  final ToggleSpellFlagCallback onTogglePrepared;
  final bool actionsDisabled;

  @override
  State<CharacterSpellsTabBody> createState() =>
      _CharacterSpellsTabBodyState();
}

class _CharacterSpellsTabBodyState extends State<CharacterSpellsTabBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    if (detail.spells.isEmpty) {
      final isSpellcaster = detail.classes.any(
        (classRow) => spellcastingClassNames.contains(classRow.className),
      );
      return isSpellcaster
          ? const _EmptySpellsState()
          : _NonCasterEmptyState(
              characterName: detail.name,
              className: detail.primaryClass?.className ?? 'cette classe',
            );
    }

    final filteredSpells = SpellNameFilter.apply(
      spells: detail.spells,
      query: _searchController.text,
    );
    final spellGroups = SpellsByLevelGrouper.group(filteredSpells);
    // Filtrés par la même recherche : un favori qui ne correspond pas à la
    // requête en cours n'a pas plus sa place ici que dans les groupes par
    // niveau ci-dessous — voir la documentation de classe de
    // `CharacterSpellsSection`.
    final favorites = filteredSpells.where((spell) => spell.isFavorite).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SpellSearchField(controller: _searchController),
        const SizedBox(height: AppSpacing.md),
        if (spellGroups.isEmpty)
          _NoSearchMatchState(query: _searchController.text.trim())
        else
          CharacterSpellsSection(
            groups: spellGroups,
            favorites: favorites,
            spellSlots: detail.spellSlots,
            pactSlot: detail.pactSpellSlot,
            onCastSpell: widget.onCastSpell,
            onToggleFavorite: widget.onToggleFavorite,
            onTogglePrepared: widget.onTogglePrepared,
            actionsDisabled: widget.actionsDisabled,
          ),
      ],
    );
  }
}

/// Champ "Rechercher un sort" — voir la maquette "Fiche — Sorts"
/// (`docs/cahier-des-charges/09-maquettes-captures.md`). Habillage entièrement
/// porté par `AppTheme.light.inputDecorationTheme`, même convention que
/// `character_list_screen.dart::_SearchRow`.
class _SpellSearchField extends StatelessWidget {
  const _SpellSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTypography.body(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Rechercher un sort',
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: controller.clear,
              ),
      ),
    );
  }
}

/// État "recherche sans résultat" au sein de l'onglet — distinct de
/// [_EmptySpellsState] (aucun sort du tout sur la fiche) : le personnage a
/// des sorts, mais aucun ne correspond à la recherche en cours. Pas de
/// bouton "Réinitialiser" dédié (contrairement à
/// `character_list_screen.dart::_SearchEmptyState`) : effacer le champ
/// au-dessus suffit et reste visible dans le même écran, sans navigation ni
/// second geste nécessaire.
class _NoSearchMatchState extends StatelessWidget {
  const _NoSearchMatchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucun sort pour « $query ».',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// État vide (aucun sort sur la fiche) : même agencement (icône + titre +
/// sous-titre centrés) que `_EmptyStoryState` de
/// `character_story_tab_body.dart`.
class _EmptySpellsState extends StatelessWidget {
  const _EmptySpellsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_fix_high_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'AUCUN SORT',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucun sort sur cette fiche pour l\'instant. Pour les classes '
              'qui lancent des sorts, ils se choisissent depuis l\'assistant '
              'de création ou à la montée de niveau.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// État vide d'une classe structurellement non lanceuse de sorts (ex.
/// Guerrier, Roublard) — distinct de [_EmptySpellsState] (voir maquette
/// `docs/cahier-des-charges/09-maquettes-captures.md`, section "État vide —
/// Sorts") : l'onglet reste accessible par cohérence de navigation entre
/// personnages, mais ce message précise que ce n'est pas juste "pas encore
/// choisi".
class _NonCasterEmptyState extends StatelessWidget {
  const _NonCasterEmptyState({
    required this.characterName,
    required this.className,
  });

  final String characterName;
  final String className;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cette classe ne lance pas de sorts',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$characterName est $className — hors archétype dédié (ex. '
              'Chevalier occulte), cette classe ne dispose pas '
              'd\'emplacements de sorts. Cet onglet reste accessible par '
              'cohérence de navigation, mais restera vide pour ce '
              'personnage.',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
