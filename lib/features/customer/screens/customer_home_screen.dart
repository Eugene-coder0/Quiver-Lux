import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/widgets/product_image.dart';
import '../../../providers/api_provider.dart';
import '../../admin/models/admin_models.dart';
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vendor/providers/vendor_providers.dart';
import '../providers/account_profile_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/review_provider.dart';
import '../models/product_model.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  String selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = const [
    'All',
    'Clothing',
    'Home Accessories',
    'Footwear',
    'Jewelry',
    'Bags',
    'Décor',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: QuiverLuxTheme.champagneGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showVendorApplicationDialog() async {
    final auth = ref.read(authProvider);
    final account = ref.read(accountProfileProvider);
    List<Map<String, dynamic>> banks;
    try {
      final banksResponse =
          await ref.read(apiClientProvider).get(ApiEndpoints.paystackBanks);
      if (!mounted) return;
      final banksData =
          banksResponse.data['data'] as Map<String, dynamic>? ?? const {};
      banks = (banksData['banks'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((bank) => (bank['code'] ?? '').isNotEmpty)
          .toList()
        ..sort(
          (a, b) => a['name']
              .toString()
              .compareTo(b['name'].toString()),
        );
    } catch (error) {
      if (!mounted) return;
      _showFeedback('Unable to open vendor application: $error');
      return;
    }
    final storeNameController = TextEditingController();
    final ownerNameController =
        TextEditingController(text: auth.user?.name ?? '');
    final emailController =
        TextEditingController(text: auth.user?.email ?? '');
    final phoneController = TextEditingController(text: account.phone);
    final businessAddressController = TextEditingController();
    final descController = TextEditingController();
    final paystackBusinessController = TextEditingController();
    final paystackAccountNameController = TextEditingController();
    final paystackAccountNumberController = TextEditingController();
    String selectedCat = 'Clothing';
    String? selectedBankCode;
    bool isVerifyingAccount = false;
    String paystackStatus = 'Pending';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        color: QuiverLuxTheme.forest, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Apply to Become a Vendor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: QuiverLuxTheme.matteBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sell your luxury collections on Quiver Lux. Applications are reviewed by platform administrators.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Store / Brand Name *',
                    hintText: 'e.g. Atelier Noir Luxury',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Representative Full Name *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Business Contact Email *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Business Phone Number *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: businessAddressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Business Address *',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(
                    labelText: 'Primary Product Category',
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Clothing', child: Text('Clothing')),
                    DropdownMenuItem(
                        value: 'Home Accessories',
                        child: Text('Home Accessories')),
                    DropdownMenuItem(
                        value: 'Footwear', child: Text('Footwear')),
                    DropdownMenuItem(
                        value: 'Jewelry', child: Text('Jewelry')),
                    DropdownMenuItem(value: 'Bags', child: Text('Bags')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCat = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Brand Profile & Craftsmanship Story',
                    hintText: 'Tell us about your materials, origin, and offerings.',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paystack Settlement Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: QuiverLuxTheme.matteBlack,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the settlement bank, verify the account name, and Quiver Lux will create and manage the vendor Paystack subaccount.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paystackBusinessController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedBankCode,
                  decoration: const InputDecoration(
                    labelText: 'Settlement Bank',
                  ),
                  items: banks
                      .map(
                        (bank) => DropdownMenuItem(
                          value: bank['code']?.toString(),
                          child: Text(
                            bank['name']?.toString() ?? 'Bank',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  selectedItemBuilder: (context) => banks
                      .map(
                        (bank) => Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            bank['name']?.toString() ?? 'Bank',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setModalState(() {
                      selectedBankCode = value;
                      paystackAccountNameController.clear();
                      paystackStatus = 'Pending';
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paystackAccountNumberController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (paystackStatus == 'Verified') {
                      setModalState(() {
                        paystackAccountNameController.clear();
                        paystackStatus = 'Pending';
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Settlement Account Number',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: paystackAccountNameController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Verified Account Name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isVerifyingAccount
                          ? null
                          : () async {
                              final accountNumber =
                                  paystackAccountNumberController.text.trim();
                              if ((selectedBankCode ?? '').isEmpty ||
                                  accountNumber.length < 10) {
                                _showFeedback(
                                  'Choose a bank and enter a valid account number first.',
                                );
                                return;
                              }
                              setModalState(() {
                                isVerifyingAccount = true;
                                paystackStatus = 'Verifying';
                              });
                              try {
                                final verifyResponse = await ref
                                    .read(apiClientProvider)
                                    .post(
                                  ApiEndpoints.paystackVerifyAccount,
                                  data: {
                                    'bankCode': selectedBankCode,
                                    'accountNumber': accountNumber,
                                  },
                                );
                                final verifyData = verifyResponse.data['data']
                                        as Map<String, dynamic>? ??
                                    const {};
                                setModalState(() {
                                  paystackAccountNameController.text =
                                      verifyData['accountName']?.toString() ??
                                          '';
                                  paystackStatus = 'Verified';
                                });
                              } catch (error) {
                                setModalState(() {
                                  paystackStatus = 'Failed';
                                });
                                if (mounted) {
                                  _showFeedback(error.toString());
                                }
                              } finally {
                                setModalState(() {
                                  isVerifyingAccount = false;
                                });
                              }
                            },
                      icon: const Icon(Icons.verified_outlined),
                      label:
                          Text(isVerifyingAccount ? 'Verifying' : 'Verify'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: paystackStatus == 'Verified'
                        ? Colors.green.shade50
                        : paystackStatus == 'Failed'
                            ? Colors.red.shade50
                            : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: paystackStatus == 'Verified'
                          ? Colors.green.shade200
                          : paystackStatus == 'Failed'
                              ? Colors.red.shade200
                              : Colors.amber.shade200,
                    ),
                  ),
                  child: Text(
                    'Paystack Status: $paystackStatus',
                    style: TextStyle(
                      color: paystackStatus == 'Verified'
                          ? Colors.green.shade900
                          : paystackStatus == 'Failed'
                              ? Colors.red.shade900
                              : Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: QuiverLuxTheme.forest,
                    ),
                    onPressed: () async {
                      final store = storeNameController.text.trim();
                      final owner = ownerNameController.text.trim();
                      final email = emailController.text.trim();
                      final phone = phoneController.text.trim();
                      final businessAddress =
                          businessAddressController.text.trim();
                      final paymentBusinessName =
                          paystackBusinessController.text.trim();
                      final accountNumber =
                          paystackAccountNumberController.text.trim();
                      if (store.isEmpty ||
                          owner.isEmpty ||
                          email.isEmpty ||
                          phone.isEmpty ||
                          businessAddress.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields.'),
                          ),
                        );
                        return;
                      }
                      if (paymentBusinessName.isEmpty ||
                          (selectedBankCode ?? '').isEmpty ||
                          accountNumber.length < 10 ||
                          paystackAccountNameController.text.trim().isEmpty) {
                        _showFeedback(
                          'Complete the bank verification before submitting.',
                        );
                        return;
                      }

                      final application = VendorApplication(
                        id: 'v_app_${DateTime.now().millisecondsSinceEpoch}',
                        storeName: store,
                        ownerName: owner,
                        email: email,
                        category: selectedCat,
                        description: descController.text.trim(),
                        phone: phone,
                        businessAddress: businessAddress,
                        paystackBusinessName: paymentBusinessName,
                        paystackAccountName:
                            paystackAccountNameController.text.trim(),
                        paystackAccountNumber: accountNumber,
                        paystackBankCode: selectedBankCode ?? '',
                        appliedDate: DateTime.now(),
                        status: ApprovalStatus.pending,
                      );

                      try {
                        await ref
                            .read(vendorApplicationsProvider.notifier)
                            .submitApplication(application);

                        if (!mounted) return;
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        _showFeedback(
                          'Application submitted! Platform admin will review shortly.',
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
                    child: const Text(
                      'SUBMIT APPLICATION',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: QuiverLuxTheme.softGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: const TextStyle(color: Colors.black, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search luxury items...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear, size: 16, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(2),
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: QuiverLuxTheme.forest,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  ProductModel _toProductModel(dynamic item) {
    if (item is ProductModel) return item;
    return ProductModel(
      id: item.id.toString(),
      title: item.title ?? 'Product',
      price: (item.price as num?)?.toDouble() ?? 0.0,
      category: item.category ?? 'General',
      imageUrl: item.imageUrl ?? '',
      description: 'Luxury ${item.category ?? 'piece'} curated for your home.',
      vendorName: item.vendorName ?? 'Quiver Lux Vendor',
      approvalStatus: item.approvalStatus ?? 'approved',
      vendorId: item.vendorId,
      discountPrice: item.discountPrice,
      offerStartsAt: item.offerStartsAt,
      offerEndsAt: item.offerEndsAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(customerProductsProvider);
    final allProducts = productsAsync.valueOrNull ?? const <ProductModel>[];
    final cartItems = ref.watch(cartProvider);
    final customerRatings = ref.watch(productReviewProvider);
    final auth = ref.watch(authProvider);
    final totalCartCount =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    final userRole = auth.user?.role ?? 'customer';
    final vendorStatus = auth.user?.vendorStatus ?? 'none';
    final isAdmin = userRole == 'admin';
    final isVendor = userRole == 'vendor' || vendorStatus == 'approved';
    final isPendingVendor = vendorStatus == 'pending';

    // Only approved products are visible to customers on storefront
    final approvedProducts = allProducts.where((p) {
      final model = _toProductModel(p);
      return model.approvalStatus == 'approved';
    }).toList();

    // Filter products marked as lightning deals
    final lightningProducts = approvedProducts.where((p) {
      final model = _toProductModel(p);
      return model.isLightningDeal;
    }).toList();

    // Search responds instantly for each letter typed, alongside the category filter.
    final query = _searchQuery.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    final filteredProducts = approvedProducts.where((product) {
      final item = _toProductModel(product);
      final categoryMatches = selectedCategory == 'All' ||
          item.category.toLowerCase() == selectedCategory.toLowerCase();
      final searchMatches = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.vendorName.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return categoryMatches && searchMatches;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.sizeOf(context).width < 760 ? 122 : 70),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 760;

            return Container(
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = 'All';
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              context.go('/');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: QuiverLuxTheme.matteBlack,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'QUIVER LUX',
                                style: TextStyle(
                                  color: QuiverLuxTheme.champagneGold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            onSelected: (cat) {
                              setState(() {
                                selectedCategory = cat;
                              });
                            },
                            itemBuilder: (context) => categories
                                .map((cat) => PopupMenuItem(
                                      value: cat,
                                      child: Text(
                                        cat,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ))
                                .toList(),
                            child: Row(
                              children: [
                                Text(
                                  selectedCategory == 'All'
                                      ? 'Categories'
                                      : selectedCategory,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 12),
                            Expanded(child: _buildSearchBar()),
                            const SizedBox(width: 16),
                          ] else
                            const Spacer(),
                          if (!isCompact)
                            InkWell(
                              onTap: () => context.push('/profile'),
                              child: const Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 22, color: Colors.black),
                                  SizedBox(width: 4),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Account',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Orders & Profile',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            IconButton(
                              tooltip: 'Account',
                              onPressed: () => context.push('/profile'),
                              icon: const Icon(Icons.person_outline,
                                  color: Colors.black),
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Badge(
                              label: Text('$totalCartCount'),
                              isLabelVisible: totalCartCount > 0,
                              backgroundColor: QuiverLuxTheme.champagneGold,
                              textColor: Colors.black,
                              child: const Icon(Icons.shopping_cart_outlined,
                                  color: Colors.black, size: 22),
                            ),
                            onPressed: () => context.push('/cart'),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Portals',
                            icon: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: QuiverLuxTheme.softGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                color: QuiverLuxTheme.matteBlack,
                                size: 19,
                              ),
                            ),
                            onSelected: (val) async {
                              if (val == '/admin') {
                                context.push('/admin');
                              } else if (val == '/vendor') {
                                context.push('/vendor');
                              } else if (val == 'apply_vendor') {
                                await _showVendorApplicationDialog();
                              } else if (val == 'pending_vendor') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                        'Application Under Review'),
                                    content: const Text(
                                      'Your vendor application has been submitted and is currently under review by our admin team.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              if (isAdmin) ...[
                                const PopupMenuItem(
                                  value: '/admin',
                                  child: ListTile(
                                    leading:
                                        Icon(Icons.verified_user_outlined),
                                    title: Text('Admin Console'),
                                    subtitle:
                                        Text('Marketplace oversight'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: '/vendor',
                                  child: ListTile(
                                    leading:
                                        Icon(Icons.storefront_outlined),
                                    title: Text('Vendor Studio'),
                                    subtitle:
                                        Text('Listings & fulfilment'),
                                  ),
                                ),
                              ] else if (isVendor) ...[
                                const PopupMenuItem(
                                  value: '/vendor',
                                  child: ListTile(
                                    leading:
                                        Icon(Icons.storefront_outlined),
                                    title: Text('Vendor Studio'),
                                    subtitle:
                                        Text('Listings & fulfilment'),
                                  ),
                                ),
                              ] else if (isPendingVendor) ...[
                                const PopupMenuItem(
                                  value: 'pending_vendor',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.hourglass_top_outlined,
                                      color: Colors.amber,
                                    ),
                                    title: Text('Vendor Application'),
                                    subtitle: Text('Under Admin Review'),
                                  ),
                                ),
                              ] else ...[
                                const PopupMenuItem(
                                  value: 'apply_vendor',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.storefront_outlined,
                                      color: QuiverLuxTheme.forest,
                                    ),
                                    title: Text('Become a Vendor'),
                                    subtitle: Text(
                                        'Apply to sell your luxury items'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (isCompact) ...[
                        const SizedBox(height: 10),
                        _buildSearchBar(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (!isSearching) ...[
              Container(
                color: const Color(0xFF1B3B2B),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: const [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: QuiverLuxTheme.champagneGold, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Why choose Quiver Lux?',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline,
                            color: Colors.white70, size: 12),
                        SizedBox(width: 4),
                        Text('Secure Checkout',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            color: Colors.white70, size: 12),
                        SizedBox(width: 4),
                        Text('Delivery Guarantee',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _HomeHero(),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 22),
                    const Text(
                      'LIGHTNING DEALS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: QuiverLuxTheme.matteBlack,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/explore'),
                      child: const Text(
                        'Limited-time offers >',
                        style: TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 250,
                child: productsAsync.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : productsAsync.hasError
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                productsAsync.error.toString(),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                    : lightningProducts.isEmpty
                        ? const Center(
                            child: Text(
                              'No active lightning deals.',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: lightningProducts.length,
                            itemBuilder: (context, index) {
                              final rawItem = lightningProducts[index];
                              final productModel = _toProductModel(rawItem);
                              final originalPrice = productModel.price;
                              final dealPrice = productModel.discountPrice ?? productModel.price;

                              return Container(
                                width: 150,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () => context.push(
                                          '/product-detail',
                                          extra: productModel),
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(8)),
                                        child: Container(
                                          height: 135,
                                          width: double.infinity,
                                          color: Colors.grey.shade200,
                                          child: ProductImage(
                                            imageUrl: productModel.imageUrl,
                                            imageBytes:
                                                productModel.imageBytes,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                formatNaira(dealPrice),
                                                style: const TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  formatNaira(originalPrice),
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 9,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  size: 10,
                                                  color: Colors.amber),
                                              const Icon(Icons.star,
                                                  size: 10,
                                                  color: Colors.amber),
                                              const Icon(Icons.star,
                                                  size: 10,
                                                  color: Colors.amber),
                                              const Icon(Icons.star,
                                                  size: 10,
                                                  color: Colors.amber),
                                              const Icon(Icons.star_half,
                                                  size: 10,
                                                  color: Colors.amber),
                                              const SizedBox(width: 2),
                                              Text(
                                                  (customerRatings[
                                                              productModel
                                                                  .id] ??
                                                          productModel.rating)
                                                      .toStringAsFixed(1),
                                                  style: const TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 26,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    QuiverLuxTheme.matteBlack,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () {
                                                ref
                                                    .read(cartProvider.notifier)
                                                    .addToCart(productModel);
                                                _showFeedback(
                                                    '${productModel.title} added to bag');
                                              },
                                              child: const Text(
                                                'ADD TO BAG',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  selectedCategory == 'All'
                      ? _searchQuery.trim().isEmpty
                          ? 'Featured Luxury Collection'
                          : 'Results for “${_searchQuery.trim()}” (${filteredProducts.length})'
                      : '$selectedCategory Collection',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            filteredProducts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                        child: Text(_searchQuery.trim().isEmpty
                            ? 'No pieces found in this category.'
                            : 'No pieces match “${_searchQuery.trim()}”.')),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 900
                          ? 4
                          : MediaQuery.sizeOf(context).width >= 600
                              ? 3
                              : 2,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final rawItem = filteredProducts[index];
                      final productModel = _toProductModel(rawItem);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push('/product-detail',
                                    extra: productModel),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.grey.shade100,
                                    child: ProductImage(
                                      imageUrl: productModel.imageUrl,
                                      imageBytes: productModel.imageBytes,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productModel.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: QuiverLuxTheme.champagneGold,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    productModel.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatNaira(productModel.price),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: QuiverLuxTheme.matteBlack,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          ref
                                              .read(cartProvider.notifier)
                                              .addToCart(productModel);
                                          _showFeedback(
                                              '${productModel.title} added to bag');
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: QuiverLuxTheme.champagneGold,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Icon(
                                            Icons.add_shopping_cart,
                                            size: 13,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [QuiverLuxTheme.forest, Color(0xFF285646)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: QuiverLuxTheme.forest.withValues(alpha: .25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -38,
            child: Icon(Icons.chair_alt_outlined,
                size: 180, color: Colors.white.withValues(alpha: .12)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('THE EDIT',
                    style: TextStyle(
                        color: Color(0xFFF5D99B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4)),
              ),
              const Spacer(),
              Text('Objects that make\nhome feel exceptional.',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white, height: 1.08)),
              const SizedBox(height: 7),
              const Text('Curated pieces, delivered across Nigeria.',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
