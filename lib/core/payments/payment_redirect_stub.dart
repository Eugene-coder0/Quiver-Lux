String? buildPaymentCallbackUrl(String routePath) => null;

Future<void> redirectToPaymentUrl(String url) async {
  throw UnsupportedError('Browser payment redirect is only implemented for Flutter web.');
}
