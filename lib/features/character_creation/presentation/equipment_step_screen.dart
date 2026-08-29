import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/accent_icon_badge.dart';
import '../../../core/widgets/checkable_option_tile.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/segmented_toggle.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../../core/widgets/stepper_counter.dart';
import '../domain/background_equipment_entry.dart';
import '../domain/character_creation_failure.dart';
import '../domain/equipment_category_rules.dart';
import '../domain/equipment_choice_tab.dart';
import '../domain/equipment_step_selection.dart';
import '../domain/gold_amount_formatter.dart';
import '../domain/item_option.dart';
import 'providers/character_creation_draft_provider.dart';
import 'providers/character_creation_providers.dart';

/// Étape 7/9 de l'assistant de création de personnage : équipement de départ
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 7, maquette réelle "Étape 7 — Équipement de départ" —
/// `docs/cahier-des-charges/09-maquettes-captures.md`).
///
/// Périmètre réduit par le chef de projet par rapport à la maquette réelle
/// (qui montre un "Paquetage du Magicien" par classe, donnée absente du
/// schéma peuplé) : deux choix mutuellement exclusifs, tous deux avec de
/// vraies données —
/// - onglet "Historique" : `BackgroundOption.equipment` de l'historique
///   choisi à l'étape 3, automatiquement accordé (voir
///   `domain/background_equipment_parser.dart`/
///   `domain/background_equipment_resolver.dart`) ;
/// - onglet "Acheter" : achat libre dans `items`, budget = "Bourse (N po)"
///   de cet historique (voir `domain/equipment_step_selection.dart`).
///
/// Choix mutuellement exclusif à la validation : seul le contenu de l'onglet
/// **actif** au moment de "Suivant" est retenu dans le brouillon (voir
/// `domain/equipment_choice_tab.dart`) — le panier de l'onglet "Acheter"
/// reste néanmoins préservé en mémoire au changement d'onglet, pour ne pas
/// perdre la saisie d'un joueur qui hésite entre les deux options avant de
/// valider.
///
/// En-tête bois plein portant le titre d'étape et la barre de progression
/// (contrairement aux étapes 4/5/7... précédentes, qui les placent sur le
/// fond parchemin) — mais **sans** le sélecteur d'onglets dessus,
/// contrairement à `spells_step_screen.dart` (étape 6/9) qui, lui, porte son
/// sélecteur "Mineurs"/"Niveau 1" sur le bois : la maquette réelle de cette
/// étape 7/9 place le `SegmentedToggle` sur le fond parchemin (spec visuelle
/// validée par l'agent `direction-artistique`). `_Header` n'a donc, à la
/// différence de `SpellsStepScreen._Header`, besoin d'aucune donnée chargée
/// et peut être affiché en permanence, y compris pendant le chargement —
/// `_MinimalHeader` est néanmoins conservé pour les états
/// chargement/erreur, copie exacte du pattern des étapes 4/6 (cohérence
/// visuelle avec le reste de l'assistant plutôt qu'une simplification
/// techniquement possible ici).
class EquipmentStepScreen extends ConsumerStatefulWidget {
  const EquipmentStepScreen({super.key});

  @override
  ConsumerState<EquipmentStepScreen> createState() =>
      _EquipmentStepScreenState();
}

class _EquipmentStepScreenState extends ConsumerState<EquipmentStepScreen> {
  static const int _totalSteps = 9;

  late EquipmentChoiceTab _activeTab;
  late Map<String, int> _cart;

  @override
  void initState() {
    super.initState();
    // Réhydrate la sélection depuis le brouillon déjà en mémoire (retour en
    // arrière depuis une étape suivante) — même rationale que les étapes
    // précédentes. Onglet "Historique" par défaut tant que "Suivant" n'a
    // jamais été validé sur cette étape (`equipmentChoiceTab` encore `null`).
    final draft = ref.read(characterCreationDraftControllerProvider);
    _activeTab = draft.equipmentChoiceTab ?? EquipmentChoiceTab.background;
    _cart = Map.of(draft.purchasedEquipment);
  }

  /// Bascule d'onglet : ne réinitialise jamais le panier "Acheter" (voir la
  /// documentation de classe).
  void _selectTab(EquipmentChoiceTab tab) {
    if (tab == _activeTab) return;
    setState(() => _activeTab = tab);
  }

  void _setQuantity(String name, int quantity) {
    setState(() {
      _cart = EquipmentStepSelection.setQuantity(
        current: _cart,
        name: name,
        quantity: quantity,
      );
    });
  }

  /// Toujours poussée depuis `/characters/new/step-5` ou
  /// `/characters/new/step-6` (selon que la classe choisie à l'étape 2 est
  /// lanceuse de sorts ou non, voir `skills_and_tools_step_screen.dart`) via
  /// `context.push` : `pop()` suffit, même rationale que les étapes
  /// précédentes.
  void _goBack() => context.pop();

