import 'dart:math';

/// UUID v4 aléatoire (RFC 9562), en minuscules : identifiant généré côté
/// client pour une ligne que le serveur accepte avec un `id` explicite
/// (`uuid primary key default gen_random_uuid()`), ex. une entrée de journal
/// créée hors ligne. `package:uuid` n'est pas déclaré dans ce dépôt : seize
/// octets aléatoires suffisent. [random] n'est injecté que par les tests.
String generateUuidV4([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{12}$',
);

/// `true` si [value] a la forme canonique d'un UUID (8-4-4-4-12 hexadécimal).
bool isUuid(String value) => _uuidPattern.hasMatch(value);
