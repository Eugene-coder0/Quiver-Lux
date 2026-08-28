import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const String _configuredBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  static String get baseUrl {
    return baseUrlCandidates.first;
  }

  static List<String> get baseUrlCandidates {
    final candidates = <String>[];

    void addCandidate(String value) {
      final normalized = _normalizeBaseUrl(value);
      if (normalized.isEmpty) return;
      final apiUrl =
          normalized.endsWith('/api') ? normalized : '$normalized/api';
      if (!candidates.contains(apiUrl)) {
        candidates.add(apiUrl);
      }
    }

    addCandidate(_configuredBaseUrl);

    if (kIsWeb) {
      final currentHost = Uri.base.host.trim();
      final currentScheme = Uri.base.scheme.trim().isEmpty ? 'http' : Uri.base.scheme;
      if (currentHost.isNotEmpty) {
        addCandidate('$currentScheme://$currentHost:5000');
      }
      addCandidate('http://127.0.0.1:5000');
      addCandidate('http://localhost:5000');
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          addCandidate('http://10.0.2.2:5000');
          addCandidate('http://127.0.0.1:5000');
          addCandidate('http://localhost:5000');
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          addCandidate('http://127.0.0.1:5000');
          addCandidate('http://localhost:5000');
          break;
      }
    }

    return candidates;
  }

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String users = '/auth/users';
  static const String paystackBanks = '/auth/paystack/banks';
  static const String paystackVerifyAccount = '/auth/paystack/verify-account';

  static const String products = '/products';
  static const String categories = '/categories';
  static const String vendorProducts = '/products/vendor';
  static const String productApproval = '/products';

  static const String vendors = '/vendors';
  static const String vendorMe = '/vendors/me';
  static const String vendorApply = '/vendors/apply';
  static const String vendorApplications = '/vendors/applications';

  static const String ordersCheckout = '/orders/checkout';
  static const String customerOrders = '/orders/customer';
  static const String portalOrders = '/orders/portal';
  static const String verifyOrderPayment = '/orders/verify-payment';
  static String confirmPortalOrderPayment(String vendorOrderId) =>
      '/orders/portal/$vendorOrderId/confirm-payment';

  static const String vendorAnalytics = '/analytics/vendor';
  static const String adminAnalytics = '/analytics/admin';
}
