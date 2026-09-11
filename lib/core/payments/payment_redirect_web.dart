import 'package:web/web.dart' as web;

String? buildPaymentCallbackUrl(String routePath) {
  final normalizedPath = routePath.startsWith('/') ? routePath : '/$routePath';
  return Uri.base
      .resolve(normalizedPath)
      .replace(queryParameters: {}).toString();
}

Future<void> redirectToPaymentUrl(String url) async {
  web.window.location.assign(url);
}
