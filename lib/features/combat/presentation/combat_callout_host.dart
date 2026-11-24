import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/route_stack_observer.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/grimoire_combat_view.dart';
import 'combat_announcer.dart';
import 'combat_motion.dart';
import 'providers/combat_callout_providers.dart';
import 'providers/grimoire_combat_providers.dart';
import 'providers/grimoire_groups_providers.dart';
import 'widgets/combat_callout.dart';

/// Pose le signal global de combat ([combatCalloutControllerProvider]) en bas
/// de l'écran, au-dessus de [child] (le navigateur de l'app) — à placer dans
/// `MaterialApp.router(builder: ...)` (`docs/combat-grimoire-ui.md` §5, §6).
///
/// - Un seul signal à la fois, flottant, marges `lg`, au-dessus de la barre
///   d'onglets de la page ([RouteStackObserver.visibleBottomBar]) et du
///   clavier ; jamais en haut.
/// - Masqué tant qu'une feuille modale ou une boîte de dialogue est ouverte :
///   il apparaît à sa fermeture. « À toi de jouer » : haptique et annonce
///   assertive **tout de suite**, même feuille ouverte.
/// - Variante annonce retirée après 10 s, sauf `accessibleNavigation` ;
///   variante tour jamais retirée par une minuterie.
/// - Toucher : écran Combat du groupe (poussé : le retour ramène à l'écran
///   d'où le joueur venait), signal retiré.
/// - Entrée en fondu + glissement de 8 dp (200 ms), sortie en fondu (150 ms) ;
///   immédiat en reduce motion.
class CombatCalloutHost extends ConsumerStatefulWidget {
  const CombatCalloutHost({
    required this.child,
    this.assertiveAnnouncer,
    super.key,
  });

  final Widget child;

  /// Annonceur **assertif** (« C'est ton tour. »), surchargeable en test.
  final CombatSheetAnnouncer? assertiveAnnouncer;

  @override
  ConsumerState<CombatCalloutHost> createState() => _CombatCalloutHostState();
}

class _CombatCalloutHostState extends ConsumerState<CombatCalloutHost> {
  Timer? _announceTimer;

  /// Signal dont la minuterie de 10 s tourne.
  int? _timedId;

  @override
  void dispose() {
    _announceTimer?.cancel();
    super.dispose();
  }

  /// Nouveau signal « À toi de jouer » : un seul retour haptique et une
  /// annonce assertive, même s'il est encore masqué par une feuille.
  void _onCallout(CombatCallout? previous, CombatCallout? next) {
    if (next == null || next.id == previous?.id || !next.isTurn) return;
    unawaited(HapticFeedback.mediumImpact());
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    (widget.assertiveAnnouncer ?? defaultCombatAssertiveAnnouncer)(
      context,
      l10n.combatAnnounceYourTurn,
    );
  }

  /// Minuterie de la variante annonce, comptée depuis son affichage
  /// effectif ; suspendue tant qu'il est masqué.
  void _syncTimer(CombatCallout? shown, {required bool accessible}) {
    final id = shown == null || shown.isTurn || accessible ? null : shown.id;
    if (id == _timedId) return;
    _announceTimer?.cancel();
    _announceTimer = null;
    _timedId = id;
    if (id == null) return;
    _announceTimer = Timer(kCombatCalloutAnnounceDuration, () {
      _announceTimer = null;
      _timedId = null;
      if (mounted) {
        ref.read(combatCalloutControllerProvider.notifier).dismiss(id);
      }
    });
  }

