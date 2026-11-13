import 'package:flutter/widgets.dart';

/// Reduce motion : `disableAnimations` ou navigation accessible (lecteur
/// d'écran). Les widgets animés rendent alors leur enfant directement
/// (jamais `Duration.zero` sur un `AnimatedSize`).
bool combatReduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.accessibleNavigationOf(context);
