import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../providers/api_provider.dart';
import '../providers/auth_provider.dart';

class _PaystackBankOption {
  const _PaystackBankOption({
    required this.name,
    required this.code,
  });

  final String name;
  final String code;
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _paystackBusinessController = TextEditingController();
  final _paystackAccountNameController = TextEditingController();
  final _paystackAccountNumberController = TextEditingController();

  String _role = 'customer';
  List<_PaystackBankOption> _banks = const [];
  bool _isLoadingBanks = false;
  bool _isVerifyingAccount = false;
  String? _selectedBankCode;
  String? _bankLoadError;
  String _paystackStatus = 'Pending';

  Future<void> _loadPaystackBanks() async {
    if (_isLoadingBanks || _banks.isNotEmpty) {
      return;
    }

    setState(() {
      _isLoadingBanks = true;
      _bankLoadError = null;
    });

    try {
      final response = await ref.read(apiClientProvider).get(
            ApiEndpoints.paystackBanks,
          );
      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final banks = (data['banks'] as List<dynamic>? ?? const [])
          .map(
            (item) => _PaystackBankOption(
              name: item['name']?.toString() ?? 'Bank',
              code: item['code']?.toString() ?? '',
            ),
          )
          .where((bank) => bank.code.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _banks = banks;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bankLoadError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBanks = false;
        });
      }
    }
  }

  void _resetVerifiedAccount() {
    _paystackAccountNameController.clear();
    _paystackStatus = 'Pending';
  }

  Future<void> _verifySettlementAccount() async {
    final bankCode = _selectedBankCode;
    final accountNumber = _paystackAccountNumberController.text.trim();

    if (bankCode == null || bankCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a settlement bank first.')),
      );
      return;
    }
    if (accountNumber.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid account number.')),
      );
      return;
    }

    setState(() {
      _isVerifyingAccount = true;
      _paystackStatus = 'Verifying';
    });

    try {
      final response = await ref.read(apiClientProvider).post(
            ApiEndpoints.paystackVerifyAccount,
            data: {
              'bankCode': bankCode,
              'accountNumber': accountNumber,
            },
          );
      final data = response.data['data'] as Map<String, dynamic>? ?? const {};
      final accountName = data['accountName']?.toString().trim() ?? '';
      if (accountName.isEmpty) {
        throw Exception('Paystack did not return an account name.');
      }

      if (!mounted) return;
      setState(() {
        _paystackAccountNameController.text = accountName;
        _paystackStatus = 'Verified';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _paystackStatus = 'Failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingAccount = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nameParts = name.split(RegExp(r'\s+'));

    if (nameParts.length < 2 ||
        nameParts.first.length < 2 ||
        nameParts.sublist(1).join(' ').length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first and last name.')),
      );
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }

    if (_role == 'vendor') {
      final storeName = _storeNameController.text.trim();
      final businessAddress = _businessAddressController.text.trim();
      final paymentBusinessName = _paystackBusinessController.text.trim();
      final accountNumber = _paystackAccountNumberController.text.trim();

      if (storeName.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a store name.')),
        );
        return;
      }
      if (businessAddress.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the business address.')),
        );
        return;
      }
      if (paymentBusinessName.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the business name for payment setup.'),
          ),
        );
        return;
      }
      if ((_selectedBankCode ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose the settlement bank.')),
        );
        return;
      }
      if (accountNumber.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid account number.')),
        );
        return;
      }
      if (_paystackAccountNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verify the settlement account before registering.'),
          ),
        );
        return;
      }
    }

    final ok = await ref.read(authProvider.notifier).register(
          name,
          email,
          password,
          _role,
          phone: _phoneController.text,
          storeName: _storeNameController.text,
          brandName: _brandNameController.text,
          businessAddress: _businessAddressController.text,
          paystackBusinessName: _paystackBusinessController.text,
          paystackAccountName: _paystackAccountNameController.text,
          paystackAccountNumber: _paystackAccountNumberController.text,
          paystackBankCode: _selectedBankCode ?? '',
        );

    if (!mounted) return;

    if (ok) {
      final role = ref.read(authProvider).user?.role ?? 'customer';
      final route = switch (role) {
        'vendor' => '/vendor',
        'admin' => '/admin',
        _ => '/',
      };
      context.go(route);
      return;
    }

    final error = ref.read(authProvider).error ?? 'Unable to register.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _storeNameController.dispose();
    _brandNameController.dispose();
    _businessAddressController.dispose();
    _paystackBusinessController.dispose();
    _paystackAccountNameController.dispose();
    _paystackAccountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1ED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: QuiverLuxTheme.matteBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join the Quiver Lux experience',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(labelText: 'Email Address'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(
                        labelText: 'Account type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'customer',
                          child: Text('Customer'),
                        ),
                        DropdownMenuItem(
                          value: 'vendor',
                          child: Text('Vendor'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _role = value);
                          if (value == 'vendor') {
                            _loadPaystackBanks();
                          }
                        }
                      },
                    ),
                    if (_role == 'vendor') ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Vendor Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: QuiverLuxTheme.matteBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the store and settlement details. Quiver Lux will create the Paystack subaccount in the backend.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _storeNameController,
                        decoration: const InputDecoration(
                          labelText: 'Store Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _brandNameController,
                        decoration: const InputDecoration(
                          labelText: 'Brand Name (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _businessAddressController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Business Address',
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Vendor Payment Setup',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: QuiverLuxTheme.matteBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose the bank, verify the account name, and Quiver Lux will store the resulting Paystack subaccount for future orders.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _paystackBusinessController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingBanks)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedBankCode,
                        decoration: const InputDecoration(
                          labelText: 'Settlement Bank',
                        ),
                        items: _banks
                            .map(
                              (bank) => DropdownMenuItem(
                                value: bank.code,
                                child: Text(
                                  bank.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        selectedItemBuilder: (context) => _banks
                            .map(
                              (bank) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  bank.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBankCode = value;
                            _resetVerifiedAccount();
                          });
                        },
                      ),
                      if (_bankLoadError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _bankLoadError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: _paystackAccountNumberController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (_paystackStatus == 'Verified') {
                            setState(_resetVerifiedAccount);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Settlement Account Number',
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 520;
                          return Flex(
                            direction:
                                isCompact ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCompact)
                                TextField(
                                  controller: _paystackAccountNameController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Verified Account Name',
                                  ),
                                )
                              else
                                Expanded(
                                  child: TextField(
                                    controller: _paystackAccountNameController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Verified Account Name',
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: isCompact ? 0 : 12,
                                height: isCompact ? 12 : 0,
                              ),
                              SizedBox(
                                width: isCompact ? double.infinity : null,
                                child: ElevatedButton.icon(
                                  onPressed: _isVerifyingAccount
                                      ? null
                                      : _verifySettlementAccount,
                                  icon: const Icon(Icons.verified_outlined),
                                  label: Text(
                                    _isVerifyingAccount
                                        ? 'Verifying'
                                        : 'Verify',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _paystackStatus == 'Verified'
                              ? Colors.green.shade50
                              : _paystackStatus == 'Failed'
                                  ? Colors.red.shade50
                                  : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _paystackStatus == 'Verified'
                                ? Colors.green.shade200
                                : _paystackStatus == 'Failed'
                                    ? Colors.red.shade200
                                    : Colors.amber.shade200,
                          ),
                        ),
                        child: Text(
                          'Paystack Status: $_paystackStatus',
                          style: TextStyle(
                            color: _paystackStatus == 'Verified'
                                ? Colors.green.shade900
                                : _paystackStatus == 'Failed'
                                    ? Colors.red.shade900
                                    : Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'REGISTER',
                      isLoading: authState.isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Already have an account? Sign in',
                          style: TextStyle(color: QuiverLuxTheme.matteBlack),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
