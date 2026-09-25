import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/character_edit_session_provider.dart';

/// Libellé du bandeau bois de chaque étape de l'assistant : « CRÉATION », ou
/// « MODIFICATION » quand une [CharacterEditSession] est ouverte.
class CreationModeTitle extends ConsumerWidget {
  const CreationModeTitle({required this.style, super.key});

  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = ref.watch(characterEditSessionControllerProvider) != null;
    return Text(editing ? 'MODIFICATION' : 'CRÉATION', style: style);
  }
}
