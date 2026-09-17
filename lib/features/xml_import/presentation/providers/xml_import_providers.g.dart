// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xml_import_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(xmlImportRepository)
final xmlImportRepositoryProvider = XmlImportRepositoryProvider._();

final class XmlImportRepositoryProvider
    extends
        $FunctionalProvider<
          XmlImportRepository,
          XmlImportRepository,
          XmlImportRepository
        >
    with $Provider<XmlImportRepository> {
  XmlImportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'xmlImportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$xmlImportRepositoryHash();

  @$internal
  @override
  $ProviderElement<XmlImportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  XmlImportRepository create(Ref ref) {
    return xmlImportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(XmlImportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<XmlImportRepository>(value),
    );
  }
}

String _$xmlImportRepositoryHash() =>
    r'efbf7204f5e44fcb4ce57d83d0fd0edf3245d184';

/// Passerelle "Garder comme élément personnalisé" pour Race/Historique/
/// Sorts (voir la doc de classe de [XmlImportPlaceholderCatalogRepository])
/// — même patron que [xmlImportRepositoryProvider] ci-dessus.

@ProviderFor(xmlImportPlaceholderCatalogRepository)
final xmlImportPlaceholderCatalogRepositoryProvider =
    XmlImportPlaceholderCatalogRepositoryProvider._();

/// Passerelle "Garder comme élément personnalisé" pour Race/Historique/
/// Sorts (voir la doc de classe de [XmlImportPlaceholderCatalogRepository])
/// — même patron que [xmlImportRepositoryProvider] ci-dessus.

final class XmlImportPlaceholderCatalogRepositoryProvider
    extends
        $FunctionalProvider<
          XmlImportPlaceholderCatalogRepository,
          XmlImportPlaceholderCatalogRepository,
          XmlImportPlaceholderCatalogRepository
        >
    with $Provider<XmlImportPlaceholderCatalogRepository> {
  /// Passerelle "Garder comme élément personnalisé" pour Race/Historique/
  /// Sorts (voir la doc de classe de [XmlImportPlaceholderCatalogRepository])
  /// — même patron que [xmlImportRepositoryProvider] ci-dessus.
  XmlImportPlaceholderCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'xmlImportPlaceholderCatalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$xmlImportPlaceholderCatalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<XmlImportPlaceholderCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  XmlImportPlaceholderCatalogRepository create(Ref ref) {
    return xmlImportPlaceholderCatalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(XmlImportPlaceholderCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<XmlImportPlaceholderCatalogRepository>(value),
    );
  }
}

String _$xmlImportPlaceholderCatalogRepositoryHash() =>
    r'53467e5c65565a198d4c7f61d42db659f963e92f';

/// Charge, parse et résout un export XML aidedd.org [xmlSource] (contenu
/// déjà lu par le sélecteur de fichier natif, voir
/// `features/characters/presentation/character_list_screen.dart::
/// _startXmlImport`), puis porte les corrections manuelles faites par
/// l'utilisateur sur l'écran de vérification (bottom sheet de correction).
///
/// `family` par ([fileName], [xmlSource]) plutôt qu'un provider simple : un
/// écran de vérification par fichier importé, jamais partagé entre deux
/// imports différents dans la même session — `autoDispose` (comportement par
/// défaut du générateur) laisse la mémoire se libérer dès que l'écran est
/// quitté (retour arrière avant validation, ou après sauvegarde réussie).
///
/// Toutes les corrections passent par [_updateResolved] plutôt que de
/// réimplémenter la même reconstruction d'enregistrement 11 champs à chaque
/// méthode — chaque méthode publique ne fait que calculer le nouveau
/// [XmlFieldResolution] à injecter dans [XmlCharacterImportResolved.copyWith].

@ProviderFor(XmlImportReviewController)
final xmlImportReviewControllerProvider = XmlImportReviewControllerFamily._();

