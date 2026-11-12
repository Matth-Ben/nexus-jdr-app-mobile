import '../../l10n/app_localizations.dart';
import '../cache/sync_alert_store.dart';
import 'sync_alert_payload.dart';

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
