import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'sheet_action_row.dart';

/// "Liste de réglages" du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4) : "Groupe de
/// lignes dans une même carte `parchment.card` (bordure 2px `wood.light`,
/// séparateurs 1px `#E0D2AB` entre lignes) : icône à gauche, libellé,
/// chevron à droite. Dernière ligne sans séparateur."
///
/// Introduit pour le recettage direction-artistique du 13/09/2026 (Hub
/// profil, Notifications, Confidentialité) : jusque-là chaque tuile de
/// réglage (`MenuTile`) était sa propre carte bordée indépendante, espacée
/// verticalement — non conforme à cette section du design système.
///
/// [children] sont typiquement des [MenuTile] construits avec
/// `standalone: false` (voir sa doc de classe : ce composant porte déjà la
/// carte englobante, `MenuTile` ne doit pas dupliquer sa propre bordure/fond
/// par-dessus), mais n'importe quel widget convient — ce composant ne fait
/// qu'empiler ses enfants et les séparer d'un [SheetActionDivider], jamais
/// de logique propre aux tuiles.
///
/// Réutilise [SheetActionDivider] (même séparateur 1px `#E0D2AB` que les
/// bottom sheets d'actions) plutôt que de redéfinir un `Divider` local : même
/// token de couleur, pas de raison de le dupliquer une 3e fois.
class SettingsListCard extends StatelessWidget {
  const SettingsListCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      // `ClipRRect` : sans lui, le rectangle de tap/ripple de chaque ligne
      // (voir `MenuTile.standalone == false`) déborderait des coins arrondis
      // de la carte englobante sur la première/dernière ligne.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SheetActionDivider(),
            ],
          ],
        ),
      ),
    );
  }
}
