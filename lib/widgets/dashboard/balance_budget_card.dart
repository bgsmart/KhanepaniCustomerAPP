// lib/widgets/dashboard/balance_budget_card.dart
import 'package:flutter/material.dart';

class BalanceBudgetCard extends StatelessWidget {
  final String dueBalance;
  final ColorScheme colorScheme;
  final VoidCallback? onPayNow;

  const BalanceBudgetCard({
    super.key,
    required this.dueBalance,
    required this.colorScheme,
    this.onPayNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.payments,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                "Due Balance",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dueBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onPayNow ?? () {
                // Navigate to payment page
              },
              icon: const Icon(Icons.payment),
              label: const Text("Pay Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}