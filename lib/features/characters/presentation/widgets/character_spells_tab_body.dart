import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/rules/class_spellcasting_rule.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_spell_slot.dart';
import '../../domain/spell_name_filter.dart';
import '../../domain/spell_preparation_filter.dart';
import '../../domain/spell_status_formatter.dart';
import '../../domain/spells_by_level_grouper.dart';
import '../providers/spell_preparation_filter_preference_provider.dart';
import 'character_class_features_card.dart';
import 'character_spells_section.dart';
import 'class_feature_action_sheet.dart';
import 'spell_action_sheet.dart';
import 'spell_preparation_card.dart';

/// Contenu de l'onglet "Sorts" de la fiche personnage — scindé de l'onglet
/// "Compétences" (voir `character_skills_tab_body.dart`) pour donner aux
/// sorts leur propre onglet à part entière, spec validée par l'agent
/// `direction-artistique`.
///
/// [onCastSpell]/[actionsDisabled] délégués tels quels à
/// [CharacterSpellsSection] — voir sa documentation de classe.
///
/// `ConsumerStatefulWidget` (depuis l'ajout du champ de recherche, voir
/// `domain/spell_name_filter.dart`, puis du filtre de préparation,
/// `domain/spell_preparation_filter.dart`) plutôt qu'un état soulevé chez
/// l'appelant : la recherche reste un pur confort d'affichage local à
/// l'onglet, sans rien à persister ni à partager avec le reste de la fiche —
/// même choix que la recherche de `character_list_screen.dart`. Le filtre de
/// préparation, lui, est mémorisé comme préférence globale à l'appareil
/// (demande utilisateur du 29/10/2026) via
/// `providers/spell_preparation_filter_preference_provider.dart` — d'où le
/// passage de `StatefulWidget` à `ConsumerStatefulWidget`, sans rien changer
/// chez les appelants (déjà dans l'arbre Riverpod).
///
/// **Le filtre mémorisé est lu via `ref.watch` dans `build()`, jamais via un
/// `ref.read` figé en `initState` mis en cache dans un champ local** — bug
/// confirmé par `qa-testeur` le 29/10/2026
/// (`shared_character_view_screen_test.dart`, groupe "filtre de préparation
/// mémorisé sur l'appareil") : `SpellPreparationFilterPreferenceController`
/// retombe "momentanément" sur [SpellPreparationFilter.all] tant que
/// `sharedPreferencesProvider` n'a pas résolu — TOUJOURS le cas au tout
/// premier `build()` de ce widget (au moins un microtask Dart). Un
/// `ref.read` en `initState` capturait donc systématiquement ce retour à
/// vide sans jamais se corriger ensuite, puisque rien ne réécoutait le
/// provider une fois la vraie valeur disponible. Sur la fiche du
/// propriétaire, ça ne se voyait presque jamais : `UpdateSuggestedBanner`
/// (`character_list_screen.dart`) lit déjà `sharedPreferencesProvider` bien
/// avant que le joueur n'atteigne cet onglet, qui trouvait donc
/// généralement le provider déjà résolu. `shared_character_view_screen.dart`
/// (lecteur anonyme) ne passe jamais par cet écran d'accueil — rien ne
/// "préchauffe" le provider avant cet onglet, le défaut y était donc
/// déterministe. `ref.watch` (sans champ local redondant, voir `build()`)
/// corrige ça à la racine : la carte se mettra à jour d'elle-même dès que
/// le provider résout, au prix d'un flash très bref sur "Tous" si ce
/// provider n'a jamais encore été lu dans la session — même compromis
/// documenté que `UpdateBannerDismissalController.build` dans
/// `update_banner_dismissal_provider.dart`, jugé préférable à un
/// `ref.listen` qui aurait dû dupliquer cette même logique de
/// resynchronisation dans un champ local, pour le même résultat visuel.
class CharacterSpellsTabBody extends ConsumerStatefulWidget {
  const CharacterSpellsTabBody({
    required this.detail,
    required this.onCastSpell,
    required this.onTogglePrepared,
    this.onUseFeature,
    this.actionsDisabled = false,
    this.searchFocusNode,
    super.key,
  });

  final CharacterDetail detail;
  final CastSpellCallback onCastSpell;
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
  ConsumerState<CharacterSpellsTabBody> createState() =>
      _CharacterSpellsTabBodyState();
}

