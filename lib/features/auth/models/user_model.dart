class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String vendorStatus; // 'none', 'pending', 'approved', 'rejected'
  final Map<String, dynamic>? vendor;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.vendorStatus = 'none',
    this.vendor,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] ?? 'customer').toString().toLowerCase();
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final derivedName = [firstName, lastName]
        .where((part) => part.trim().isNotEmpty)
        .join(' ')
        .trim();
    final rawVendorStatus = (json['vendorStatus'] ??
            (json['vendor'] is Map ? (json['vendor'] as Map)['status'] : null) ??
            (rawRole == 'vendor' ? 'approved' : 'none'))
        .toString()
        .toLowerCase();

    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: (json['name']?.toString().trim().isNotEmpty ?? false)
          ? json['name'].toString().trim()
          : (derivedName.isNotEmpty ? derivedName : ''),
      role: rawRole,
      vendorStatus: rawVendorStatus == 'suspended'
          ? 'rejected'
          : rawVendorStatus == 'none'
              ? 'none'
              : rawVendorStatus,
      vendor: json['vendor'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['vendor'] as Map<String, dynamic>)
          : json['vendor'] is Map
              ? Map<String, dynamic>.from(json['vendor'] as Map)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'vendorStatus': vendorStatus,
      'vendor': vendor,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? vendorStatus,
    Map<String, dynamic>? vendor,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      vendorStatus: vendorStatus ?? this.vendorStatus,
      vendor: vendor ?? this.vendor,
    );
  }
}
