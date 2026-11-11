import 'package:flutter/widgets.dart' show StringCharacters;

/// Forme **structurée** (JSON, colonne `SyncAlerts.serverValue`, sans migration)
/// d'une alerte de conflit F19 (T8) et règles de dédoublonnage. Partagée par
/// l'enregistreur (`SyncAlertRecorder`, qui construit et fusionne) et le
/// bandeau (`syncAlertMessage`, qui lit) : une seule définition des clés.
///
/// Toute lecture est **tolérante** : une ligne persistée avant T8 (sans
/// `queued`), tronquée ou mal formée donne `null` et le bandeau retombe sur son
/// texte de repli, jamais d'exception.
///
/// Formes par `dataKind` :
/// - `hp` : `{currentHp, temporaryHp, maxHp?, queued: {currentHp, temporaryHp}}`
///   (serveur d'avant l'envoi ; `queued` = valeur appliquée) ;
/// - `currency` : `{currency_xx: serveur..., queued: {currency_xx: appliqué...}}`
///   (seules les monnaies en conflit) ;
/// - `inventory_item` : `{items: [{id, name?, server, queued}]}` ;
/// - `xp` : `{xp, queued}`.
abstract final class SyncAlertKeys {
  static const queued = 'queued';
  static const currentHp = 'currentHp';
  static const temporaryHp = 'temporaryHp';
  static const maxHp = 'maxHp';
  static const xp = 'xp';
  static const items = 'items';
  static const itemId = 'id';
  static const itemName = 'name';
  static const itemServer = 'server';
  static const itemQueued = 'queued';

  /// Colonnes de monnaie dans l'ordre d'affichage fixe : pc, pa, pe, po, pp.
  static const currencyColumns = [
    'currency_cp',
    'currency_sp',
    'currency_ep',
    'currency_gp',
    'currency_pp',
  ];
}

/// Longueur maximale (en graphèmes) du nom de personnage cité dans une alerte.
const int syncAlertNameMaxLength = 24;

/// Longueur maximale du nom d'objet cité, réduite à
/// [syncAlertLongItemNameMaxLength] quand le texte dépasse
/// [syncAlertLongTextThreshold] caractères.
const int syncAlertItemNameMaxLength = 24;
const int syncAlertLongItemNameMaxLength = 20;
const int syncAlertLongTextThreshold = 150;

/// Tronque [text] à [maxLength] **graphèmes** (jamais au milieu d'un émoji ou
/// d'un accent combiné) et ajoute « … » si quelque chose a été retiré.
String truncateForAlert(String text, int maxLength) {
  final chars = text.characters;
  if (chars.length <= maxLength) return text;
  return '${chars.take(maxLength)}…';
}

int? _intOrNull(Object? value) => value is num ? value.toInt() : null;

