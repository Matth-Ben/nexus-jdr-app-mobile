import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/push_notification_gateway.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../domain/notification_preferences.dart';
import 'providers/notification_preferences_providers.dart';

/// Sous-écran "Préférences de notifications", route `/profile/notifications`
/// — poussé depuis la tuile "Notifications" de `profile_screen.dart` (qui
/// affichait auparavant `_showComingSoon`, voir la doc de classe de
/// `ProfileScreen`).
///
/// Même gabarit exact que `ProfilePrivacyScreen`/`ProfileHelpScreen`
/// (`WoodBackHeader` + corps parchemin scrollable), mais avec un vrai état
/// asynchrone (contrairement à ces deux écrans, purement synchrones) :
/// `notificationPreferencesProvider` lit `notification_preferences`
/// (`data/notification_preferences_repository.dart`), table du chantier
/// backend "Notifications" —
/// `docs/cahier-des-charges/15-profil-parametres.md` section 3.
///
/// 2 groupes ("NOTIFICATIONS PUSH"/"EMAIL", `_SectionHeader`) de rangées
/// `_ToggleRow` — spec direction-artistique de la tâche. Les 2
/// sous-interrupteurs push ("Rappel de repos long"/"Accès à une histoire
/// retiré") sont grisés (`onChanged: null`) quand l'interrupteur global
/// "Activer les notifications push" est désactivé ; le switch email est
/// toujours indépendant du push.
///
/// **Bascule optimiste + revert** (voir [_toggle]) : chaque bascule met à
/// jour [_optimistic] immédiatement puis appelle
/// `NotificationPreferencesRepository.update` ; un échec réseau réaffiche la
/// valeur précédente et un `SnackBar` générique
/// ([_genericErrorMessage]) — jamais le détail technique de l'exception,
/// même discipline que `profile_help_screen.dart`/`report_bug_sheet.dart`.
/// [_optimistic] n'est jamais un second état de vérité : juste un vernis
/// affiché par-dessus la dernière valeur connue de
/// `notificationPreferencesProvider` (voir [_effective]) — même principe que
/// `character_detail_screen.dart::_effectiveDetail`.
///
/// **Activer le switch global déclenche la demande de permission OS**
/// (`FirebaseMessaging.instance.requestPermission()`, via
/// [PushNotificationGateway] — voir sa doc de classe) *avant* d'écrire
/// `push_enabled: true` en base (décision chef de projet, la DA ayant
/// remonté ce point comme hors de son périmètre) : le switch applicatif doit
/// refléter une capacité réelle, jamais une simple intention. Une permission
/// refusée n'écrit rien et affiche un [AlertBanner] (bandeau d'erreur/action
/// corrective — pas [InfoBanner], réservé à l'information neutre, voir la
/// doc de classe de `core/widgets/info_banner.dart`) au-dessus du groupe
/// "NOTIFICATIONS PUSH" (voir [_osPermissionDenied]) — pas de lien direct
/// vers les réglages système dans cette itération (même limite déjà assumée
/// pour les autorisations caméra/galerie de `ProfilePrivacyScreen`, voir
/// `widgets/device_permissions_sheet.dart`).
class ProfileNotificationsScreen extends ConsumerStatefulWidget {
  const ProfileNotificationsScreen({super.key});

