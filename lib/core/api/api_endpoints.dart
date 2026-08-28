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
    final configured = _normalizeBaseUrl(_configuredBaseUrl);
    if (configured.isNotEmpty) {
      return configured.endsWith('/api') ? configured : '$configured/api';
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:5000/api';
    }
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
