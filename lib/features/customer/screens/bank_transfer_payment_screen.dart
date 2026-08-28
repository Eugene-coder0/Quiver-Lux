import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/formatters/currency_formatter.dart';

class BankTransferPaymentScreen extends StatelessWidget {
  const BankTransferPaymentScreen({super.key, required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final vendors =
        (payload['bankTransfer']?['vendors'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>();
    final orderNumber = payload['orderNumber']?.toString() ?? '';
    final totalAmount = (payload['totalAmount'] as num?)?.toDouble() ?? 0;
    final instruction = payload['bankTransfer']?['instruction']?.toString() ??
        'Transfer to the vendor account below and wait for confirmation.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Bank Transfer Payment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$orderNumber',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(instruction,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 12),
                Text('Total: ${formatNaira(totalAmount)}',
                    style: const TextStyle(
                        color: QuiverLuxTheme.forest,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...vendors.map((vendor) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor['vendorName']?.toString() ?? 'Vendor',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Business',
                      value: vendor['paystackBusinessName']?.toString() ?? '',
                    ),
                    _DetailRow(
                      label: 'Account name',
                      value: vendor['paystackAccountName']?.toString() ?? '',
                    ),
                    _DetailRow(
                      label: 'Account number',
                      value: vendor['paystackAccountNumber']?.toString() ?? '',
                    ),
                    _DetailRow(
                      label: 'Bank code',
                      value: vendor['paystackBankCode']?.toString() ?? '',
                    ),
                    _DetailRow(
                      label: 'Transfer amount',
                      value: formatNaira(
                        (vendor['subtotal'] as num?)?.toDouble() ?? 0,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: const Text(
              'After you transfer, the vendor or admin will confirm receipt. The order will move into the paid workflow after that confirmation.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: QuiverLuxTheme.matteBlack,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () => context.go('/order-tracking'),
            child: const Text(
              'I HAVE MADE THE TRANSFER',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Continue shopping'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
