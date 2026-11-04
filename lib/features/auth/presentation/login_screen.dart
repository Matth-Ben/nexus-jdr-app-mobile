import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/apple_logo.dart';
import '../../../core/widgets/app_brand_badge.dart';
import '../../../core/widgets/google_g_logo.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_validators.dart';
import 'providers/auth_providers.dart';
import 'widgets/forgot_password_dialog.dart';

/// Résout le texte final d'une [AuthFailure] à afficher à l'écran.
///
/// Voir la doc de classe d'[AuthErrorCode] (`domain/auth_failure.dart`) pour
/// le choix architectural : [AuthFailure.code] est résolu ici via
/// [AppLocalizations] pour les codes connus, [AuthFailure.message] (déjà
/// construit par `data/auth_error_mapper.dart`, ou fourni directement par
/// `AuthRepository`/les tests) reste utilisé tel quel pour
/// [AuthErrorCode.generic] — notamment le repli volontaire sur le message
/// brut de Supabase quand aucun code stable n'est exploitable (voir
/// `mapAuthException`).
String _resolveAuthFailureMessage(AppLocalizations l10n, AuthFailure failure) {
  switch (failure.code) {
    case AuthErrorCode.invalidCredentials:
      return l10n.authErrorInvalidCredentials;
    case AuthErrorCode.emailAlreadyExists:
      return l10n.authErrorEmailAlreadyExists;
    case AuthErrorCode.weakPassword:
      return l10n.authErrorWeakPassword(AuthValidators.minPasswordLength);
    case AuthErrorCode.emailNotConfirmed:
      return l10n.authErrorEmailNotConfirmed;
    case AuthErrorCode.invalidEmail:
      return l10n.authErrorInvalidEmail;
    case AuthErrorCode.tooManyRequests:
      return l10n.authErrorTooManyRequests;
    case AuthErrorCode.network:
      return l10n.authErrorNetwork;
    case AuthErrorCode.browserLaunchFailed:
      return l10n.authErrorBrowserLaunchFailed;
    case AuthErrorCode.generic:
      return failure.message;
  }
}

/// Mode du formulaire : connexion ou inscription, basculés sur un même
/// écran (voir maquette `00_connexion.png`) plutôt que deux écrans séparés.
enum _AuthMode { login, signUp }

