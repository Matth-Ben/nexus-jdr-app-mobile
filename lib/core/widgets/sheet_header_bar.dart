import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Hauteur minimale de la barre : celle qu'elle avait quand elle était à
/// hauteur fixe, conservée pour tout titre qui y tient avec ses marges.
const double _minBarHeight = 56;

/// Marge verticale minimale entre le titre et les bords de la barre, quand
/// c'est le titre qui dicte la hauteur. `AppSpacing.xs` et pas plus : à
/// l'échelle de texte 1, un titre de 3 lignes (48px) tient ainsi exactement
/// dans les 56px de la barre, à la position qu'il avait à hauteur fixe.
const double _titleVerticalMargin = AppSpacing.xs;

/// Nombre de lignes du titre au-delà duquel il est tronqué par une ellipse.
const int _titleMaxLines = 3;

/// Plafond d'agrandissement du texte appliqué au seul titre : au-delà, il ne
/// reste qu'environ 8 caractères par ligne sur un écran de 360 dp, et le
/// titre devient une colonne de mots coupés. 2.0 couvre le redimensionnement
/// du texte à 200 %.
const double _titleMaxTextScale = 2;

/// Côté de la zone de tap du bouton de fermeture.
const double _closeButtonSize = 44;

/// Barre de tête de bottom sheet (fond `wood.medium`, hauteur minimale 56px,
/// titre `font.display` majuscules, icône fermeture zone de tap 44×44) —
/// composant partagé (`core/widgets/`), extrait de
/// `features/xml_import/presentation/xml_import_review_screen.dart`
/// (`_SheetHeaderBar`, gabarit B "mode liste"/"pleine page" du design
/// système) : 3e usage identique (panneaux "Infos" sort/aptitude de la fiche
/// personnage), factorisé ici plutôt que dupliqué une 3e fois.
///
/// La barre n'a pas de hauteur fixe : elle grandit avec le titre (titre long,
/// ou texte agrandi dans les réglages du téléphone) au lieu de le rogner. À
/// l'échelle de texte 1, elle reste à 56px jusqu'à 3 lignes de titre. Le
/// titre est centré verticalement, limité à [_titleMaxLines] lignes puis
/// tronqué par une ellipse — un lecteur d'écran annonce quand même le titre
/// complet. Le bouton de fermeture reste ancré en haut, à la position qu'il
/// occupe dans une barre de 56px : il ne se recentre pas quand elle grandit.
class SheetHeaderBar extends StatelessWidget {
  const SheetHeaderBar({
    required this.title,
    this.closeEnabled = true,
    super.key,
  });

  final String title;

  /// Désactive le bouton de fermeture (X) sans rien changer visuellement au
  /// reste de la barre — ajouté pour l'éditeur "Histoire" de la fiche
  /// personnage (`presentation/widgets/character_story_edit_sheet.dart`),
  /// qui doit empêcher un tap sur le X d'interrompre un `await` de
  /// sauvegarde en cours (la sheet reste ouverte le temps de l'appel
  /// réseau, voir sa documentation de classe). `true` par défaut :
  /// rétrocompatible avec les usages existants, qui ne passent jamais ce
  /// paramètre.
  final bool closeEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.woodMedium,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            // `heightFactor: 1` : l'`Align` prend la hauteur du titre et de
            // ses marges — jamais celle qu'offre le parent de la barre —,
            // relevée à la hauteur minimale de la barre par le
            // `ConstrainedBox`, et y centre le titre verticalement.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minBarHeight),
              child: Align(
                alignment: Alignment.centerLeft,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: _titleVerticalMargin,
                  ),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: _titleMaxTextScale,
                    // Toute la largeur disponible, comme sous l'`Expanded`
                    // d'origine : l'`Align` ne l'impose plus au titre.
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        title,
                        maxLines: _titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textOnWood,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: (_minBarHeight - _closeButtonSize) / 2,
            ),
            child: SizedBox(
              width: _closeButtonSize,
              height: _closeButtonSize,
              child: IconButton(
                onPressed: closeEnabled
                    ? () => Navigator.of(context).pop()
                    : null,
                icon: const Icon(Icons.close, color: AppColors.textOnWood),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
