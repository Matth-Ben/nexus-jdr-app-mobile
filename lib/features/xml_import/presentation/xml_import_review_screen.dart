import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/selectable_option_tile.dart';
import '../../../core/widgets/sheet_header_bar.dart';
import '../../character_creation/domain/ability_score_definitions.dart';
import '../../character_creation/domain/character_creation_failure.dart';
import '../../character_creation/domain/spell_option.dart';
import '../../characters/presentation/providers/character_providers.dart';
import '../domain/aidedd_reference_tables.dart';
import '../domain/xml_character_import_resolved.dart';
import '../domain/xml_field_resolution.dart';
import '../domain/xml_import_alert_summary.dart';
import '../domain/xml_import_save_data_resolver.dart';
import 'providers/xml_import_providers.dart';

/// Écran de vérification/récapitulatif de l'import XML aidedd.org
/// (`docs/cahier-des-charges/03-import-xml-aidedd.md`, points 5/6 du
/// "Comportement attendu de l'import" — spec visuelle produite par l'agent
/// `direction-artistique`, voir la consigne d'origine de la tâche).
///
/// Niveau scène "Parchemin" : `Scaffold` classique avec un bandeau bois plein
/// posé manuellement au sommet (`_Header`/`_MinimalHeader`), même patron que
/// les écrans de l'assistant de création (`race_step_screen.dart` et
/// consorts) — pas `SceneScaffold`.
///
/// Toute la mécanique de résolution (parsing + catalogues + résolution
/// aidedd) vit dans `presentation/providers/xml_import_providers.dart`
/// (`xmlImportReviewControllerProvider`) : cet écran ne fait qu'afficher son
/// état et déléguer les corrections manuelles au contrôleur.
class XmlImportReviewScreen extends ConsumerStatefulWidget {
  const XmlImportReviewScreen({
    required this.fileName,
    required this.xmlSource,
    super.key,
  });

  final String fileName;
  final String xmlSource;

  @override
  ConsumerState<XmlImportReviewScreen> createState() =>
      _XmlImportReviewScreenState();
}

class _XmlImportReviewScreenState extends ConsumerState<XmlImportReviewScreen> {
  bool _isSaving = false;
  String? _saveErrorMessage;

  /// Type inféré depuis l'expression (pas d'annotation explicite) : évite de
  /// dépendre du nom exact de la classe générée par `riverpod_generator` pour
  /// un provider `family` (`XmlImportReviewControllerProvider`, connue
  /// seulement après `build_runner`) — un simple champ `late final` suffit,
  /// aucun des appelants ci-dessous n'a besoin d'écrire ce type au clavier.
  late final _provider = xmlImportReviewControllerProvider(
    fileName: widget.fileName,
    xmlSource: widget.xmlSource,
  );

