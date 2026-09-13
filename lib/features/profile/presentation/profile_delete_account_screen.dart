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

/// Hors-ligne (vérifiée deux fois — voir [_confirmDelete] : avant
/// `signInWithPassword` **et** avant `deleteAccount`) — même texte que les
/// autres sheets/écrans de ce dépôt, migré tel quel depuis
/// `delete_account_sheet.dart`.
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

/// Erreur générique — toute erreur autre qu'un mot de passe incorrect (spec
/// de la tâche d'origine), affichée qu'elle vienne de la vérification du mot
/// de passe (échec réseau/serveur, pas un identifiant invalide, voir
/// [_confirmDelete]) ou de l'edge function `delete-account` elle-même.
/// Migré tel quel depuis `delete_account_sheet.dart`.
const String _genericErrorMessage =
    'Impossible de supprimer le compte. Réessayez.';

/// Message affiché sous le champ mot de passe (`TextFormField.errorText`)
/// quand `AuthRepository.signInWithPassword` échoue — toute [AuthFailure] à
/// cette étape est traitée comme un mot de passe incorrect, jamais son
/// [AuthFailure.message] réel. Migré tel quel depuis
/// `delete_account_sheet.dart`.
const String _wrongPasswordMessage = 'Mot de passe incorrect.';

/// Message d'avertissement du bandeau "ACTION IRRÉVERSIBLE" — texte verbatim
/// migré depuis `delete_account_sheet.dart::_warningMessage`, qui documentait
/// déjà "à ne pas modifier sans revalider auprès du chef de projet" : repris
/// ici sans y toucher (consigne explicite de la tâche de refonte visuelle).
// Le compte Supabase est unique et partagé avec l'app web "Histoires" :
// supprimer le compte (`auth.admin.deleteUser`) cascade en base non
// seulement vers les personnages de cette app, mais aussi vers les
// histoires que ce compte a créées en tant que MJ côté web
// (`stories.user_id`) et ses entrées codex (`codex_entries.user_id`),
// toutes deux référençant `auth.users` en cascade — vérifié par le
// chantier backend qui a construit l'edge function `delete-account`
// (dépôt web `markdown-editor`). Le texte ci-dessous doit refléter
// cette ampleur réelle, pas seulement les données propres à l'app
// mobile.
const String _warningMessage =
    'Cette action est irréversible. Elle supprimera définitivement :\n'
    '• Tous tes personnages et leurs portraits\n'
    '• Tes rattachements aux histoires que tu as rejointes\n'
    '• Toutes les histoires que tu as créées en tant que MJ sur l\'app '
    'Histoires (et l\'accès de tes joueurs à ces histoires)\n\n'
    'Cette action ne peut pas être annulée.';

/// Libellé de la case à cocher de confirmation — texte de la maquette
/// (`09-maquettes-captures.md`).
const String _confirmationCheckboxLabel =
    'Je comprends que cette action est définitive et que mes données ne '
    'pourront pas être récupérées.';

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
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
      _passwordError = null;
    });

    if (!await ref.read(connectivityCheckerProvider).hasConnection()) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = _offlineMessage;
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
        _errorMessage = _genericErrorMessage;
      });
      return;
    }

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithPassword(email: email, password: _passwordController.text);
    } on AuthFailure {
      // Voir la documentation de [_wrongPasswordMessage] : toute
      // [AuthFailure] ici est traitée comme un mot de passe incorrect,
      // jamais son message réel. Ne procède **pas** à la suppression.
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _passwordError = _wrongPasswordMessage;
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
        _errorMessage = _genericErrorMessage;
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
        _errorMessage = _offlineMessage;
      });
      return;
    }

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } catch (error) {
      debugPrint(
        'ProfileDeleteAccountScreen._confirmDelete: erreur inattendue '
        '(suppression du compte): $error',
      );
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = _genericErrorMessage;
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
    return PopScope(
      // Même garde que `delete_account_sheet.dart::PopScope` : bloque le
      // geste retour Android pendant l'appel réseau, pour ne pas
      // contourner `_isDeleting`.
      canPop: !_isDeleting,
      child: Scaffold(
        backgroundColor: AppColors.parchmentBg,
        body: Column(
          children: [
            WoodBackHeader(title: 'SUPPRIMER LE COMPTE', onBack: _goBack),
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
                    const _IrreversibleActionBanner(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'CE QUI SERA SUPPRIMÉ',
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const SettingsListCard(
                      children: [
                        _ChecklistRow(
                          label: 'Tous tes personnages et leurs fiches',
                        ),
                        _ChecklistRow(
                          label: 'Ton accès aux histoires partagées',
                        ),
                        _ChecklistRow(label: 'Ton profil et tes préférences'),
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
                      'SAISIS TON MOT DE PASSE POUR CONFIRMER',
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
                        hintText: '••••••••',
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
                        ? 'Suppression en cours…'
                        : 'Supprimer définitivement',
                    onPressed: _canSubmit ? _confirmDelete : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Annuler',
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
/// [_warningMessage] (migré tel quel, voir sa documentation) — agencement
/// distinct de l'`AlertBanner` partagé (`core/widgets/alert_banner.dart`,
/// icône + texte alignés en ligne, sans titre), non extrait en composant
/// partagé car c'est pour l'instant son seul usage dans ce dépôt.
class _IrreversibleActionBanner extends StatelessWidget {
  const _IrreversibleActionBanner();

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
            'ACTION IRRÉVERSIBLE',
            textAlign: TextAlign.center,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.accentBrick,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _warningMessage,
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
                  _confirmationCheckboxLabel,
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
