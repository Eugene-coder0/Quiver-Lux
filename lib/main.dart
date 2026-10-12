import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/sync/portal_sync_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) {
        _startBackgroundSync();
      } else {
        _stopBackgroundSync();
      }
    });
  }

  @override
  void dispose() {
    _stopBackgroundSync();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startBackgroundSync() {
    if (_syncTimer != null) return;
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        ref.read(portalSyncProvider).refresh();
      }
    });
  }

  void _stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(portalSyncProvider).refresh();
      if (ref.read(authProvider).isAuthenticated) {
        _startBackgroundSync();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopBackgroundSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quiver Lux',
      debugShowCheckedModeBanner: false,
      theme: QuiverLuxTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
