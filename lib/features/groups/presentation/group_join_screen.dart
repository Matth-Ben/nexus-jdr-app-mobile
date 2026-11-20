import '../../combat/presentation/providers/character_combat_provider.dart';

import 'dart:async';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/portrait_frame.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/sheet_header_bar.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../characters/domain/character_failure.dart';
import '../../characters/domain/character_summary.dart';
import '../../characters/presentation/providers/character_providers.dart';
import '../domain/group_invite_failure.dart';
import '../domain/group_preview.dart';
import 'providers/group_providers.dart';
import 'widgets/group_campaign_card.dart';
import '../../characters/presentation/character_failure_l10n.dart';
import '../../../l10n/app_localizations.dart';

/// Longueur brute (sans le tiret de présentation) d'un code d'invitation de
/// groupe — voir `domain/group_invite_code_generator.dart::_length`.
const int _rawCodeLength = 8;

/// Longueur minimale saisie avant d'activer "Rejoindre" — même seuil que
/// l'ancienne étape 1/3 (`group_join_code_step_screen.dart`, retirée par
/// cette tâche), gardé pour ne pas durcir la validation au-delà de ce qui
/// existait déjà.
const int _rawCodeMinLength = 6;

const String _genericJoinErrorMessage =
    'Impossible de rejoindre ce groupe. Réessayez.';

const String _invalidCodeMessage = "Ce code d'invitation n'est pas valide.";

/// Écran unique "REJOINDRE UN GROUPE", route `/groups/join` — recettage
/// direction-artistique du 13/09/2026 (`docs/cahier-des-charges/
/// 09-maquettes-captures.md`, section "Groupe — Rejoindre") : fusionne les 3
/// écrans de l'ancien flux à étapes (`group_join_code_step_screen.dart`
/// "Code", un écran de confirmation intermédiaire "Nom du groupe/nombre de
/// membres", `group_join_character_step_screen.dart` "Choix du personnage",
/// tous les 3 retirés par cette tâche, ainsi que
/// `widgets/group_join_step_header.dart`) en un seul écran scrollable : code
/// d'invitation, rôle du joueur dans ce groupe, bouton "Rejoindre" unique.
///
/// **MJ sans personnage** (décision de Matthias du 12-13/10/2026) : le
/// sélecteur de personnage devient tri-état — rien choisi / personnage
/// choisi / MJ choisi ([_joinAsGameMaster]) — voir [_RoleSelectorTile]/
/// [_GmOptionRow]. La ligne MJ de la sheet reste toujours
/// visible/sélectionnable quel que soit l'état de `charactersProvider`
/// (correctif d'un bug trouvé par direction-artistique : auparavant,
/// l'ouverture de la tuile/la sheet ET l'activation du bouton "Rejoindre"
/// dépendaient de `charactersProvider` ayant résolu en `data`, bloquant à
/// tort un joueur qui veut rejoindre en MJ si sa liste de personnages est
/// lente/en erreur/hors-ligne — sans rapport avec son choix).
///
/// **Logique métier migrée telle quelle**, jamais réécrite : la validation
/// du code passe toujours par `GroupRepository.previewGroupInvite` (résout
/// le groupe ciblé, lève une [GroupInviteFailure] `invalidCode`/`generic` —
/// jamais `alreadyInGroup`/`mjAlreadyAssigned` à ce stade, aucun rôle n'est
/// encore choisi par l'edge function `preview-group-invite`, même remarque
/// que l'ancienne étape 2/3), puis le rattachement par
/// `GroupRepository.joinGroup` (peut, lui, lever les 4 natures d'échec). Les
/// deux appels sont orchestrés ([_loadPreview], [_join]) sur ce seul écran
/// plutôt que répartis sur 2 routes séparées (voir « Aperçu avant de
/// rejoindre » ci-dessous).
///
/// **Affichage des erreurs, 2 canaux distincts** (spec de la tâche) :
/// - code invalide (`GroupInviteFailureKind.invalidCode`, qu'il vienne de
///   l'aperçu ou du rattachement) → texte d'aide discret sous le champ code
///   ([_CodeErrorHint], triangle + texte, jamais encadré) — la maquette
///   n'étiquette ce texte que d'un "Exemple d'erreur : « ... »" à titre
///   d'illustration statique ; ce libellé "Exemple d'erreur" n'a lui-même
///   aucune vocation à apparaître dans l'app, seul le style (icône + texte
///   sans bordure) est repris pour le vrai message dynamique.
/// - tout le reste (`alreadyInGroup`/`mjAlreadyAssigned`/`generic`, échec
///   réseau) → [AlertBanner] en tête d'écran, même composant que l'ancienne
///   étape 3/3.
///
/// **Aperçu avant de rejoindre** (étape 4, décisions n° 33, 34 et 36 du
/// 19/11/2026) : une carte sous le champ code ([_GroupInvitePreviewCard])
/// montre le nom du groupe, son nombre de membres et le titre de sa
/// campagne (jamais le résumé). Un code complet ([_rawCodeLength]
/// caractères, la longueur de tous les codes générés) est prévisualisé dès sa
/// saisie (`groupInvitePreviewProvider`, en ligne seulement), avec un état
/// « Recherche du groupe… » ([_GroupInvitePreviewLoading]) ; un code
/// invalide s'affiche aussitôt sous le champ, une erreur réseau seulement au
/// toucher du bouton. Le bouton principal ne rattache qu'à un groupe dont la
/// carte est affichée (« Rejoindre ») : sinon il s'intitule « Voir le
/// groupe » et charge l'aperçu (même validation du code et mêmes canaux
/// d'erreur qu'avant), sans voile ; le joueur confirme ensuite. Garde-fous
/// (relecture de code de la PR #304) : bouton inactif pendant l'aperçu
/// automatique, action et clé du bouton tirées de ce qui est affiché (un
/// appui en cours est annulé quand le bouton change de rôle), « Rejoindre »
/// ignoré pendant [kDoubleTapTimeout] après l'apparition de la carte.
class GroupJoinScreen extends ConsumerStatefulWidget {
  const GroupJoinScreen({this.initialCode, super.key});

