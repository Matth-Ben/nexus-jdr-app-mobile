import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/locale_preference_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/selectable_option_tile.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';

/// Sous-écran "Langue", route `/profile/language` — poussé depuis la tuile
/// "Langue" de `profile_screen.dart`. Chantier "traduction de l'app" Phase A
/// (infrastructure + réglage de langue uniquement) : les libellés de CET
/// écran sont les premiers textes migrés vers `AppLocalizations`
/// (`lib/l10n/app_fr.arb`/`app_en.arb`) — tout le reste de l'app reste en
/// français en dur pour l'instant (Phase B).
///
/// Même gabarit exact que `ProfileNotificationsScreen`/`ProfilePrivacyScreen`
/// (`WoodBackHeader` + corps parchemin scrollable), mais entièrement
/// synchrone (stockage `SharedPreferences` local, décision
/// direction-artistique) : pas d'état de chargement/erreur pleine page.
///
/// Trois `SelectableOptionTile` à choix exclusif
/// (`core/widgets/selectable_option_tile.dart`), dans cet ordre :
/// 1. "Langue du téléphone" (préférence par défaut, `LocalePreferenceController`
///    à `null`) — sous-titre fixe dans l'autre langue (indice bilingue
///    volontaire), et un `selectedDetail` bilingue visible uniquement quand
///    sélectionnée.
/// 2. "Français" (force `Locale('fr')`).
/// 3. "English" (force `Locale('en')`).
///
/// **Au tap** : appelle `LocalePreferenceController.setLocale` immédiatement
/// (pas de bouton "Valider"), reste sur l'écran — le re-rendu instantané du
/// titre/des libellés de CET écran (reconstruits via `AppLocalizations`, qui
/// dépend de `MaterialApp.router(locale: ...)` dans `main.dart`) sert
/// lui-même de confirmation visuelle (spec direction-artistique explicite :
/// pas de `SnackBar` de confirmation). Un `SnackBar` d'erreur générique
/// uniquement si l'écriture `SharedPreferences` échoue (filet de sécurité,
/// improbable en pratique — stockage 100% local synchrone).
class ProfileLanguageScreen extends ConsumerWidget {
  const ProfileLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localePreferenceControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: l10n.profileLanguageScreenTitle,
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  SelectableOptionTile(
                    title: l10n.profileLanguagePhoneOption,
                    subtitle: l10n.profileLanguagePhoneOptionSubtitle,
                    selected: locale == null,
                    selectedDetail: l10n.profileLanguagePhoneOptionDetail,
                    onTap: () => _setLocale(context, ref, null),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableOptionTile(
                    title: l10n.profileLanguageFrenchOption,
                    selected: locale?.languageCode == 'fr',
                    onTap: () => _setLocale(context, ref, const Locale('fr')),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableOptionTile(
                    title: l10n.profileLanguageEnglishOption,
                    selected: locale?.languageCode == 'en',
                    onTap: () => _setLocale(context, ref, const Locale('en')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setLocale(
    BuildContext context,
    WidgetRef ref,
    Locale? locale,
  ) async {
    try {
      await ref
          .read(localePreferenceControllerProvider.notifier)
          .setLocale(locale);
    } catch (_) {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.profileLanguageSaveError)));
    }
  }

  /// Même garde que `ProfileScreen._goBack`/`ProfileNotificationsScreen._goBack` :
  /// cet écran est normalement toujours atteint via
  /// `context.push('/profile/language')` (donc `canPop()` vrai), mais reste
  /// défensif si jamais poussé un jour comme route initiale (deep link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}
