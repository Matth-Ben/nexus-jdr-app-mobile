import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException;

/// `true` si [error] est une erreur de **certificat** TLS (certificat invalide,
/// expiré, non approuvé, nom d'hôte non concordant) : elle ne se résout pas en
/// retentant (D194), contrairement à une coupure ou à une poignée de main
/// interrompue. Ce n'est donc pas un échec de transport récupérable : l'écriture
/// n'est pas mise en file et l'échec est explicite.
///
/// Dart remonte la plupart des certificats refusés comme une
/// [HandshakeException] dont le message système contient
/// `CERTIFICATE_VERIFY_FAILED` ; [CertificateException] couvre les certificats
/// mal formés. Une [HandshakeException] sans mention de certificat reste un
/// échec de transport.
bool isCertificateFailure(Object error) {
  if (error is CertificateException) return true;
  if (error is HandshakeException) {
    final text = '${error.message} ${error.osError?.message ?? ''}'
        .toUpperCase();
    return text.contains('CERTIFICATE');
  }
  return false;
}

/// `true` si [error] est un échec de **transport** (réseau coupé, requête ou
/// réponse perdue, délai dépassé, TLS) et non un refus du serveur : on ne sait
/// alors pas si l'écriture a atteint le serveur, mais rien n'indique qu'un
/// nouvel essai échouerait de la même façon — l'écriture peut être mise en
/// file puis rejouée (valeur absolue, idempotente).
///
/// Un refus Postgrest (`PostgrestException`, code SQLSTATE) n'en est
/// **jamais** un : il se rejouerait à l'identique, il reste un échec (D184 du
/// registre de dette technique : seule `TimeoutException` était traitée avant,
/// une coupure en cours de requête faisait croire à un échec alors que le
/// serveur avait peut-être déjà enregistré l'écriture).
bool isTransportFailure(Object error) =>
    error is TimeoutException ||
    error is SocketException ||
    error is HttpException ||
    (error is TlsException && !isCertificateFailure(error)) ||
    error is WebSocketException ||
    error is ClientException ||
    error is AuthRetryableFetchException;
