import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_brand_badge.dart';
import '../../../core/widgets/dashed_border_painter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/scene_scaffold.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Carousel de bienvenue/onboarding (5 pages), montré après connexion — pour
/// les comptes nouveaux ET existants — avant d'atterrir sur la liste des
/// personnages. Spec visuelle validée par `direction-artistique` et le chef
/// de projet (pas de maquette dédiée dans
/// `docs/cahier-des-charges/09-maquettes-captures.md` à ce jour).
///
/// Deux points d'entrée (voir `core/router/app_router.dart::computeAuthRedirect`) :
/// - **Forcé par le routeur** à la première connexion qui suit l'introduction
///   de cette fonctionnalité (`needsOnboarding`, dérivé de
///   `user_metadata['onboarding_completed'] != true`) — cet écran est alors
///   la route initiale, jamais "poppable" (`context.canPop()` vaut `false`).
/// - **Ouvert volontairement** depuis "Profil > Aide et support > Revoir la
///   présentation de l'app" (`ProfileHelpScreen`, `context.push('/onboarding')`)
///   — poussé par-dessus la pile, donc "poppable".
///
/// [_finishOnboarding] gère les deux cas avec le même patron défensif déjà
/// utilisé ailleurs dans ce dépôt (`profile_help_screen.dart::_goBack`,
/// `profile_screen.dart::_goBack`) : `canPop()` vrai → `pop()` (retour au
/// profil) ; `canPop()` faux → `go('/')` (atterrit sur la liste des
/// personnages, seule destination possible pour une route initiale forcée).
///
/// [AuthRepository.markOnboardingSeen] est appelée systématiquement en
/// sortie (bouton "Passer", n'importe quelle page, OU CTA final "C'est
/// parti !" de la page 5) : idempotente, elle ne redéclenche jamais de
/// réévaluation du redirect du routeur (pas de changement de session, voir
/// sa doc) — c'est pourquoi cet écran navigue lui-même plutôt que de compter
/// sur `GoRouter.refreshListenable`. Un échec réseau de cet appel est avalé
/// silencieusement (best-effort, voir [_finishOnboarding]) : il ne doit
/// jamais empêcher la sortie de l'écran, l'onboarding se rattrapera (routeur
/// toujours `needsOnboarding: true`) à la prochaine connexion.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();

  /// 0-indexé (contrairement à [StepProgressBar.currentStep]/au texte "n /
  /// 5" du bandeau haut, 1-indexés) — converti au point d'affichage.
  int _currentPageIndex = 0;

  static const Duration _pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve _pageTransitionCurve = Curves.easeInOut;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    setState(() => _currentPageIndex = index);
  }

  /// Boutons "Retour"/"Suivant" : même transition que le swipe (voir la doc
  /// de classe), `animateToPage` redéclenche [_handlePageChanged] via
  /// `PageView.onPageChanged` — pas de double mise à jour d'état ici.
  void _animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: _pageTransitionDuration,
      curve: _pageTransitionCurve,
    );
  }

  /// Action de sortie partagée par "Passer" (n'importe quelle page) et
  /// "C'est parti !" (page 5) — voir la doc de classe.
  Future<void> _finishOnboarding() async {
    try {
      await ref.read(authRepositoryProvider).markOnboardingSeen();
    } catch (_) {
      // Best-effort : voir la doc de classe, un échec réseau ne doit jamais
      // bloquer la sortie de l'écran.
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFirstPage = _currentPageIndex == 0;
    final isLastPage = _currentPageIndex == _onboardingPages.length - 1;

    return SceneScaffold(
      body: Column(
        children: [
          _TopBanner(
            currentStep: _currentPageIndex + 1,
            totalSteps: _onboardingPages.length,
            onSkip: _finishOnboarding,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _handlePageChanged,
              children: [
                for (final page in _onboardingPages)
                  _OnboardingPageView(page: page),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: isFirstPage
                  ? PrimaryButton(
                      label: 'Suivant',
                      onPressed: () => _animateToPage(_currentPageIndex + 1),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            surface: SecondaryButtonSurface.scene,
                            label: 'Retour',
                            onPressed: () =>
                                _animateToPage(_currentPageIndex - 1),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: PrimaryButton(
                            label: isLastPage ? "C'est parti !" : 'Suivant',
                            onPressed: isLastPage
                                ? _finishOnboarding
                                : () => _animateToPage(_currentPageIndex + 1),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau haut persistant (visible sur les 5 pages) : lien "Passer" +
/// `StepProgressBar`/texte "n / 5" — voir la section A de la spec de la
/// tâche.
class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.currentStep,
    required this.totalSteps,
    required this.onSkip,
  });

  /// 1-indexé.
  final int currentStep;
  final int totalSteps;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSkip,
                child: Padding(
                  // Zone de tap ≥44×44px (section 7 "Accessibilité" du
                  // design system) — même recette que le lien "Mot de passe
                  // oublié ?" de `login_screen.dart`.
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 14,
                  ),
                  child: Text(
                    'Passer',
                    style: AppTypography.display(
                      fontSize: 11,
                      color: AppColors.textOnWoodMuted,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StepProgressBar(
                      totalSteps: totalSteps,
                      currentStep: currentStep,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$currentStep / $totalSteps',
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textOnWoodMuted,
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

/// Contenu d'une page du carousel : illustration (médaillon générique ou
/// [AppBrandBadge] pour la page 1, voir [_OnboardingPage.icon]), titre, texte
/// — voir la section B de la spec de la tâche.
///
/// `Center` + `SingleChildScrollView` (même patron que `login_screen.dart`) :
/// centré verticalement quand le contenu tient dans la hauteur disponible,
/// défile sans déborder sinon (ex. petit écran + texte scalé par
/// l'accessibilité).
class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            page.icon == null
                ? const AppBrandBadge(size: 96)
                : _OnboardingMedallion(
                    icon: page.icon!,
                    color: page.accentColor!,
                  ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              // `.toUpperCase()` explicite : `AppTypography.display` ne
              // transforme jamais la casse automatiquement (voir sa doc de
              // classe) — les libellés de [_onboardingPages] sont déjà
              // saisis en majuscules, mais cet appel reste la convention du
              // dépôt plutôt qu'une dépendance silencieuse à une saisie déjà
              // capitalisée.
              page.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.display(
                fontSize: 13,
                color: AppColors.textOnWood,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                page.body,
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 15,
                  color: AppColors.textOnWoodMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Médaillon générique (icône Material sur bordure pointillée circulaire) —
/// même patron que les médaillons d'état vide de `character_list_screen.dart`
/// (`_EmptyState`/`_SearchEmptyState`), repris ici plutôt qu'un nouvel asset
/// (décision assumée, voir la section "Ce que tu n'as pas à faire" de la
/// spec de la tâche).
class _OnboardingMedallion extends StatelessWidget {
  const _OnboardingMedallion({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: const DashedBorderPainter(
          color: AppColors.textOnWoodMuted,
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, size: 52, color: color)),
      ),
    );
  }
}

/// Contenu statique d'une page du carousel — voir le tableau de la section 2
/// de la spec de la tâche.
class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.icon,
    this.accentColor,
  });

  final String title;
  final String body;

  /// `null` uniquement pour la page 1 : [_OnboardingPageView] affiche alors
  /// [AppBrandBadge] à la place du médaillon générique (cohérence avec
  /// `LoginScreen`, voir la doc de classe de [OnboardingScreen]).
  final IconData? icon;

  /// Couleur de l'icône du médaillon — non-null dès que [icon] est non-null
  /// (jamais utilisé pour la page 1).
  final Color? accentColor;
}

/// Les 5 pages du carousel, dans l'ordre d'affichage — voir le tableau de la
/// section 2 de la spec de la tâche.
const List<_OnboardingPage> _onboardingPages = [
  _OnboardingPage(
    title: 'BIENVENUE, AVENTURIER',
    body:
        "Nexus JDR t'accompagne pour créer, suivre et jouer tes personnages "
        'D&D, à la table comme en solo. Découvrons ensemble comment ça '
        'marche.',
    icon: null,
  ),
  _OnboardingPage(
    title: 'TES PERSONNAGES',
    body:
        'Retrouve tous tes aventuriers sur un seul écran. Crée-en un nouveau '
        'pas à pas, ou importe directement une fiche depuis aidedd.org.',
    icon: Icons.shield_rounded,
    accentColor: AppColors.goldEnd,
  ),
  _OnboardingPage(
    title: 'LA FICHE DE TON PERSONNAGE',
    body:
        'Cinq onglets réunissent tout ce qu\'il te faut en jeu : ta fiche, '
        'tes aptitudes, tes sorts, ton sac... et l\'histoire que tu écris '
        'avec lui.',
    icon: Icons.auto_stories_outlined,
    accentColor: AppColors.accentBlue,
  ),
  _OnboardingPage(
    title: 'REJOINDRE UNE HISTOIRE',
    body:
        "Un MJ t'a transmis un code d'invitation ? Rejoins son groupe pour "
        'lier ton personnage à son histoire et rester synchronisé avec la '
        'table.',
    icon: Icons.group_add_outlined,
    accentColor: AppColors.accentTeal,
  ),
  _OnboardingPage(
    title: "C'EST PARTI !",
    body:
        'Tout est prêt. Entre dans la taverne et commence à écrire tes '
        'légendes.',
    icon: Icons.auto_awesome_outlined,
    accentColor: AppColors.goldEnd,
  ),
];