  void _open(CombatCallout callout) {
    ref.read(combatCalloutControllerProvider.notifier).dismiss(callout.id);
    unawaited(
      ref.read(appRouterProvider).push('/groups/${callout.groupId}/combat'),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CombatCallout?>(combatCalloutControllerProvider, _onCallout);
    final callout = ref.watch(combatCalloutControllerProvider);
    final routes = ref.watch(routeStackObserverProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        ListenableBuilder(
          listenable: routes,
          builder: (context, _) {
            final shown =
                callout != null &&
                    !routes.overlayOpen &&
                    !ref
                        .read(combatCalloutControllerProvider.notifier)
                        .isCombatScreenOf(callout.groupId)
                ? callout
                : null;
            final accessible = MediaQuery.accessibleNavigationOf(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _syncTimer(shown, accessible: accessible);
            });
            return _position(context, routes, shown);
          },
        ),
      ],
    );
  }

  Widget _position(
    BuildContext context,
    RouteStackObserver routes,
    CombatCallout? shown,
  ) {
    final media = MediaQuery.of(context);
    final bottom =
        math.max(
          media.viewInsets.bottom,
          math.max(media.viewPadding.bottom, routes.visibleBottomBar),
        ) +
        AppSpacing.lg;
    final Widget content = shown == null
        ? const SizedBox.shrink(key: ValueKey('combatCalloutNone'))
        : KeyedSubtree(
            key: ValueKey('combatCallout-${shown.id}'),
            child: _Callout(
              callout: shown,
              maxHeight: math.max(56, media.size.height * 0.25),
              onOpen: () => _open(shown),
              onClose: () => ref
                  .read(combatCalloutControllerProvider.notifier)
                  .dismiss(shown.id),
            ),
          );
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      bottom: bottom,
      child: combatReduceMotion(context)
          ? content
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              reverseDuration: const Duration(milliseconds: 150),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.bottomCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: AnimatedBuilder(
                  animation: animation,
                  // Glissement de 8 dp à l'entrée seulement : la sortie est
                  // un simple fondu.
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      0,
                      animation.status == AnimationStatus.reverse
                          ? 0
                          : (1 - animation.value) * 8,
                    ),
                    child: child,
                  ),
                  child: child,
                ),
              ),
              child: content,
            ),
    );
  }
}

/// Textes du signal [callout], lus dans le suivi du groupe (nom, round,
/// initiative à envoyer) au moment de l'affichage.
class _Callout extends ConsumerWidget {
  const _Callout({
    required this.callout,
    required this.maxHeight,
    required this.onOpen,
    required this.onClose,
  });

  final CombatCallout callout;
  final double maxHeight;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groupId = callout.groupId;
    final group = ref.watch(
      myGroupMembershipsProvider.select((memberships) {
        for (final membership in memberships ?? const []) {
          if (membership.groupId == groupId) return membership.groupName;
        }
        return '';
      }),
    );
    final info = ref.watch(
      grimoireCombatProvider(groupId).select((session) {
        final view = session.view;
        return (
          canSend:
              view.isRunning &&
              !view.removedFromCombat &&
              view.initiative.canSend,
          round: view.status == GrimoireCombatStatus.active ? view.round : null,
        );
      }),
    );
    final named = group.trim().isNotEmpty;
    final String title;
    final String body;
    switch (callout.kind) {
      case CombatCalloutKind.combatStart:
      case CombatCalloutKind.initiativeRequested:
        title = callout.kind == CombatCalloutKind.combatStart
            ? l10n.combatShout
            : l10n.combatCalloutInitiativeTitle;
        body = info.canSend
            ? (named
                  ? l10n.combatCalloutSendInitiative(group)
                  : l10n.combatBannerSendInitiative)
            : (named ? l10n.combatCalloutOpen(group) : l10n.combatBannerOpen);
      case CombatCalloutKind.yourTurn:
        title = l10n.combatYourTurn;
        final round = info.round;
        body = !named
            ? l10n.combatBannerOpen
            : round == null
            ? l10n.combatCalloutOpen(group)
            : l10n.combatCalloutYourTurnBody(group, round);
    }
    return CombatCalloutView(
      variant: callout.isTurn
          ? CombatCalloutVariant.turn
          : CombatCalloutVariant.announce,
      title: title,
      body: body,
      openLabel: l10n.combatBannerOpen,
      closeLabel: l10n.combatCalloutClose,
      onOpen: onOpen,
      onClose: onClose,
      maxHeight: maxHeight,
    );
  }
}