  /// Retour au sélecteur de fichier — rien n'est encore sauvegardé, aucune
  /// confirmation nécessaire (voir la spec visuelle). Ce dépôt n'a pas
  /// d'écran de sélecteur de fichier dédié (sélection via le dialogue natif
  /// `file_picker` depuis `CharacterListScreen`, voir sa documentation) :
  /// `pop()` revient donc simplement à la liste des personnages, d'où un
  /// nouvel import peut être relancé.
  void _goBack() {
    if (_isSaving) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(_provider);

    return Scaffold(
      body: Stack(
        children: [
          dataAsync.when(
            data: (data) => Column(
              children: [
                _Header(
                  title: 'VÉRIFICATION IMPORT',
                  subtitle: '${widget.fileName} importé depuis aidedd.org',
                  onBack: _goBack,
                ),
                Expanded(child: _buildContent(context, data)),
              ],
            ),
            loading: () => Column(
              children: [
                _Header(
                  title: 'VÉRIFICATION IMPORT',
                  subtitle: 'Analyse de ${widget.fileName} en cours...',
                  onBack: _goBack,
                ),
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.woodMedium,
                    ),
                  ),
                ),
              ],
            ),
            error: (error, stackTrace) => _buildError(context, error),
          ),
          if (_isSaving) const _SavingOverlay(),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    if (error is XmlImportInvalidFileFailure) {
      return Column(
        children: [
          _Header(
            title: 'VÉRIFICATION IMPORT',
            subtitle: '${widget.fileName} — échec de l\'analyse',
            onBack: _goBack,
          ),
          Expanded(
            child: _InvalidFileErrorState(
              message: error.message,
              onPickAnother: _goBack,
            ),
          ),
        ],
      );
    }

    // Erreur réseau (chargement des catalogues) — pas de rendu dédié dans la
    // spec visuelle pour ce cas (seul "XML invalide" y est décrit) : repli
    // sur le patron générique déjà utilisé par le reste de l'app
    // (message + bouton "Réessayer"), signalé ici plutôt qu'improvisé
    // silencieusement.
    return Column(
      children: [
        _Header(
          title: 'VÉRIFICATION IMPORT',
          subtitle: '${widget.fileName} importé depuis aidedd.org',
          onBack: _goBack,
        ),
        Expanded(
          child: _NetworkErrorState(
            message: error is CharacterCreationFailure
                ? error.message
                : 'Impossible de charger les données de référence. '
                      'Réessayez.',
            onRetry: () => ref.invalidate(_provider),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, XmlImportReviewData data) {
    final unresolvedCount = XmlImportAlertSummary.countUnresolved(
      data.resolved,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: _buildRows(context, data),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              if (unresolvedCount == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Tous les champs ont été reconnus automatiquement.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentTeal,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    unresolvedCount == 1
                        ? '1 champ à vérifier avant l\'enregistrement.'
                        : '$unresolvedCount champs à vérifier avant '
                              'l\'enregistrement.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentBrick,
                    ),
                  ),
                ),
              if (_saveErrorMessage != null) ...[
                AlertBanner(message: _saveErrorMessage!),
                const SizedBox(height: AppSpacing.sm),
              ],
              PrimaryButton(
                label: 'Valider le personnage',
                isLoading: _isSaving,
                onPressed: _isSaving
                    ? null
                    : () => _handleValidate(context, data, unresolvedCount),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Décision produit (revue `qa-testeur`/`code-reviewer`) : contrairement à
  /// tous les autres champs (jamais bloquants, voir la spec visuelle
  /// d'origine), la race et la classe restent les deux SEULS champs qui
  /// bloquent réellement "Valider le personnage" tant qu'ils sont
  /// [XmlFieldResolution.unrecognized] — un personnage sans classe résolue
  /// serait structurellement invalide partout ailleurs dans l'app (bonus de
  /// maîtrise, emplacements de sorts, dés de vie), exactement comme
  /// l'assistant de création manuel ne permet déjà pas de créer un
  /// personnage sans classe choisie dans un catalogue réel. Pas de dialogue
  /// de confirmation pour ce cas : un blocage direct (message réutilisant
  /// [AlertBanner], même widget que l'échec de sauvegarde) invitant à
  /// corriger, la sauvegarde n'est même pas tentée.
  Future<void> _handleValidate(
    BuildContext context,
    XmlImportReviewData data,
    int unresolvedCount,
  ) async {
    setState(() => _saveErrorMessage = null);

    final raceBlocked = data.resolved.race.isUnrecognized;
    final classBlocked = data.resolved.characterClass.isUnrecognized;
    if (raceBlocked || classBlocked) {
      final missingFields = [
        if (raceBlocked) 'la race',
        if (classBlocked) 'la classe',
      ].join(' et ');
      setState(() {
        _saveErrorMessage =
            'Corrigez d\'abord $missingFields avant d\'enregistrer ce '
            'personnage.';
      });
      return;
    }

    if (unresolvedCount > 0) {
      final shouldContinue = await _showUnresolvedFieldsDialog(context);
      if (shouldContinue != true) return;
      if (!context.mounted) return;
    }
    await _save(data);
  }

  Future<bool?> _showUnresolvedFieldsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.parchmentCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(
            color: AppColors.woodLight,
            width: AppBorders.card,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHAMPS NON RÉSOLUS',
                style: AppTypography.display(fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Certains éléments importés n\'ont pas pu être reconnus '
                'automatiquement. Ils seront enregistrés comme non '
                'catalogués et resteront corrigibles plus tard depuis la '
                'fiche du personnage.',
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Retourner corriger',
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Continuer',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(XmlImportReviewData data) async {
    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      final saveData = XmlImportSaveDataResolver.resolve(
        resolved: data.resolved,
        itemCatalog: data.itemCatalog,
        skillCatalog: data.skillCatalog,
        alignmentCatalog: data.alignmentCatalog,
      );
      final name = data.resolved.name.trim().isEmpty
          ? 'Personnage importé'
          : data.resolved.name.trim();

      await ref
          .read(xmlImportRepositoryProvider)
          .saveImportedCharacter(data: saveData, characterName: name);

      ref.invalidate(charactersProvider);
      if (!mounted) return;
      context.go('/');
    } on CharacterCreationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveErrorMessage = failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveErrorMessage = 'Une erreur est survenue. Réessayez.';
      });
    }
  }

  /// Construit la liste de cartes, dans l'ordre du tableau champ-par-champ de
  /// `docs/cahier-des-charges/03-import-xml-aidedd.md` — voir la spec
  /// visuelle : "pas de regroupement des alertes en tête de liste, garder le
  /// repère où dans mon personnage se trouve le problème".
  ///
  /// Périmètre volontairement réduit par rapport au tableau complet du
  /// cahier des charges : `styleCombat1`/`styleCombat2`/`favoredEnemy0`/
  /// `favoredEnemy6`/`favoredEnemy14`/`pack`/`classPath` (sous-classe)/
  /// `knownInvocation` ne sont ni affichés ni corrigibles ici — aucune table
  /// de correspondance fiable ni aucun catalogue Supabase encore précédent
  /// dans ce dépôt pour ces champs (`class_features`/`invocations`/
  /// `subclasses`), et l'assistant de création manuel lui-même ne propose
  /// encore aucun choix de sous-classe/invocation/style de combat — les
  /// afficher comme "corrigibles" aurait été trompeur (aucune correction
  /// n'aurait jamais rien changé à la sauvegarde). Décision de périmètre
  /// signalée au chef de projet plutôt qu'appliquée silencieusement.
  List<Widget> _buildRows(BuildContext context, XmlImportReviewData data) {
    final resolved = data.resolved;
    final widgets = <Widget>[];

    void addSpacer() {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: AppSpacing.sm));
      }
    }

