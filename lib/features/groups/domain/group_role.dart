/// Rôle d'un membre au sein d'un groupe (`group_members.role`) — voir
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.1.
enum GroupRole {
  /// Créateur du groupe — seul rôle habilité à gérer le groupe (renommer,
  /// régénérer le code, dissoudre, exclure un membre), voir
  /// `presentation/widgets/group_management_sheet.dart`.
  owner,

  /// Tout autre membre — peut quitter le groupe, consulter le tableau de
  /// bord et le butin commun.
  membre,
}

/// Conversion depuis/vers la colonne texte brute `group_members.role`
/// (`'owner'`/`'membre'`) — jamais un simple `.name` (`'owner'`/`'membre'`
/// coïncident avec les valeurs enum ici, mais cette indirection documente
/// explicitement le contrat de la colonne plutôt que de s'appuyer
/// implicitement sur une coïncidence de nommage).
extension GroupRoleRaw on GroupRole {
  static GroupRole fromRaw(String? raw) =>
      raw == 'owner' ? GroupRole.owner : GroupRole.membre;

  String get raw => switch (this) {
    GroupRole.owner => 'owner',
    GroupRole.membre => 'membre',
  };
}
