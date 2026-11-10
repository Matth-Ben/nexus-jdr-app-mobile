import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/display_text.dart';
import '../providers/character_edit_session_provider.dart';

/// Libellé du bandeau bois de chaque étape de l'assistant : « CRÉATION », ou
/// « MODIFICATION » quand une [CharacterEditSession] est ouverte.
///
/// Police pixel plafonnée par [DisplayText] (palier `title`, x1,3) : le style
/// est fixé ici (11 px, [AppColors.textOnWood]) pour que les écrans d'étape
/// n'appellent jamais `AppTypography.display` directement.
class CreationModeTitle extends ConsumerWidget {
  const CreationModeTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = ref.watch(characterEditSessionControllerProvider) != null;
    return DisplayText(
      editing ? 'MODIFICATION' : 'CRÉATION',
      style: AppTypography.display(fontSize: 11, color: AppColors.textOnWood),
    );
  }
}
