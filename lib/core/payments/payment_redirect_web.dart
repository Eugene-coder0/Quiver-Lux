import 'dart:html' as html;

String? buildPaymentCallbackUrl(String routePath) {
  final normalizedPath = routePath.startsWith('/') ? routePath : '/$routePath';
  return Uri.base.resolve(normalizedPath).replace(queryParameters: {}).toString();
}

Future<void> redirectToPaymentUrl(String url) async {
  html.window.location.assign(url);
}
