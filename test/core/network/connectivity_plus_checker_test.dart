import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_checker.dart';

/// `ConnectivityPlusChecker` avec le canal de plateforme de `connectivity_plus`
/// simulé (jamais de vrai plugin) : `onConnectivityChanged` émet la perte ET
/// le retour, sans doublon consécutif (`distinct`) ; `onConnectivityRestored`
/// n'émet que les retours.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const eventChannel = EventChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  MockStreamHandlerEventSink? sink;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) => sink = events,
            onCancel: (arguments) => sink = null,
          ),
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(eventChannel, null);
  });

  test('onConnectivityChanged : perte, retour, et distinct ; '
      'onConnectivityRestored : retours seulement', () async {
    final checker = ConnectivityPlusChecker(Connectivity());
    final changed = <bool>[];
    final restored = <bool>[];
    final subChanged = checker.onConnectivityChanged.listen(changed.add);
    final subRestored = checker.onConnectivityRestored.listen(restored.add);
    await pumpEventQueue();
    expect(sink, isNotNull);

    sink!.success(['wifi']);
    sink!.success(['mobile']); // autre interface connectée : même état
    sink!.success(['none']); // perte
    sink!.success(['none']); // doublon
    sink!.success(['wifi', 'mobile']); // retour
    await pumpEventQueue();

    expect(changed, [true, false, true]);
    expect(restored, [true, true, true], reason: 'chaque état connecté émis');

    await subChanged.cancel();
    await subRestored.cancel();
  });
}
