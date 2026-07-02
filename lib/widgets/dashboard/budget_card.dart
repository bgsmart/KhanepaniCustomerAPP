// lib/widgets/dashboard/budget_card.dart
import 'package:flutter/material.dart';

class BudgetCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final double? fontSize;

  const BudgetCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: textTheme.labelLarge?.copyWith(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
              Icon(
                icon,
                color: textColor.withValues(alpha: 0.8),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: textTheme.displaySmall?.copyWith(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}