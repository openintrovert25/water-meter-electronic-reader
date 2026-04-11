import 'package:flutter/material.dart';
import 'iot_service.dart';

class CostSummaryCard extends StatelessWidget {
  final double totalLiters;
  final double dailyLiters;
  final double monthlyLiters;

  const CostSummaryCard({
    super.key,
    required this.totalLiters,
    required this.dailyLiters,
    required this.monthlyLiters,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rate = IotService.phpPerLiter;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.currency_exchange,
                    color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Estimated Cost (₱)',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _CostItem(
                  label: "Today",
                  amount: dailyLiters * rate,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 16),
                _CostItem(
                  label: "This Month",
                  amount: monthlyLiters * rate,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 16),
                _CostItem(
                  label: "Total",
                  amount: totalLiters * rate,
                  color: colorScheme.onPrimaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rate: ₱${(rate * 1000).toStringAsFixed(2)} / cu.m (MWSS Tier 1)',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _CostItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
