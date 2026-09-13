import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// "Avatar de profil" du design système (section 4) : cercle bordure 3px
/// `gold-end` + halo 1px `wood.dark` (même technique de halo que
/// `PortraitFrame` : `boxShadow` non flouté, `spreadRadius` égal à
/// `AppBorders.cardEmphasisHalo`) — conservés dans tous les cas, avec ou
/// sans photo (spec direction-artistique du flux "Modifier le profil").
/// Sans [avatarUrl] : fond `wood.light` + silhouette `Icons.person`
/// (comportement historique, inchangé). Avec [avatarUrl] : `ClipOval` +
/// `Image.network` (`BoxFit.cover`) remplit le cercle — jamais le
/// traitement "cadre bois sculpté" du portrait de personnage (bordure
/// `wood.light`, coins `radius.md`), qui reste distinct.
///
/// Non interactif ici (pas d'`InkWell`) : le flux d'upload/retrait reste à
/// la charge de l'appelant (badge caméra + liens dédiés sur
/// `ProfileEditScreen`, rien de tel sur `ProfileScreen`).
///
/// Composant partagé (`core/widgets/`), extrait de
/// `features/profile/presentation/profile_screen.dart::_ProfileAvatar` (2e
/// usage identique — [size] paramétrable — sur
/// `features/profile/presentation/profile_edit_screen.dart`, recettage
/// direction-artistique du 13/09/2026 "Profil — Modifier le profil") :
/// même seuil d'extraction que `MenuTile`/`SheetActionRow` (dupliquer
/// jusqu'à 2 usages, extraire au 2e quand il s'agit du même composant à
/// l'identique plutôt que d'une simple ressemblance visuelle).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.avatarUrl, this.size = 76, super.key});

  final String? avatarUrl;

  /// Diamètre du cercle — 76px par défaut (comportement historique de
  /// `ProfileScreen`), 88px sur `ProfileEditScreen` (spec direction-
  /// artistique). La silhouette de repli est mise à l'échelle avec (même
  /// ratio que l'original 40/76), pour ne pas avoir à retoucher ce fichier
  /// à chaque nouvelle taille d'usage.
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final iconSize = size * 40 / 76;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.woodLight,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.goldEnd, width: AppBorders.cardEmphasis),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark,
            blurRadius: 0,
            spreadRadius: AppBorders.cardEmphasisHalo,
          ),
        ],
      ),
      child: url == null || url.isEmpty
          ? Icon(Icons.person, size: iconSize, color: AppColors.textOnWood)
          : ClipOval(
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Même repli que `PortraitFrame` : ne jamais laisser un
                // espace vide/une icône d'erreur brute si le chargement
                // réseau échoue (avatar pas encore retéléchargé, URL
                // périmée...), retombe silencieusement sur la silhouette par
                // défaut.
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  size: iconSize,
                  color: AppColors.textOnWood,
                ),
              ),
            ),
    );
  }
}
