import 'package:web/web.dart' as web;

String? buildPaymentCallbackUrl(String routePath) {
  final normalizedPath = routePath.startsWith('/') ? routePath : '/$routePath';
  final base = Uri.base;
  if (base.fragment.startsWith('/')) {
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path.isEmpty ? '/' : base.path,
      fragment: normalizedPath,
    ).toString();
  }
  return base
      .resolve(normalizedPath)
      .replace(queryParameters: {}).toString();
}

Future<void> redirectToPaymentUrl(String url) async {
  web.window.location.assign(url);
}
