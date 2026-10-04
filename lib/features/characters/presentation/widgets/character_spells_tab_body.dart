import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_add_tile.dart';
import '../../domain/character_detail.dart';
import '../../domain/prepared_caster_spell_list.dart';
import '../../domain/spell_name_filter.dart';
import '../../domain/spell_status_formatter.dart';
import '../../domain/spellcasting_class_names.dart';
import '../../domain/spells_by_level_grouper.dart';
import 'add_prepared_spells_sheet.dart';
import 'character_class_features_card.dart';
import 'character_spells_section.dart';
import 'class_feature_action_sheet.dart';
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
    this.onUseFeature,
    this.actionsDisabled = false,
    this.searchFocusNode,
    super.key,
  });

  final CharacterDetail detail;
  final CastSpellCallback onCastSpell;
  final ToggleSpellFlagCallback onToggleFavorite;
  final ToggleSpellFlagCallback onTogglePrepared;

  /// Carte de pied "INVOCATIONS & APTITUDES À USAGE LIMITÉ" (recettage
  /// direction-artistique du 13/09) : `null` masque entièrement cette carte
  /// (ex. `shared_character_view_screen.dart`, vue en lecture seule — pas de
  /// callback d'écriture à proposer à un lecteur anonyme), même convention
  /// que les autres callbacks d'écriture de cet écran.
  final UseClassFeatureCallback? onUseFeature;

  final bool actionsDisabled;

  /// Focus programmatique du champ "Rechercher un sort" (icône loupe du
  /// bandeau bois, voir `character_detail_screen.dart`) — `null` crée un
  /// `FocusNode` entièrement interne, comportement inchangé pour les usages
  /// qui n'en ont pas besoin.
  final FocusNode? searchFocusNode;

  @override
  State<CharacterSpellsTabBody> createState() => _CharacterSpellsTabBodyState();
}

