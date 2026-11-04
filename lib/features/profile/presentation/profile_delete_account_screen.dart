import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/destructive_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/settings_list_card.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_repository.dart'
    show pendingHpXpWritesBlockedMessage;
import '../../auth/domain/auth_failure.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Écran dédié "Supprimer le compte", route `/profile/privacy/delete-account`
/// — poussé depuis la tuile "Supprimer mon compte" de `ProfilePrivacyScreen`
/// (`DestructiveMenuTile`, section "ZONE DANGEREUSE"), qui ouvrait
/// auparavant `widgets/delete_account_sheet.dart` (bottom sheet modale à 2
/// étapes internes) — voir la doc de classe de cette dernière pour
/// l'historique. Refonte de conformité visuelle (recettage
/// direction-artistique du 13/09/2026, `docs/cahier-des-charges/
/// 09-maquettes-captures.md` section "Profil — Suppression du compte") :
/// la maquette attend un écran plein dédié, tout visible en même temps sur
/// un seul écran scrollable, plutôt qu'un flux en 2 étapes — décision
/// chef de projet, `showDeleteAccountSheet` est retiré au profit de cette
/// route.
///
/// Toute la séquence "vérifier le mot de passe -> supprimer le compte ->
/// se déconnecter" reste gérée par cet écran lui-même, jamais par
/// l'appelant (même contrat que l'ancienne sheet) — voir [_confirmDelete].
/// Contrairement à la sheet à 2 étapes (avertissement puis confirmation),
/// tout est visible d'emblée ici : le bandeau d'alerte, la liste de ce qui
/// sera supprimé, la case à cocher de confirmation et le champ mot de passe
/// partagent le même écran scrollable, et le bouton "SUPPRIMER
/// DÉFINITIVEMENT" reste désactivé tant que la case n'est pas cochée et que
/// le mot de passe est vide (pas de notion d'étape à franchir).
class ProfileDeleteAccountScreen extends ConsumerStatefulWidget {
  const ProfileDeleteAccountScreen({super.key});

  @override
  ConsumerState<ProfileDeleteAccountScreen> createState() =>
      _ProfileDeleteAccountScreenState();
}

