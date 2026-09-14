// Tests de `appVersionCheckProvider` — résolution du statut à partir de la
// version installée (mockée via `PackageInfo.setMockInitialValues`, même
// convention que `test/features/profile/presentation/profile_screen_test.dart`)
// et d'un `AppVersionRepository` factice (`appVersionRepositoryProvider`
// surchargé, jamais `Supabase.instance.client`).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/domain/app_version_status.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';

class _FakeAppVersionRepository implements AppVersionRepository {
  _FakeAppVersionRepository.returning(this._row) : _errorToThrow = null;
  _FakeAppVersionRepository.throwing(Object error)
    : _row = null,
      _errorToThrow = error;

  final AppVersionRow? _row;
  final Object? _errorToThrow;

  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async {
    if (_errorToThrow != null) throw _errorToThrow;
    return _row!;
  }
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'com.nexusjdr.personnages',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  ProviderContainer buildContainer(AppVersionRepository repository) {
    final container = ProviderContainer(
      overrides: [appVersionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'version installée < minimum requis -> AppVersionStatus.updateRequired',
    () async {
      final container = buildContainer(
        _FakeAppVersionRepository.returning(
          const AppVersionRow(
            minimumSupportedVersion: '0.3.0',
            latestVersion: '0.5.0',
          ),
        ),
      );

      final result = await container.read(appVersionCheckProvider.future);

      expect(result.status, AppVersionStatus.updateRequired);
      expect(result.installedVersion, '0.1.0');
      expect(result.minimumVersion, '0.3.0');
      expect(result.latestVersion, '0.5.0');
    },
  );

  test('version installée >= minimum mais < latest -> '
      'AppVersionStatus.updateSuggested', () async {
    final container = buildContainer(
      _FakeAppVersionRepository.returning(
        const AppVersionRow(
          minimumSupportedVersion: '0.1.0',
          latestVersion: '0.5.0',
        ),
      ),
    );

    final result = await container.read(appVersionCheckProvider.future);

    expect(result.status, AppVersionStatus.updateSuggested);
  });

  test('version installée >= latest -> AppVersionStatus.upToDate', () async {
    final container = buildContainer(
      _FakeAppVersionRepository.returning(
        const AppVersionRow(
          minimumSupportedVersion: '0.1.0',
          latestVersion: '0.1.0',
        ),
      ),
    );

    final result = await container.read(appVersionCheckProvider.future);

    expect(result.status, AppVersionStatus.upToDate);
  });

  test(
    'version installée strictement supérieure à latest (ex. build interne) '
    '-> AppVersionStatus.upToDate, jamais un statut négatif inattendu',
    () async {
      final container = buildContainer(
        _FakeAppVersionRepository.returning(
          const AppVersionRow(
            minimumSupportedVersion: '0.0.1',
            latestVersion: '0.0.9',
          ),
        ),
      );

      final result = await container.read(appVersionCheckProvider.future);

      expect(result.status, AppVersionStatus.upToDate);
    },
  );

  group('échec de la vérification réseau (spec : ne bloque jamais '
      'l\'utilisateur)', () {
    test(
      'le dépôt lève une exception -> AppVersionStatus.upToDate, version '
      'installée recopiée dans les 3 champs, jamais d\'exception propagée',
      () async {
        final container = buildContainer(
          _FakeAppVersionRepository.throwing(Exception('pas de réseau')),
        );

        final result = await container.read(appVersionCheckProvider.future);

        expect(result.status, AppVersionStatus.upToDate);
        expect(result.installedVersion, '0.1.0');
        expect(result.minimumVersion, '0.1.0');
        expect(result.latestVersion, '0.1.0');
      },
    );
  });
}