    void addSummary(String title, String value, {bool badge = false}) {
      addSpacer();
      widgets.add(_SummaryCard(title: title, value: value, badge: badge));
    }

    void addAlert(String title, String message, VoidCallback onTap) {
      addSpacer();
      widgets.add(_AlertCard(title: title, message: message, onTap: onTap));
    }

    // Nom.
    addSummary('Nom', resolved.name.isEmpty ? 'Sans nom' : resolved.name);

    // Race.
    _addSingleCatalogField(
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Race',
      resolution: resolved.race,
      valueOf: (race) => race.name,
      candidates: [for (final race in data.raceCatalog.races) race.name],
      onCorrect: (label) => _controller().correctRace(label),
    );

    // Classe.
    _addSingleCatalogField(
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Classe',
      resolution: resolved.characterClass,
      valueOf: (classOption) => classOption.name,
      candidates: [
        for (final classOption in data.classCatalog.classes) classOption.name,
      ],
      onCorrect: (label) => _controller().correctClass(label),
    );

    // Niveau.
    addSummary('Niveau', '${resolved.level}');

    // Historique.
    _addSingleCatalogField(
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Historique',
      resolution: resolved.background,
      valueOf: (background) => background.name,
      candidates: [
        for (final background in data.backgroundCatalog.backgrounds)
          background.name,
      ],
      onCorrect: (label) => _controller().correctBackground(label),
    );

    // Caractéristiques.
    addSummary(
      'Caractéristiques',
      _formatAbilityScores(resolved.abilityScores),
    );

    // Points de vie.
    final constitutionModifier = _abilityModifier(
      resolved.abilityScores['con'] ?? 10,
    );
    addSummary(
      'Points de vie',
      '${_XmlImportHitPointsPreview.compute(resolved, constitutionModifier)} PV',
    );

    // Compétences (4 groupes consolidés).
    _addGroupedField(
      context: context,
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Compétences',
      groups: resolved.skillProficiencies,
      candidates: AideddReferenceTables.skills.values.toList(),
      confirmFor: (groupId, index) =>
          (label) => _controller().correctSkill(
            groupId: groupId,
            index: index,
            label: label,
          ),
    );

    // Outils (maîtrises).
    _addToolOrLanguageField(
      context: context,
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Outils',
      groups: resolved.toolProficiencies,
      nameOf: (tool) => tool.name,
      candidates: [for (final tool in data.toolCatalog.tools) tool.name],
      confirmFor: (groupId, index) =>
          (label) => _controller().correctToolProficiency(
            groupId: groupId,
            index: index,
            name: label,
          ),
    );

    // Langues.
    _addToolOrLanguageField(
      context: context,
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Langues',
      groups: resolved.languages,
      nameOf: (language) => language.name,
      candidates: [
        for (final language in data.languageCatalog.languages) language.name,
      ],
      confirmFor: (groupId, index) =>
          (label) => _controller().correctLanguage(
            groupId: groupId,
            index: index,
            name: label,
          ),
    );

    // Sorts innés.
    _addSpellField(
      context: context,
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Sorts innés',
      entries: resolved.innateSpells,
      candidates: [for (final spell in data.spellCatalog.spells) spell.name],
      onCorrect: (index) =>
          (label) => _controller().correctInnateSpell(index, label),
    );

    // Sorts connus.
    _addSpellField(
      context: context,
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Sorts connus',
      entries: resolved.knownSpells,
      candidates: [for (final spell in data.spellCatalog.spells) spell.name],
      onCorrect: (index) =>
          (label) => _controller().correctKnownSpell(index, label),
    );

    // Argent.
    addSummary('Argent', _formatCurrency(resolved));

    // Armure.
    _addCodedField(
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Armure',
      resolution: resolved.armor,
      candidates: AideddReferenceTables.armor.values.toList(),
      fieldId: 'armor',
    );

    // Bouclier.
    _addCodedField(
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Bouclier',
      resolution: resolved.shield,
      candidates: AideddReferenceTables.shield.values.toList(),
      fieldId: 'shield',
    );

    // Armes.
    _addQuantifiedField(
      context: context,
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Armes',
      entries: resolved.weapons,
      candidates: AideddReferenceTables.weapons.values
          .where((label) => label != AideddReferenceTables.weapons[0])
          .toList(),
      onCorrect: (index) =>
          (label) => _controller().correctWeapon(index, label),
    );

    // Outils physiques.
    _addQuantifiedField(
      context: context,
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Outils physiques',
      entries: resolved.toolEquipment,
      candidates: AideddReferenceTables.toolsEquipment.values
          .where((label) => label != AideddReferenceTables.toolsEquipment[0])
          .toList(),
      onCorrect: (index) =>
          (label) => _controller().correctToolEquipment(index, label),
    );

