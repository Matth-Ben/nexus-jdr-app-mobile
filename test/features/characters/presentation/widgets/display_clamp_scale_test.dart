// Plafond de la police pixel (D192, PR 2) sur les cartes et feuilles de la
// fiche personnage : à x2,0 et x3,0 sur 320 et 360 dp, aucun débordement,
// aucun mot coupé en plein mot, aucun texte display sous 11 px effectifs et
// aucun agrandissement au-delà du palier (x1,5 au plus). Voir
// `display_scale_helpers.dart`.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_feat_summary.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/prepared_spells_limit.dart';
import 'package:personnages/features/characters/domain/spell_preparation_filter.dart';
import 'package:personnages/features/characters/presentation/widgets/character_appearance_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_armor_proficiencies_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_feats_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_capacity_gauge.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_item_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/character_invocations_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_languages_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/character_class_choices_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_race_choices_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_stat_pills_row.dart';
import 'package:personnages/features/characters/presentation/widgets/character_story_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/character_tool_proficiencies_card.dart';
import 'package:personnages/features/characters/presentation/widgets/character_weapon_proficiencies_card.dart';
import 'package:personnages/features/characters/presentation/widgets/connection_error_state.dart';
import 'package:personnages/features/characters/presentation/widgets/level_up_header.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_preparation_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/widgets/display_scale_helpers.dart';

const _wizard = CharacterDetailClassRow(
  classId: 1,
  className: 'Magicien',
  level: 3,
  isPrimary: true,
  savingThrowProficiencies: [],
  hitDie: 6,
);

const _longName = 'Épée longue enchantée de flamme éternelle';

CharacterDetail _detail({
  List<String> raceSkills = const [],
  List<CharacterInventoryItem> inventory = const [],
  List<CharacterSpellEntry> spells = const [],
  List<CharacterSpellSlot> spellSlots = const [],
  List<CharacterDetailClassRow> classes = const [],
}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: classes,
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: const {'str': 10},
  inventory: inventory,
  spells: spells,
  spellSlots: spellSlots,
  raceSkillChoiceNames: raceSkills,
  eyes: 'Vert émeraude',
  hair: 'Châtain clair',
  height: '1,75 m',
);

const _longItem = CharacterInventoryItem(
  id: 'i1',
  itemId: 1,
  name: _longName,
  category: 'arme',
  quantity: 1,
  equipped: true,
  isAttuned: true,
  totalWeight: 1.5,
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d8',
    damageType: 'tranchant',
    properties: [],
  ),
);

Widget _inventoryTab(CharacterDetail detail) => CharacterInventoryTabBody(
  detail: detail,
  actionsDisabled: false,
  onUseItem: (_) {},
  onToggleItemEquipped: (_) {},
  onToggleItemAttuned: (_) {},
  onRemoveItem: (_) {},
  onAdjustCurrency: (_, _) {},
  onAddInventoryItem: (_, _) {},
  onAddCustomInventoryItem: (
    name,
    quantity, {
    description,
    damageDice,
    damageType,
    properties = const [],
  }) {},
  onEquipWeaponToSlot: (_, _) {},
);

