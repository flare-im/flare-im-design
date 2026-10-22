import 'dart:async';
import 'dart:io';

/// HTTP for widget tests whose remote pictures should stay loading.
///
/// The test binding answers every request with 400, which a message picture
/// now shows as its failure placeholder — a tap there retries rather than
/// opens. Tests about what a tap opens install this for the file instead
/// ([installHangingHttp]): a request that never answers keeps the picture
/// loading, the state a tap opens from.
class HangingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _HangingClient();
}

class _HangingClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Completer<HttpClientRequest>().future;

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

/// Installs [HangingHttpOverrides] for the test file before any picture
/// loads (the image cache keeps one client for the whole run).
void installHangingHttp(
  void Function(void Function()) setUpAll,
  void Function(void Function()) tearDownAll,
) {
  HttpOverrides? previous;
  setUpAll(() {
    previous = HttpOverrides.current;
    HttpOverrides.global = HangingHttpOverrides();
  });
  tearDownAll(() => HttpOverrides.global = previous);
}
