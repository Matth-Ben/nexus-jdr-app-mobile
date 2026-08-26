import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Échec du téléchargement/de la validation d'une image distante (flux
/// "Utiliser une URL" du bottom sheet d'upload de portrait, voir
/// `presentation/widgets/portrait_upload_sheet.dart`).
class PortraitUrlFetchFailure implements Exception {
  const PortraitUrlFetchFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Télécharge et valide l'image pointée par [url].
///
/// `dart:io HttpClient` plutôt qu'une dépendance supplémentaire
/// (`package:http`, absente de ce dépôt) : un simple GET suffit ici, et
/// cette app cible mobile/desktop — pas le web, où `dart:io` n'existe pas —
/// comme le reste du dépôt (`path_provider`, `sqlite3`...).
///
/// Valide que la réponse est bien une image décodable
/// (`ui.instantiateImageCodec`) avant de retourner les octets : une réponse
/// 200 sur une page HTML (URL qui ne pointe pas vers une image) doit être
/// rejetée ici plutôt que de planter plus tard sur l'écran de recadrage.
Future<Uint8List> fetchPortraitBytesFromUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
    throw const PortraitUrlFetchFailure('URL invalide.');
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != 200) {
      throw PortraitUrlFetchFailure(
        'Impossible de charger cette image (${response.statusCode}).',
      );
    }

    final builder = BytesBuilder();
    await for (final chunk in response) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      await codec.getNextFrame();
    } catch (_) {
      throw const PortraitUrlFetchFailure(
        "Ce fichier n'est pas une image valide.",
      );
    }

    return bytes;
  } on PortraitUrlFetchFailure {
    rethrow;
  } catch (_) {
    throw const PortraitUrlFetchFailure(
      "Impossible de charger cette image. Vérifiez l'URL.",
    );
  } finally {
    client.close();
  }
}