Widget _spellsTab(CharacterDetail detail) => CharacterSpellsTabBody(
  detail: detail,
  onCastSpell: (_, _) {},
  onTogglePrepared: (_) {},
  onUseFeature: (_) {},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(loadAppFonts);

  // Cartes simples (titre display + contenu).
  displayScaleMatrix(
    'carte Outils',
    () => const CharacterToolProficienciesCard(names: ['Outils de voleur']),
  );
  displayScaleMatrix(
    'carte Langues',
    () => const CharacterLanguagesCard(names: ['Commun', 'Elfique']),
  );
  displayScaleMatrix(
    'carte Invocations',
    () => const CharacterInvocationsCard(names: ['Armure d’ombres']),
  );
  displayScaleMatrix(
    'carte Dons',
    () => const CharacterFeatsCard(
      feats: [CharacterFeatSummary(name: 'Sentinelle', description: 'Texte')],
    ),
  );
  displayScaleMatrix(
    'carte Armures',
    () => CharacterArmorProficienciesCard(
      names: const ['Armures légères'],
      onTapToken: (_) {},
    ),
  );
  displayScaleMatrix(
    'carte Armes',
    () => CharacterWeaponProficienciesCard(
      names: const ['Armes courantes'],
      onTapToken: (_) {},
    ),
  );
  displayScaleMatrix(
    'carte Apparence',
    () => CharacterAppearanceCard(detail: _detail()),
  );
  displayScaleMatrix(
    'carte Choix de race',
    () => CharacterRaceChoicesCard(
      detail: _detail(raceSkills: const ['Perception', 'Discrétion']),
    ),
  );
  displayScaleMatrix(
    'carte Choix de classe',
    () => CharacterClassChoicesCard(
      detail: _detail(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Magicien',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: [],
            hitDie: 6,
            subclassName: 'École d’évocation',
          ),
        ],
      ),
    ),
  );
  displayScaleMatrix(
    'jauge de capacité d’inventaire',
    () => CharacterInventoryCapacityGauge(detail: _detail()),
  );
  displayScaleMatrix(
    'en-tête de montée de niveau',
    () => const LevelUpHeader(
      eyebrow: 'MONTÉE DE NIVEAU',
      levelLabel: 'NIVEAU 4',
    ),
    scroll: false,
    minDisplayTexts: 2,
  );
  displayScaleMatrix(
    'état d’erreur de connexion',
    () => ConnectionErrorState(onRetry: () {}),
    scroll: false,
  );

  // V3-1 : carte « PRÉPARATION DES SORTS » et compteur « SORTS PRÉPARÉS 2/2 ».
  displayScaleMatrix(
    'carte préparation des sorts (V3-1)',
    () => SpellPreparationCard(
      filter: SpellPreparationFilter.all,
      onFilterChanged: (_) {},
      classLimits: const [
        ClassPreparedSpells(
          classId: 1,
          className: 'Magicien',
          limit: 2,
          preparedCount: 2,
        ),
      ],
    ),
    minDisplayTexts: 2,
  );

  // V3-1 : onglet Sorts (EMPLACEMENTS DE SORTS, sections de sorts).
  displayScaleMatrix(
    'onglet Sorts (V3-1)',
    () => _spellsTab(
      _detail(
        classes: const [_wizard],
        spells: const [
          CharacterSpellEntry(
            id: 1,
            name: 'Lumière',
            level: 0,
            school: 'Évocation',
            status: SpellStatus.known,
          ),
          CharacterSpellEntry(
            id: 2,
            name: 'Projectile magique',
            level: 1,
            school: 'Évocation',
            status: SpellStatus.prepared,
          ),
        ],
        spellSlots: const [CharacterSpellSlot(level: 1, total: 4, used: 1)],
      ),
    ),
    scroll: false,
    minDisplayTexts: 2,
  );
  displayScaleMatrix(
    'onglet Sorts sans sorts (état vide)',
    () => _spellsTab(_detail(classes: const [_wizard])),
    scroll: false,
  );

  // V3-1 : inventaire, le nom de l'objet reste lisible (sur sa ligne).
  displayScaleMatrix(
    'fiche d’objet d’inventaire (V3-1)',
    () => const CharacterInventoryItemCard(item: _longItem),
    minDisplayTexts: 0,
    afterPump: (tester) async {
      expect(find.text(_longName), findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.text(_longName),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
    },
  );
  displayScaleMatrix(
    'onglet Inventaire (V3-1)',
    () => _inventoryTab(_detail(inventory: const [_longItem])),
    scroll: false,
    afterPump: (tester) async {
      expect(find.text(_longName), findsOneWidget);
    },
  );
  displayScaleMatrix(
    'onglet Inventaire vide',
    () => _inventoryTab(_detail()),
    scroll: false,
  );
  displayScaleMatrix(
    'onglet Histoire (état vide)',
    () => CharacterStoryTabBody(detail: _detail(), onEdit: () {}),
    scroll: false,
  );

  // V3-2 : tuiles VIT./CA/INIT./INSP. (corps de texte, FittedBox) : libellés
  // complets, sans « IN… » ni débordement (VIT. : 27 px à x3,0 sur 411 dp).
  displayScaleMatrix(
    'tuiles VIT./CA/INIT./INSP. (V3-2)',
    () => const CharacterStatPillsRow(
      speed: 30,
      armorClass: 15,
      armorClassBonus: 2,
      initiative: 3,
      inspiration: true,
    ),
    minDisplayTexts: 0,
    widths: [320.0, 360.0, 411.0],
    afterPump: (tester) async {
      for (final label in ['VIT.', 'CA', 'INIT.', 'INSP.']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text(label),
            matching: find.byType(RichText),
          ),
        );
        expect(paragraph.text.toPlainText(), label);
        // Taille effective à l'écran : taille du texte agrandie, réduite par
        // le FittedBox ancêtre (échelle du transform) ; jamais sous 11 px.
        final scale = paragraph.getTransformTo(null).getMaxScaleOnAxis();
        final effective = paragraph.textScaler.scale(11) * scale;
        expect(
          effective,
          greaterThanOrEqualTo(11),
          reason: '$label : $effective px',
        );
        // Libellé complet : la largeur de mise en page contient le mot.
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
      }
    },
  );
}
