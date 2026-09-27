/// Une version publiée de l'app, telle que décrite dans `CHANGELOG.md`
/// (écran « Nouveautés » du profil).
class ChangelogRelease {
  const ChangelogRelease({
    required this.version,
    required this.notes,
    this.date,
  });

  /// Numéro de version, ex. `1.0.4`.
  final String version;

  /// Date de publication (`AAAA-MM-JJ`), `null` si absente de l'en-tête.
  final String? date;

  /// Lignes de notes à afficher aux joueurs.
  final List<String> notes;
}

/// Lit `CHANGELOG.md` (embarqué comme asset) et en extrait les versions
/// publiées, de la plus récente à la plus ancienne.
///
/// Seules les sections `## [X.Y.Z] — AAAA-MM-JJ …` qui contiennent un bloc
/// « Notes de version (stores) » sont renvoyées : ce sont les notes
/// rédigées pour les joueurs, le même texte que sur le Play Store (sans la
/// balise `<fr-FR>`). Les versions sans ce bloc (jamais publiées sur un
/// store) et la section `[Non publié]` sont ignorées.
abstract final class ChangelogParser {
  static final RegExp _header = RegExp(
    r'^##\s+\[([^\]]+)\](?:\s+—\s+(\d{4}-\d{2}-\d{2}))?',
  );

  static List<ChangelogRelease> parse(String markdown) {
    final releases = <ChangelogRelease>[];
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');

    String? version;
    String? date;
    var section = <String>[];

    void flush() {
      if (version != null && _isVersion(version)) {
        final notes = _storeNotes(section);
        if (notes != null && notes.isNotEmpty) {
          releases.add(
            ChangelogRelease(version: version, date: date, notes: notes),
          );
        }
      }
    }

    for (final line in lines) {
      final match = _header.firstMatch(line);
      if (match != null) {
        flush();
        version = match.group(1)!.trim();
        date = match.group(2);
        section = [];
      } else if (line.startsWith('## ')) {
        // Autre titre de niveau 2 (ex. « Publier une nouvelle version ») :
        // fin de la section de version en cours.
        flush();
        version = null;
        date = null;
        section = [];
      } else {
        section.add(line);
      }
    }
    flush();
    return releases;
  }

  static bool _isVersion(String value) =>
      RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value);

  /// Contenu du bloc de code qui suit « Notes de version », sans balises.
  static List<String>? _storeNotes(List<String> section) {
    final titleIndex = section.indexWhere(
      (line) => line.startsWith('###') && line.contains('Notes de version'),
    );
    if (titleIndex < 0) return null;
    final start = section.indexWhere(
      (line) => line.trim().startsWith('```'),
      titleIndex + 1,
    );
    if (start < 0) return null;
    final end = section.indexWhere(
      (line) => line.trim().startsWith('```'),
      start + 1,
    );
    if (end < 0) return null;
    return [
      for (final line in section.sublist(start + 1, end))
        if (!RegExp(r'^</?[a-z]{2}-[A-Z]{2}>$').hasMatch(line.trim()) &&
            line.trim().isNotEmpty)
          line.trim(),
    ];
  }
}
