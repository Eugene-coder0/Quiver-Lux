class AdminUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String vendorStatus;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.vendorStatus,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final vendor = json['vendor'];
    return AdminUserModel(
      id: json['id']?.toString() ?? '',
      name: '$firstName $lastName'.trim(),
      email: json['email']?.toString() ?? '',
      role: (json['role']?.toString() ?? 'CUSTOMER').toLowerCase(),
      vendorStatus: vendor is Map
          ? (vendor['status']?.toString() ?? 'none').toLowerCase()
          : 'none',
    );
  }
}