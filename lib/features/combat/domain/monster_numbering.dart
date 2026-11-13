/// Noms que recevront les monstres d'un ajout « ×N » — **aperçu** de la
/// numérotation (le serveur reste l'autorité, `add_npc_participants`).
///
/// N = 1 : le nom tel quel, sans suffixe. N > 1 : « Nom 1 … Nom N ». En cas de
/// collision avec des participants existants, la numérotation continue après
/// le plus grand suffixe déjà présent pour ce nom.
List<String> monsterNames(
  String baseName,
  int count, {
  Iterable<String> existingNames = const [],
}) {
  final base = baseName.trim();
  if (count <= 1) return [base];
  final pattern = RegExp(
    '^${RegExp.escape(base)}'
    r' (\d+)$',
    caseSensitive: false,
  );
  var highest = 0;
  for (final name in existingNames) {
    final match = pattern.firstMatch(name.trim());
    if (match == null) continue;
    final suffix = int.parse(match.group(1)!);
    if (suffix > highest) highest = suffix;
  }
  return [for (var i = 1; i <= count; i++) '$base ${highest + i}'];
}
