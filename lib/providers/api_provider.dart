import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
