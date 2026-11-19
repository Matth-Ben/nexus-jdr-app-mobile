// Refus `combat_active` : le texte propre à l'action refusée (départ,
// dissolution, « Devenir MJ ») l'emporte sur le texte générique du code. Les
// textes FR/EN de chaque code sont vérifiés dans
// `test/features/characters/presentation/character_failure_l10n_test.dart`.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/presentation/group_failure_l10n.dart';
import 'package:personnages/l10n/app_localizations.dart';

void main() {
  testWidgets('combat_active : le texte propre à l\'action l\'emporte, '
      'seulement pour ce code ; sans délégué, le message brut', (tester) async {
    late AppLocalizations fr;
    late BuildContext bareContext;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fr'),
        delegates: AppLocalizations.localizationsDelegates,
        child: Builder(
          builder: (context) {
            fr = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          bareContext = context;
          return const SizedBox.shrink();
        },
      ),
    );
    const override = "Texte propre à l'action.";
    const combatActive = GroupFailure(
      'brut',
      code: GroupErrorCode.combatActive,
    );

    expect(
      combatActive.localizedWith(fr, combatActiveMessage: override),
      override,
    );
    expect(combatActive.localizedWith(fr), fr.groupCombatActiveErrorMessage);
    expect(
      const GroupFailure(
        'brut',
        code: GroupErrorCode.notMember,
      ).localizedWith(fr, combatActiveMessage: override),
      fr.groupNotMemberErrorMessage,
    );
    expect(
      combatActive.localized(bareContext, combatActiveMessage: override),
      'brut',
    );
  });
}