    // Objets.
    _addQuantifiedField(
      context: context,
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Objets',
      entries: resolved.items,
      candidates: AideddReferenceTables.items.values
          .where((label) => label != AideddReferenceTables.items[0])
          .toList(),
      onCorrect: (index) =>
          (label) => _controller().correctItem(index, label),
    );

    // Objets personnalisés (toujours `custom`, jamais un problème).
    if (resolved.customItems.isNotEmpty) {
      final texts = [
        for (final resolution in resolved.customItems)
          if (resolution case XmlFieldResolutionCustom<String>(:final text))
            text,
      ];
      if (texts.isNotEmpty) {
        addSummary('Objets personnalisés', texts.join(', '), badge: true);
      }
    }

    // Paquetage de départ (pack) — traçabilité/validation croisée
    // uniquement, jamais exploité pour reconstruire l'inventaire (voir
    // `AideddReferenceTables.packs`) : toujours une carte lecture seule,
    // jamais une alerte, pas de bottom sheet de correction — même un
    // libellé non reconnu reste affiché tel quel (jeton brut), jamais perdu
    // silencieusement, mais sans jamais compter dans
    // `XmlImportAlertSummary.countUnresolved`.
    final pack = resolved.pack;
    if (pack != null) {
      final packLabel = switch (pack) {
        XmlFieldResolutionRecognized<String>(:final value) => value,
        XmlFieldResolutionUnrecognized<String>(:final rawValue) =>
          'Non reconnu (traçabilité uniquement) : $rawValue',
        XmlFieldResolutionCustom<String>() => '',
      };
      if (packLabel.isNotEmpty) {
        addSummary('Paquetage de départ', packLabel);
      }
    }

    // Alignement.
    _addCodedField(
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Alignement',
      resolution: resolved.alignment,
      candidates: AideddReferenceTables.alignments.values.toList(),
      fieldId: 'alignment',
    );

    // Sexe.
    _addCodedField(
      addSummary: addSummary,
      addAlert: addAlert,
      title: 'Sexe',
      resolution: resolved.sexe,
      candidates: AideddReferenceTables.sexes.values.toList(),
      fieldId: 'sexe',
    );

    // Apparence (physique).
    final hasAppearance =
        resolved.age != null ||
        resolved.height != null ||
        resolved.weight != null ||
        resolved.eyes != null ||
        resolved.skin != null ||
        resolved.hair != null ||
        resolved.appearanceText.isNotEmpty;
    addSummary('Apparence', hasAppearance ? 'Renseignée' : 'Non renseignée');

    // Histoire.
    final hasHistory =
        resolved.traitsText.isNotEmpty ||
        resolved.idealsText.isNotEmpty ||
        resolved.bondsText.isNotEmpty ||
        resolved.flawsText.isNotEmpty ||
        resolved.backstoryText.isNotEmpty ||
        resolved.alliesText.isNotEmpty ||
        resolved.featuresText.isNotEmpty ||
        resolved.treasureText.isNotEmpty;
    addSummary('Histoire', hasHistory ? 'Renseignée' : 'Non renseignée');

    // Expérience.
    if (resolved.xp != null) {
      addSummary('Expérience', '${resolved.xp} XP');
    }

    // Carte informative neutre listant les champs du fichier source pour
    // lesquels aucune correction n'est proposée — ni alerte rouge (rien à
    // "corriger" faute de catalogue existant, y compris côté assistant de
    // création manuel pour sous-classe/invocation), ni disparition
    // silencieuse (voir la doc de classe de [XmlImportAlertSummary
    // .countUnresolved] : ces champs n'y sont volontairement pas comptés).
    // Seuls les champs réellement présents dans CE fichier sont listés (pas
    // une liste statique des 5 champs possibles) — voir [_buildUnhandledInfo
    // Message].
    final infoMessage = _buildUnhandledInfoMessage(resolved);
    if (infoMessage != null) {
      addSpacer();
      widgets.add(_InfoCard(message: infoMessage));
    }

