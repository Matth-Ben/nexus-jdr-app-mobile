// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bug_report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bugReportRepository)
final bugReportRepositoryProvider = BugReportRepositoryProvider._();

final class BugReportRepositoryProvider
    extends
        $FunctionalProvider<
          BugReportRepository,
          BugReportRepository,
          BugReportRepository
        >
    with $Provider<BugReportRepository> {
  BugReportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bugReportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bugReportRepositoryHash();

  @$internal
  @override
  $ProviderElement<BugReportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BugReportRepository create(Ref ref) {
    return bugReportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BugReportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BugReportRepository>(value),
    );
  }
}

String _$bugReportRepositoryHash() =>
    r'02cec587858afae2cf2a8e37aeedd9b07ccb3774';

/// Sélecteur/préparateur de la capture d'écran d'un signalement — surchargé
/// par un double dans les tests de widget de `report_bug_sheet.dart`.

@ProviderFor(bugReportScreenshotPicker)
final bugReportScreenshotPickerProvider = BugReportScreenshotPickerProvider._();

/// Sélecteur/préparateur de la capture d'écran d'un signalement — surchargé
/// par un double dans les tests de widget de `report_bug_sheet.dart`.

final class BugReportScreenshotPickerProvider
    extends
        $FunctionalProvider<
          BugReportScreenshotPicker,
          BugReportScreenshotPicker,
          BugReportScreenshotPicker
        >
    with $Provider<BugReportScreenshotPicker> {
  /// Sélecteur/préparateur de la capture d'écran d'un signalement — surchargé
  /// par un double dans les tests de widget de `report_bug_sheet.dart`.
  BugReportScreenshotPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bugReportScreenshotPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bugReportScreenshotPickerHash();

  @$internal
  @override
  $ProviderElement<BugReportScreenshotPicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BugReportScreenshotPicker create(Ref ref) {
    return bugReportScreenshotPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BugReportScreenshotPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BugReportScreenshotPicker>(value),
    );
  }
}

String _$bugReportScreenshotPickerHash() =>
    r'01b20ad16986476ea432911cb9d0f4280b4469dc';
