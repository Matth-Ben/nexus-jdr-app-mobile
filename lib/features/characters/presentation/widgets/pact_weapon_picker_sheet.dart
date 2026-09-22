import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_retry_state.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/pact_weapon_option.dart';
import '../../domain/pact_weapon_rules.dart';
import '../providers/pact_weapon_providers.dart';

/// Feuille « FORME DE L'ARME » (Pacte de la lame) : liste des armes de corps
/// à corps éligibles, un tap ferme la feuille et retourne l'arme choisie.
///
/// Aucune écriture ici : l'appelant fait l'upsert (voir
/// `PactWeaponRepository.setPactWeapon`). [currentWeaponId] marque la forme
/// courante ; la retaper ferme la feuille en renvoyant cette même arme (à
/// l'appelant de ne rien écrire). Fermer sans choisir renvoie `null`.
Future<PactWeaponOption?> showPactWeaponPickerSheet(
  BuildContext context, {
  int? currentWeaponId,
}) {
  return showModalBottomSheet<PactWeaponOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _PactWeaponPickerContent(currentWeaponId: currentWeaponId),
  );
}

class _PactWeaponPickerContent extends ConsumerStatefulWidget {
  const _PactWeaponPickerContent({required this.currentWeaponId});

  final int? currentWeaponId;

  @override
  ConsumerState<_PactWeaponPickerContent> createState() =>
      _PactWeaponPickerContentState();
}

class _PactWeaponPickerContentState
    extends ConsumerState<_PactWeaponPickerContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final optionsAsync = ref.watch(pactWeaponOptionsProvider);

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: "FORME DE L'ARME"),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher une arme...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  ),
                ),
              ),
              Expanded(
                child: optionsAsync.when(
                  data: _buildList,
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.woodMedium,
                    ),
                  ),
                  error: (error, stackTrace) => ErrorRetryState(
                    message: 'Impossible de charger les armes. Réessayez.',
                    onRetry: () => ref.invalidate(pactWeaponOptionsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<PactWeaponOption> options) {
    if (options.isEmpty) {
      return const _CenteredMessage('Aucune arme disponible.');
    }
    final filtered = PactWeaponRules.sortByName(
      PactWeaponRules.search(options, _searchController.text),
    );
    if (filtered.isEmpty) {
      return const _CenteredMessage('Aucune arme trouvée.');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        for (final option in filtered) ...[
          _WeaponRow(
            option: option,
            selected: option.id == widget.currentWeaponId,
            onTap: () => Navigator.of(context).pop(option),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTypography.body(color: AppColors.textMuted),
      ),
    );
  }
}

class _WeaponRow extends StatelessWidget {
  const _WeaponRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PactWeaponOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [?option.damageLabel, ?option.propertiesLabel].join(' · ');

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.parchmentCard : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: selected
                  ? Border.all(color: AppColors.goldEnd, width: AppBorders.card)
                  : null,
            ),
            child: Row(
              children: [
                _Radio(selected: selected),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.goldEnd : null,
        border: Border.all(
          color: selected ? AppColors.woodDark : AppColors.woodLight,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