class _CharacterSpellsTabBodyState
    extends ConsumerState<CharacterSpellsTabBody> {
  final TextEditingController _searchController = TextEditingController();
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.searchFocusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.searchFocusNode == null) _ownedFocusNode = FocusNode();
    _searchController.addListener(_handleSearchChanged);
  }

  /// Persiste [filter] — la carte [SpellPreparationCard] se met à jour
  /// elle-même dès que `build()` relit
  /// `spellPreparationFilterPreferenceControllerProvider` (`ref.watch`,
  /// aucun `setState` local nécessaire) : `setFilter` affecte son `state`
  /// de façon synchrone avant d'écrire sur le disque (voir sa doc), donc
  /// l'application est immédiate même sans attendre cette écriture.
  void _handleFilterChanged(SpellPreparationFilter filter) {
    unawaited(
      ref
          .read(spellPreparationFilterPreferenceControllerProvider.notifier)
          .setFilter(filter),
    );
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
    final l10n = AppLocalizations.of(context)!;
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

    final availableSlots = _availableSlotLevels(detail.spellSlots);
    final hasPactSlots = (detail.pactSpellSlot?.total ?? 0) > 0;

    if (detail.spells.isEmpty) {
      // Un personnage qui a des emplacements (sous-classe lanceuse du
      // Guerrier/Roublard, multiclassage...) se comporte comme un lanceur
      // même si sa classe n'en est pas un par défaut ; la règle partagée
      // `ClassSpellcastingRegistry` (création/montée de niveau) n'est pas
      // modifiée.
      final isSpellcaster =
          availableSlots.isNotEmpty ||
          hasPactSlots ||
          detail.classes.any(
            (classRow) =>
                ClassSpellcastingRegistry.ruleForFrenchName(classRow.className)
                    .isCaster,
          );
      if (!isSpellcaster) {
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _NonCasterEmptyState(),
            if (showLimitedUseCard) ...[
              const SizedBox(height: AppSpacing.md),
              CharacterClassFeaturesCard(
                features: limitedUseFeatures,
                onUseFeature: onUseFeature,
                actionsDisabled: widget.actionsDisabled,
                title: l10n.characterSpellsTabBodyResourcesTitle,
              ),
            ],
          ],
        );
      }
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (availableSlots.isNotEmpty) ...[
            _SpellSlotsCard(slots: availableSlots),
            const SizedBox(height: AppSpacing.md),
          ],
          const _EmptySpellsState(),
          if (showLimitedUseCard) ...[
            const SizedBox(height: AppSpacing.md),
            CharacterClassFeaturesCard(
              features: limitedUseFeatures,
              onUseFeature: onUseFeature,
              actionsDisabled: widget.actionsDisabled,
              title: l10n.characterSpellsTabBodyLimitedUseFeaturesCardTitle,
            ),
          ],
        ],
      );
    }

    // Tous les sorts que le personnage possède/connaît sont affichés, y
    // compris ceux restant à préparer (grisés, après les sorts préparés de
    // leur niveau — voir `SpellsByLevelGrouper.group`) : pour les classes à
    // préparation « liste complète » (Clerc/Druide/Paladin),
    // `CharacterRepository` a déjà fusionné toute la liste de sorts de la
    // classe dans `detail.spells`. Le filtre de [SpellPreparationCard]
    // remplace l'ancien masquage par défaut + bouton "Ajouter un sort" —
    // demande utilisateur du 06/10/2026.
    final hasPreparation = detail.spells.any(
      SpellStatusFormatter.canTogglePrepared,
    );
    // `ref.watch` (pas `ref.read` en `initState`, bug confirmé par
    // `qa-testeur` le 29/10/2026 — voir le commentaire de classe) : le
    // provider retombe "momentanément" sur [SpellPreparationFilter.all] le
    // temps que `sharedPreferencesProvider` résolve, TOUJOURS le cas au
    // premier `build()` de ce widget. `ref.watch` permet au rebuild
    // automatique de rattraper la vraie valeur mémorisée dès cette
    // résolution — y compris sur `shared_character_view_screen.dart`, où
    // rien d'autre dans l'arbre ne lit ce provider en amont pour le
    // "préchauffer".
    final preferredFilter = ref.watch(
      spellPreparationFilterPreferenceControllerProvider,
    );
    final preparationFilter = hasPreparation
        ? preferredFilter
        : SpellPreparationFilter.all;
    final visibleSpells = preparationFilter.apply(
      SpellNameFilter.apply(
        spells: detail.spells,
        query: _searchController.text,
      ),
    );
    final spellGroups = SpellsByLevelGrouper.group(
      visibleSpells,
      preparedFirst: true,
    );
    final query = _searchController.text.trim();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _SpellSearchField(controller: _searchController, focusNode: _focusNode),
        const SizedBox(height: AppSpacing.md),
        if (availableSlots.isNotEmpty) ...[
          _SpellSlotsCard(slots: availableSlots),
          const SizedBox(height: AppSpacing.md),
        ],
        if (hasPreparation) ...[
          SpellPreparationCard(
            filter: preparationFilter,
            onFilterChanged: _handleFilterChanged,
            classLimits: detail.preparedSpellsByClass,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (spellGroups.isEmpty)
          _NoMatchState(query: query, filter: preparationFilter)
        else
          CharacterSpellsSection(
            groups: spellGroups,
            spellSlots: detail.spellSlots,
            pactSlot: detail.pactSpellSlot,
            onCastSpell: widget.onCastSpell,
            onTogglePrepared: widget.onTogglePrepared,
            actionsDisabled: widget.actionsDisabled,
          ),
        if (showLimitedUseCard) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterClassFeaturesCard(
            features: limitedUseFeatures,
            onUseFeature: onUseFeature,
            actionsDisabled: widget.actionsDisabled,
            title: l10n.characterSpellsTabBodyLimitedUseFeaturesCardTitle,
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
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: AppTypography.body(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: l10n.characterSpellsTabBodySearchHint,
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.characterSpellsTabBodySearchClearTooltip,
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: controller.clear,
              ),
      ),
    );
  }
}

