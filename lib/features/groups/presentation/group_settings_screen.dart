import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../combat/presentation/providers/character_combat_provider.dart';
import '../../combat/presentation/providers/combat_providers.dart';
import '../domain/group_detail.dart';
import '../domain/group_failure.dart';
import 'providers/group_providers.dart';
import 'widgets/group_confirmation_dialog.dart';
import 'widgets/group_dissolve_sheet.dart';
import 'widgets/group_invite_code_chip.dart';
import 'group_failure_l10n.dart';

const String _genericRenameErrorMessage =
    "Impossible d'enregistrer les modifications. Réessayez.";

/// Écran dédié "Paramètres du groupe", route `/groups/:id/settings` —
/// recettage direction-artistique du 13/09/2026 (`docs/cahier-des-charges/
/// 09-maquettes-captures.md`, section "Groupe — Paramètres") : remplace
/// `showGroupManagementSheet` (bottom sheet compacte, retirée par cette
/// tâche), la maquette attend un écran plein dédié plutôt qu'une sheet.
///
/// `WoodBackHeader` + corps parchemin scrollable (même gabarit que
/// `ProfileEditScreen`/`GroupCreateScreen`) : "Nom du groupe" (le
/// `TextFormField` est migré tel quel depuis `widgets/group_rename_sheet.dart`,
/// retiré par cette tâche — seul le libellé au-dessus change de style pour
/// suivre la maquette, voir [_SectionLabel]), "CODE D'INVITATION" (chip +
/// "Régénérer", même logique de confirmation/appel réseau que l'ancienne
/// `showGroupManagementSheet`, voir [_GroupSettingsScreenState
/// ._confirmRegenerateInviteCode]), puis "ZONE DANGEREUSE"
/// (`DestructiveButton` "Dissoudre le groupe", flux de confirmation existant
/// [showGroupDissolveSheet] réutilisé tel quel, jamais réécrit).
///
/// Pas de "Quitter le groupe" ici : cet écran n'est accessible qu'au
/// fondateur (icône réglages du header de `group_screen.dart`, réservée à
/// `detail.isOwner` — les autres membres y voient une icône déconnexion qui
/// déclenche directement `_GroupScreenState._confirmLeaveGroup`, jamais
/// cet écran). Décision du chef de projet : un fondateur ne "quitte" pas
/// son groupe, il le dissout (voir la "ZONE DANGEREUSE" ci-dessus) —
/// `GroupRepository.leaveGroup` ne gère de toute façon pas le transfert de
/// `groups.owner_id` qu'un départ du fondateur supposerait.
///
/// Le nom se sauvegarde via le `PrimaryButton` "Enregistrer" fixé en pied
/// d'écran (`_submitRename`, logique reprise de `group_rename_sheet.dart`) —
/// les autres actions (régénérer/quitter/dissoudre) restent immédiates au
/// tap, comme sur l'ancienne sheet.
///
/// **« Devenir MJ »** (étape 3b, migration DeepCore `20261119090000`) :
/// section « MAÎTRE DU JEU » affichée seulement au propriétaire qui joue un
/// personnage dans ce groupe ([GroupDetail.canBecomeGameMaster]), cible du
/// lien « Paramètres du groupe » du bandeau « Pas de combat sans MJ dans
/// l'app » (`StartCombatSection`). Confirmation, puis RPC
/// `become_group_game_master` (bouton bloqué pendant l'appel), puis relecture
/// du groupe : la section disparaît et l'onglet Membres propose « Lancer un
/// combat ». Action serveur : désactivée hors ligne, jamais mise en file
/// d'attente.
///
/// **Dissolution pendant un combat (D224)** : garde cliente avant d'ouvrir
/// la feuille ([_GroupSettingsScreenState._openDissolveSheet]) ; le serveur
/// reste l'autorité (refus `combat_active` traduit par la feuille).
class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _nameInitialized = false;
  String _initialName = '';
  bool _isSaving = false;
  String? _errorMessage;
  bool _becomingGameMaster = false;
  String? _gameMasterErrorMessage;
  bool _dissolveGuardInFlight = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_isSaving) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _canSave {
    final trimmed = _nameController.text.trim();
    return _nameInitialized &&
        !_isSaving &&
        trimmed.isNotEmpty &&
        trimmed != _initialName;
  }

  /// Migré depuis `group_rename_sheet.dart::_GroupRenameSheetContentState
  /// ._submit` : même appel réseau (écriture directe `UPDATE groups`) et même
  /// distinction [GroupFailure]/erreur générique, adapté pour rester sur
  /// place (écran dédié, pas de `Navigator.pop`) et remettre à jour
  /// [_initialName] pour redésactiver "Enregistrer" jusqu'à la prochaine
  /// modification — même patron que `ProfileEditScreen._submit`.
  Future<void> _submitRename() async {
    if (!_canSave) return;
    final name = _nameController.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(groupRepositoryProvider)
          .renameGroup(groupId: widget.groupId, name: name);
      ref.invalidate(groupDetailProvider(widget.groupId));
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _initialName = name;
      });
      _showSnackBar('Groupe renommé.');
    } on GroupFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = failure.localized(context);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = _genericRenameErrorMessage;
      });
    }
  }

  /// Même confirmation/appel réseau/invalidation que l'ancienne
  /// `showGroupManagementSheet` (`group_screen.dart::_GroupScreenState
  /// ._confirmRegenerateInviteCode`, retirée avec le bandeau d'identité de
  /// `group_screen.dart` par une tâche parallèle à celle-ci — voir sa doc de
  /// classe).
  Future<void> _confirmRegenerateInviteCode() async {
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: "Régénérer le code d'invitation ?",
      message:
          "L'ancien code cessera de fonctionner immédiatement. Les membres "
          'déjà présents ne sont pas affectés.',
      confirmLabel: 'Régénérer',
      destructive: false,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(groupRepositoryProvider)
          .regenerateInviteCode(widget.groupId);
      ref.invalidate(groupDetailProvider(widget.groupId));
      if (!mounted) return;
      _showSnackBar('Code régénéré.');
    } on GroupFailure catch (failure) {
      _showSnackBar(failure.localized(context));
    } catch (_) {
      _showSnackBar('Impossible de régénérer le code. Réessayez.');
    }
  }

  bool get _isOffline => ref.read(connectivityStatusProvider).value == false;

  /// « Dissoudre le groupe » — garde cliente (D224), même principe que la
  /// garde de départ de `GroupScreen._confirmLeaveGroup` : on relit le combat
  /// avant de décider (un état `loading`/périmé ne doit jamais laisser passer
  /// un combat actif connu), puis on refuse pendant un combat actif. Hors
  /// ligne, la relecture échoue et garde le dernier état connu ; sans état
  /// connu, la feuille s'ouvre et la dissolution échouera de toute façon.
  /// Le serveur reste l'autorité : son refus `combat_active` (état local
  /// périmé, course) est traduit par la feuille elle-même.
  Future<void> _openDissolveSheet(GroupDetail detail) async {
    if (_dissolveGuardInFlight) return;
    _dissolveGuardInFlight = true;
    try {
      await ref.read(combatProvider(widget.groupId).notifier).refresh();
      if (!mounted) return;
      if (ref.read(combatProvider(widget.groupId)).hasActiveCombat) {
        _showSnackBar(
          AppLocalizations.of(context)!.groupDissolveBlockedByCombat,
        );
        return;
      }
      await showGroupDissolveSheet(
        context,
        groupId: widget.groupId,
        groupName: detail.name,
      );
    } finally {
      _dissolveGuardInFlight = false;
    }
  }

  /// « Devenir MJ » : confirmation, puis RPC `become_group_game_master`
  /// (bouton bloqué pendant l'appel), puis relecture du groupe avant de
  /// débloquer (la section disparaît dès que le rôle MJ est relu).
  Future<void> _confirmBecomeGameMaster(GroupDetail detail) async {
    if (_becomingGameMaster) return;
    final l10n = AppLocalizations.of(context)!;
    final characterName = detail.currentMember?.name ?? '';
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: l10n.groupBecomeGameMasterConfirmTitle(detail.name),
      message: l10n.groupBecomeGameMasterConfirmBody(characterName),
      confirmLabel: l10n.groupBecomeGameMasterConfirmAction,
      cancelLabel: l10n.groupBecomeGameMasterCancel,
      destructive: false,
      focusCancelInitially: true,
    );
    if (confirmed != true || !mounted || _becomingGameMaster) return;
    // Le réseau a pu tomber pendant la confirmation : jamais d'appel hors
    // ligne, jamais de file d'attente (action serveur). Message passager :
    // l'indice sous le bouton désactivé prend le relais tant que le réseau
    // manque, rien ne reste affiché après la reconnexion.
    if (_isOffline) {
      _showSnackBar(l10n.groupBecomeGameMasterOffline);
      return;
    }

    // Conteneur capturé avant l'appel : les caches sont invalidés même si
    // l'écran a été quitté pendant l'appel (`ref` n'est alors plus utilisable).
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _becomingGameMaster = true;
      _gameMasterErrorMessage = null;
    });
    try {
      await container
          .read(groupRepositoryProvider)
          .becomeGroupGameMaster(widget.groupId);
    } on GroupFailure catch (failure) {
      _onBecomeGameMasterFailure(container, failure, l10n);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _becomingGameMaster = false;
        _gameMasterErrorMessage = l10n.groupBecomeGameMasterGenericError;
      });
      return;
    }

    // Le personnage a quitté le groupe : sa fiche ne doit plus afficher le
    // bandeau de combat de ce groupe, et l'écran Groupe doit relire le rôle
    // (Realtime n'écoute pas les mises à jour de `group_members`).
    container
      ..invalidate(characterGroupIdsProvider)
      ..invalidate(groupDetailProvider(widget.groupId));
    if (!mounted) return;
    await _awaitGroupDetail();
    if (!mounted) return;
    setState(() => _becomingGameMaster = false);
    _showSnackBar(l10n.groupBecomeGameMasterSuccess);
  }

  void _onBecomeGameMasterFailure(
    ProviderContainer container,
    GroupFailure failure,
    AppLocalizations l10n,
  ) {
    switch (failure.code) {
      case GroupErrorCode.combatActive:
        // État local périmé : le serveur a vu un combat actif. On relit le
        // combat pour que l'écran Groupe affiche son bandeau.
        unawaited(
          container.read(combatProvider(widget.groupId).notifier).refresh(),
        );
      case GroupErrorCode.mjAlreadyAssigned:
        // L'autre MJ apparaît dans la liste des membres une fois relue.
        container.invalidate(groupDetailProvider(widget.groupId));
      default:
        break;
    }
    if (!mounted) return;
    setState(() {
      _becomingGameMaster = false;
      _gameMasterErrorMessage = failure.code == GroupErrorCode.generic
          ? l10n.groupBecomeGameMasterGenericError
          : failure.localizedWith(
              l10n,
              combatActiveMessage: l10n.groupBecomeGameMasterCombatActive,
            );
    });
  }

  /// Attend la relecture du détail du groupe (déjà invalidé). Un échec est
  /// affiché par l'écran lui-même (état d'erreur + « Réessayer »).
  Future<void> _awaitGroupDetail() async {
    try {
      await ref.read(groupDetailProvider(widget.groupId).future);
    } on Object {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    // Initialise le contrôleur de nom une seule fois, dès que
    // `groupDetailProvider` résout une première valeur — pas de
    // `ref.listen(..., fireImmediately: true)` ici : contrairement au `Ref`
    // générique utilisé par `groupMembersRealtimeWatcherProvider`
    // (`providers/group_providers.dart`), le `WidgetRef.listen` d'un
    // `ConsumerState` ne supporte pas `fireImmediately` (un rebuild ne permet
    // pas de savoir quel appel `listen` doit être "réémis"). Une simple
    // lecture de `detailAsync.value` après `ref.watch` suffit : ce `build`
    // est de toute façon ré-exécuté dès que le provider passe de
    // chargement à donnée.
    final detail = detailAsync.value;
    if (detail != null && !_nameInitialized) {
      _nameController.text = detail.name;
      _initialName = detail.name;
      _nameInitialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(title: 'PARAMÈTRES DU GROUPE', onBack: _goBack),
          Expanded(
            child: detailAsync.when(
              data: _buildBody,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.woodMedium),
              ),
              error: (error, stackTrace) => _ErrorState(
                message: error is GroupFailure
                    ? error.localized(context)
                    : 'Impossible de charger ce groupe. Réessayez.',
                onRetry: () =>
                    ref.invalidate(groupDetailProvider(widget.groupId)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GroupDetail detail) {
    final l10n = AppLocalizations.of(context)!;
    final offline = ref.watch(connectivityStatusProvider).value == false;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  AlertBanner(message: _errorMessage!),
                  const SizedBox(height: AppSpacing.md),
                ],
                const _SectionLabel('Nom du groupe'),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  minLines: 1,
                  maxLines: 1,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Ex. Les Lames de l\'Aube',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  "CODE D'INVITATION",
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: GroupInviteCodeChip(code: detail.inviteCode),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SecondaryButton(
                      label: 'Régénérer',
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: _confirmRegenerateInviteCode,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Régénérer invalide l'ancien code : les membres déjà "
                  'rattachés ne sont pas affectés.',
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                if (detail.canBecomeGameMaster) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildGameMasterSection(detail, l10n, offline: offline),
                ],
                const SizedBox(height: AppSpacing.lg),
                const Divider(color: AppColors.woodLight, thickness: 1),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'ZONE DANGEREUSE',
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentBrick,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DestructiveButton(
                  label: l10n.groupSettingsDissolveAction,
                  icon: Icons.delete_outline,
                  onPressed: () => _openDissolveSheet(detail),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.groupSettingsDissolveCaption,
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.gaugeTrack),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: PrimaryButton(
            label: 'Enregistrer',
            isLoading: _isSaving,
            onPressed: _canSave ? _submitRename : null,
          ),
        ),
      ],
    );
  }

  /// Section « MAÎTRE DU JEU » (propriétaire qui joue un personnage) : même
  /// gabarit que « CODE D'INVITATION » (titre 13/800 `textSecondary`,
  /// légende 12 `textMuted`, qui porte la conséquence) ; `SecondaryButton`
  /// parchemin pleine largeur « Devenir MJ » (revue direction-artistique de la
  /// PR #303 : ni brique, réservée à la zone dangereuse, rien n'est supprimé
  /// ici ; ni or, réservé à « Enregistrer »). Erreur serveur affichée juste
  /// au-dessus du bouton (`AlertBanner`).
  Widget _buildGameMasterSection(
    GroupDetail detail,
    AppLocalizations l10n, {
    required bool offline,
  }) {
    final characterName = detail.currentMember?.name ?? '';
    final error = _gameMasterErrorMessage;
    return Column(
      key: const Key('groupSettingsGameMasterSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.groupBecomeGameMasterSectionTitle,
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.groupBecomeGameMasterExplain(characterName),
          style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (error != null) ...[
          AlertBanner(message: error),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          width: double.infinity,
          child: SecondaryButton(
            key: const Key('becomeGameMasterButton'),
            surface: SecondaryButtonSurface.parchment,
            icon: Icons.admin_panel_settings_outlined,
            label: _becomingGameMaster
                ? l10n.groupBecomeGameMasterInProgress
                : l10n.groupBecomeGameMasterAction,
            onPressed: (offline || _becomingGameMaster)
                ? null
                : () => _confirmBecomeGameMaster(detail),
          ),
        ),
        if (offline) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.groupBecomeGameMasterOffline,
            style: AppTypography.body(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Libellé "Nom du groupe" — casse normale, plus grand/plus sombre que la
/// convention "MAJUSCULES + `textSecondary`" du reste du module (voir
/// `group_rename_sheet.dart::"NOM DU GROUPE"`) : la maquette "Groupe —
/// Paramètres" (`docs/cahier-des-charges/09-maquettes-captures.md`) montre
/// explicitement cette casse — recettage direction-artistique du 13/09/2026,
/// même écart assumé que `GroupJoinScreen._SectionLabel` (écran "Groupe —
/// Rejoindre" du même recettage).
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
