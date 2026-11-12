import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../cache/sync_alert_store.dart';
import '../sync/sync_alert_payload.dart';
import '../sync/sync_banner_engine.dart';
import '../sync/sync_status_providers.dart';
import 'alert_banner.dart';
import 'info_banner.dart';
import 'sync_alerts_sheet.dart';

/// Bandeau de synchro hors-ligne (T2 du chantier hors-ligne) : **un seul**
/// état visible à la fois, silencieux en usage normal. Réutilise
/// [InfoBanner]/[AlertBanner], aucune nouvelle couleur. L'état vient de
/// `syncBannerProvider` (précédence et temporisations : [SyncBannerEngine]).
///
/// [characterId] renseigné : bandeau de la fiche (compteur de CE personnage,
/// « Hors ligne » affiché même sans modification en attente). `null` : bandeau
/// de la liste (total du compte, hors-ligne seulement si N > 0).
///
/// [visiblePadding] : marges autour du bandeau **uniquement quand il est
/// visible** (le placement diffère entre la fiche et la liste, voir leurs
/// écrans) ; rien n'est réservé quand il est masqué.
///
/// Alertes persistées : un seul bandeau « {N} alerte(s) de synchronisation »
/// qui ouvre le panneau (`showSyncAlertsSheet`), voir [_AlertSummaryBanner].
///
/// Accessibilité : région live seulement pour l'alerte (apparition), le
/// passage hors-ligne (libellé fixe, sans compteur : un changement de N
/// n'est jamais ré-annoncé) et « Synchronisé » ; jamais pour « en cours » ni
/// « en attente ». Icône + texte, jamais la couleur seule.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({
    required this.visiblePadding,
    this.characterId,
    super.key,
  });

  final String? characterId;
  final EdgeInsets visiblePadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncBannerProvider(characterId: characterId));
    final l10n = AppLocalizations.of(context)!;

    final Widget? banner = switch (state.kind) {
      SyncBannerKind.none => null,
      SyncBannerKind.alert => _AlertSummaryBanner(
        count: state.alertCount,
        onTap: () => unawaited(showSyncAlertsSheet(context)),
      ),
      SyncBannerKind.syncing => InfoBanner(
        icon: Icons.sync,
        message: l10n.syncBannerSyncing,
      ),
      SyncBannerKind.offline => Semantics(
        liveRegion: true,
        container: true,
        label: l10n.syncBannerOfflineSemantics,
        child: ExcludeSemantics(
          child: InfoBanner(
            icon: Icons.cloud_off_outlined,
            message: state.pendingCount > 0
                ? l10n.syncBannerOfflinePending(state.pendingCount)
                : l10n.syncBannerOfflineEmpty,
          ),
        ),
      ),
      SyncBannerKind.pending => InfoBanner(
        icon: Icons.cloud_upload_outlined,
        message: l10n.syncBannerPendingOnline(state.pendingCount),
      ),
      SyncBannerKind.synced => Semantics(
        liveRegion: true,
        container: true,
        child: InfoBanner(icon: Icons.check, message: l10n.syncBannerSynced),
      ),
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        // Clé par nature d'état, jamais par compteur : un changement de N met
        // le texte à jour sur place, sans fondu (ni nouvelle annonce).
        child: banner == null
            ? const SizedBox(key: ValueKey('none'), width: double.infinity)
            : Padding(
                key: ValueKey(state.kind),
                padding: visiblePadding,
                child: banner,
              ),
      ),
    );
  }
}

/// Bandeau « {N} alerte(s) de synchronisation · Voir les alertes » : entier
/// tappable, ouvre le panneau des alertes. Pas de bouton de fermeture : on
/// écarte les alertes depuis le panneau.
///
/// Sémantique : un seul nœud bouton « {N} alertes de synchronisation. Ouvrir
/// la liste. » (texte visible exclu). La région live n'est active qu'à
/// l'**apparition** du bandeau (premier rendu de cet état) : le widget la
/// retire dès l'image suivante, un changement de N ensuite met le libellé à
/// jour sans nouvelle annonce.
class _AlertSummaryBanner extends StatefulWidget {
  const _AlertSummaryBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  State<_AlertSummaryBanner> createState() => _AlertSummaryBannerState();
}

class _AlertSummaryBannerState extends State<_AlertSummaryBanner> {
  bool _live = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _live = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      button: true,
      liveRegion: _live,
      label: l10n.syncAlertsBannerSemantics(widget.count),
      onTap: widget.onTap,
      excludeSemantics: true,
      child: AlertBanner(
        message: l10n.syncAlertsBannerCount(widget.count),
        actionLabel: l10n.syncAlertsBannerAction,
        onTap: widget.onTap,
      ),
    );
  }
}

