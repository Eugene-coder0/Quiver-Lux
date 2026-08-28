import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../providers/api_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_models.dart';
import '../models/admin_user_model.dart';

final adminUsersProvider = FutureProvider<List<AdminUserModel>>((ref) async {
  final response = await ref.read(apiClientProvider).get(ApiEndpoints.users);
  final data = response.data['data'] as Map<String, dynamic>? ?? const {};
  return (data['users'] as List<dynamic>? ?? const [])
      .map((item) => AdminUserModel.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

class VendorApplicationsNotifier
    extends StateNotifier<List<VendorApplication>> {
  VendorApplicationsNotifier(this.ref) : super(const []) {
    load();
  }

  final Ref ref;

  Future<void> load() async {
    try {
      final response =
          await ref.read(apiClientProvider).get(ApiEndpoints.vendorApplications);
      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final applications = (data['applications'] as List<dynamic>? ?? const [])
          .map((item) =>
              VendorApplication.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      state = applications;
    } catch (_) {
      state = const [];
    }
  }

  Future<void> submitApplication(VendorApplication application) async {
    await ref.read(apiClientProvider).post(
      ApiEndpoints.vendorApply,
      data: {
        'storeName': application.storeName,
        'brandName': application.storeName,
        'description': application.description,
        'category': application.category,
        'phone': application.phone,
        'businessAddress': application.businessAddress,
        if (application.paystackRecipientCode.isNotEmpty)
          'paystackRecipientCode': application.paystackRecipientCode,
        if (application.paystackSubaccountCode.isNotEmpty)
          'paystackSubaccountCode': application.paystackSubaccountCode,
        if (application.paystackBusinessName.isNotEmpty)
          'paystackBusinessName': application.paystackBusinessName,
        if (application.paystackAccountName.isNotEmpty)
          'paystackAccountName': application.paystackAccountName,
        if (application.paystackAccountNumber.isNotEmpty)
          'paystackAccountNumber': application.paystackAccountNumber,
        if (application.paystackBankCode.isNotEmpty)
          'paystackBankCode': application.paystackBankCode,
      },
    );
    await ref.read(authProvider.notifier).refreshProfile();
    await load();
  }

  Future<void> approveApplication(String id) async {
    await ref.read(apiClientProvider).patch(
      '${ApiEndpoints.vendorApplications}/$id',
      data: {'status': 'APPROVED'},
    );
    await load();
  }

  Future<void> rejectApplication(String id) async {
    await ref.read(apiClientProvider).patch(
      '${ApiEndpoints.vendorApplications}/$id',
      data: {'status': 'REJECTED'},
    );
    await load();
  }
}

final vendorApplicationsProvider =
    StateNotifierProvider<VendorApplicationsNotifier, List<VendorApplication>>(
  (ref) {
    final notifier = VendorApplicationsNotifier(ref);
    ref.listen<String?>(
      authProvider.select((state) {
        final user = state.user;
        return user == null ? null : '${user.id}:${user.role}:${user.vendorStatus}';
      }),
      (_, __) {
        notifier.load();
      },
    );
    return notifier;
  },
);

final adminAnalyticsProvider = FutureProvider<AdminAnalyticsModel>((ref) async {
  final response = await ref.read(apiClientProvider).get(ApiEndpoints.adminAnalytics);
  final data = response.data['data'] as Map<String, dynamic>? ?? const {};
  return AdminAnalyticsModel.fromJson(data);
});
