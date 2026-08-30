import 'package:freezed_annotation/freezed_annotation.dart';

part 'xml_raw_spell_entry.freezed.dart';

/// Une entrée `<innateSpell lvl="X">`/`<knownSpell lvl="X">` du XML
/// aidedd.org — [level] est le niveau du sort (0 = mineur), pas le niveau du
/// personnage, [name] est le nom du sort en clair.
@freezed
abstract class XmlRawSpellEntry with _$XmlRawSpellEntry {
  const factory XmlRawSpellEntry({required int level, required String name}) =
      _XmlRawSpellEntry;
}
