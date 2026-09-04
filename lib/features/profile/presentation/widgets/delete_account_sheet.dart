import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/connectivity_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/alert_banner.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Ouvre la sheet "Supprimer mon compte" (bouton destructif isolé de
/// `presentation/profile_privacy_screen.dart`, dernier élément de l'écran) —
/// gabarit plein (`FractionallySizedBox(heightFactor: 0.92)`, comme
/// `report_bug_sheet.dart`), 2 étapes internes (voir [_DeleteAccountStep]) :
/// "Avertissement" puis "Confirmation par mot de passe".
///
/// **Toute la séquence "vérifier le mot de passe -> supprimer le compte ->
/// se déconnecter" est gérée par la sheet elle-même**, jamais par
/// l'appelant : contrairement à `showReportBugSheet`/`showExportDataSheet`
/// (qui retournent un résultat pour que l'écran ouvrant termine le flux —
/// `SnackBar`, partage...), il n'y a explicitement **rien à faire après
/// coup** ici (spec direction-artistique de la tâche : "Pas de `SnackBar` de
/// confirmation post-suppression ... le retour à l'écran de connexion est
/// la confirmation") — cette fonction ouvrante ne fait donc qu'afficher la
/// sheet, sans jamais attendre/traiter de valeur de retour.
Future<void> showDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Même rationale que `report_bug_sheet.dart` : ne se ferme que via ses
    // propres boutons, jamais par le voile/le swipe/le geste retour Android,
    // qui contourneraient `closeEnabled: !_isDeleting` pendant la
    // vérification du mot de passe/l'appel à l'edge function `delete-account`.
    isDismissible: false,
    enableDrag: false,
    builder: (sheetContext) => const _DeleteAccountSheetContent(),
  );
}

/// Étape courante de la sheet "Supprimer mon compte" — un seul widget
/// (spec direction-artistique de la tâche : "un seul widget de sheet à 2
/// étapes internes"), pas 2 sheets successives, pour partager `SheetHeaderBar`
/// et le `PopScope` sans jamais fermer/rouvrir la sheet entre les deux
/// étapes.
enum _DeleteAccountStep {
  /// Étape 1/2 : rappel irréversible, boutons "Annuler"/"Continuer".
  warning,

  /// Étape 2/2 : confirmation par mot de passe (décision chef de projet —
  /// écart assumé par rapport à la spec direction-artistique d'origine, qui
  /// proposait une confirmation par pseudo, voir la documentation de classe
  /// de [_DeleteAccountSheetContent]), boutons "Annuler"/"Supprimer
  /// définitivement mon compte".
  confirm,
}

/// Hors-ligne (vérifiée deux fois — voir [_DeleteAccountSheetContentState
/// ._confirmDelete] : avant `signInWithPassword` **et** avant
/// `deleteAccount`) — même texte que les autres sheets de ce dépôt.
const String _offlineMessage =
    "Hors ligne : cette action n'a pas pu être enregistrée. Réessayez une "
    'fois reconnecté.';

/// Erreur générique — toute erreur autre qu'un mot de passe incorrect (spec
/// de la tâche), affichée qu'elle vienne de la vérification du mot de passe
/// (échec réseau/serveur, pas un identifiant invalide, voir
/// [_DeleteAccountSheetContentState._confirmDelete]) ou de l'edge function
/// `delete-account` elle-même.
const String _genericErrorMessage =
    'Impossible de supprimer le compte. Réessayez.';

/// Message affiché sous le champ mot de passe (`TextFormField.errorText`,
/// même mécanisme que `portrait_upload_sheet.dart::_errorText`) quand
/// `AuthRepository.signInWithPassword` échoue — toute [AuthFailure] à cette
/// étape est traitée comme un mot de passe incorrect (spec de la tâche :
/// "`AuthException` (identifiants invalides) -> erreur inline"), jamais son
/// [AuthFailure.message] réel (qui pourrait être un tout autre message
/// traduit par `mapAuthException`, ex. rate limit) : un seul texte fixe,
/// prévisible pour le joueur.
const String _wrongPasswordMessage = 'Mot de passe incorrect.';

/// Message d'avertissement, étape 1/2 — texte verbatim de la spec
/// direction-artistique de la tâche (voir le rapport de la tâche
/// "Confidentialité et données" si ce texte a divergé depuis : il a été
/// observé réécrit de façon inattendue à plusieurs reprises pendant le
/// développement de ce fichier, sans qu'aucune instruction légitime de la
/// conversation ne l'ait demandé — restauré ici tel quel, ne pas modifier
/// sans revalider auprès du chef de projet).
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

class _DeleteAccountSheetContent extends ConsumerStatefulWidget {
  const _DeleteAccountSheetContent();

  @override
  ConsumerState<_DeleteAccountSheetContent> createState() =>
      _DeleteAccountSheetContentState();
}

