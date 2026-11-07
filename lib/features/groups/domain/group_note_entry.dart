/// Une entrée du carnet de notes personnel d'un membre pour un groupe
/// (`group_journal_entries`) — onglet "Notes" de l'écran "Groupe"
/// (`presentation/group_screen.dart`). Remplace l'ancien champ unique
/// `group_notes.body` (toujours en place pour compatibilité, voir
/// `group_note.dart`) par plusieurs entrées datées, une par étape/chapitre.
///
/// Personnel (décision utilisateur du 16/09/2026, inchangée par ce
/// fractionnement) : chaque membre ne lit/écrit que ses propres entrées,
/// jamais celles d'un coéquipier — RLS `auth.uid() = user_id` sur
/// `group_journal_entries`, même principe que `group_notes`.
///
/// Calque direct de `CharacterJournalEntry`
/// (`features/characters/domain/character_journal_entry.dart`), avec un
/// champ [title] nullable en plus — même classe simple (pas `freezed`), même
/// précédent.
class GroupNoteEntry {
  const GroupNoteEntry({
    required this.id,
    this.title,
    required this.body,
    required this.createdAt,
  });

  /// `group_journal_entries.id` (uuid).
  final String id;

  /// `group_journal_entries.title` — `null`/absent si le membre n'a pas
  /// donné de titre à cette entrée (champ optionnel, voir
  /// `group_note_entry_edit_sheet.dart`).
  final String? title;

  final String body;

  final DateTime createdAt;
}
