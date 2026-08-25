/// Espacements et rayons de "Nexus JDR — Personnages", tokens issus de
/// `docs/cahier-des-charges/10-design-system.md` section 3.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
}

abstract final class AppRadius {
  static const double sm = 3;
  static const double md = 5;
}

/// Épaisseurs de bordure ("border.card"/"border.card-emphasis" du design
/// système). Les couleurs associées viennent de [AppColors].
abstract final class AppBorders {
  static const double card = 2;
  static const double cardEmphasis = 3;
  static const double cardEmphasisHalo = 1;
}