    return widgets;
  }

  /// Construit le message de la carte informative neutre listant les champs
  /// réellement présents dans [resolved] mais non importés automatiquement
  /// (`styleCombat1`/`styleCombat2` -> "Style de combat", `favoredEnemy0`/
  /// `favoredEnemy6`/`favoredEnemy14` -> "Ennemi juré", `subclass` ->
  /// "Sous-classe", `knownInvocations` -> "Invocation connue") ainsi que les
  /// augmentations de caractéristiques (`aug_carac0/1/2`, voir
  /// `docs/xml-import-reference-mapping.md` section "aug_caracN (ASI) —
  /// correction" : hypothèse de mapping initiale invalidée, aucune
  /// persistance construite dessus pour ne pas fausser silencieusement les
  /// caractéristiques d'un personnage importé). `null` si aucun de ces
  /// champs n'est présent dans ce fichier précis.
  String? _buildUnhandledInfoMessage(XmlCharacterImportResolved resolved) {
    final unhandledFields = [
      if (resolved.styleCombat1 != null || resolved.styleCombat2 != null)
        'Style de combat',
      if (resolved.subclass != null) 'Sous-classe',
      if (resolved.knownInvocations.isNotEmpty) 'Invocation connue',
      if (resolved.favoredEnemy0 != null ||
          resolved.favoredEnemy6 != null ||
          resolved.favoredEnemy14 != null)
        'Ennemi juré',
    ];
    final hasAsiData = resolved.levels.any(
      (level) => level.abilityIncreases.any((increase) => increase != -1),
    );

    if (unhandledFields.isEmpty && !hasAsiData) return null;

    final sentences = <String>[
      if (unhandledFields.isNotEmpty)
        'Non importé automatiquement dans cette version : '
            '${unhandledFields.join(', ')}.',
      if (hasAsiData)
        'Augmentations de caractéristiques : présentes dans le fichier '
            'mais non interprétées automatiquement.',
    ];
    return sentences.join('\n\n');
  }

  XmlImportReviewController _controller() => ref.read(_provider.notifier);

  void _addSingleCatalogField<T>({
    required void Function(String title, String value, {bool badge}) addSummary,
    required void Function(String title, String message, VoidCallback onTap)
    addAlert,
    required String title,
    required XmlFieldResolution<T> resolution,
    required String Function(T value) valueOf,
    required List<String> candidates,
    required void Function(String label) onCorrect,
  }) {
    switch (resolution) {
      case XmlFieldResolutionRecognized<T>(:final value):
        addSummary(title, valueOf(value));
      case XmlFieldResolutionUnrecognized<T>(:final rawValue):
        addAlert(
          title,
          '$title non reconnu(e) : "$rawValue"',
          () => _openCorrectionFlow(
            cardTitle: title,
            entries: [
              _CorrectableEntry(
                rawValue: rawValue,
                sheetTitle: 'CORRIGER : ${title.toUpperCase()}',
                candidates: candidates,
                onConfirm: (label) {
                  if (label != null) onCorrect(label);
                },
              ),
            ],
          ),
        );
      case XmlFieldResolutionCustom<T>():
        // Ne s'applique à aucun des champs consommés par cette méthode.
        break;
    }
  }

  void _addCodedField({
    required void Function(String title, String value, {bool badge}) addSummary,
    required void Function(String title, String message, VoidCallback onTap)
    addAlert,
    required String title,
    required XmlFieldResolution<String> resolution,
    required List<String> candidates,
    required String fieldId,
  }) {
    switch (resolution) {
      case XmlFieldResolutionRecognized<String>(:final value):
        addSummary(title, value);
      case XmlFieldResolutionUnrecognized<String>(:final rawValue):
        addAlert(
          title,
          '$title non reconnu(e) : "$rawValue"',
          () => _openCorrectionFlow(
            cardTitle: title,
            entries: [
              _CorrectableEntry(
                rawValue: rawValue,
                sheetTitle: 'CORRIGER : ${title.toUpperCase()}',
                candidates: candidates,
                onConfirm: (label) {
                  if (label != null) {
                    _controller().correctCodedField(fieldId, label);
                  }
                },
              ),
            ],
          ),
        );
      case XmlFieldResolutionCustom<String>():
        break;
    }
  }

  void _addGroupedField({
    required BuildContext context,
    required void Function(String title, String value, {bool badge}) addSummary,
    required void Function(String title, String message, VoidCallback onTap)
    addAlert,
    required String title,
    required Map<int, List<XmlFieldResolution<String>>> groups,
    required List<String> candidates,
    required void Function(String label) Function(int groupId, int index)
    confirmFor,
  }) {
    final recognizedLabels = <String>[];
    final entries = <_CorrectableEntry>[];
    for (var groupId = 0; groupId <= 3; groupId++) {
      final list = groups[groupId] ?? const [];
      for (var index = 0; index < list.length; index++) {
        final resolution = list[index];
        switch (resolution) {
          case XmlFieldResolutionRecognized<String>(:final value):
            recognizedLabels.add(value);
          case XmlFieldResolutionUnrecognized<String>(:final rawValue):
            entries.add(
              _CorrectableEntry(
                rawValue: rawValue,
                sheetTitle: 'CORRIGER : ${title.toUpperCase()}',
                candidates: candidates,
                onConfirm: (label) {
                  if (label != null) confirmFor(groupId, index)(label);
                },
              ),
            );
          case XmlFieldResolutionCustom<String>():
            break;
        }
      }
    }

    if (recognizedLabels.isNotEmpty) {
      addSummary(title, recognizedLabels.join(', '));
    }
    if (entries.isNotEmpty) {
      addAlert(
        title,
        entries.length == 1
            ? '1 élément non catalogué — à corriger manuellement.'
            : '${entries.length} éléments non catalogués — à corriger '
                  'manuellement.',
        () => _openCorrectionFlow(cardTitle: title, entries: entries),
      );
    }
  }

  void _addToolOrLanguageField<T>({
    required BuildContext context,
    required void Function(String title, String value, {bool badge}) addSummary,
    required void Function(String title, String message, VoidCallback onTap)
    addAlert,
    required String title,
    required Map<int, List<XmlFieldResolution<T>>> groups,
    required String Function(T value) nameOf,
    required List<String> candidates,
    required void Function(String label) Function(int groupId, int index)
    confirmFor,
  }) {
    final recognizedLabels = <String>[];
    final entries = <_CorrectableEntry>[];
    for (var groupId = 0; groupId <= 3; groupId++) {
      final list = groups[groupId] ?? const [];
      for (var index = 0; index < list.length; index++) {
        final resolution = list[index];
        switch (resolution) {
          case XmlFieldResolutionRecognized<T>(:final value):
            recognizedLabels.add(nameOf(value));
          case XmlFieldResolutionUnrecognized<T>(:final rawValue):
            entries.add(
              _CorrectableEntry(
                rawValue: rawValue,
                sheetTitle: 'CORRIGER : ${title.toUpperCase()}',
                candidates: candidates,
                onConfirm: (label) {
                  if (label != null) confirmFor(groupId, index)(label);
                },
              ),
            );
          case XmlFieldResolutionCustom<T>():
            break;
        }
      }
    }

    if (recognizedLabels.isEmpty && entries.isEmpty) return;
    if (recognizedLabels.isNotEmpty) {
      addSummary(title, recognizedLabels.join(', '));
    }
    if (entries.isNotEmpty) {
      addAlert(
        title,
        entries.length == 1
            ? '1 élément non catalogué — à corriger manuellement.'
            : '${entries.length} éléments non catalogués — à corriger '
                  'manuellement.',
        () => _openCorrectionFlow(cardTitle: title, entries: entries),
      );
    }
  }

  void _addSpellField({
    required BuildContext context,
    required void Function(String title, String value, {bool badge}) addSummary,
    required void Function(String title, String message, VoidCallback onTap)
    addAlert,
    required String title,
    required List<XmlSpellResolution> entries,
    required List<String> candidates,
    required void Function(String label) Function(int index) onCorrect,
  }) {
    if (entries.isEmpty) return;
    final recognizedLabels = <String>[];
    final alertEntries = <_CorrectableEntry>[];
    for (var index = 0; index < entries.length; index++) {
      final XmlFieldResolution<SpellOption> resolution =
          entries[index].resolution;
      switch (resolution) {
        case XmlFieldResolutionRecognized<SpellOption>(:final value):
          recognizedLabels.add(value.name);
        case XmlFieldResolutionUnrecognized<SpellOption>(:final rawValue):
          alertEntries.add(
            _CorrectableEntry(
              rawValue: rawValue,
              sheetTitle: 'CORRIGER : ${title.toUpperCase()}',
              candidates: candidates,
              onConfirm: (label) {
                if (label != null) onCorrect(index)(label);
              },
            ),
          );
        case XmlFieldResolutionCustom<SpellOption>():
          break;
      }
    }

    if (recognizedLabels.isNotEmpty) {
      addSummary(title, recognizedLabels.join(', '));
    }
    if (alertEntries.isNotEmpty) {
      addAlert(
        title,
        alertEntries.length == 1
            ? '1 sort non catalogué — à corriger manuellement.'
            : '${alertEntries.length} sorts non catalogués — à corriger '
                  'manuellement.',
        () => _openCorrectionFlow(cardTitle: title, entries: alertEntries),
      );
    }
  }

  void _addQuantifiedField({
    required BuildContext context,
    required void Function(String title, String value, {bool badge}) addSummary,
    required void Function(String title, String message, VoidCallback onTap)
    addAlert,
    required String title,
    required List<XmlQuantifiedResolution> entries,
    required List<String> candidates,
    required void Function(String label) Function(int index) onCorrect,
  }) {
    if (entries.isEmpty) return;
    final recognizedLabels = <String>[];
    final alertEntries = <_CorrectableEntry>[];
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      switch (entry.resolution) {
        case XmlFieldResolutionRecognized<String>(:final value):
          recognizedLabels.add('$value ×${entry.quantity}');
        case XmlFieldResolutionUnrecognized<String>(:final rawValue):
          alertEntries.add(
            _CorrectableEntry(
              rawValue: rawValue,
              sheetTitle: 'CORRIGER : ${title.toUpperCase()}',
              candidates: candidates,
              onConfirm: (label) {
                if (label != null) onCorrect(index)(label);
              },
            ),
          );
        case XmlFieldResolutionCustom<String>():
          break;
      }
    }

    if (recognizedLabels.isNotEmpty) {
      addSummary(title, recognizedLabels.join(', '));
    }
    if (alertEntries.isNotEmpty) {
      addAlert(
        title,
        alertEntries.length == 1
            ? '1 élément non catalogué — à corriger manuellement.'
            : '${alertEntries.length} éléments non catalogués — à corriger '
                  'manuellement.',
        () => _openCorrectionFlow(cardTitle: title, entries: alertEntries),
      );
    }
  }

  Future<void> _openCorrectionFlow({
    required String cardTitle,
    required List<_CorrectableEntry> entries,
  }) async {
    if (entries.length == 1) {
      await _openSingleSheet(entries.single);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.woodDark.withValues(alpha: 0.55),
      builder: (sheetContext) => _GroupCorrectionSheet(
        title: cardTitle,
        entries: entries,
        onCorrectEntry: (entry) {
          Navigator.of(sheetContext).pop();
          _openSingleSheet(entry);
        },
      ),
    );
  }

  Future<void> _openSingleSheet(_CorrectableEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.woodDark.withValues(alpha: 0.55),
      builder: (sheetContext) => _CorrectionBottomSheet(
        title: entry.sheetTitle,
        candidates: entry.candidates,
        onConfirm: entry.onConfirm,
      ),
    );
  }
}