/// Message localisé d'une alerte persistée (abandon ou conflit) : valeurs
/// serveur dans le texte quand elles sont connues, texte de repli sinon.
///
/// Conflit (T8) : la valeur serveur citée est celle d'**avant l'envoi**, la
/// valeur appliquée celle de la file ; le nom du personnage est tronqué à
/// l'affichage ([syncAlertNameMaxLength] graphèmes). Valeur absente, ancienne
/// (persistée avant T8) ou mal formée : texte de repli, jamais d'exception.
///
/// V3-8 : la troncature du nom s'applique à tous les types d'alerte (abandon
/// compris) ; [truncateName] `false` rend le nom complet (sémantique).
String syncAlertMessage(
  AppLocalizations l10n,
  SyncAlert alert, {
  bool truncateName = true,
}) {
  final fullName = alert.characterName.isEmpty
      ? l10n.syncAlertUnknownCharacter
      : alert.characterName;
  final name = truncateName
      ? truncateForAlert(fullName, syncAlertNameMaxLength)
      : fullName;
  final value = alert.serverValue;
  int? intOf(String key) => (value?[key] as num?)?.toInt();

  switch (alert.kind) {
    case SyncAlertKind.conflict:
      try {
        final text = _conflictMessage(l10n, alert, name);
        if (text != null) return text;
      } catch (_) {
        // Valeur persistée inattendue : repli ci-dessous.
      }
      return l10n.syncAlertConflictFallback(name);
    case SyncAlertKind.abandon:
      switch (alert.dataKind) {
        case 'hp':
          final current = intOf('currentHp');
          final max = intOf('maxHp');
          if (current != null && max != null) {
            return l10n.syncAlertAbandonHp(name, current, max);
          }
        case 'xp':
          final xp = intOf('xp');
          if (xp != null) return l10n.syncAlertAbandonXp(name, xp);
        case 'spell_slot':
          final level = intOf('level');
          final remaining = intOf('remaining');
          final max = intOf('max');
          if (level != null && remaining != null && max != null) {
            return l10n.syncAlertAbandonSlot(name, level, remaining, max);
          }
      }
      return l10n.syncAlertAbandonFallback(name);
  }
}

String? _conflictMessage(AppLocalizations l10n, SyncAlert alert, String name) {
  final value = alert.serverValue;
  switch (alert.dataKind) {
    case 'hp':
      final hp = HpConflictValue.parse(value);
      if (hp == null) return null;
      if (hp.serverCurrent == hp.queuedCurrent &&
          hp.serverTemporary != hp.queuedTemporary) {
        return l10n.syncAlertConflictTempHp(
          name,
          hp.serverTemporary,
          hp.queuedTemporary,
        );
      }
      String hpText(int current, int temporary) {
        final base = hp.max == null ? '$current' : '$current/${hp.max}';
        return temporary > 0
            ? base + l10n.syncAlertTempHpSuffix(temporary)
            : base;
      }

      return l10n.syncAlertConflictHp(
        name,
        hpText(hp.serverCurrent, hp.serverTemporary),
        hpText(hp.queuedCurrent, hp.queuedTemporary),
      );
    case 'currency':
      final entries = parseCurrencyConflict(value);
      if (entries == null) return null;
      String unit(String column) => switch (column) {
        'currency_cp' => l10n.syncAlertCurrencyUnitCp,
        'currency_sp' => l10n.syncAlertCurrencyUnitSp,
        'currency_ep' => l10n.syncAlertCurrencyUnitEp,
        'currency_gp' => l10n.syncAlertCurrencyUnitGp,
        _ => l10n.syncAlertCurrencyUnitPp,
      };
      String list(int Function(CurrencyConflictEntry) amount) =>
          entries.map((e) => '${amount(e)} ${unit(e.column)}').join(', ');
      return l10n.syncAlertConflictCurrency(
        name,
        list((e) => e.server),
        list((e) => e.queued),
      );
    case 'inventory_item':
      final items = parseItemConflicts(value);
      if (items == null) return null;
      String build(int itemMax) {
        String cite(String itemName) => truncateForAlert(itemName, itemMax);
        if (items.length == 1) {
          final only = items.single;
          if (only.name == null) return '';
          return l10n.syncAlertConflictItem(
            name,
            cite(only.name!),
            only.server,
            only.queued,
          );
        }
        final named = items.where((e) => e.name != null).toList();
        if (named.length < 2) return '';
        return l10n.syncAlertConflictItems(
          name,
          cite(named[0].name!),
          cite(named[1].name!),
          items.length - 2,
        );
      }

      var text = build(syncAlertItemNameMaxLength);
      if (text.length > syncAlertLongTextThreshold) {
        text = build(syncAlertLongItemNameMaxLength);
      }
      return text.isEmpty ? null : text;
    case 'xp':
      final xp = parseXpConflict(value);
      if (xp == null) return null;
      return l10n.syncAlertConflictXp(name, xp.server, xp.queued);
  }
  return null;
}
