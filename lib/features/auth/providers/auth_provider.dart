import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/storage_service.dart';
import '../../../providers/api_provider.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(AuthState()) {
    checkAuthStatus();
  }

  final Ref ref;
  final StorageService _storageService = StorageService();

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
        return;
      }

      final response = await ref.read(apiClientProvider).get(ApiEndpoints.me);
      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final user = UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map? ?? const {}));

      await _storageService.saveUser(user.toJson());
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    } catch (error) {
      await _storageService.deleteToken();
      await _storageService.deleteUser();
      state = state.copyWith(
        user: null,
        isLoading: false,
        isAuthenticated: false,
        error: error.toString(),
      );
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String role,
    {String phone = '',
    String storeName = '',
    String brandName = '',
    String businessAddress = '',
    String paystackRecipientCode = '',
    String paystackSubaccountCode = '',
    String paystackBusinessName = '',
    String paystackAccountName = '',
    String paystackAccountNumber = '',
    String paystackBankCode = '',}
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'Member';
      final response = await ref.read(apiClientProvider).post(
        ApiEndpoints.register,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
          'firstName': firstName,
          'lastName': lastName,
          if (phone.trim().isNotEmpty) 'phone': phone.trim(),
          'role': role.trim().toUpperCase(),
          if (storeName.trim().isNotEmpty) 'storeName': storeName.trim(),
          if (brandName.trim().isNotEmpty) 'brandName': brandName.trim(),
          if (businessAddress.trim().isNotEmpty)
            'businessAddress': businessAddress.trim(),
          if (paystackRecipientCode.trim().isNotEmpty)
            'paystackRecipientCode': paystackRecipientCode.trim(),
          if (paystackSubaccountCode.trim().isNotEmpty)
            'paystackSubaccountCode': paystackSubaccountCode.trim(),
          if (paystackBusinessName.trim().isNotEmpty)
            'paystackBusinessName': paystackBusinessName.trim(),
          if (paystackAccountName.trim().isNotEmpty)
            'paystackAccountName': paystackAccountName.trim(),
          if (paystackAccountNumber.trim().isNotEmpty)
            'paystackAccountNumber': paystackAccountNumber.trim(),
          if (paystackBankCode.trim().isNotEmpty)
            'paystackBankCode': paystackBankCode.trim(),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final token = data['token']?.toString() ?? '';
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map? ?? const {}),
      );

      await _storageService.saveToken(token);
      await _storageService.saveUser(user.toJson());
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ref.read(apiClientProvider).post(
        ApiEndpoints.login,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final token = data['token']?.toString() ?? '';
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map? ?? const {}),
      );

      await _storageService.saveToken(token);
      await _storageService.saveUser(user.toJson());
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    await checkAuthStatus();
  }

  Future<void> setVendorProfile(Map<String, dynamic> vendorJson) async {
    final currentUser = state.user;
    if (currentUser == null) return;
    final updatedUser = currentUser.copyWith(
      role: currentUser.role == 'admin'
          ? 'admin'
          : ((vendorJson['status']?.toString().toLowerCase() ?? '') == 'approved'
              ? 'vendor'
              : 'customer'),
      vendorStatus: (vendorJson['status']?.toString().toLowerCase() ?? 'pending'),
      vendor: vendorJson,
    );
    await _storageService.saveUser(updatedUser.toJson());
    state = state.copyWith(user: updatedUser, isAuthenticated: true);
  }

  Future<void> promoteUserToVendor(String email) async {
    final currentUser = state.user;
    if (currentUser == null) return;
    if (currentUser.email.trim().toLowerCase() != email.trim().toLowerCase()) return;
    final updatedUser = currentUser.copyWith(
      role: 'vendor',
      vendorStatus: 'approved',
    );
    await _storageService.saveUser(updatedUser.toJson());
    state = state.copyWith(user: updatedUser, isAuthenticated: true);
  }

  Future<void> rejectUserVendor(String email) async {
    final currentUser = state.user;
    if (currentUser == null) return;
    if (currentUser.email.trim().toLowerCase() != email.trim().toLowerCase()) return;
    final updatedUser = currentUser.copyWith(vendorStatus: 'rejected');
    await _storageService.saveUser(updatedUser.toJson());
    state = state.copyWith(user: updatedUser, isAuthenticated: true);
  }

  Future<void> setVendorStatus(String status) async {
    final currentUser = state.user;
    if (currentUser == null) return;
    final updatedUser = currentUser.copyWith(vendorStatus: status.toLowerCase());
    await _storageService.saveUser(updatedUser.toJson());
    state = state.copyWith(user: updatedUser, isAuthenticated: true);
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
    await _storageService.deleteUser();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
