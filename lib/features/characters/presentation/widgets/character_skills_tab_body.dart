import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_detail.dart';
import '../../domain/proficiency_bonus.dart';
import '../../domain/skill_bonus_calculator.dart';
import '../../domain/skill_name_filter.dart';
import 'character_armor_proficiencies_card.dart';
import 'character_class_features_card.dart';
import 'character_invocations_card.dart';
import 'character_languages_card.dart';
import 'character_skills_card.dart';
import 'character_tool_proficiencies_card.dart';
import 'character_weapon_proficiencies_card.dart';
import 'class_feature_action_sheet.dart';

/// Contenu de l'onglet "Aptitudes" de la fiche personnage (anciennement
/// "Compétences", voir `character_detail_tab_bar.dart::CharacterDetailTab
/// .skills`) — voir `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`,
/// section "Onglet Compétences".
///
/// Les sorts (aptitudes/emplacements) ont leur propre onglet "Sorts" — voir
/// `character_spells_tab_body.dart` — depuis la scission de cet onglet en 2.
///
/// [onUseFeature]/[actionsDisabled] délégués tels quels à
/// [CharacterClassFeaturesCard] — voir sa documentation de classe. Le reste
/// de l'onglet demeure en lecture seule.
///
/// `CharacterClassChoicesCard` (sous-classe/choix de classe résolus) n'est
/// plus insérée ici depuis ce recettage — absente de la maquette actuelle de
/// cet onglet (widget conservé, juste son insertion sur cet écran retirée) :
/// signalé au chef de projet, voir le rapport de la tâche qui a introduit ce
/// retrait, faute d'un autre emplacement désigné pour ces deux informations.
///
/// `StatefulWidget` (depuis l'ajout du champ de recherche filtrant "LES 18
/// COMPÉTENCES", recettage du 13/09) : même patron que
/// `character_spells_tab_body.dart::_SpellSearchField`, confort d'affichage
/// purement local à l'onglet, rien à persister.
class CharacterSkillsTabBody extends StatefulWidget {
  const CharacterSkillsTabBody({
    required this.detail,
    required this.onUseFeature,
    this.actionsDisabled = false,
    this.searchFocusNode,
    super.key,
  });

  final CharacterDetail detail;
  final UseClassFeatureCallback onUseFeature;
  final bool actionsDisabled;

  /// Focus programmatique du champ de recherche (icône loupe du bandeau bois,
  /// voir `character_detail_screen.dart`) — `null` crée un `FocusNode`
  /// entièrement interne, comportement inchangé pour les usages qui n'en ont
  /// pas besoin (ex. `shared_character_view_screen.dart`).
  final FocusNode? searchFocusNode;

  @override
  State<CharacterSkillsTabBody> createState() => _CharacterSkillsTabBodyState();
}

class _CharacterSkillsTabBodyState extends State<CharacterSkillsTabBody> {
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
    final proficiencyBonus = ProficiencyBonusRules.forTotalLevel(
      detail.totalLevel,
    );
    final skillResults = SkillNameFilter.apply(
      results: SkillBonusCalculator.computeAll(
        skills: detail.skills,
        abilityScores: detail.abilityScores,
        proficiencyBonus: proficiencyBonus,
      ),
      query: _searchController.text,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (detail.classFeatures.isNotEmpty) ...[
          CharacterClassFeaturesCard(
            features: detail.classFeatures,
            onUseFeature: widget.onUseFeature,
            actionsDisabled: widget.actionsDisabled,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _SkillSearchField(controller: _searchController, focusNode: _focusNode),
        const SizedBox(height: AppSpacing.sm),
        if (skillResults.isEmpty && _searchController.text.trim().isNotEmpty)
          _NoSkillMatchState(query: _searchController.text.trim())
        else
          CharacterSkillsCard(results: skillResults),
        if (detail.armorProficiencyNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterArmorProficienciesCard(names: detail.armorProficiencyNames),
        ],
        if (detail.weaponProficiencyNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterWeaponProficienciesCard(
            names: detail.weaponProficiencyNames,
          ),
        ],
        if (detail.toolProficiencyNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterToolProficienciesCard(names: detail.toolProficiencyNames),
        ],
        if (detail.knownLanguageNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterLanguagesCard(names: detail.knownLanguageNames),
        ],
        if (detail.knownInvocationNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          CharacterInvocationsCard(names: detail.knownInvocationNames),
        ],
      ],
    );
  }
}

/// Champ "Rechercher une compétence" — même gabarit que
/// `character_spells_tab_body.dart::_SpellSearchField` (habillage porté par
/// `AppTheme.light.inputDecorationTheme`), ne filtre que
/// [CharacterSkillsCard] ("LES 18 COMPÉTENCES"), pas les autres cartes de cet
/// onglet (spec de la tâche).
class _SkillSearchField extends StatelessWidget {
  const _SkillSearchField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: AppTypography.body(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Rechercher une compétence',
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

/// État "recherche sans résultat" de la carte "LES 18 COMPÉTENCES" — même
/// agencement compact que
/// `character_spells_tab_body.dart::_NoSearchMatchState`, mais ne remplace
/// que cette carte (les autres cartes de l'onglet restent affichées).
class _NoSkillMatchState extends StatelessWidget {
  const _NoSkillMatchState({required this.query});

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
              'Aucune compétence pour « $query ».',
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
