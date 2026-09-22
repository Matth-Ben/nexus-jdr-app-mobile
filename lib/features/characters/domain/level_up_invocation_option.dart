import 'invocation_prerequisites.dart';
import 'warlock_pact.dart';

/// Résultat de [LevelUpInvocationOption.eligibilityFor] : [reasons] vide =
/// éligible, sinon une raison lisible en français par prérequis non satisfait
/// ("Niveau 12 requis", "Pacte de la lame requis", "Sort mineur Décharge
/// occulte requis").
class InvocationEligibility {
  const InvocationEligibility({required this.reasons});

  final List<String> reasons;

  bool get isEligible => reasons.isEmpty;

  /// Raisons jointes pour l'affichage, `null` si éligible.
  String? get reasonLabel => isEligible ? null : reasons.join(' · ');
}

/// Une invocation occultiste disponible au choix à l'étape "Invocations" de
/// la montée de niveau (`presentation/level_up_screen.dart`, spec visuelle
/// direction-artistique section 3) — nom/description/prérequis déjà résolus
/// via `translations` (`entity_type = 'invocation'`) et
/// `invocations.prerequisites->>'text'`, voir
/// `data/level_up_invocation_row_mapper.dart`.
///
/// Ne liste que les invocations NON déjà connues du personnage
/// (`character_invocations`) — voir
/// `data/character_repository.dart::fetchAvailableInvocations`.
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [LevelUpFeatOption], donnée en lecture seule construite une fois par le
/// repository.
class LevelUpInvocationOption {
  const LevelUpInvocationOption({
    required this.id,
    required this.name,
    required this.description,
    this.prerequisiteText,
    this.prerequisites = InvocationPrerequisites.none,
    this.cantripName,
  });

  /// Prérequis structurés (niveau, pacte, sort mineur) — voir
  /// [InvocationPrerequisites]. [InvocationPrerequisites.none] si la ligne
  /// n'en porte aucun (ou pas encore de clés structurées).
  final InvocationPrerequisites prerequisites;

  /// Nom (traduit) du sort mineur requis par
  /// [InvocationPrerequisites.cantripSpellId], pour formuler la raison
  /// d'inéligibilité ; `null` si non résolu.
  final String? cantripName;

  /// Éligibilité de cette invocation pour l'état donné — voir
  /// [InvocationPrerequisites.unmet] pour la signification des paramètres.
  InvocationEligibility eligibilityFor({
    required int warlockLevel,
    required WarlockPact? knownPact,
    required Set<int> knownCantripSpellIds,
  }) {
    final failures = prerequisites.unmet(
      warlockLevel: warlockLevel,
      knownPact: knownPact,
      knownCantripSpellIds: knownCantripSpellIds,
    );
    return InvocationEligibility(
      reasons: [
        for (final failure in failures)
          switch (failure) {
            InvocationPrerequisiteFailure.level =>
              'Niveau ${prerequisites.level} requis',
            InvocationPrerequisiteFailure.pact =>
              '${prerequisites.pact!.label} requis',
            InvocationPrerequisiteFailure.cantrip =>
              cantripName == null
                  ? 'Sort mineur requis'
                  : 'Sort mineur $cantripName requis',
          },
      ],
    );
  }

  /// `invocations.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpFeatOption.id`).
  final Object id;

  final String name;

  /// `invocations.prerequisites->>'text'`, `null` si aucun prérequis
  /// textuel renseigné en base — affiché en `subtitle` de la
  /// `CheckableOptionTile` de l'étape "Invocations".
  final String? prerequisiteText;

  /// Description complète de l'invocation — pas encore consultable ailleurs
  /// dans l'app (aucun onglet "Invocations" de la fiche à ce chantier),
  /// affichée directement en `subtitle` étendu ou dans un futur panneau
  /// "Infos" si le besoin apparaît (hors périmètre de la spec visuelle
  /// actuelle, qui ne demande pas de panneau "Infos" pour les invocations —
  /// contrairement aux dons, voir [LevelUpFeatOption.description]). Gardée
  /// ici pour ne pas avoir à re-résoudre cette traduction plus tard.
  final String description;
}
