import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_application_model.dart';

class AdminVendorNotifier extends StateNotifier<List<VendorApplicationModel>> {
  AdminVendorNotifier() : super(_initialApplications);

  static final List<VendorApplicationModel> _initialApplications = [
    VendorApplicationModel(
      id: 'app_001',
      businessName: 'Maison de L\'Elégance',
      ownerName: 'Sophie Laurent',
      email: 'sophie@maison-elegance.com',
      category: 'Jewelry',
      description:
          'Handcrafted high-end diamond and gemstone jewelry designed in Paris.',
      documentUrl: 'https://example.com/docs/maison_licence.pdf',
      status: 'pending',
      appliedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    VendorApplicationModel(
      id: 'app_002',
      businessName: 'Nordic Craft Co.',
      ownerName: 'Lars Lindqvist',
      email: 'contact@nordiccraft.io',
      category: 'Home Accessories',
      description:
          'Minimalist luxury home decor and artisan furniture sustainably crafted in Sweden.',
      documentUrl: 'https://example.com/docs/nordic_cert.pdf',
      status: 'pending',
      appliedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    VendorApplicationModel(
      id: 'app_003',
      businessName: 'Veloce Leatherworks',
      ownerName: 'Marco Rossi',
      email: 'm.rossi@veloce.it',
      category: 'Bags',
      description:
          'Bespoke Italian full-grain leather bags and travel accessories.',
      documentUrl: 'https://example.com/docs/veloce_tax.pdf',
      status: 'approved',
      appliedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    VendorApplicationModel(
      id: 'app_004',
      businessName: 'Aura Silk Couture',
      ownerName: 'Amina El-Sayed',
      email: 'amina@aurasilk.ae',
      category: 'Clothing',
      description: 'Luxury silk evening wear and bespoke tailored apparel.',
      documentUrl: 'https://example.com/docs/aura_reg.pdf',
      status: 'rejected',
      appliedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  void approveApplication(String id) {
    state = [
      for (final app in state)
        if (app.id == id) app.copyWith(status: 'approved') else app
    ];
  }

  void rejectApplication(String id) {
    state = [
      for (final app in state)
        if (app.id == id) app.copyWith(status: 'rejected') else app
    ];
  }
}

final adminVendorProvider =
    StateNotifierProvider<AdminVendorNotifier, List<VendorApplicationModel>>(
        (ref) {
  return AdminVendorNotifier();
});