/// Aucun sort à afficher alors que la fiche en a — distinct de
/// [_EmptySpellsState] (aucun sort du tout) : soit rien ne correspond à la
/// recherche en cours, soit le filtre de préparation ([filter]) ne laisse
/// passer aucun sort. Pas de bouton "Réinitialiser" dédié (contrairement à
/// `character_list_screen.dart::_SearchEmptyState`) : le champ de recherche
/// et la bascule de filtre restent visibles juste au-dessus, sans navigation
/// ni second geste nécessaire.
class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.query, required this.filter});

  final String query;
  final SpellPreparationFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kind = switch (filter) {
      SpellPreparationFilter.all => l10n.characterSpellsTabBodyNoMatchAllLabel,
      SpellPreparationFilter.prepared =>
        l10n.characterSpellsTabBodyNoMatchPreparedLabel,
      SpellPreparationFilter.unprepared =>
        l10n.characterSpellsTabBodyNoMatchUnpreparedLabel,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              query.isEmpty ? Icons.bookmark_border : Icons.search_off,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              query.isEmpty
                  ? l10n.characterSpellsTabBodyNoMatchMessageEmpty(kind)
                  : l10n.characterSpellsTabBodyNoMatchMessageQuery(kind, query),
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.characterSpellsTabBodyEmptyStateTitle,
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.characterSpellsTabBodyEmptyStateBody,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// État d'un personnage sans emplacements de sorts (ex. Barbare, Guerrier) :
/// une phrase simple, les compteurs d'aptitudes (carte "Ressources") étant
/// affichés en dessous par l'appelant.
class _NonCasterEmptyState extends StatelessWidget {
  const _NonCasterEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.characterSpellsTabBodyNonCasterMessage,
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Niveaux d'emplacements réellement disponibles (niveau >= 1, `total > 0`,
/// hors magie de pacte, triés) — du niveau 1 jusqu'au niveau maximum du
/// personnage, y compris ceux dont tous les emplacements sont dépensés.
/// `detail.spellSlots` est déjà la table combinée en cas de multiclassage.
List<CharacterSpellSlot> _availableSlotLevels(List<CharacterSpellSlot> slots) {
  return [
    for (final slot in slots)
      if (!slot.isPact && slot.level >= 1 && slot.total > 0) slot,
  ]..sort((a, b) => a.level.compareTo(b.level));
}

/// Carte "Emplacements de sorts" : une ligne de pastilles par niveau
/// d'emplacement disponible (voir [_availableSlotLevels]), indépendamment
/// des sorts connus (bug F15). `Wrap` pour ne jamais déborder à 320 px ou
/// avec un texte système agrandi.
class _SpellSlotsCard extends StatelessWidget {
  const _SpellSlotsCard({required this.slots});

  final List<CharacterSpellSlot> slots;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.characterSpellsTabBodySlotsCardTitle,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          for (final slot in slots) ...[
            const SizedBox(height: AppSpacing.sm),
            // Une seule annonce par ligne ; libellé + pastilles décoratifs
            // pour le lecteur d'écran (`excludeSemantics`).
            Semantics(
              container: true,
              excludeSemantics: true,
              label: l10n.characterSpellsSectionSlotLevelSemanticLabel(
                slot.level,
                slot.remaining,
                slot.total,
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    l10n.characterSpellsTabBodySlotsLevelLabel(slot.level),
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SpellSlotDots(slot: slot),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