  /// Pré-remplissage du champ code (ex. arrivée depuis un lien), comportement
  /// hérité de l'ancienne étape 1/3.
  final String? initialCode;

  @override
  ConsumerState<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends ConsumerState<GroupJoinScreen> {
  late final TextEditingController _codeController = TextEditingController(
    text: _formatCodeDisplay(_rawCode(widget.initialCode ?? '')),
  );
  String? _selectedCharacterId;
  bool _joinAsGameMaster = false;
  bool _isJoining = false;

  /// Aperçu demandé par « Voir le groupe » en cours ([_loadPreview]) : mêmes
  /// verrous que [_isJoining], mais sans voile (rien n'est rattaché).
  bool _isLoadingPreview = false;
  String? _codeErrorMessage;
  String? _bannerMessage;

  /// Code incomplet (6 ou 7 caractères) dont le joueur a demandé l'aperçu en
  /// touchant « Voir le groupe » ; un code complet est prévisualisé d'office.
  String? _requestedPreviewCode;

  /// Garde en vie l'aperçu demandé par [_loadPreview] (provider
  /// `autoDispose`) pendant l'attente, avant que `build` ne l'écoute.
  /// Fermé automatiquement au démontage de l'écran.
  ProviderSubscription<AsyncValue<GroupPreview>>? _previewSubscription;

  /// Code dont la carte d'aperçu est affichée (`null` sans carte) : repère sa
  /// première apparition pour [_joinGuardTimer].
  String? _shownPreviewCode;

  /// Actif pendant [kDoubleTapTimeout] après la première apparition de la
  /// carte d'un code : « Rejoindre » est alors ignoré, pour qu'un double
  /// toucher sur « Voir le groupe » ne rejoigne pas le groupe (relecture de
  /// code de la PR #304).
  Timer? _joinGuardTimer;

  @override
  void dispose() {
    _joinGuardTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  /// Rattachement ou aperçu demandé en cours : champ, rôle, bouton et retour
  /// verrouillés.
  bool get _isBusy => _isJoining || _isLoadingPreview;

  void _goBack() {
    if (_isBusy) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  String get _rawCurrentCode => _rawCode(_codeController.text);

  /// Code dont l'aperçu est chargé et affiché sous le champ : le code saisi
  /// s'il est complet, ou s'il est celui que le joueur a demandé
  /// ([_requestedPreviewCode]) ; `null` sinon.
  String? get _previewCode {
    final code = _rawCurrentCode;
    if (code.length == _rawCodeLength || code == _requestedPreviewCode) {
      return code;
    }
    return null;
  }

  /// Note la première apparition de la carte de [previewCode] (appelé par
  /// `build` avec ce qui est affiché) et arme [_joinGuardTimer]. Sans carte,
  /// le repère est effacé : une carte qui réapparaît réarme la garde.
  void _trackShownPreview(String? previewCode, {required bool shown}) {
    if (!shown) {
      _shownPreviewCode = null;
      return;
    }
    if (previewCode == _shownPreviewCode) return;
    _shownPreviewCode = previewCode;
    _joinGuardTimer?.cancel();
    _joinGuardTimer = Timer(kDoubleTapTimeout, () {});
  }

  /// Auto-sélectionne le premier personnage de [characters] tant qu'aucun
  /// personnage n'a été explicitement choisi — comportement hérité, inchangé
  /// par l'ajout du rôle MJ (voir la doc de classe) : n'est consulté que
  /// lorsque [_joinAsGameMaster] est faux.
  CharacterSummary? _selectedCharacter(List<CharacterSummary> characters) {
    for (final character in characters) {
      if (character.id == _selectedCharacterId) return character;
    }
    return characters.isEmpty ? null : characters.first;
  }

  void _selectCharacter(String characterId) {
    if (_isBusy) return;
    setState(() {
      _selectedCharacterId = characterId;
      _joinAsGameMaster = false;
    });
  }

  /// Sélectionne le rôle "MJ — sans personnage" — mutuellement exclusif avec
  /// [_selectCharacter] (voir la doc de classe).
  void _selectGameMaster() {
    if (_isBusy) return;
    setState(() {
      _joinAsGameMaster = true;
      _selectedCharacterId = null;
    });
  }

  /// Ouvre "CHOISIR TON RÔLE" (tap sur la tuile de rôle) — même gabarit de
  /// sheet "mode liste" que `group_create_screen.dart::_openRolePicker`
  /// (liste radio exclusive, `SheetHeaderBar` + 75 % de la hauteur), dupliqué
  /// ici : classes privées à leur fichier, même rationale de duplication que
  /// le reste de ce dépôt (voir `GroupMemberRowMapper`). La ligne MJ
  /// ([_GmOptionRow]) est toujours en première position, toujours
  /// sélectionnable ; seule la zone SOUS elle reflète l'état de
  /// [charactersAsync].
  Future<void> _openRolePicker(
    AsyncValue<List<CharacterSummary>> charactersAsync,
  ) {
    final selected = _selectedCharacter(charactersAsync.value ?? const []);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.parchmentBg),
            child: Column(
              children: [
                const SheetHeaderBar(title: 'CHOISIR TON RÔLE'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _GmOptionRow(
                        selected: _joinAsGameMaster,
                        onTap: () {
                          _selectGameMaster();
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      charactersAsync.when(
                        data: (characters) => characters.isEmpty
                            ? const _NoCharacterNote()
                            : Column(
                                children: [
                                  for (final character in characters) ...[
                                    _SelectableCharacterRow(
                                      character: character,
                                      selected:
                                          !_joinAsGameMaster &&
                                          character.id == selected?.id,
                                      onTap: () {
                                        _selectCharacter(character.id);
                                        Navigator.of(sheetContext).pop();
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ],
                              ),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.woodMedium,
                            ),
                          ),
                        ),
                        error: (error, stackTrace) => _CharacterTileError(
                          message: error is CharacterFailure
                              ? error.localized(context)
                              : AppLocalizations.of(context)!
                                    .characterLoadFailedErrorMessage,
                          onRetry: () => ref.invalidate(charactersProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// `true` si le bouton principal (« Voir le groupe » ou « Rejoindre ») peut
  /// être activé — **jamais gaté par
  /// l'état de [charactersAsync] quand [_joinAsGameMaster] est vrai** (voir
  /// la doc de classe). Faux pendant l'aperçu automatique
  /// ([isPreviewLoading], « Recherche du groupe… ») : un toucher ne doit pas
  /// croiser la réponse (relecture de code de la PR #304).
  bool _canSubmit(
    AsyncValue<List<CharacterSummary>> charactersAsync, {
    required bool isPreviewLoading,
  }) {
    if (_isBusy || isPreviewLoading) return false;
    if (_rawCurrentCode.length < _rawCodeMinLength) return false;
    if (_joinAsGameMaster) return true;
    final characters = charactersAsync.value;
    return characters != null && _selectedCharacter(characters) != null;
  }

  /// « Rejoindre » : `joinGroup` pour [code], dont la carte d'aperçu est
  /// affichée (l'action est choisie par `build` d'après ce qui est affiché,
  /// décision n° 34 : le joueur voit le groupe, puis confirme). Ignoré pendant
  /// [kDoubleTapTimeout] après la première apparition de la carte
  /// ([_joinGuardTimer]). Voir la documentation de classe pour le routage des
  /// 2 canaux d'erreur.
  Future<void> _join(String code, List<CharacterSummary> characters) async {
    final character = _joinAsGameMaster ? null : _selectedCharacter(characters);
    final hasRole = _joinAsGameMaster || character != null;
    final guarded = _joinGuardTimer?.isActive ?? false;
    if (!hasRole || _isBusy || guarded) return;

    setState(() {
      _isJoining = true;
      _codeErrorMessage = null;
      _bannerMessage = null;
    });

    try {
      final result = await ref
          .read(groupRepositoryProvider)
          .joinGroup(code: code, characterId: character?.id);
      ref.invalidate(characterGroupIdsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Groupe rejoint !')));
      context.go('/groups/${result.groupId}');
    } on GroupInviteFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        switch (failure.kind) {
          case GroupInviteFailureKind.invalidCode:
            _codeErrorMessage = _invalidCodeMessage;
          case GroupInviteFailureKind.alreadyInGroup:
            _bannerMessage = 'Ce personnage est déjà membre de ce groupe.';
          case GroupInviteFailureKind.mjAlreadyAssigned:
            _bannerMessage = 'Ce groupe a déjà un MJ sans personnage.';
          case GroupInviteFailureKind.generic:
            _bannerMessage = _genericJoinErrorMessage;
        }
      });
      // Code régénéré entre l'aperçu et la jonction : relit l'aperçu, pour
      // que la carte de l'ancien groupe ne reste pas affichée avec
      // « Rejoindre » (relecture de code de la PR #304).
      if (failure.kind == GroupInviteFailureKind.invalidCode) {
        ref.invalidate(groupInvitePreviewProvider(code: code));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _bannerMessage = _genericJoinErrorMessage;
      });
    }
  }

  /// « Voir le groupe » : charge l'aperçu de [code] (`preview-group-invite`,
  /// qui valide aussi le code) sans rejoindre ni voile (le bouton montre son
  /// indicateur, la zone de l'aperçu « Recherche du groupe… ») ; la carte
  /// apparaît sous le champ et le joueur confirme par « Rejoindre ». Aperçu
  /// en cours : attendu ; en échec : relancé. Mêmes canaux d'erreur qu'avant
  /// l'étape 4 (code invalide sous le champ, tout le reste en bandeau).
  Future<void> _loadPreview(String code) async {
    if (_isBusy) return;
    final provider = groupInvitePreviewProvider(code: code);
    setState(() {
      _isLoadingPreview = true;
      _codeErrorMessage = null;
      _bannerMessage = null;
      _requestedPreviewCode = code;
    });
    _previewSubscription?.close();
    final subscription = ref.listenManual(provider, (_, _) {});
    _previewSubscription = subscription;

    String? codeError;
    String? banner;
    try {
      // Aperçu automatique en échec : relancé (la lecture qui suit attend le
      // nouvel appel). En cours : la lecture attend l'appel déjà lancé.
      if (subscription.read().hasError) ref.invalidate(provider);
      await ref.read(provider.future);
    } on GroupInviteFailure catch (failure) {
      if (failure.kind == GroupInviteFailureKind.invalidCode) {
        codeError = _invalidCodeMessage;
      } else {
        banner = _genericJoinErrorMessage;
      }
    } catch (_) {
      banner = _genericJoinErrorMessage;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingPreview = false;
      _codeErrorMessage = codeError;
      _bannerMessage = banner;
    });
  }

  /// Erreur « code invalide » de l'aperçu automatique, connue sans toucher le
  /// bouton : affichée aussitôt sous le champ. Les autres échecs (réseau)
  /// restent silencieux jusqu'au toucher de « Voir le groupe ». Rien pendant
  /// une relance en cours.
  static bool _isInvalidCodeError(AsyncValue<GroupPreview>? previewAsync) {
    if (previewAsync == null || previewAsync.isLoading) return false;
    final error = previewAsync.error;
    return error is GroupInviteFailure &&
        error.kind == GroupInviteFailureKind.invalidCode;
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync = ref.watch(charactersProvider);
    final characters = charactersAsync.value;
    final selectedCharacter = _joinAsGameMaster
        ? null
        : (characters != null ? _selectedCharacter(characters) : null);
    final hasResolvedEmptyList = characters != null && characters.isEmpty;
    final l10n = AppLocalizations.of(context)!;
    final previewCode = _previewCode;
    final previewAsync = previewCode == null
        ? null
        : ref.watch(groupInvitePreviewProvider(code: previewCode));
    // Seulement un aperçu établi : pendant une relecture (code régénéré, voir
    // [_join]) ou après son échec, l'ancienne carte n'est plus montrée.
    final preview = previewAsync is AsyncData<GroupPreview>
        ? previewAsync.value
        : null;
    final isPreviewLoading =
        preview == null && (previewAsync?.isLoading ?? false);
    final codeErrorMessage =
        _codeErrorMessage ??
        (_isInvalidCodeError(previewAsync) ? _invalidCodeMessage : null);
    _trackShownPreview(previewCode, shown: preview != null);
    final code = _rawCurrentCode;
    final canSubmit = _canSubmit(
      charactersAsync,
      isPreviewLoading: isPreviewLoading,
    );

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              WoodBackHeader(title: 'REJOINDRE UN GROUPE', onBack: _goBack),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_bannerMessage != null) ...[
                          AlertBanner(message: _bannerMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        Text(
                          'Demande le code d\'invitation à un membre du '
                          'groupe, puis choisis le personnage qui vous '
                          'rejoindra.',
                          style: AppTypography.body(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionLabel('Code d\'invitation'),
                        const SizedBox(height: AppSpacing.xs),
                        _CodeField(
                          controller: _codeController,
                          enabled: !_isBusy,
                          // Code modifié : l'erreur de code et le bandeau
                          // portaient sur l'ancien code (sinon ils
                          // resteraient à côté de l'aperçu du nouveau).
                          onChanged: (_) => setState(() {
                            _codeErrorMessage = null;
                            _bannerMessage = null;
                          }),
                        ),
                        if (codeErrorMessage != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          _CodeErrorHint(message: codeErrorMessage),
                        ],
                        if (preview != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _GroupInvitePreviewCard(preview: preview),
                        ] else if (isPreviewLoading) ...[
                          const SizedBox(height: AppSpacing.sm),
                          const _GroupInvitePreviewLoading(),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionLabel(
                          'Qui te représente dans ce groupe ?',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Correctif F01 (`docs/retours-utilisateurs.md`) :
                        // signale explicitement l'option "MJ — sans
                        // personnage" avant même d'ouvrir la sheet de choix
                        // de rôle (voir [_GmOptionRow]) — même texte que
                        // `group_create_screen.dart`.
                        Text(
                          'Choisis ton personnage, ou sélectionne '
                          '« MJ — sans personnage » si tu animes la partie '
                          'sans fiche.',
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _RoleSelectorTile(
                          character: selectedCharacter,
                          isGameMaster: _joinAsGameMaster,
                          hasResolvedEmptyList: hasResolvedEmptyList,
                          enabled: !_isBusy,
                          onTap: () => _openRolePicker(charactersAsync),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  // Décision n° 34 : rejoindre seulement un groupe vu. Rôle
                  // et action choisis d'après ce qui est affiché ; la clé
                  // change avec le rôle (et avec le code du groupe affiché) :
                  // un appui commencé sur « Voir le groupe » est annulé si le
                  // bouton devient « Rejoindre » avant que le doigt se lève
                  // (relecture de code de la PR #304).
                  child: PrimaryButton(
                    key: ValueKey(
                      preview == null ? 'see' : 'join-$previewCode',
                    ),
                    label: preview == null
                        ? l10n.groupJoinSeeGroupAction
                        : l10n.groupJoinAction,
                    isLoading: _isBusy,
                    onPressed: !canSubmit
                        ? null
                        : preview == null
                        ? () => _loadPreview(code)
                        : () => _join(
                            code,
                            characters ?? const <CharacterSummary>[],
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_isJoining) const _JoinSavingOverlay(),
        ],
      ),
    );
  }
}

/// Libellé de section normal case/gras — distinct de la convention
/// "MAJUSCULES + `textSecondary`" utilisée ailleurs dans ce module
/// (`NOM DU GROUPE`, `MES DONNÉES`...) : la maquette "Groupe — Rejoindre"
/// (`docs/cahier-des-charges/09-maquettes-captures.md`) montre explicitement
/// "Code d'invitation"/"Qui te représente dans ce groupe ?" en casse
/// normale, plus grand et plus sombre — recettage direction-artistique du
/// 13/09/2026, écart assumé par rapport à la convention majuscule des autres
/// écrans du module.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.body(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Champ code — encadré `parchmentCard`/bordure `goldEnd`, texte centré large
/// avec un tiret de présentation ("AB3F - 7K2M"), inspiré du style visuel de
/// `_InviteCodeChip` (`group_screen.dart`) mais éditable (`TextField`) — voir
/// [_GroupCodeInputFormatter] pour la logique de formatage/validation.
class _CodeField extends StatelessWidget {
  const _CodeField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.goldEnd, width: AppBorders.card),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        autofocus: controller.text.isEmpty,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [_GroupCodeInputFormatter()],
        onChanged: onChanged,
        style: AppTypography.body(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ).copyWith(letterSpacing: 4),
        decoration: const InputDecoration(
          hintText: 'AB3F - 7K2M',
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// Texte d'aide discret sous le champ code (triangle + texte, jamais encadré)
/// — voir la documentation de classe de [GroupJoinScreen] pour le rationale
/// de ce choix face à [AlertBanner].
class _CodeErrorHint extends StatelessWidget {
  const _CodeErrorHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // Annoncé par le lecteur d'écran : l'erreur peut apparaître seule, sans
    // toucher, via l'aperçu automatique (relecture de code de la PR #304).
    return Semantics(liveRegion: true, container: true, child: _buildContent());
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 16,
          color: AppColors.accentBrick,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: AppTypography.body(
              fontSize: 12,
              color: AppColors.accentBrick,
            ),
          ),
        ),
      ],
    );
  }
}

/// Carte d'aperçu du groupe visé par le code (décision n° 34) : nom, nombre
/// de membres, puis « Campagne : … » sans icône (décision n° 33 : le titre
/// seul, jamais le résumé), omis sans campagne ou si le titre répète le nom
/// du groupe (décision n° 36, [GroupPreview.campaignTitle]). Même encadré
/// que [_RoleSelectorTile]. `liveRegion` : son apparition est annoncée par
/// le lecteur d'écran.
class _GroupInvitePreviewCard extends StatelessWidget {
  const _GroupInvitePreviewCard({required this.preview});

  final GroupPreview preview;

  @override
  Widget build(BuildContext context) {
    final campaignTitle = preview.campaignTitle;

    return Semantics(
      liveRegion: true,
      container: true,
      child: _PreviewFrame(
        key: const ValueKey('groupInvitePreviewCard'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preview.name,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              AppLocalizations.of(context)!
                  .groupInvitePreviewMemberCount(preview.memberCount),
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (campaignTitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              // Variante compacte : ne concurrence pas le nom du groupe.
              GroupCampaignTitleText.compact(title: campaignTitle),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chargement de l'aperçu (revue direction-artistique de la PR #304) : même
/// emplacement et même encadré que [_GroupInvitePreviewCard], indicateur
/// 16×16 et « Recherche du groupe… », annoncé par le lecteur d'écran.
class _GroupInvitePreviewLoading extends StatelessWidget {
  const _GroupInvitePreviewLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: _PreviewFrame(
        key: const ValueKey('groupInvitePreviewLoading'),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.woodMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.groupInvitePreviewLoading,
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encadré commun de l'aperçu et de son chargement : même encadré que
/// [_RoleSelectorTile] (`parchmentCard`, bordure `woodLight`, `AppRadius.md`).
class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: child,
    );
  }
}

/// Tuile affichant le rôle actuellement sélectionné : le personnage choisi
/// (portrait, nom, "Race · Classe · Niv. X"), le rôle "MJ — sans personnage"
/// si [isGameMaster], ou un état neutre selon que [character] est `null`
/// parce que rien n'est encore résolu (placeholder générique) ou parce que
/// la liste de personnages est confirmée vide ([hasResolvedEmptyList]).
///
/// **Toujours tappable** ([enabled] ne dépend que de `!_isBusy`, jamais
/// de l'état de `charactersProvider`) — voir la doc de classe de
/// [GroupJoinScreen] pour le rationale du correctif. Tap ouvre "CHOISIR TON
/// RÔLE" (voir `GroupJoinScreen._openRolePicker`).
class _RoleSelectorTile extends StatelessWidget {
  const _RoleSelectorTile({
    required this.character,
    required this.isGameMaster,
    required this.hasResolvedEmptyList,
    required this.enabled,
    required this.onTap,
  });

  final CharacterSummary? character;
  final bool isGameMaster;
  final bool hasResolvedEmptyList;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = character;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              isGameMaster
                  ? const PortraitFrame(
                      portraitUrl: null,
                      fallbackIcon: Icons.visibility_outlined,
                      classThemeColor: AppColors.woodMedium,
                      size: 44,
                    )
                  : PortraitFrame(
                      portraitUrl: summary?.portraitUrl,
                      size: 44,
                      classThemeColor: _classThemeColor(summary?.className),
                    ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildLabel(summary)),
              if (enabled)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(CharacterSummary? summary) {
    if (isGameMaster) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'MJ — sans personnage',
            style: AppTypography.body(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Suit le groupe sans fiche de personnage.',
            style: AppTypography.body(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
    if (summary != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summary.name,
            style: AppTypography.body(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            _summaryLine(summary),
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
    final text = hasResolvedEmptyList
        ? "Tu n'as pas encore de personnage à rattacher."
        : 'Choisir un personnage ou un rôle';
    return Text(
      text,
      style: AppTypography.body(fontSize: 13, color: AppColors.textSecondary),
    );
  }

  /// "Race · Classe · Niv. X" — même omission des segments non résolus que
  /// `CharacterCard._summaryLine`, dupliqué ici (classe privée à son
  /// fichier).
  String _summaryLine(CharacterSummary character) {
    final segments = [
      if (character.raceName != null) character.raceName!,
      if (character.className != null) character.className!,
      'Niv. ${character.level}',
    ];
    return segments.join(' · ');
  }

  /// Même mapping que `CharacterCard._classThemeColor` (dupliqué ici, classe
  /// privée à son fichier).
  Color? _classThemeColor(String? className) {
    return switch (className) {
      'Magicien' => AppColors.accentTeal,
      'Guerrier' => AppColors.accentBrick,
      'Clerc' => AppColors.accentBlue,
      _ => null,
    };
  }
}

/// Note compacte "aucun personnage" affichée SOUS [_GmOptionRow] dans la
/// sheet "CHOISIR TON RÔLE" lorsque la liste résolue est vide — même gabarit
/// que `group_create_screen.dart::_NoCharacterNote` (boîte `parchment.card`/
/// `wood.light`/`radius.sm`, icône + texte sur une ligne), dupliqué ici avec
/// le texte déjà utilisé par [_RoleSelectorTile] sur cet écran.
class _NoCharacterNote extends StatelessWidget {
  const _NoCharacterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Tu n'as pas encore de personnage à rattacher.",
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterTileError extends StatelessWidget {
  const _CharacterTileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}

/// Ligne sélectionnable de la sheet "CHOISIR TON RÔLE" — même patron que
/// `group_create_screen.dart::_SelectableCharacterRow` (`CharacterCard` +
/// bouton radio 20×20), dupliqué ici (classe privée à son fichier).
class _SelectableCharacterRow extends StatelessWidget {
  const _SelectableCharacterRow({
    required this.character,
    required this.selected,
    required this.onTap,
  });

  final CharacterSummary character;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              PortraitFrame(portraitUrl: character.portraitUrl, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      character.name,
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _RadioIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne "MJ — sans personnage" de la sheet "CHOISIR TON RÔLE" — toujours en
/// première position, toujours sélectionnable indépendamment de l'état de
/// `charactersProvider` (voir la doc de classe de [GroupJoinScreen]). Même
/// gabarit visuel que [_SelectableCharacterRow], même tuile 44×44 que
/// [_RoleSelectorTile], titre/sous-titre identiques à son état "MJ choisi"
/// (contrairement à `group_create_screen.dart::_GmOptionRow`, cet écran
/// affiche un sous-titre sur 2 lignes, comme ses lignes personnage dans la
/// tuile).
class _GmOptionRow extends StatelessWidget {
  const _GmOptionRow({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              const PortraitFrame(
                portraitUrl: null,
                fallbackIcon: Icons.visibility_outlined,
                classThemeColor: AppColors.woodMedium,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MJ — sans personnage',
                      style: AppTypography.body(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Suit le groupe sans fiche de personnage.',
                      style: AppTypography.body(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _RadioIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton radio 20×20px du design système — duplication volontaire de
/// `group_create_screen.dart::_RadioIndicator` (classe privée à son fichier).
class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.goldEnd : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.woodDark : AppColors.woodLight,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

/// Overlay de rattachement en cours — calque exact de l'ancien
/// `_JoinSavingOverlay` (`group_join_character_step_screen.dart`, retiré par
/// cette tâche), affiché pendant `joinGroup` seulement : l'aperçu (« Voir le
/// groupe », `previewGroupInvite`) ne rattache rien et n'a pas de voile, son
/// attente se lit sur le bouton et dans la zone de l'aperçu (revue
/// direction-artistique de la PR #304).
class _JoinSavingOverlay extends StatelessWidget {
  const _JoinSavingOverlay();

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
                'Rattachement au groupe...',
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

/// Ne garde que les caractères alphanumériques de [text], en majuscules — le
/// code réellement transmis à `previewGroupInvite`/`joinGroup` ne doit jamais
/// porter le tiret de présentation ajouté par [_GroupCodeInputFormatter].
String _rawCode(String text) =>
    text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

/// "AB3F - 7K2M" : insère un tiret de présentation après la moitié de
/// [_rawCodeLength] caractères, une fois [raw] assez long — voir la maquette
/// "Groupe — Rejoindre" (`docs/cahier-des-charges/09-maquettes-captures.md`),
/// qui illustre ce même séparateur sur un exemple de code plus court. Rendu
/// inchangé tant que [raw] ne dépasse pas la moitié de [_rawCodeLength].
String _formatCodeDisplay(String raw) {
  const splitAt = _rawCodeLength ~/ 2;
  if (raw.length <= splitAt) return raw;
  return '${raw.substring(0, splitAt)} - ${raw.substring(splitAt)}';
}

/// Met en majuscules, ne garde que les caractères alphanumériques, limite à
/// [_rawCodeLength] caractères bruts et insère le tiret de présentation
/// ([_formatCodeDisplay]) à chaque frappe — le curseur est systématiquement
/// replacé en fin de champ (simplification assumée, même principe que
/// `_UpperCaseTextFormatter` des flux "Rejoindre" existants : un code court
/// ne justifie pas de préserver une position de curseur au milieu du texte).
class _GroupCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = _rawCode(newValue.text);
    final truncated = raw.length > _rawCodeLength
        ? raw.substring(0, _rawCodeLength)
        : raw;
    final formatted = _formatCodeDisplay(truncated);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
