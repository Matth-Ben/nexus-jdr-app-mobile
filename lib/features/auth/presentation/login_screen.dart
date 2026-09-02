import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_validators.dart';
import 'providers/auth_providers.dart';
import 'widgets/forgot_password_dialog.dart';

/// Mode du formulaire : connexion ou inscription, basculés sur un même
/// écran (voir maquette `00_connexion.png`) plutôt que deux écrans séparés.
enum _AuthMode { login, signUp }

/// Écran de connexion / inscription — premier écran présenté à un
/// utilisateur non connecté (`docs/cahier-des-charges/05-ux-navigation.md`).
///
/// Après un login/signup réussi, la redirection vers `/` est gérée par le
/// routeur (`core/router/app_router.dart`), qui réagit lui-même au flux
/// `onAuthStateChange` : cet écran n'a pas besoin de naviguer explicitement.
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

  _AuthMode _mode = _AuthMode.login;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isSignUp => _mode == _AuthMode.signUp;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        await repository.signUp(email: email, password: password);
      } else {
        await repository.signInWithPassword(email: email, password: password);
      }
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() => _errorMessage = failure.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Une erreur inattendue est survenue. Réessayez.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.shield_rounded,
                    size: 56,
                    color: AppColors.goldEnd,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'NEXUS JDR',
                    style: AppTypography.display(
                      fontSize: 15,
                      color: AppColors.textOnWood,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Le registre des aventuriers',
                    style: AppTypography.body(color: AppColors.textOnWoodMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AuthCard(
                    formKey: _formKey,
                    isSignUp: _isSignUp,
                    isSubmitting: _isSubmitting,
                    errorMessage: _errorMessage,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    onSubmit: _submit,
                    onSwitchMode: _switchMode,
                    onForgotPassword: _openForgotPasswordDialog,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "Même compte que l'app Histoires",
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
    required this.formKey,
    required this.isSignUp,
    required this.isSubmitting,
    required this.errorMessage,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    required this.onSwitchMode,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final bool isSignUp;
  final bool isSubmitting;
  final String? errorMessage;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchMode;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSignUp ? 'CRÉER UN COMPTE' : 'ENTRER DANS LA TAVERNE',
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldLabel('Adresse e-mail'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'nom@exemple.com'),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldLabel('Mot de passe'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              textInputAction: isSignUp
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: const InputDecoration(hintText: '••••••••'),
              validator: AuthValidators.password,
              onFieldSubmitted: isSignUp ? null : (_) => onSubmit(),
            ),
            if (!isSignUp) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isSubmitting ? null : onForgotPassword,
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
                      'Mot de passe oublié ?',
                      style: AppTypography.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.woodDark,
                      ).copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ),
            ],
            if (isSignUp) ...[
              const SizedBox(height: AppSpacing.md),
              _FieldLabel('Confirmer le mot de passe'),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(hintText: '••••••••'),
                validator: (value) => AuthValidators.passwordConfirmation(
                  value,
                  passwordController.text,
                ),
                onFieldSubmitted: (_) => onSubmit(),
              ),
            ],
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
            PrimaryButton(
              label: isSignUp ? 'Créer le compte' : 'Entrer',
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : onSubmit,
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
                    isSignUp ? 'Déjà un compte ? ' : 'Pas encore de compte ? ',
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isSubmitting ? null : onSwitchMode,
                    child: Padding(
                      // Élargit la zone de tap à au moins 44x44px (section 7
                      // "Accessibilité" du design system) sans agrandir le
                      // texte lui-même.
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 14,
                      ),
                      child: Text(
                        isSignUp ? 'Se connecter' : 'Créer un compte',
                        style: AppTypography.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.woodDark,
                        ).copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
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
