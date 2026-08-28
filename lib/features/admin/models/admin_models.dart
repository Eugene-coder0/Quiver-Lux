enum ApprovalStatus { pending, approved, rejected }

class VendorApplication {
  final String id;
  final String storeName;
  final String ownerName;
  final String email;
  final String category;
  final String description;
  final String phone;
  final String businessAddress;
  final String paystackRecipientCode;
  final String paystackSubaccountCode;
  final String paystackBusinessName;
  final String paystackAccountName;
  final String paystackAccountNumber;
  final String paystackBankCode;
  final DateTime appliedDate;
  final ApprovalStatus status;

  VendorApplication({
    required this.id,
    required this.storeName,
    required this.ownerName,
    this.email = '',
    required this.category,
    this.description = '',
    this.phone = '',
    this.businessAddress = '',
    this.paystackRecipientCode = '',
    this.paystackSubaccountCode = '',
    this.paystackBusinessName = '',
    this.paystackAccountName = '',
    this.paystackAccountNumber = '',
    this.paystackBankCode = '',
    required this.appliedDate,
    this.status = ApprovalStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeName': storeName,
      'ownerName': ownerName,
      'email': email,
      'category': category,
      'description': description,
      'phone': phone,
      'businessAddress': businessAddress,
      'paystackRecipientCode': paystackRecipientCode,
      'paystackSubaccountCode': paystackSubaccountCode,
      'paystackBusinessName': paystackBusinessName,
      'paystackAccountName': paystackAccountName,
      'paystackAccountNumber': paystackAccountNumber,
      'paystackBankCode': paystackBankCode,
      'appliedDate': appliedDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory VendorApplication.fromJson(Map<String, dynamic> json) {
    return VendorApplication(
      id: json['id']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General Luxury',
      description: json['description']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      businessAddress: json['businessAddress']?.toString() ?? '',
      paystackRecipientCode: json['paystackRecipientCode']?.toString() ?? '',
      paystackSubaccountCode: json['paystackSubaccountCode']?.toString() ?? '',
      paystackBusinessName: json['paystackBusinessName']?.toString() ?? '',
      paystackAccountName: json['paystackAccountName']?.toString() ?? '',
      paystackAccountNumber: json['paystackAccountNumber']?.toString() ?? '',
      paystackBankCode: json['paystackBankCode']?.toString() ?? '',
      appliedDate: json['appliedDate'] != null
          ? DateTime.tryParse(json['appliedDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: ApprovalStatus.values.firstWhere(
        (e) => e.name == json['status']?.toString(),
        orElse: () => ApprovalStatus.pending,
      ),
    );
  }

  VendorApplication copyWith({
    String? id,
    String? storeName,
    String? ownerName,
    String? email,
    String? category,
    String? description,
    String? phone,
    String? businessAddress,
    String? paystackRecipientCode,
    String? paystackSubaccountCode,
    String? paystackBusinessName,
    String? paystackAccountName,
    String? paystackAccountNumber,
    String? paystackBankCode,
    DateTime? appliedDate,
    ApprovalStatus? status,
  }) {
    return VendorApplication(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      category: category ?? this.category,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      businessAddress: businessAddress ?? this.businessAddress,
      paystackRecipientCode:
          paystackRecipientCode ?? this.paystackRecipientCode,
      paystackSubaccountCode:
          paystackSubaccountCode ?? this.paystackSubaccountCode,
      paystackBusinessName: paystackBusinessName ?? this.paystackBusinessName,
      paystackAccountName: paystackAccountName ?? this.paystackAccountName,
      paystackAccountNumber:
          paystackAccountNumber ?? this.paystackAccountNumber,
      paystackBankCode: paystackBankCode ?? this.paystackBankCode,
      appliedDate: appliedDate ?? this.appliedDate,
      status: status ?? this.status,
    );
  }
}

class PendingProduct {
  final String id;
  final String title;
  final String vendorName;
  final double price;
  final String category;
  ApprovalStatus status;

  PendingProduct({
    required this.id,
    required this.title,
    required this.vendorName,
    required this.price,
    required this.category,
    this.status = ApprovalStatus.pending,
  });
}

class AdminAnalyticsModel {
  final int totalUsers;
  final int totalCustomers;
  final int totalVendors;
  final int totalProducts;
  final int totalOrders;
  final int totalCustomerSignIns;
  final double totalPlatformRevenue;
  final double totalPlatformCommission;

  const AdminAnalyticsModel({
    this.totalUsers = 0,
    this.totalCustomers = 0,
    this.totalVendors = 0,
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.totalCustomerSignIns = 0,
    this.totalPlatformRevenue = 0,
    this.totalPlatformCommission = 0,
  });

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalVendors: (json['totalVendors'] as num?)?.toInt() ?? 0,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalCustomerSignIns: (json['totalCustomerSignIns'] as num?)?.toInt() ?? 0,
      totalPlatformRevenue:
          (json['totalPlatformRevenue'] as num?)?.toDouble() ?? 0,
      totalPlatformCommission:
          (json['totalPlatformCommission'] as num?)?.toDouble() ?? 0,
    );
  }
}