Map<String, dynamic>? _mapOrNull(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// PV d'une alerte de conflit lue de façon tolérante.
class HpConflictValue {
  const HpConflictValue({
    required this.serverCurrent,
    required this.serverTemporary,
    required this.queuedCurrent,
    required this.queuedTemporary,
    this.max,
  });

  final int serverCurrent;
  final int serverTemporary;
  final int queuedCurrent;
  final int queuedTemporary;
  final int? max;

  static HpConflictValue? parse(Map<String, dynamic>? value) {
    final queued = _mapOrNull(value?[SyncAlertKeys.queued]);
    final serverCurrent = _intOrNull(value?[SyncAlertKeys.currentHp]);
    final queuedCurrent = _intOrNull(queued?[SyncAlertKeys.currentHp]);
    if (serverCurrent == null || queuedCurrent == null) return null;
    return HpConflictValue(
      serverCurrent: serverCurrent,
      serverTemporary: _intOrNull(value?[SyncAlertKeys.temporaryHp]) ?? 0,
      queuedCurrent: queuedCurrent,
      queuedTemporary: _intOrNull(queued?[SyncAlertKeys.temporaryHp]) ?? 0,
      max: _intOrNull(value?[SyncAlertKeys.maxHp]),
    );
  }
}

/// Une monnaie en conflit : colonne, total serveur d'avant l'envoi, total appliqué.
typedef CurrencyConflictEntry = ({String column, int server, int queued});

/// Monnaies en conflit, dans l'ordre fixe pc, pa, pe, po, pp ; `null` si la
/// valeur est ancienne ou mal formée (aucune monnaie exploitable).
List<CurrencyConflictEntry>? parseCurrencyConflict(
  Map<String, dynamic>? value,
) {
  final queued = _mapOrNull(value?[SyncAlertKeys.queued]);
  if (value == null || queued == null) return null;
  final entries = <CurrencyConflictEntry>[];
  for (final column in SyncAlertKeys.currencyColumns) {
    final server = _intOrNull(value[column]);
    final applied = _intOrNull(queued[column]);
    if (server == null || applied == null) continue;
    entries.add((column: column, server: server, queued: applied));
  }
  return entries.isEmpty ? null : entries;
}

/// Un objet en conflit ([name] `null` : nom introuvable dans le cache).
typedef ItemConflictEntry = ({String id, String? name, int server, int queued});

List<ItemConflictEntry>? parseItemConflicts(Map<String, dynamic>? value) {
  final raw = value?[SyncAlertKeys.items];
  if (raw is! List) return null;
  final entries = <ItemConflictEntry>[];
  for (final element in raw) {
    if (element is! Map) continue;
    final server = _intOrNull(element[SyncAlertKeys.itemServer]);
    final queued = _intOrNull(element[SyncAlertKeys.itemQueued]);
    if (server == null || queued == null) continue;
    final name = element[SyncAlertKeys.itemName];
    entries.add((
      id: '${element[SyncAlertKeys.itemId] ?? ''}',
      name: name is String && name.trim().isNotEmpty ? name : null,
      server: server,
      queued: queued,
    ));
  }
  return entries.isEmpty ? null : entries;
}

/// XP d'une alerte de conflit : `(serveur, appliquée)`, `null` si illisible.
({int server, int queued})? parseXpConflict(Map<String, dynamic>? value) {
  final server = _intOrNull(value?[SyncAlertKeys.xp]);
  final queued = _intOrNull(value?[SyncAlertKeys.queued]);
  if (server == null || queued == null) return null;
  return (server: server, queued: queued);
}

/// Fusionne un nouveau conflit [incoming] dans l'alerte non fermée [existing]
/// de même (personnage, `dataKind`) : **plus ancienne valeur serveur**
/// conservée, **plus récente valeur appliquée** retenue. Une valeur [existing]
/// ancienne (avant T8, sans `queued`) ou illisible est simplement remplacée.
Map<String, dynamic> mergeConflictValue(
  String dataKind,
  Map<String, dynamic>? existing,
  Map<String, dynamic> incoming,
) {
  if (existing == null) return incoming;
  switch (dataKind) {
    case 'hp':
      if (HpConflictValue.parse(existing) == null) return incoming;
      return {
        SyncAlertKeys.currentHp: existing[SyncAlertKeys.currentHp],
        SyncAlertKeys.temporaryHp: existing[SyncAlertKeys.temporaryHp],
        SyncAlertKeys.maxHp:
            existing[SyncAlertKeys.maxHp] ?? incoming[SyncAlertKeys.maxHp],
        SyncAlertKeys.queued: incoming[SyncAlertKeys.queued],
      };
    case 'currency':
      final old = parseCurrencyConflict(existing);
      if (old == null) return incoming;
      final oldQueued = _mapOrNull(existing[SyncAlertKeys.queued])!;
      final newQueued = _mapOrNull(incoming[SyncAlertKeys.queued]) ?? {};
      final server = <String, dynamic>{};
      final queued = <String, dynamic>{};
      for (final column in SyncAlertKeys.currencyColumns) {
        if (existing[column] is num) {
          server[column] = existing[column];
          queued[column] = newQueued[column] ?? oldQueued[column];
        } else if (incoming[column] is num) {
          server[column] = incoming[column];
          queued[column] = newQueued[column];
        }
      }
      return {...server, SyncAlertKeys.queued: queued};
    case 'inventory_item':
      final old = parseItemConflicts(existing);
      final added = parseItemConflicts(incoming);
      if (old == null || added == null) return incoming;
      final merged = [...old];
      for (final item in added) {
        final index = merged.indexWhere((e) => e.id == item.id);
        if (index < 0) {
          merged.add(item);
        } else {
          merged[index] = (
            id: item.id,
            name: item.name ?? merged[index].name,
            server: merged[index].server,
            queued: item.queued,
          );
        }
      }
      return {
        SyncAlertKeys.items: [
          for (final e in merged)
            {
              SyncAlertKeys.itemId: e.id,
              SyncAlertKeys.itemName: e.name,
              SyncAlertKeys.itemServer: e.server,
              SyncAlertKeys.itemQueued: e.queued,
            },
        ],
      };
    case 'xp':
      if (parseXpConflict(existing) == null) return incoming;
      return {
        SyncAlertKeys.xp: existing[SyncAlertKeys.xp],
        SyncAlertKeys.queued: incoming[SyncAlertKeys.queued],
      };
  }
  return incoming;
}