/// Modificateur D&D 5e standard (`floor((score - 10) / 2)`) — dupliqué depuis
/// `AbilityScoreRules.abilityModifier` plutôt que réutilisé directement à cet
/// unique point d'affichage : évite d'importer toute la classe pour une seule
/// formule à un chiffre, même rationale que le reste de ce module (voir la
/// documentation de classe de `RaceRowMapper` dans `character_creation`).
int _abilityModifier(int score) => ((score - 10) / 2).floor();

/// Petit alias local pour ne pas importer directement
/// `XmlImportHitPointsCalculator` juste pour un affichage — regroupe le
/// calcul pour rester lisible au point d'appel.
abstract final class _XmlImportHitPointsPreview {
  static int compute(
    XmlCharacterImportResolved resolved,
    int constitutionModifier,
  ) {
    var total = 0;
    for (final entry in resolved.levels) {
      if (entry.hpBrut > 0) total += entry.hpBrut + constitutionModifier;
    }
    return total < 1 ? 1 : total;
  }
}

const Map<String, String> _abilityAbbreviations = {
  'str': 'For',
  'dex': 'Dex',
  'con': 'Con',
  'int': 'Int',
  'wis': 'Sag',
  'cha': 'Cha',
};

String _formatAbilityScores(Map<String, int> scores) {
  final parts = <String>[
    for (final definition in abilityScoreDefinitions)
      if (scores.containsKey(definition.key))
        '${_abilityAbbreviations[definition.key]} ${scores[definition.key]}',
  ];
  return parts.join(' · ');
}

