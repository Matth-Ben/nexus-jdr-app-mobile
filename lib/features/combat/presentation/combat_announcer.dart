import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Annonceur sémantique des feuilles et de l'écran Combat (surchargeable en
/// test).
typedef CombatSheetAnnouncer = void Function(BuildContext context, String text);

/// Annonce sémantique via `SemanticsService` (annonceur par défaut).
void defaultCombatAnnouncer(BuildContext context, String text) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    text,
    Directionality.of(context),
  );
}