/// Charge, parse et résout un export XML aidedd.org [xmlSource] (contenu
/// déjà lu par le sélecteur de fichier natif, voir
/// `features/characters/presentation/character_list_screen.dart::
/// _startXmlImport`), puis porte les corrections manuelles faites par
/// l'utilisateur sur l'écran de vérification (bottom sheet de correction).
///
/// `family` par ([fileName], [xmlSource]) plutôt qu'un provider simple : un
/// écran de vérification par fichier importé, jamais partagé entre deux
/// imports différents dans la même session — `autoDispose` (comportement par
/// défaut du générateur) laisse la mémoire se libérer dès que l'écran est
/// quitté (retour arrière avant validation, ou après sauvegarde réussie).
///
/// Toutes les corrections passent par [_updateResolved] plutôt que de
/// réimplémenter la même reconstruction d'enregistrement 11 champs à chaque
/// méthode — chaque méthode publique ne fait que calculer le nouveau
/// [XmlFieldResolution] à injecter dans [XmlCharacterImportResolved.copyWith].
final class XmlImportReviewControllerProvider
    extends
        $AsyncNotifierProvider<XmlImportReviewController, XmlImportReviewData> {
  /// Charge, parse et résout un export XML aidedd.org [xmlSource] (contenu
  /// déjà lu par le sélecteur de fichier natif, voir
  /// `features/characters/presentation/character_list_screen.dart::
  /// _startXmlImport`), puis porte les corrections manuelles faites par
  /// l'utilisateur sur l'écran de vérification (bottom sheet de correction).
  ///
  /// `family` par ([fileName], [xmlSource]) plutôt qu'un provider simple : un
  /// écran de vérification par fichier importé, jamais partagé entre deux
  /// imports différents dans la même session — `autoDispose` (comportement par
  /// défaut du générateur) laisse la mémoire se libérer dès que l'écran est
  /// quitté (retour arrière avant validation, ou après sauvegarde réussie).
  ///
  /// Toutes les corrections passent par [_updateResolved] plutôt que de
  /// réimplémenter la même reconstruction d'enregistrement 11 champs à chaque
  /// méthode — chaque méthode publique ne fait que calculer le nouveau
  /// [XmlFieldResolution] à injecter dans [XmlCharacterImportResolved.copyWith].
  XmlImportReviewControllerProvider._({
    required XmlImportReviewControllerFamily super.from,
    required ({String fileName, String xmlSource}) super.argument,
  }) : super(
         retry: null,
         name: r'xmlImportReviewControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$xmlImportReviewControllerHash();

  @override
  String toString() {
    return r'xmlImportReviewControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  XmlImportReviewController create() => XmlImportReviewController();

  @override
  bool operator ==(Object other) {
    return other is XmlImportReviewControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$xmlImportReviewControllerHash() =>
    r'bb1a5870d6be44a4da1fc67cebc588202c2fc9d5';

/// Charge, parse et résout un export XML aidedd.org [xmlSource] (contenu
/// déjà lu par le sélecteur de fichier natif, voir
/// `features/characters/presentation/character_list_screen.dart::
/// _startXmlImport`), puis porte les corrections manuelles faites par
/// l'utilisateur sur l'écran de vérification (bottom sheet de correction).
///
/// `family` par ([fileName], [xmlSource]) plutôt qu'un provider simple : un
/// écran de vérification par fichier importé, jamais partagé entre deux
/// imports différents dans la même session — `autoDispose` (comportement par
/// défaut du générateur) laisse la mémoire se libérer dès que l'écran est
/// quitté (retour arrière avant validation, ou après sauvegarde réussie).
///
/// Toutes les corrections passent par [_updateResolved] plutôt que de
/// réimplémenter la même reconstruction d'enregistrement 11 champs à chaque
/// méthode — chaque méthode publique ne fait que calculer le nouveau
/// [XmlFieldResolution] à injecter dans [XmlCharacterImportResolved.copyWith].

final class XmlImportReviewControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          XmlImportReviewController,
          AsyncValue<XmlImportReviewData>,
          XmlImportReviewData,
          FutureOr<XmlImportReviewData>,
          ({String fileName, String xmlSource})
        > {
  XmlImportReviewControllerFamily._()
    : super(
        retry: null,
        name: r'xmlImportReviewControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Charge, parse et résout un export XML aidedd.org [xmlSource] (contenu
  /// déjà lu par le sélecteur de fichier natif, voir
  /// `features/characters/presentation/character_list_screen.dart::
  /// _startXmlImport`), puis porte les corrections manuelles faites par
  /// l'utilisateur sur l'écran de vérification (bottom sheet de correction).
  ///
  /// `family` par ([fileName], [xmlSource]) plutôt qu'un provider simple : un
  /// écran de vérification par fichier importé, jamais partagé entre deux
  /// imports différents dans la même session — `autoDispose` (comportement par
  /// défaut du générateur) laisse la mémoire se libérer dès que l'écran est
  /// quitté (retour arrière avant validation, ou après sauvegarde réussie).
  ///
  /// Toutes les corrections passent par [_updateResolved] plutôt que de
  /// réimplémenter la même reconstruction d'enregistrement 11 champs à chaque
  /// méthode — chaque méthode publique ne fait que calculer le nouveau
  /// [XmlFieldResolution] à injecter dans [XmlCharacterImportResolved.copyWith].

  XmlImportReviewControllerProvider call({
    required String fileName,
    required String xmlSource,
  }) => XmlImportReviewControllerProvider._(
    argument: (fileName: fileName, xmlSource: xmlSource),
    from: this,
  );

  @override
  String toString() => r'xmlImportReviewControllerProvider';
}

/// Charge, parse et résout un export XML aidedd.org [xmlSource] (contenu
/// déjà lu par le sélecteur de fichier natif, voir
/// `features/characters/presentation/character_list_screen.dart::
/// _startXmlImport`), puis porte les corrections manuelles faites par
/// l'utilisateur sur l'écran de vérification (bottom sheet de correction).
///
/// `family` par ([fileName], [xmlSource]) plutôt qu'un provider simple : un
/// écran de vérification par fichier importé, jamais partagé entre deux
/// imports différents dans la même session — `autoDispose` (comportement par
/// défaut du générateur) laisse la mémoire se libérer dès que l'écran est
/// quitté (retour arrière avant validation, ou après sauvegarde réussie).
///
/// Toutes les corrections passent par [_updateResolved] plutôt que de
/// réimplémenter la même reconstruction d'enregistrement 11 champs à chaque
/// méthode — chaque méthode publique ne fait que calculer le nouveau
/// [XmlFieldResolution] à injecter dans [XmlCharacterImportResolved.copyWith].

abstract class _$XmlImportReviewController
    extends $AsyncNotifier<XmlImportReviewData> {
  late final _$args = ref.$arg as ({String fileName, String xmlSource});
  String get fileName => _$args.fileName;
  String get xmlSource => _$args.xmlSource;

  FutureOr<XmlImportReviewData> build({
    required String fileName,
    required String xmlSource,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<XmlImportReviewData>, XmlImportReviewData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<XmlImportReviewData>, XmlImportReviewData>,
              AsyncValue<XmlImportReviewData>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(fileName: _$args.fileName, xmlSource: _$args.xmlSource),
    );
  }
}