/// Écran de connexion / inscription — premier écran présenté à un
/// utilisateur non connecté (`docs/cahier-des-charges/05-ux-navigation.md`).
///
/// Après un **login** réussi, la redirection vers `/` est gérée par le
/// routeur (`core/router/app_router.dart`), qui réagit lui-même au flux
/// `onAuthStateChange` : cet écran n'a pas besoin de naviguer explicitement.
///
/// Un **signup** réussi ne crée en revanche pas forcément de session : la
/// confirmation par e-mail est activée sur ce projet Supabase (voir la doc
/// de classe de `AuthRepository.signUp`), donc `onAuthStateChange` ne se
/// déclenchera qu'une fois le lien reçu par e-mail suivi — jusque-là, cet
/// écran doit afficher explicitement un état "vérifie ta boîte mail"
/// ([_signUpConfirmationEmail]) plutôt que de rester silencieux en
/// attendant une redirection qui n'arrivera pas tout de suite.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pseudoController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _isSubmitting = false;

  /// Distinct de [_isSubmitting] : connexion/inscription par e-mail et
  /// connexion Google sont deux actions concurrentes possibles sur le même
  /// écran — voir [_AuthCard], qui désactive tous les éléments interactifs
  /// de la carte dès que l'une des deux est active, mais n'affiche
  /// l'indicateur de chargement que sur le bouton réellement déclenché.
  bool _isGoogleSubmitting = false;

  /// Même rôle que [_isGoogleSubmitting], pour la connexion Apple (voir
  /// [_AuthCard], qui désactive les mêmes éléments interactifs qu'avec
  /// Google dès que l'une des trois soumissions concurrentes — e-mail/mot de
  /// passe, Google, Apple — est active).
  bool _isAppleSubmitting = false;
  String? _errorMessage;

  /// Non-null une fois qu'une inscription a réussi mais nécessite une
  /// confirmation par e-mail (voir la doc de classe) : porte l'adresse
  /// saisie pour l'afficher dans le message, et fait basculer [_AuthCard]
  /// sur son état "vérifie ta boîte mail" à la place du formulaire.
  String? _signUpConfirmationEmail;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pseudoController.dispose();
    super.dispose();
  }

  Future<void> _openForgotPasswordDialog() {
    return showForgotPasswordDialog(
      context,
      ref: ref,
      initialEmail: _emailController.text.trim(),
    );
  }

  void _switchMode() {
    setState(() {
      _mode = _isSignUp ? _AuthMode.login : _AuthMode.signUp;
      _errorMessage = null;
      _signUpConfirmationEmail = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      // Réinitialise l'état de validation du formulaire (champs "touchés")
      // en plus de vider les contrôleurs : sans ça, `AutovalidateMode
      // .onUserInteraction` réaffiche instantanément une erreur sur un champ
      // vidé programmatiquement, alors que l'utilisateur n'a encore rien
      // saisi dans le nouveau mode.
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    // Validation locale d'abord : en cas de champ vide/mal formé, on ne
    // contacte jamais Supabase (voir tests de widget associés).
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUp) {
        final needsEmailConfirmation = await repository.signUp(
          email: email,
          password: password,
          displayName: _pseudoController.text,
        );
        if (!mounted) return;
        if (needsEmailConfirmation) {
          setState(() => _signUpConfirmationEmail = email);
        }
        // Sinon (compte immédiatement actif) : rien à faire ici,
        // `onAuthStateChange` a déjà créé une session, le routeur
        // redirigera (voir doc de classe).
      } else {
        await repository.signInWithPassword(email: email, password: password);
      }
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = _resolveAuthFailureMessage(l10n, failure));
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = l10n.authErrorUnexpected);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Connexion Google (`AuthRepository.signInWithGoogle`) — voir sa doc de
  /// classe pour le flux complet (navigateur système puis retour dans l'app
  /// via `nexusjdr://login-callback/`, redirection pilotée par
  /// `onAuthStateChange` une fois revenu). Aucune validation de formulaire
  /// ici : ce flux ne dépend d'aucun champ de la carte.
  Future<void> _submitGoogle() async {
    setState(() {
      _isGoogleSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = _resolveAuthFailureMessage(l10n, failure));
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = l10n.authErrorUnexpected);
    } finally {
      if (mounted) {
        setState(() => _isGoogleSubmitting = false);
      }
    }
  }

  /// Connexion Apple (`AuthRepository.signInWithApple`) — voir sa doc de
  /// classe pour le flux complet (feuille système native, pas de
  /// navigateur/redirection contrairement à [_submitGoogle]) et pour la
  /// dépendance bloquante (compte Apple Developer Program à créer) qui
  /// empêche ce flux de fonctionner en conditions réelles pour l'instant.
  /// Même structure que [_submitGoogle] : aucune validation de formulaire,
  /// une annulation volontaire du joueur ne lève aucune exception (voir la
  /// doc de `AuthRepository.signInWithApple`) donc ne déclenche jamais
  /// [_errorMessage] ici.
  Future<void> _submitApple() async {
    setState(() {
      _isAppleSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithApple();
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = _resolveAuthFailureMessage(l10n, failure));
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() => _errorMessage = l10n.authErrorUnexpected);
    } finally {
      if (mounted) {
        setState(() => _isAppleSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAppleButton = ref.watch(appleSignInSupportedProvider);
    final l10n = AppLocalizations.of(context)!;

    return SceneScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  const AppBrandBadge(size: 72),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.authLoginBrandTitle,
                    style: AppTypography.display(
                      fontSize: 15,
                      color: AppColors.textOnWood,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.authLoginTagline,
                    style: AppTypography.body(color: AppColors.textOnWoodMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AuthCard(
                    l10n: l10n,
                    formKey: _formKey,
                    isSignUp: _isSignUp,
                    isSubmitting: _isSubmitting,
                    isGoogleSubmitting: _isGoogleSubmitting,
                    isAppleSubmitting: _isAppleSubmitting,
                    showAppleButton: showAppleButton,
                    errorMessage: _errorMessage,
                    signUpConfirmationEmail: _signUpConfirmationEmail,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    pseudoController: _pseudoController,
                    onSubmit: _submit,
                    onSubmitGoogle: _submitGoogle,
                    onSubmitApple: _submitApple,
                    onSwitchMode: _switchMode,
                    onForgotPassword: _openForgotPasswordDialog,
                    onBackToLogin: _switchMode,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.authLoginSharedAccountNotice,
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textOnWoodMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte "parchemin" contenant le formulaire (extraite en widget séparé pour
/// garder `_LoginScreenState.build` lisible ; reste privée au fichier, ce
/// composant n'a pas vocation à être réutilisé ailleurs contrairement à
/// [PrimaryButton]/[SceneScaffold]).
class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.l10n,
    required this.formKey,
    required this.isSignUp,
    required this.isSubmitting,
    required this.isGoogleSubmitting,
    required this.isAppleSubmitting,
    required this.showAppleButton,
    required this.errorMessage,
    required this.signUpConfirmationEmail,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.pseudoController,
    required this.onSubmit,
    required this.onSubmitGoogle,
    required this.onSubmitApple,
    required this.onSwitchMode,
    required this.onForgotPassword,
    required this.onBackToLogin,
  });

  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final bool isSignUp;
  final bool isSubmitting;

  /// Voir la doc de `_LoginScreenState._isGoogleSubmitting`.
  final bool isGoogleSubmitting;

  /// Voir la doc de `_LoginScreenState._isAppleSubmitting`.
  final bool isAppleSubmitting;

  /// Voir la doc de `appleSignInSupportedProvider`
  /// (`presentation/providers/auth_providers.dart`) — `true` sur iOS/macOS
  /// uniquement.
  final bool showAppleButton;
  final String? errorMessage;

  /// Non-null : remplace le formulaire par l'état "vérifie ta boîte mail"
  /// (voir la doc de classe de `_LoginScreenState._signUpConfirmationEmail`).
  final String? signUpConfirmationEmail;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  /// Pseudo optionnel (mode inscription uniquement) — voir
  /// `AuthRepository.signUp`.
  final TextEditingController pseudoController;
  final VoidCallback onSubmit;
  final VoidCallback onSubmitGoogle;
  final VoidCallback onSubmitApple;
  final VoidCallback onSwitchMode;
  final VoidCallback onForgotPassword;
  final VoidCallback onBackToLogin;

  /// Petits "clous" décoratifs aux 4 coins de la carte (voir maquette
  /// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Écran de
  /// connexion") — absents du design system écrit à ce jour, ajoutés ici en
  /// suivant fidèlement la maquette plutôt qu'extraits en composant partagé
  /// tant qu'on n'a pas confirmé ce motif sur d'autres écrans "parchemin".
  static const _rivetInset = 10.0;

  Widget _rivet() => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      color: AppColors.woodDark,
      shape: BoxShape.circle,
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Trois actions concurrentes possibles sur cette carte (voir la doc de
    // `_LoginScreenState._isGoogleSubmitting`/`_isAppleSubmitting`) : tant
    // que l'une des trois est active, tous les éléments interactifs de la
    // carte sont désactivés — seul le bouton réellement déclenché affiche
    // son propre indicateur de chargement (`isSubmitting`/
    // `isGoogleSubmitting`/`isAppleSubmitting` restent distincts pour ça).
    final isBusy = isSubmitting || isGoogleSubmitting || isAppleSubmitting;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodMedium,
              width: AppBorders.cardEmphasis,
            ),
            // Halo net (pas de flou) autour de la bordure, conformément au
            // token `border.card-emphasis` de la section 3 du design system :
            // un `BoxShadow` sans `blurRadius` et avec `spreadRadius` égal à
            // l'épaisseur voulue dessine un contour net plutôt qu'une ombre.
            boxShadow: const [
              BoxShadow(
                color: AppColors.woodDark,
                blurRadius: 0,
                spreadRadius: AppBorders.cardEmphasisHalo,
              ),
            ],
          ),
          child: signUpConfirmationEmail != null
              ? _SignUpConfirmationView(
                  l10n: l10n,
                  email: signUpConfirmationEmail!,
                  onBackToLogin: onBackToLogin,
                )
              : Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isSignUp
                            ? l10n.authLoginCardTitleSignUp
                            : l10n.authLoginCardTitleLogin,
                        textAlign: TextAlign.center,
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FieldLabel(l10n.authLoginEmailLabel),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: emailController,
                        enabled: !isBusy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: l10n.authLoginEmailHint,
                        ),
                        validator: (value) => AuthValidators.email(value, l10n),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FieldLabel(l10n.authLoginPasswordLabel),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: passwordController,
                        enabled: !isBusy,
                        obscureText: true,
                        textInputAction: isSignUp
                            ? TextInputAction.next
                            : TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: l10n.authLoginPasswordHint,
                        ),
                        validator: (value) =>
                            AuthValidators.password(value, l10n),
                        onFieldSubmitted: isSignUp ? null : (_) => onSubmit(),
                      ),
                      if (!isSignUp) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: isBusy ? null : onForgotPassword,
                            child: Padding(
                              // Élargit la zone de tap à au moins 44x44px (section 7
                              // "Accessibilité" du design system) sans agrandir le
                              // texte lui-même, même principe que le lien
                              // "Créer un compte"/"Se connecter" ci-dessous.
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 14,
                              ),
                              child: Text(
                                l10n.authLoginForgotPasswordLink,
                                style: AppTypography.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldEnd,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (isSignUp) ...[
                        const SizedBox(height: AppSpacing.md),
                        _FieldLabel(l10n.authLoginConfirmPasswordLabel),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: confirmPasswordController,
                          enabled: !isBusy,
                          obscureText: true,
                          // `.next` (plus `.done`) : ce champ n'est plus le
                          // dernier du formulaire en mode inscription depuis
                          // l'ajout du champ "Pseudo" ci-dessous.
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: l10n.authLoginPasswordHint,
                          ),
                          validator: (value) =>
                              AuthValidators.passwordConfirmation(
                                value,
                                passwordController.text,
                                l10n,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FieldLabel(l10n.authLoginPseudoLabel),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: pseudoController,
                          enabled: !isBusy,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: l10n.authLoginPseudoHint,
                          ),
                          onFieldSubmitted: (_) => onSubmit(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.authLoginPseudoHelper,
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: isSignUp
                            ? l10n.authLoginSubmitSignUp
                            : l10n.authLoginSubmitLogin,
                        isLoading: isSubmitting,
                        onPressed: isBusy ? null : onSubmit,
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          errorMessage!,
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.accentBrick,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              thickness: 1,
                              color: AppColors.woodLight,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.authLoginOrDivider,
                            style: AppTypography.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: Divider(
                              thickness: 1,
                              color: AppColors.woodLight,
                            ),
                          ),
                        ],
                      ),
                      if (showAppleButton) ...[
                        const SizedBox(height: AppSpacing.md),
                        SocialAuthButton(
                          label: l10n.authLoginContinueWithApple,
                          icon: const AppleLogo(),
                          isLoading: isAppleSubmitting,
                          onPressed: isBusy ? null : onSubmitApple,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      SocialAuthButton(
                        label: l10n.authLoginContinueWithGoogle,
                        icon: const GoogleGLogo(),
                        isLoading: isGoogleSubmitting,
                        onPressed: isBusy ? null : onSubmitGoogle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          // Centre verticalement le lien (dont la zone de tap est
                          // agrandie ci-dessous) par rapport au texte simple voisin,
                          // pour que la ligne reste visuellement cohérente malgré la
                          // différence de hauteur entre les deux éléments.
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isSignUp
                                  ? l10n.authLoginSwitchModePromptLogin
                                  : l10n.authLoginSwitchModePromptSignUp,
                              style: AppTypography.body(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: isBusy ? null : onSwitchMode,
                              child: Padding(
                                // Élargit la zone de tap à au moins 44x44px (section 7
                                // "Accessibilité" du design system) sans agrandir le
                                // texte lui-même.
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 14,
                                ),
                                child: Text(
                                  isSignUp
                                      ? l10n.authLoginSwitchModeActionLogin
                                      : l10n.authLoginSwitchModeActionSignUp,
                                  style: AppTypography.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.goldEnd,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Positioned(top: _rivetInset, left: _rivetInset, child: _rivet()),
        Positioned(top: _rivetInset, right: _rivetInset, child: _rivet()),
        Positioned(bottom: _rivetInset, left: _rivetInset, child: _rivet()),
        Positioned(bottom: _rivetInset, right: _rivetInset, child: _rivet()),
      ],
    );
  }
}

/// État affiché à la place du formulaire une fois qu'une inscription a
/// réussi mais nécessite une confirmation par e-mail (voir la doc de classe
/// de [LoginScreen]) — message équivalent à celui de l'app web "Histoires"
/// (`apps/web/app/(auth)/register/register-form.tsx`) : "Un email de
/// confirmation vient de t'être envoyé...".
class _SignUpConfirmationView extends StatelessWidget {
  const _SignUpConfirmationView({
    required this.l10n,
    required this.email,
    required this.onBackToLogin,
  });

  final AppLocalizations l10n;
  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.authLoginSignUpConfirmationTitle,
          textAlign: TextAlign.center,
          style: AppTypography.display(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.authLoginSignUpConfirmationBody(email),
          textAlign: TextAlign.center,
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: l10n.authLoginBackToLogin,
          onPressed: onBackToLogin,
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}
