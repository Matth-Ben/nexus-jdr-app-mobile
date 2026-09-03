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