String _formatCurrency(XmlCharacterImportResolved resolved) {
  final parts = <String>[
    if (resolved.gp > 0) '${resolved.gp} po',
    if (resolved.pp > 0) '${resolved.pp} pp',
    if (resolved.ep > 0) '${resolved.ep} pe',
    if (resolved.sp > 0) '${resolved.sp} pa',
    if (resolved.cp > 0) '${resolved.cp} pc',
  ];
  return parts.isEmpty ? 'Aucune' : parts.join(' · ');
}

/// Une entrée corrigible individuelle (un champ singulier, ou un sous-élément
/// d'un champ consolidé) — porte tout ce dont la bottom sheet de correction a
/// besoin : le texte brut affiché, le titre de la bottom sheet, les
/// candidats proposés à la recherche, et le callback de confirmation
/// (`null` = "garder tel quel", voir [_CorrectionBottomSheet]).
class _CorrectableEntry {
  const _CorrectableEntry({
    required this.rawValue,
    required this.sheetTitle,
    required this.candidates,
    required this.onConfirm,
  });

  final String rawValue;
  final String sheetTitle;
  final List<String> candidates;
  final ValueChanged<String?> onConfirm;
}

/// Bandeau bois plein en tête d'écran, avec titre + sous-titre — pas de barre
/// de progression contrairement à `_Header` de l'assistant de création (cet
/// écran n'est pas une étape numérotée). Le sous-titre reprend le token déjà
/// défini pour les icônes inactives de la barre d'onglets
/// (`AppColors.textOnWoodMuted`, voir `CharacterDetailTabBar`) plutôt qu'une
/// nouvelle valeur d'opacité — voir la spec visuelle de la tâche.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textOnWood,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.display(
                          fontSize: 13,
                          color: AppColors.textOnWood,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textOnWoodMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de résumé en lecture seule (composant nouveau, voir la spec
/// visuelle) : jamais tappable, jamais `font.display` pour une valeur
/// importée. [badge] affiche "Personnalisé" en petit texte discret
/// (`textMuted`) — seul usage à ce jour : "Objets personnalisés" (toujours
/// `XmlFieldResolution.custom`, jamais un problème, voir sa documentation de
/// classe).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    this.badge = false,
  });

  final String title;
  final String value;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: AppTypography.body(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (badge) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Personnalisé',
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte informative neutre — ni un bandeau d'alerte (pas de bordure/icône
/// rouge, rien à corriger faute de catalogue existant), ni une carte de
/// résumé (pas de couple titre/valeur, un simple paragraphe) : nouveau
/// composant, non tappable, `parchment.card-alt` (déjà utilisé ailleurs pour
/// une surface secondaire discrète, ex. `SecondaryButtonSurface.parchment`)
/// plutôt que `parchment.card` pour se distinguer visuellement des cartes
/// "normales" — voir [_XmlImportReviewScreenState._buildUnhandledInfoMessage].
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'alerte inline tappable (design système section 4, "utilisé pour
/// signaler un champ d'import XML non reconnu") — réutilisation directe des
/// tokens visuels déjà appliqués par `AlertBanner`
/// (`core/widgets/alert_banner.dart`), avec en plus un tap (ouvre la bottom
/// sheet de correction) et un chevron indiquant l'affordance.
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.message,
    required this.onTap,
  });

  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.alertBannerBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.accentBrick,
              width: AppBorders.card,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.accentBrick,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      message,
                      style: AppTypography.body(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.accentBrick,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet "mode liste" pour un champ consolidé (plusieurs sous-éléments
/// non reconnus simultanément, ex. plusieurs objets d'inventaire) — voir la
/// spec visuelle : "une ligne par item, action 'Corriger' par ligne + 'Tout
/// garder en objets personnalisés' en bas". Libellé du bouton bas généralisé
/// à "Tout garder comme éléments personnalisés" pour tous les champs
/// consolidés (pas seulement les objets) — l'exemple de la spec porte
/// spécifiquement sur les objets, généralisé ici à toute liste, signalé
/// plutôt qu'appliqué silencieusement.
class _GroupCorrectionSheet extends StatelessWidget {
  const _GroupCorrectionSheet({
    required this.title,
    required this.entries,
    required this.onCorrectEntry,
  });

  final String title;
  final List<_CorrectableEntry> entries;
  final ValueChanged<_CorrectableEntry> onCorrectEntry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(color: AppColors.parchmentBg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeaderBar(title: 'CORRIGER : ${title.toUpperCase()}'),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: entries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.parchmentCard,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.woodLight,
                        width: AppBorders.card,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.rawValue,
                            style: AppTypography.body(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => onCorrectEntry(entry),
                          child: Text(
                            'Corriger',
                            style: AppTypography.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentBrick,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SecondaryButton(
                label: 'Tout garder comme éléments personnalisés',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet de correction manuelle d'un champ unique — champ de
/// recherche, liste de résultats avec bouton radio
/// ([SelectableOptionTile], "case à cocher/élément de liste sélectionnable"
/// du design système), fallback "Garder comme élément personnalisé" (bouton
/// secondaire, sélectionnable au même titre qu'un candidat de la liste),
/// bouton primaire "CONFIRMER" désactivé tant qu'aucun choix n'est fait —
/// voir la spec visuelle de la tâche pour le détail complet.
class _CorrectionBottomSheet extends StatefulWidget {
  const _CorrectionBottomSheet({
    required this.title,
    required this.candidates,
    required this.onConfirm,
  });

  final String title;
  final List<String> candidates;

  /// `null` = "garder tel quel" (le champ reste non résolu, voir la
  /// documentation de classe de [XmlImportReviewController]).
  final ValueChanged<String?> onConfirm;

  @override
  State<_CorrectionBottomSheet> createState() => _CorrectionBottomSheetState();
}

class _CorrectionBottomSheetState extends State<_CorrectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCandidate;
  bool _keepAsIs = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.candidates;
    return widget.candidates
        .where((candidate) => candidate.toLowerCase().contains(query))
        .toList();
  }

  void _selectCandidate(String candidate) {
    setState(() {
      _selectedCandidate = candidate;
      _keepAsIs = false;
    });
  }

  void _selectKeepAsIs() {
    setState(() {
      _keepAsIs = true;
      _selectedCandidate = null;
    });
  }

  void _confirm() {
    if (_selectedCandidate == null && !_keepAsIs) return;
    Navigator.of(context).pop();
    widget.onConfirm(_selectedCandidate);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final canConfirm = _selectedCandidate != null || _keepAsIs;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetHeaderBar(title: widget.title),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Text(
                            'Aucune correspondance trouvée.',
                            style: AppTypography.body(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppSpacing.xs),
                            itemBuilder: (context, index) {
                              final candidate = filtered[index];
                              return SelectableOptionTile(
                                title: candidate,
                                selected: _selectedCandidate == candidate,
                                onTap: () => _selectCandidate(candidate),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Garder comme élément personnalisé',
                              onPressed: _selectKeepAsIs,
                            ),
                          ),
                          if (_keepAsIs) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.accentTeal,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PrimaryButton(
                        label: 'Confirmer',
                        onPressed: canConfirm ? _confirm : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlay de sauvegarde en cours — scrim `wood.dark` 60% par-dessus l'écran,
/// carte `parchment.card` centrée avec spinner foncé — voir la spec visuelle.
class _SavingOverlay extends StatelessWidget {
  const _SavingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodDark.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.cardEmphasis,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.woodMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enregistrement du personnage...',
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// État d'erreur "XML invalide/structure non reconnue" — voir la spec
/// visuelle : icône alerte, message principal, texte secondaire, bouton
/// secondaire pleine largeur "CHOISIR UN AUTRE FICHIER" (pas de bouton
/// primaire), pas de liste de cartes.
class _InvalidFileErrorState extends StatelessWidget {
  const _InvalidFileErrorState({
    required this.message,
    required this.onPickAnother,
  });

  final String message;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Ce fichier ne semble pas être un export aidedd.org valide.',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'Choisir un autre fichier',
                surface: SecondaryButtonSurface.parchment,
                onPressed: onPickAnother,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// État d'erreur réseau (chargement des catalogues) — patron générique
/// message + "Réessayer", déjà utilisé par le reste de l'app.
class _NetworkErrorState extends StatelessWidget {
  const _NetworkErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.accentBrick,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Réessayer',
              surface: SecondaryButtonSurface.parchment,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
