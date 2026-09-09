/// Une entrée du journal de campagne de l'onglet "Histoire"
/// (`character_journal_entries`) — voir `docs/cahier-des-charges/`
/// 11-fonctionnalites-a-ajouter.md, section "Onglet Histoire" : "Journal de
/// campagne / notes de séance (distinct du backstory figé)."
///
/// Distinct de `CharacterDetail.backstoryText` (et des 8 autres champs de
/// texte libre figés de cet onglet) : une liste d'entrées horodatées,
/// éditables/supprimables indépendamment les unes des autres, plutôt qu'un
/// unique champ de texte remplacé en bloc.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `CharacterGalleryPhoto`/`CharacterSpellEntry`.
class CharacterJournalEntry {
  const CharacterJournalEntry({
    required this.id,
    required this.body,
    required this.createdAt,
  });

  /// `character_journal_entries.id` (uuid).
  final String id;

  final String body;

  final DateTime createdAt;
}
