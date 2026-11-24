// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_stack_observer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [RouteStackObserver] unique de l'app (`keepAlive`), comme
/// `routeObserverProvider` : `GoRouter.observers` et ses lecteurs pointent vers
/// la même instance.

@ProviderFor(routeStackObserver)
final routeStackObserverProvider = RouteStackObserverProvider._();

/// [RouteStackObserver] unique de l'app (`keepAlive`), comme
/// `routeObserverProvider` : `GoRouter.observers` et ses lecteurs pointent vers
/// la même instance.

final class RouteStackObserverProvider
    extends
        $FunctionalProvider<
          RouteStackObserver,
          RouteStackObserver,
          RouteStackObserver
        >
    with $Provider<RouteStackObserver> {
  /// [RouteStackObserver] unique de l'app (`keepAlive`), comme
  /// `routeObserverProvider` : `GoRouter.observers` et ses lecteurs pointent vers
  /// la même instance.
  RouteStackObserverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeStackObserverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeStackObserverHash();

  @$internal
  @override
  $ProviderElement<RouteStackObserver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RouteStackObserver create(Ref ref) {
    return routeStackObserver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteStackObserver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteStackObserver>(value),
    );
  }
}

String _$routeStackObserverHash() =>
    r'946486a455a67e6fab120b93c3e5da6b94868787';
