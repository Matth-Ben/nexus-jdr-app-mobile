import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/app_update/domain/app_store_urls.dart';

void main() {
  test('playStore() pointe vers la fiche Play Store du bundle id du dépôt', () {
    expect(
      AppStoreUrls.playStore().toString(),
      'https://play.google.com/store/apps/details?id=com.nexus_jdr',
    );
  });

  test('appStore() est construite à partir du même identifiant applicatif', () {
    expect(
      AppStoreUrls.appStore().toString(),
      'https://apps.apple.com/app/com.nexusjdr.personnages',
    );
  });

  test('current() retombe sur playStore() hors iOS (hôte `flutter test`)', () {
    expect(AppStoreUrls.current(), AppStoreUrls.playStore());
  });
}
