import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/settings_list_card.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';

/// Écran "Questions fréquentes", route `/profile/help/faq` — poussé depuis
/// `ProfileHelpScreen`, soit par "Voir toutes les questions" (sans
/// pré-ouverture), soit par une des 3 tuiles question déjà affichées sur
/// `ProfileHelpScreen` ("Comment importer...", "Comment rejoindre...",
/// "Mes personnages sont-ils...") — ces 3 dernières pré-ouvrent leur
/// question respective ([initialQuestionId], 1/2/3 dans [_faqItems]) via le
/// paramètre de requête `?question=N`, résolu par `core/router/app_router.dart`
/// — même convention que `?level=N`/`?code=...` déjà en place dans ce
/// dépôt (jamais d'`extra`, ce contenu reste simple/inspectable, voir la
/// doc de `app_router.dart`).
///
/// Même gabarit exact que `ProfilePrivacyScreen`/`ProfileHelpScreen`
/// (`WoodBackHeader` + corps parchemin scrollable), mais un seul
/// `SettingsListCard` regroupant les 6 questions/réponses de [_faqItems] —
/// spec direction-artistique de la tâche : "Accordéon FAQ", un seul
/// [_FaqAccordionTile] par question, plusieurs pouvant être ouvertes
/// simultanément (état indépendant par tuile, voir sa doc de classe).
///
/// Contenu final rédigé et validé par le chef de projet, texte affiché
/// verbatim (jamais reformulé) — voir [_faqItems].
///
/// Lecture 100% synchrone à l'ouverture (texte statique, aucun appel
/// réseau).
class ProfileFaqScreen extends StatelessWidget {
  const ProfileFaqScreen({this.initialQuestionId, super.key});

  /// Identifiant (1-indexé, voir [_faqItems]) de la question à pré-ouvrir,
  /// `null` si aucune (cas "Voir toutes les questions").
  final int? initialQuestionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(
            title: l10n.profileFaqScreenTitle,
            onBack: () => _goBack(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsListCard(
                    children: [
                      for (final item in _faqItems(l10n))
                        _FaqAccordionTile(
                          key: ValueKey(item.id),
                          icon: item.icon,
                          question: item.question,
                          answer: item.answer,
                          initiallyExpanded: item.id == initialQuestionId,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Même garde que `ProfilePrivacyScreen._goBack`/`ProfileHelpScreen._goBack`
  /// : cet écran est normalement toujours atteint via
  /// `context.push('/profile/help/faq...')` (donc `canPop()` vrai), mais
  /// reste défensif si jamais poussé un jour comme route initiale (deep
  /// link).
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }
}

/// Une question/réponse de la FAQ — [id] 1-indexé, sert de contrat stable
/// pour `?question=N` (`app_router.dart`) et pour les 3 tuiles de
/// `ProfileHelpScreen` qui pré-ouvrent respectivement les questions 1/2/3.
/// Ne jamais réordonner [_faqItems] sans mettre à jour ces appelants.
class _FaqItem {
  const _FaqItem({
    required this.id,
    required this.icon,
    required this.question,
    required this.answer,
  });

  final int id;
  final IconData icon;
  final String question;
  final String answer;
}

/// Les 6 questions/réponses de l'écran, dans l'ordre d'affichage — contenu
/// final rédigé et validé par le chef de projet, texte affiché verbatim.
/// Icônes des 3 premières identiques à celles déjà utilisées sur leur tuile
/// de `ProfileHelpScreen` (voir sa doc de classe) ; les 3 suivantes
/// choisies dans le même esprit (icône `_outlined`, cohérente avec le reste
/// du design système).
///
/// Fonction plutôt qu'une constante (depuis la migration `.arb`, chantier
/// "traduction de l'app" Phase B) : le texte dépend désormais de
/// [AppLocalizations], qui n'est disponible qu'avec un `BuildContext`.
List<_FaqItem> _faqItems(AppLocalizations l10n) => [
  _FaqItem(
    id: 1,
    icon: Icons.file_upload_outlined,
    question: l10n.profileFaqQuestion1,
    answer: l10n.profileFaqAnswer1,
  ),
  _FaqItem(
    id: 2,
    icon: Icons.group_add_outlined,
    question: l10n.profileFaqQuestion2,
    answer: l10n.profileFaqAnswer2,
  ),
  _FaqItem(
    id: 3,
    icon: Icons.cloud_off_outlined,
    question: l10n.profileFaqQuestion3,
    answer: l10n.profileFaqAnswer3,
  ),
  _FaqItem(
    id: 4,
    icon: Icons.trending_up,
    question: l10n.profileFaqQuestion4,
    answer: l10n.profileFaqAnswer4,
  ),
  _FaqItem(
    id: 5,
    icon: Icons.photo_camera_outlined,
    question: l10n.profileFaqQuestion5,
    answer: l10n.profileFaqAnswer5,
  ),
  _FaqItem(
    id: 6,
    icon: Icons.delete_outline,
    question: l10n.profileFaqQuestion6,
    answer: l10n.profileFaqAnswer6,
  ),
];

/// Tuile "accordéon" d'une question/réponse — ligne fermée aux mêmes
/// métriques que `core/widgets/menu_tile.dart::MenuTile` (padding
/// `AppSpacing.md`, icône 22px `textSecondary`, libellé `font.body`
/// 14px/700 `textPrimary`), mais chevron remplacé par
/// `Icons.expand_more`/`Icons.expand_less` (20px `textMuted`) selon l'état
/// — pas une extraction de `MenuTile` car son contrat (`onTap` + chevron
/// fixe) ne porte pas d'état d'expansion ni de contenu déplié, jamais
/// réutilisée ailleurs qu'ici (widget privé à ce fichier, spec
/// direction-artistique de la tâche).
///
/// Plusieurs tuiles peuvent être ouvertes simultanément : chaque instance
/// possède son propre état d'expansion (`_expanded`), aucun état partagé
/// entre elles au niveau de l'écran.
///
/// [initiallyExpanded] pré-ouvre la tuile visée par `?question=N`
/// (`ProfileFaqScreen.initialQuestionId`) : elle démarre dépliée et reçoit
/// en plus une bordure `AppColors.accentBrick` ([AppBorders.card], même
/// épaisseur que `core/widgets/destructive_menu_tile.dart` pour ce même
/// accent) tant qu'elle reste ouverte. Dès que le joueur la referme (tap),
/// [_highlighted] passe définitivement à `false` : la bordure disparaît et
/// ne revient jamais, même si la tuile est rouverte ensuite — "se referme
/// normalement au tap comme les autres, pas de traitement spécial
/// au-delà" (spec direction-artistique de la tâche).
class _FaqAccordionTile extends StatefulWidget {
  const _FaqAccordionTile({
    required this.icon,
    required this.question,
    required this.answer,
    this.initiallyExpanded = false,
    super.key,
  });

  final IconData icon;
  final String question;
  final String answer;
  final bool initiallyExpanded;

  @override
  State<_FaqAccordionTile> createState() => _FaqAccordionTileState();
}

class _FaqAccordionTileState extends State<_FaqAccordionTile> {
  late bool _expanded;
  late bool _highlighted;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _highlighted = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) _highlighted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(widget.icon, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.question,
                      style: AppTypography.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              widget.answer,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );

    if (!(_expanded && _highlighted)) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.accentBrick,
          width: AppBorders.card,
        ),
      ),
      child: content,
    );
  }
}
