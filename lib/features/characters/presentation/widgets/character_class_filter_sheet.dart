import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/checkable_option_tile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';

/// Sheet "Filtrer par classe" de la liste des personnages (icône entonnoir
/// de la barre de recherche, voir `character_list_screen.dart`) — choix
/// multiple via [CheckableOptionTile], même composant que l'étape 5/9
/// "Compétences et outils" de l'assistant de création.
///
/// Retourne le nouvel ensemble de classes sélectionnées, ou `null` si la
/// sheet est fermée sans "Appliquer" (croix, tap en dehors) — l'appelant ne
/// doit alors rien changer à son filtre actuel.
Future<Set<String>?> showCharacterClassFilterSheet(
  BuildContext context, {
  required List<String> availableClassNames,
  required Set<String> selectedClassNames,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _CharacterClassFilterSheetContent(
      availableClassNames: availableClassNames,
      initialSelection: selectedClassNames,
    ),
  );
}

class _CharacterClassFilterSheetContent extends StatefulWidget {
  const _CharacterClassFilterSheetContent({
    required this.availableClassNames,
    required this.initialSelection,
  });

  final List<String> availableClassNames;
  final Set<String> initialSelection;

  @override
  State<_CharacterClassFilterSheetContent> createState() =>
      _CharacterClassFilterSheetContentState();
}

class _CharacterClassFilterSheetContentState
    extends State<_CharacterClassFilterSheetContent> {
  late Set<String> _selection = {...widget.initialSelection};

  void _toggle(String className) {
    setState(() {
      if (!_selection.remove(className)) {
        _selection.add(className);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              const SheetHeaderBar(title: 'FILTRER PAR CLASSE'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    for (final className in widget.availableClassNames) ...[
                      CheckableOptionTile(
                        title: className,
                        checked: _selection.contains(className),
                        onTap: () => _toggle(className),
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
                        label: 'Réinitialiser',
                        surface: SecondaryButtonSurface.parchment,
                        onPressed: _selection.isEmpty
                            ? null
                            : () => setState(() => _selection = {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Appliquer',
                        onPressed: () => Navigator.of(context).pop(_selection),
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
}