class _CharacterSpellsTabBodyState extends State<CharacterSpellsTabBody> {
  final TextEditingController _searchController = TextEditingController();
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.searchFocusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.searchFocusNode == null) _ownedFocusNode = FocusNode();
    _searchController.addListener(_handleSearchChanged);
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;

    // Carte de pied "INVOCATIONS & APTITUDES À USAGE LIMITÉ" (recettage
    // direction-artistique du 13/09) : `null` (vue en lecture seule, voir
    // `CharacterSpellsTabBody.onUseFeature`) masque entièrement la carte,
    // même sans aptitude — aucune écriture ne peut être proposée sans
    // callback pour l'exécuter.
    final onUseFeature = widget.onUseFeature;
    final limitedUseFeatures = [
      for (final feature in detail.classFeatures)
        if (!feature.isPassive) feature,
    ];
    final showLimitedUseCard =
        onUseFeature != null && limitedUseFeatures.isNotEmpty;

    if (detail.spells.isEmpty) {
      final isSpellcaster = detail.classes.any(
        (classRow) => spellcastingClassNames.contains(classRow.className),
      );
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          isSpellcaster
              ? const _EmptySpellsState()
              : _NonCasterEmptyState(
                  characterName: detail.name,
                  className: detail.primaryClass?.className ?? 'cette classe',
                ),
          if (showLimitedUseCard) ...[
            const SizedBox(height: AppSpacing.md),
            CharacterClassFeaturesCard(
              features: limitedUseFeatures,
              onUseFeature: onUseFeature,
              actionsDisabled: widget.actionsDisabled,
              title: 'INVOCATIONS & APTITUDES À USAGE LIMITÉ',
            ),
          ],
        ],
      );
    }

    final filteredSpells = SpellNameFilter.apply(
      spells: detail.spells,
      query: _searchController.text,
    );
    // Pour les classes à préparation « liste complète » (Clerc/Druide/
    // Paladin, voir `PreparedCasterSpellList`), `CharacterRepository` a déjà
    // fusionné toute la liste de sorts de la classe dans `detail.spells`
    // (`_fetchPreparedCasterClassListSpellIds`) : sans filtrage, l'onglet
    // afficherait des dizaines de sorts jamais préparés. Seuls les sorts
    // "visibles par défaut" (voir `SpellStatusFormatter
    // .isVisibleInPreparedView`) restent affichés ici ; la totalité de la
    // liste reste accessible depuis la sheet "Ajouter un sort" ci-dessous —
    // décision confirmée le 05/10/2026. En cas de multiclassage avec une
    // classe à sorts connus en plus, tout l'onglet passe en mode filtré
    // (comportement le plus simple, pas de distinction par classe d'origine
    // du sort).
    final isPreparedCasterFiltered = detail.classes.any(
      (classRow) =>
          PreparedCasterSpellList.classNames.contains(classRow.className),
    );
    final visibleSpells = isPreparedCasterFiltered
        ? filteredSpells
              .where(SpellStatusFormatter.isVisibleInPreparedView)
              .toList()
        : filteredSpells;
    final spellGroups = SpellsByLevelGrouper.group(visibleSpells);
    // Filtrés par la même recherche (jamais par le filtrage de préparation
    // ci-dessus) : un favori qui ne correspond pas à la requête en cours n'a
    // pas plus sa place ici que dans les groupes par niveau ci-dessous —
    // voir la documentation de classe de `CharacterSpellsSection`.
    final favorites = filteredSpells
        .where((spell) => spell.isFavorite)
        .toList();
    final query = _searchController.text.trim();
    // Distinct de l'état "recherche sans résultat" ci-dessous, qui ne
    // regarde que la recherche : un groupe de niveau >= 1 peut disparaître
    // uniquement parce qu'aucun de ses sorts n'est actuellement préparé,
    // indépendamment de toute recherche active — les cantrips/sorts
    // innés/accordés (toujours visibles) restent eux affichés normalement.
    final showNoPreparedState =
        isPreparedCasterFiltered &&
        !spellGroups.any((group) => group.level > 0);
    final noSearchMatch = spellGroups.isEmpty && query.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SpellSearchField(controller: _searchController, focusNode: _focusNode),
        const SizedBox(height: AppSpacing.md),
        if (noSearchMatch)
          _NoSearchMatchState(query: query)
        else ...[
          if (spellGroups.isNotEmpty)
            CharacterSpellsSection(
              groups: spellGroups,
              favorites: favorites,
              spellSlots: detail.spellSlots,
              pactSlot: detail.pactSpellSlot,
              preparedLimit: detail.preparedSpellLimit,
              preparedCount: detail.preparedSpellCount,
              onCastSpell: widget.onCastSpell,
              onToggleFavorite: widget.onToggleFavorite,
              onTogglePrepared: widget.onTogglePrepared,
              actionsDisabled: widget.actionsDisabled,
            ),
          if (showNoPreparedState) ...[
            if (spellGroups.isNotEmpty) const SizedBox(height: AppSpacing.md),
            const _NoPreparedSpellsState(),
          ],
        ],
        if (isPreparedCasterFiltered) ...[
          const SizedBox(height: AppSpacing.md),
          DashedAddTile(
            label: 'Ajouter un sort',
            onTap: widget.actionsDisabled
                ? null
                : () => showAddPreparedSpellsSheet(
                    context,
                    spells: detail.spells,
                    spellSlots: detail.spellSlots,
                    pactSlot: detail.pactSpellSlot,
                    onTogglePrepared: widget.onTogglePrepared,
                    onCastSpell: widget.onCastSpell,
                  ),
          ),
        ],
        if (showLimitedUseCard) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterClassFeaturesCard(
            features: limitedUseFeatures,
            onUseFeature: onUseFeature,
            actionsDisabled: widget.actionsDisabled,
            title: 'INVOCATIONS & APTITUDES À USAGE LIMITÉ',
          ),
        ],
      ],
    );
  }
}

/// Champ "Rechercher un sort" — voir la maquette "Fiche — Sorts"
/// (`docs/cahier-des-charges/09-maquettes-captures.md`). Habillage entièrement
/// porté par `AppTheme.light.inputDecorationTheme`, même convention que
/// `character_list_screen.dart::_SearchRow`.
class _SpellSearchField extends StatelessWidget {
  const _SpellSearchField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
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

/// État affiché à la place des groupes de niveau >= 1 pour un lanceur à
/// préparation « liste complète » (voir [PreparedCasterSpellList]) n'ayant
/// actuellement aucun sort préparé — les cantrips/sorts innés/accordés
/// restent eux affichés normalement au-dessus (toujours visibles, voir
/// `SpellStatusFormatter.isVisibleInPreparedView`). Même gabarit que
/// [_EmptySpellsState]/[_NonCasterEmptyState] (icône 48px + titre
/// `font.display` majuscules + corps centré). Pas de bouton ici : la tuile
/// "Ajouter un sort" (`DashedAddTile`) reste affichée juste en dessous,
/// inconditionnellement — même précédent que `_EmptyInventoryState` suivi de
/// `_AddRowButtons` dans `character_inventory_tab_body.dart`.
class _NoPreparedSpellsState extends StatelessWidget {
  const _NoPreparedSpellsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'AUCUN SORT PRÉPARÉ',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucun sort préparé pour l\'instant. Utilisez « Ajouter un '
              'sort » ci-dessous pour choisir parmi la liste complète.',
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