  @override
  ConsumerState<ProfileNotificationsScreen> createState() =>
      _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState
    extends ConsumerState<ProfileNotificationsScreen> {
  NotificationPreferences? _optimistic;
  bool _osPermissionDenied = false;

  NotificationPreferences _effective(NotificationPreferences fetched) =>
      _optimistic ?? fetched;

  Future<void> _togglePushEnabled(
    NotificationPreferences current,
    bool value,
  ) async {
    if (value) {
      final settings = await ref
          .read(pushNotificationGatewayProvider)
          .requestPermission();
      if (!mounted) return;
      if (!isPushPermissionGranted(settings)) {
        setState(() => _osPermissionDenied = true);
        return;
      }
    }
    if (_osPermissionDenied) setState(() => _osPermissionDenied = false);
    await _toggle(current, pushEnabled: value);
  }

  Future<void> _toggle(
    NotificationPreferences current, {
    bool? pushEnabled,
    bool? pushRestReminder,
    bool? pushAccessRevoked,
    bool? emailDigestEnabled,
  }) async {
    setState(
      () => _optimistic = current.copyWith(
        pushEnabled: pushEnabled,
        pushRestReminder: pushRestReminder,
        pushAccessRevoked: pushAccessRevoked,
        emailDigestEnabled: emailDigestEnabled,
      ),
    );
    try {
      await ref
          .read(notificationPreferencesRepositoryProvider)
          .update(
            pushEnabled: pushEnabled,
            pushRestReminder: pushRestReminder,
            pushAccessRevoked: pushAccessRevoked,
            emailDigestEnabled: emailDigestEnabled,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _optimistic = current);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_genericErrorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: 'NOTIFICATIONS',
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: preferencesAsync.when(
              data: (fetched) => _buildBody(_effective(fetched)),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                onRetry: () => ref.invalidate(notificationPreferencesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NotificationPreferences prefs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader('NOTIFICATIONS PUSH'),
          const SizedBox(height: AppSpacing.sm),
          if (_osPermissionDenied) ...[
            const AlertBanner(
              message:
                  'Les notifications sont désactivées au niveau du '
                  "téléphone. Active-les dans les réglages de l'appareil "
                  'pour les recevoir.',
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _ToggleRow(
            icon: Icons.notifications_none,
            title: 'Activer les notifications push',
            value: prefs.pushEnabled,
            onChanged: (value) => _togglePushEnabled(prefs, value),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ToggleRow(
            title: 'Rappel de repos long',
            subtitle:
                "Te prévient si un personnage n'a pas fait de repos long "
                'depuis un moment.',
            value: prefs.pushRestReminder,
            onChanged: prefs.pushEnabled
                ? (value) => _toggle(prefs, pushRestReminder: value)
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ToggleRow(
            title: 'Accès à une histoire retiré',
            subtitle:
                'Te prévient si un MJ retire l\'accès de ton personnage à '
                'son histoire.',
            value: prefs.pushAccessRevoked,
            onChanged: prefs.pushEnabled
                ? (value) => _toggle(prefs, pushAccessRevoked: value)
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader('EMAIL'),
          const SizedBox(height: AppSpacing.sm),
          _ToggleRow(
            title: 'Recevoir un résumé par email',
            subtitle: 'Résumé hebdomadaire des personnages qui ont progressé.',
            value: prefs.emailDigestEnabled,
            onChanged: (value) => _toggle(prefs, emailDigestEnabled: value),
          ),
        ],
      ),
    );
  }

  /// Même garde que `ProfileScreen._goBack`/`ProfilePrivacyScreen._goBack` :
  /// cet écran est normalement toujours atteint via
  /// `context.push('/profile/notifications')` (donc `canPop()` vrai), mais
  /// reste défensif si jamais poussé un jour comme route initiale (deep
  /// link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

/// `SnackBar` générique d'échec d'écriture — jamais le détail technique de
/// l'exception affiché à l'utilisateur, même discipline que
/// `profile_help_screen.dart::_genericErrorMessage`.
const String _genericErrorMessage =
    "Impossible d'enregistrer ce réglage. Réessaie.";

/// Titre de section ("NOTIFICATIONS PUSH"/"EMAIL"), recréé localement plutôt
/// qu'un composant partagé — même précédent que
/// `character_creation/presentation/equipment_step_screen.dart::_SectionHeader`
/// (voir sa doc de classe pour le rationale de la duplication).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

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

/// Rangée "carte + interrupteur" du groupe "NOTIFICATIONS PUSH"/"EMAIL" —
/// nouveau composant local (un seul écran l'utilise pour l'instant, voir la
/// doc de classe de [ProfileNotificationsScreen]) : carte `parchment.card`,
/// bordure `wood.light` 2px constante (jamais de mise en avant dorée façon
/// `SelectableOptionTile` — un interrupteur n'est pas un choix exclusif).
///
/// [onChanged] à `null` grise la rangée (titre/sous-titre en
/// `color.text.muted`, `Switch` désactivé) — jamais un `Opacity` manuel, voir
/// [_AppSwitch].
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;

  /// Ligne de sous-titre optionnelle sous [title] — absente pour "Activer
  /// les notifications push" (voir [icon] à la place).
  final String? subtitle;

  /// Icône affichée à gauche de la rangée — seule "Activer les notifications
  /// push" en a une (spec direction-artistique de la tâche).
  final IconData? icon;
  final bool value;

  /// `null` -> rangée désactivée (grisée) — voir la doc de classe.
  final ValueChanged<bool>? onChanged;

  bool get _enabled => onChanged != null;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 22, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _enabled
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: _enabled
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _AppSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// `Switch` Material thématisé aux tokens "Interrupteur (switch)" de
/// `docs/cahier-des-charges/10-design-system.md` section 4 (ajoutés pour cet
/// écran) : piste ON `wood.medium`, piste OFF `wood.light`, pastille
/// `parchment.card`. Jamais `gold-end` comme piste (contraste insuffisant,
/// voir cette même entrée du design system).
///
/// **Approximation assumée** : l'API `Switch` de Flutter n'expose qu'un
/// contour de *piste* (`trackOutlineColor`), jamais de contour dédié à la
/// *pastille* — le liseré 1px `wood.dark` de la spec (pensé pour la
/// pastille) est donc appliqué à la piste, résultat visuel équivalent (un
/// contour `wood.dark` bien visible) sans widget entièrement réécrit à la
/// main pour ce seul écran.
///
/// État désactivé : couleurs de piste/pastille/contour toutes ramenées à un
/// alpha réduit (jamais un `Opacity` enveloppant tout le widget, qui
/// dimmerait aussi la zone de tap) — combiné au texte déjà en
/// `color.text.muted` côté [_ToggleRow], suffisant pour un rendu "grisé"
/// clair sans dépendre d'un token de désactivation Material par défaut (qui
/// n'aurait aucune raison de ressembler à cette palette parchemin/bois).
class _AppSwitch extends StatelessWidget {
  const _AppSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _disabledAlpha = 0.5;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.parchmentCard.withValues(alpha: _disabledAlpha)
            : AppColors.parchmentCard,
      ),
      trackColor: WidgetStateProperty.resolveWith((states) {
        final base = value ? AppColors.woodMedium : AppColors.woodLight;
        return states.contains(WidgetState.disabled)
            ? base.withValues(alpha: _disabledAlpha)
            : base;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.woodDark.withValues(alpha: _disabledAlpha)
            : AppColors.woodDark,
      ),
      trackOutlineWidth: const WidgetStatePropertyAll(1),
    );
  }
}

/// État d'erreur de chargement — même patron que
/// `character_detail_screen.dart::_ErrorState` (dupliqué ici, cette dernière
/// étant privée à son fichier) : icône `Icons.error_outline` 48px
/// `accent.brick`, `SecondaryButton` "Réessayer".
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

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
              'Impossible de charger tes préférences de notifications. '
              'Réessaie.',
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