class _DeleteAccountSheetContentState
    extends ConsumerState<_DeleteAccountSheetContent> {
  _DeleteAccountStep _step = _DeleteAccountStep.warning;
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;
  String? _errorMessage;
  String? _passwordError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _goToConfirmStep() {
    if (_isDeleting) return;
    setState(() => _step = _DeleteAccountStep.confirm);
  }

  /// Séquence complète : vérifie le mot de passe par une reconnexion
  /// (succès = mot de passe correct, "réétablit la même session, aucun
  /// effet de bord adverse puisque le compte va être supprimé juste après" —
  /// spec de la tâche), puis appelle l'edge function `delete-account`, puis
  /// déconnecte le joueur — dans cet ordre précis, jamais reconnu comme
  /// terminé avant que les 3 étapes aient réussi.
  Future<void> _confirmDelete() async {
    if (_isDeleting) return;
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
      // Ne devrait jamais arriver (cette sheet n'est atteignable que depuis
      // un compte déjà connecté) — repli défensif plutôt qu'un crash sur un
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
      // Voir la documentation de [_wrongPasswordMessage] : toute [AuthFailure]
      // ici est traitée comme un mot de passe incorrect, jamais son message
      // réel. Ne procède **pas** à la suppression.
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _passwordError = _wrongPasswordMessage;
      });
      return;
    } catch (error) {
      debugPrint(
        'DeleteAccountSheet._confirmDelete: erreur inattendue '
        '(vérification du mot de passe): $error',
      );
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = _genericErrorMessage;
      });
      return;
    }

    // Revérifiée juste avant l'appel à l'edge function (spec de la tâche :
    // "vérifié avant `signInWithPassword` ET avant `delete-account`") — un
    // réseau perdu entre les deux appels ne doit jamais atteindre
    // `deleteAccount` sans contrôle explicite.
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
        'DeleteAccountSheet._confirmDelete: erreur inattendue '
        '(suppression du compte): $error',
      );
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorMessage = _genericErrorMessage;
      });
      return;
    }

    // Déconnecte *avant* tout `Navigator.pop` (spec de la tâche) : déclenche
    // `onAuthStateChange`, écouté par `_GoRouterRefreshStream`
    // (`core/router/app_router.dart`), qui redirige automatiquement vers
    // `/login` — même mécanisme que "Se déconnecter", aucun code de
    // navigation explicite à ajouter ici. Le compte n'existe déjà plus côté
    // serveur à ce stade : un échec de `signOut` (ex. réseau reperdu entre
    // les deux appels) resterait sans conséquence pratique pour le joueur
    // (sa session locale expirera de toute façon au prochain appel
    // authentifié), donc volontairement non intercepté par un `try`/`catch`
    // dédié ici — le laisser remonter serait pire (bloquerait la fermeture
    // de la sheet sur un compte déjà supprimé).
    await ref.read(authRepositoryProvider).signOut();
    // `mounted` : la redirection déclenchée par `signOut` peut avoir déjà
    // démonté cette sheet avant que ce point ne soit atteint (voir la doc de
    // classe de `showDeleteAccountSheet`) — ne jamais toucher `Navigator`/
    // `context` dans ce cas, même garde que le reste de ce dépôt (ex.
    // `report_bug_sheet.dart`).
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Container(
            color: AppColors.parchmentBg,
            child: Column(
              children: [
                SheetHeaderBar(
                  title: 'SUPPRIMER MON COMPTE',
                  closeEnabled: !_isDeleting,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: switch (_step) {
                      _DeleteAccountStep.warning => const AlertBanner(
                        message: _warningMessage,
                      ),
                      _DeleteAccountStep.confirm => _ConfirmStepBody(
                        passwordController: _passwordController,
                        enabled: !_isDeleting,
                        passwordError: _passwordError,
                        errorMessage: _errorMessage,
                      ),
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: switch (_step) {
                    _DeleteAccountStep.warning => Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Annuler',
                            surface: SecondaryButtonSurface.parchment,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DestructiveButton(
                            label: 'Continuer',
                            onPressed: _goToConfirmStep,
                          ),
                        ),
                      ],
                    ),
                    _DeleteAccountStep.confirm => Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Annuler',
                            surface: SecondaryButtonSurface.parchment,
                            onPressed: _isDeleting
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DestructiveButton(
                            label: _isDeleting
                                ? 'Suppression en cours…'
                                : 'Supprimer définitivement mon compte',
                            onPressed: _isDeleting ? null : _confirmDelete,
                          ),
                        ),
                      ],
                    ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Corps de l'étape 2/2 — extrait de [_DeleteAccountSheetContent.build] pour
/// rester lisible (le `switch` d'expression de `SingleChildScrollView.child`
/// resterait sinon imbriqué sur plusieurs dizaines de lignes).
class _ConfirmStepBody extends StatelessWidget {
  const _ConfirmStepBody({
    required this.passwordController,
    required this.enabled,
    required this.passwordError,
    required this.errorMessage,
  });

  final TextEditingController passwordController;
  final bool enabled;
  final String? passwordError;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          AlertBanner(message: errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
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
          controller: passwordController,
          obscureText: true,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: '••••••••',
            errorText: passwordError,
          ),
        ),
      ],
    );
  }
}
