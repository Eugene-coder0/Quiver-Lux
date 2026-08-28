class VendorApplicationModel {
  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String category;
  final String description;
  final String documentUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime appliedAt;

  VendorApplicationModel({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.category,
    required this.description,
    required this.documentUrl,
    required this.status,
    required this.appliedAt,
  });

  VendorApplicationModel copyWith({
    String? status,
  }) {
    return VendorApplicationModel(
      id: id,
      businessName: businessName,
      ownerName: ownerName,
      email: email,
      category: category,
      description: description,
      documentUrl: documentUrl,
      status: status ?? this.status,
      appliedAt: appliedAt,
    );
  }
}
