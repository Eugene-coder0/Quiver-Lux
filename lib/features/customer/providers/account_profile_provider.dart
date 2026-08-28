import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountProfile {
  final String fullName;
  final String phone;
  final String address;

  const AccountProfile({
    this.fullName = '',
    this.phone = '+234 801 234 5678',
    this.address = '12 Victoria Island, Lagos, Nigeria',
  });

  AccountProfile copyWith({String? fullName, String? phone, String? address}) {
    return AccountProfile(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}

class AccountProfileNotifier extends StateNotifier<AccountProfile> {
  AccountProfileNotifier() : super(const AccountProfile()) {
    _load();
  }

  static const _nameKey = 'quiver_lux_account_name';
  static const _phoneKey = 'quiver_lux_account_phone';
  static const _addressKey = 'quiver_lux_account_address';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AccountProfile(
      fullName: prefs.getString(_nameKey) ?? '',
      phone: prefs.getString(_phoneKey) ?? state.phone,
      address: prefs.getString(_addressKey) ?? state.address,
    );
  }

  Future<void> update(
      {String? fullName, String? phone, String? address}) async {
    state = state.copyWith(fullName: fullName, phone: phone, address: address);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, state.fullName);
    await prefs.setString(_phoneKey, state.phone);
    await prefs.setString(_addressKey, state.address);
  }
}

final accountProfileProvider =
    StateNotifierProvider<AccountProfileNotifier, AccountProfile>((ref) {
  return AccountProfileNotifier();
});