  /// Met à jour le brouillon en mémoire et passe à l'étape suivante — aucun
  /// appel réseau ici, même rationale que les étapes précédentes.
  void _submit() {
    ref
        .read(characterCreationDraftControllerProvider.notifier)
        .setEquipment(activeTab: _activeTab, purchasedEquipment: _cart);
    context.push('/characters/new/step-8');
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(equipmentStepDataProvider);

    return Scaffold(
      body: dataAsync.when(
        data: _buildContent,
        loading: () => Column(
          children: [
            _MinimalHeader(onBack: _goBack),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          children: [
            _MinimalHeader(onBack: _goBack),
            Expanded(
              child: _ErrorState(
                message: error is CharacterCreationFailure
                    ? error.message
                    : "Impossible de charger l'équipement de départ. "
                          'Réessayez.',
                // Invalide les providers *feuilles* plutôt que le seul
                // `equipmentStepDataProvider` — même bug déjà corrigé sur
                // `SkillsAndToolsStepScreen`/`SpellsStepScreen` (voir leur
                // documentation) : invalider seulement le provider combiné
                // ne force pas un nouvel appel réseau sur celui des deux
                // catalogues qui a échoué.
                onRetry: () {
                  ref.invalidate(backgroundCatalogProvider);
                  ref.invalidate(itemCatalogProvider);
                  ref.invalidate(equipmentStepDataProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(EquipmentStepData data) {
    final items = data.itemCatalog.items;
    final spent = EquipmentStepSelection.totalCost(cart: _cart, items: items);
    final remainingGold = EquipmentStepSelection.remainingGold(
      startingGold: data.startingGold,
      spent: spent,
    );
    final isOverBudget = EquipmentStepSelection.isOverBudget(remainingGold);
    final canProceed = EquipmentStepSelection.canProceed(
      activeTab: _activeTab,
      remainingGold: remainingGold,
    );
    final isPurchaseTab = _activeTab == EquipmentChoiceTab.purchase;

    return Column(
      children: [
        _Header(onBack: _goBack, currentStep: 7, totalSteps: _totalSteps),
        Expanded(
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: SegmentedToggle<EquipmentChoiceTab>(
                    options: [
                      const SegmentedToggleOption(
                        value: EquipmentChoiceTab.background,
                        label: 'Historique',
                      ),
                      SegmentedToggleOption(
                        value: EquipmentChoiceTab.purchase,
                        label:
                            'Acheter '
                            '(${GoldAmountFormatter.format(data.startingGold)} po)',
                      ),
                    ],
                    value: _activeTab,
                    onChanged: _selectTab,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    children: isPurchaseTab
                        ? _shopSection(items)
                        : _historySection(data.historyEquipment),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      if (isPurchaseTab && isOverBudget)
                        _AlertBanner(
                          message:
                              'Budget dépassé de '
                              '${GoldAmountFormatter.format(-remainingGold)} po',
                        )
                      else
                        _GoldBanner(
                          label: isPurchaseTab ? 'OR RESTANT' : 'OR DE DÉPART',
                          amount: isPurchaseTab
                              ? remainingGold
                              : data.startingGold.toDouble(),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Retour',
                              surface: SecondaryButtonSurface.parchment,
                              onPressed: _goBack,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Suivant',
                              onPressed: canProceed ? _submit : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Contenu de l'onglet "Historique" : titre de section (sans badge, aucun
  /// quota ici) puis une carte non interactive par [BackgroundEquipmentEntry]
  /// — ou l'état vide si l'historique n'a aucun équipement (ne devrait
  /// normalement jamais arriver pour le contenu peuplé, voir
  /// `domain/background_equipment_parser.dart`, mais reste géré proprement).
  List<Widget> _historySection(List<BackgroundEquipmentEntry> entries) {
    if (entries.isEmpty) {
      return const [
        _EmptyState(message: 'Aucun équipement pour cet historique.'),
      ];
    }

    return [
      const _SectionHeader(title: "ÉQUIPEMENT DE L'HISTORIQUE"),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xs),
        _historyTile(entries[i], index: i),
      ],
    ];
  }

  Widget _historyTile(BackgroundEquipmentEntry entry, {required int index}) {
    return CheckableOptionTile(
      title: entry.name,
      subtitle: EquipmentCategoryRules.labelFor(entry.category),
      leading: AccentIconBadge(
        index: index,
        icon: EquipmentCategoryRules.iconFor(entry.category),
      ),
      checked: false,
      showIndicator: false,
    );
  }

  /// Contenu de l'onglet "Acheter" : le catalogue [items] groupé par
  /// catégorie, dans l'ordre fixe `EquipmentCategoryRules.shopSectionOrder`,
  /// tri alphabétique FR à l'intérieur de chaque groupe — catégories non
  /// peuplées (ex. `objet_magique`) simplement absentes, jamais affichées
  /// comme section vide.
  List<Widget> _shopSection(List<ItemOption> items) {
    if (items.isEmpty) {
      return const [_EmptyState(message: "Aucun objet disponible à l'achat.")];
    }

    final widgets = <Widget>[];
    var index = 0;
    for (final category in EquipmentCategoryRules.shopSectionOrder) {
      final categoryItems =
          items.where((item) => item.category == category).toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      if (categoryItems.isEmpty) continue;

      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }
      widgets.add(
        _SectionHeader(
          title: EquipmentCategoryRules.labelFor(category).toUpperCase(),
        ),
      );
      widgets.add(const SizedBox(height: AppSpacing.sm));
      for (var i = 0; i < categoryItems.length; i++) {
        if (i > 0) widgets.add(const SizedBox(height: AppSpacing.xs));
        widgets.add(_shopTile(categoryItems[i], index: index));
        index++;
      }
    }
    return widgets;
  }

  Widget _shopTile(ItemOption item, {required int index}) {
    final quantity = _cart[item.name] ?? 0;
    return CheckableOptionTile(
      title: item.name,
      subtitle:
          '${EquipmentCategoryRules.labelFor(item.category)} · '
          '${GoldAmountFormatter.format(item.costAmount)} po',
      leading: AccentIconBadge(
        index: index,
        icon: EquipmentCategoryRules.iconFor(item.category),
      ),
      checked: quantity > 0,
      showIndicator: false,
      trailing: StepperCounter(
        value: quantity,
        onIncrement: () => _setQuantity(item.name, quantity + 1),
        onDecrement: quantity > 0
            ? () => _setQuantity(item.name, quantity - 1)
            : null,
      ),
    );
  }
}

/// Titre de section ("ÉQUIPEMENT DE L'HISTORIQUE"/"ARME"/"ARMURE"...), sans
/// badge de quota — cette étape n'a aucune limite de choix, contrairement
/// aux étapes 5/9 et 6/9 (`_SectionHeader` de ces écrans, dupliqué ici pour
/// ne jamais coupler les étapes entre elles, même rationale que
/// `SpellRowMapper` dupliqué depuis `ToolRowMapper`).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.body(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
      ),
    );
  }
}

/// État vide discret (historique sans équipement, ou catalogue d'achat
/// vide) — icône neutre, message centré, jamais un `_ErrorState` complet
/// (ce n'est pas une erreur).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.inventory_2, size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Bandeau "OR DE DÉPART"/"OR RESTANT" (`docs/cahier-des-charges/10-design-system.md`
/// section 4, `AppBorders.cardEmphasis` doré) — montant en `textPrimary`
/// plutôt qu'en `gold.end` (contraste AA insuffisant sur ce fond, ~2.1:1,
/// vérifié par l'agent `direction-artistique` ; seule la bordure du bandeau
/// reste dorée).
class _GoldBanner extends StatelessWidget {
  const _GoldBanner({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.goldEnd,
          width: AppBorders.cardEmphasis,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${GoldAmountFormatter.format(amount)} po',
            style: AppTypography.body(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Bandeau d'alerte inline" du design système (section 4) : fond
/// `AppColors.alertBannerBackground`, bordure 2px `accent.brick`, icône
/// d'avertissement — remplace [_GoldBanner] sur l'onglet "Acheter" tant que
/// le budget est dépassé. Premier usage de ce composant sur le dépôt,
/// gardé privé à cet écran plutôt que promu dans `core/widgets/` (pas
/// d'autre écran ne l'utilise encore, voir la consigne d'origine) : à
/// extraire s'il devient réutilisé.
class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.accentBrick,
          width: AppBorders.card,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentBrick,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau bois plein en tête d'écran, avec le titre d'étape et la barre de
/// progression — voir la documentation de classe de [EquipmentStepScreen]
/// pour le rationale de cette différence avec `SpellsStepScreen._Header`
/// (pas de sélecteur d'onglets ici).
class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textOnWood,
                      ),
                    ),
                    Text(
                      'CRÉATION',
                      style: AppTypography.display(
                        fontSize: 11,
                        color: AppColors.textOnWood,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '7. Équipement',
                          style: AppTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnWood,
                          ),
                        ),
                        Text(
                          'Étape $currentStep / $totalSteps',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.textOnWoodMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StepProgressBar(
                      totalSteps: totalSteps,
                      currentStep: currentStep,
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
}

/// Bandeau bois minimal (retour + "CRÉATION" uniquement), affiché pendant le
/// chargement/l'erreur — copie exacte du pattern des étapes 4/6 (voir la
/// documentation de classe de [EquipmentStepScreen]).
class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textOnWood,
                ),
              ),
              Text(
                'CRÉATION',
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textOnWood,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