class _ProfileDeleteAccountScreenState
    extends ConsumerState<ProfileDeleteAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _confirmed = false;
  bool _isDeleting = false;
  String? _errorMessage;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Réévalue `_canSubmit` à chaque frappe (le bouton "SUPPRIMER
    // DÉFINITIVEMENT" doit se dégriser dès que le mot de passe cesse d'être
    // vide, sans attendre une soumission).
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() => setState(() {});

  /// Case cochée ET mot de passe non vide (spec de la tâche) — pas de
  /// validation plus poussée du mot de passe ici, c'est
  /// `signInWithPassword` qui fait foi.
  bool get _canSubmit =>
      _confirmed && _passwordController.text.isNotEmpty && !_isDeleting;

  void _toggleConfirmed() {
    if (_isDeleting) return;
    setState(() => _confirmed = !_confirmed);
  }

  /// Séquence complète migrée à l'identique depuis
  /// `delete_account_sheet.dart::_confirmDelete` : vérifie le mot de passe
  /// par une reconnexion (succès = mot de passe correct, "réétablit la même
  /// session, aucun effet de bord adverse puisque le compte va être
  /// supprimé juste après"), puis appelle l'edge function `delete-account`,
  /// puis déconnecte le joueur — dans cet ordre précis, jamais reconnu comme
  /// terminé avant que les 3 étapes aient réussi. Seule adaptation par
  /// rapport à l'original : `Navigator.of(context).pop()` devient
  /// `context.pop()` (cet écran est maintenant une route `go_router`, plus
  /// une sheet modale).
  Future<void> _confirmDelete() async {
    if (!_canSubmit) return;
    // Capturé avant tout `await` (même précaution que
    // `avatar_crop_screen.dart`) : les gardes `mounted` ci-dessous couvrent
    // déjà l'usage de `context`/`l10n` après chaque point d'attente.
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
      _passwordError = null;
    });

    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = l10n.profileDeleteAccountOfflineMessage;
      });
      return;
    }

    final email = ref.read(currentUserProvider)?.email;
    if (email == null || email.isEmpty) {
      // Ne devrait jamais arriver (cet écran n'est atteignable que depuis un
      // compte déjà connecté) — repli défensif plutôt qu'un crash sur un
      // e-mail nul, même philosophie que `_requireOwnerId` côté repositories.
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = l10n.profileDeleteAccountGenericError;
      });
      return;
    }

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email, password: _passwordController.text);
    } on AuthFailure {
      // Voir la documentation de `profileDeleteAccountWrongPassword` : toute
      // [AuthFailure] ici est traitée comme un mot de passe incorrect,
      // jamais son message réel. Ne procède **pas** à la suppression.
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _passwordError = l10n.profileDeleteAccountWrongPassword;
      });
      return;
    } catch (error) {
      debugPrint(
        'ProfileDeleteAccountScreen._confirmDelete: erreur inattendue '
        '(vérification du mot de passe): $error',
      );
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = l10n.profileDeleteAccountGenericError;
      });
      return;
    }

    // Revérifiée juste avant l'appel à l'edge function (spec de la tâche
    // d'origine : "vérifié avant `signInWithPassword` ET avant
    // `delete-account`") — un réseau perdu entre les deux appels ne doit
    // jamais atteindre `deleteAccount` sans contrôle explicite.
    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = l10n.profileDeleteAccountOfflineMessage;
      });
      return;
    }

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } on AuthFailure catch (failure) {
      // D31 du registre de dette technique : seul cas où le message réel
      // d'une [AuthFailure] est affiché ici plutôt que le message générique
      // (spec de la tâche d'origine de cet écran, voir sa doc de classe) —
      // `pendingHpXpWritesBlockedMessage` est un texte applicatif de ce
      // dépôt (pas une erreur serveur brute, pas encore migré vers `.arb`,
      // voir `auth_repository.dart`), le joueur doit savoir que la
      // suppression est bloquée par une synchro PV/XP en attente, pas par un
      // échec générique, pour pouvoir réessayer en connaissance de cause.
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = failure.message == pendingHpXpWritesBlockedMessage
            ? failure.message
            : l10n.profileDeleteAccountGenericError;
      });
      return;
    } catch (error) {
      debugPrint(
        'ProfileDeleteAccountScreen._confirmDelete: erreur inattendue '
        '(suppression du compte): $error',
      );
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = l10n.profileDeleteAccountGenericError;
      });
      return;
    }

    // Déconnecte *avant* toute navigation (spec de la tâche d'origine) :
    // déclenche `onAuthStateChange`, écouté par `_GoRouterRefreshStream`
    // (`core/router/app_router.dart`), qui redirige automatiquement vers
    // `/login` — même mécanisme que "Se déconnecter", aucun code de
    // navigation explicite requis pour ça. Le compte n'existe déjà plus côté
    // serveur à ce stade : un échec de `signOut` (ex. réseau reperdu entre
    // les deux appels) resterait sans conséquence pratique pour le joueur
    // (sa session locale expirera de toute façon au prochain appel
    // authentifié), donc volontairement non intercepté par un `try`/`catch`
    // dédié ici.
    await ref.read(authRepositoryProvider).signOut();
    // `mounted` : la redirection déclenchée par `signOut` peut avoir déjà
    // démonté cet écran avant que ce point ne soit atteint — ne jamais
    // toucher `context` dans ce cas, même garde que
    // `delete_account_sheet.dart`.
    if (!mounted) return;
    if (context.canPop()) context.pop();
  }

  /// Même garde que `ProfilePrivacyScreen._goBack` : cet écran est
  /// normalement toujours atteint via `context.push(...)` (donc `canPop()`
  /// vrai), mais reste défensif si jamais poussé un jour comme route
  /// initiale (deep link).
  void _goBack() {
    if (_isDeleting) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      // Même garde que `delete_account_sheet.dart::PopScope` : bloque le
      // geste retour Android pendant l'appel réseau, pour ne pas
      // contourner `_isDeleting`.
      canPop: !_isDeleting,
      child: Scaffold(
        backgroundColor: AppColors.parchmentBg,
        body: Column(
          children: [
            WoodBackHeader(
              title: l10n.profileDeleteAccountScreenTitle,
              onBack: _goBack,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      _ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _IrreversibleActionBanner(l10n: l10n),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.profileDeleteAccountWhatWillBeDeletedTitle,
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SettingsListCard(
                      children: [
                        _ChecklistRow(
                          label: l10n.profileDeleteAccountChecklistCharacters,
                        ),
                        _ChecklistRow(
                          label: l10n.profileDeleteAccountChecklistStories,
                        ),
                        _ChecklistRow(
                          label: l10n.profileDeleteAccountChecklistProfile,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ConfirmationCheckbox(
                      value: _confirmed,
                      enabled: !_isDeleting,
                      onTap: _toggleConfirmed,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.profileDeleteAccountPasswordSectionTitle,
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !_isDeleting,
                      decoration: InputDecoration(
                        hintText: l10n.profileDeleteAccountPasswordHint,
                        errorText: _passwordError,
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
              child: Column(
                children: [
                  DestructiveButton(
                    filled: true,
                    label: _isDeleting
                        ? l10n.profileDeleteAccountSubmitInProgress
                        : l10n.profileDeleteAccountSubmitLabel,
                    onPressed: _canSubmit ? _confirmDelete : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: l10n.profileDeleteAccountCancel,
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: _isDeleting ? null : _goBack,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'erreur générique/hors-ligne — même style que l'`AlertBanner`
/// partagé (`core/widgets/alert_banner.dart`), dupliqué ici en privé car cet
/// écran a aussi besoin du bandeau "ACTION IRRÉVERSIBLE"
/// ([_IrreversibleActionBanner]) qui n'a, lui, pas le même agencement
/// (icône/titre centrés) que le composant partagé — voir sa documentation.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau "ACTION IRRÉVERSIBLE" en tête d'écran (maquette
/// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Profil —
/// Suppression du compte") : icône et titre centrés au-dessus du texte
/// `profileDeleteAccountWarningMessage` (texte à ne pas modifier sans
/// revalider auprès du chef de projet) — agencement distinct de
/// l'`AlertBanner` partagé (`core/widgets/alert_banner.dart`, icône + texte
/// alignés en ligne, sans titre), non extrait en composant partagé car
/// c'est pour l'instant son seul usage dans ce dépôt.
class _IrreversibleActionBanner extends StatelessWidget {
  const _IrreversibleActionBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.accentBrick,
          width: AppBorders.card,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.accentBrick,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.profileDeleteAccountWarningTitle,
            textAlign: TextAlign.center,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.accentBrick,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.profileDeleteAccountWarningMessage,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de la carte "CE QUI SERA SUPPRIMÉ" — coche + libellé, pensée pour
/// être empilée dans un `SettingsListCard` (icône/carte englobante/
/// séparateurs déjà portés par lui, même principe que `MenuTile(standalone:
/// false)`), mais sans chevron ni interaction (ligne purement informative).
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Case à cocher de confirmation (maquette : carré ~18×18px, bordure
/// `accent.brick`) — aucun composant partagé existant ne correspond (
/// `CheckableOptionTile` de `core/widgets/` porte toujours sa propre carte
/// `parchment.card`/bordure `wood.light` pour des lignes de liste
/// sélectionnable, pas une simple case + paragraphe de confirmation ; sa
/// bordure serait de toute façon `wood.light`/`gold-end`, pas `accent.brick`
/// comme l'exige cette maquette "zone dangereuse") — implémenté ici en
/// composant local plutôt que de détourner `CheckableOptionTile` ou d'en
/// créer un nouveau variant partagé pour un unique usage.
class _ConfirmationCheckbox extends StatelessWidget {
  const _ConfirmationCheckbox({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final bool value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: value ? AppColors.accentBrick : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.accentBrick, width: 1.5),
                ),
                child: value
                    ? const Icon(
                        Icons.check,
                        size: 13,
                        color: AppColors.textOnWood,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.profileDeleteAccountConfirmationCheckboxLabel,
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.textPrimary,
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
