import 'package:url_launcher/url_launcher.dart';

String? buildPaymentCallbackUrl(String routePath) => null;

Future<void> redirectToPaymentUrl(String url) async {
  final uri = Uri.parse(url);
  final canLaunch = await canLaunchUrl(uri);
  if (canLaunch) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch payment URL: $url';
  }
}
