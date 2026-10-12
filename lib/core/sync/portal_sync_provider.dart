import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/providers/admin_providers.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/customer/providers/order_provider.dart';
import '../../features/vendor/providers/vendor_providers.dart';

final portalSyncProvider = Provider<PortalSyncService>((ref) {
  return PortalSyncService(ref);
});

class PortalSyncService {
  PortalSyncService(this.ref);

  final Ref ref;
  Future<void>? _activeRefresh;

  Future<void> refresh() {
    final activeRefresh = _activeRefresh;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _refresh();
    _activeRefresh = refresh;
    refresh.whenComplete(() {
      if (identical(_activeRefresh, refresh)) {
        _activeRefresh = null;
      }
    });
    return refresh;
  }

  Future<void> _refresh() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    ref.invalidate(customerProductsProvider);
    await ref.read(orderProvider.notifier).refresh();

    if (user.role == 'vendor' || user.role == 'admin') {
      await Future.wait([
        ref.read(vendorProductsProvider.notifier).load(),
        ref.read(vendorAnalyticsProvider.future),
      ]);
    }

    if (user.role == 'admin') {
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminAnalyticsProvider);
      await ref.read(vendorApplicationsProvider.notifier).load();
    }
  }
}
