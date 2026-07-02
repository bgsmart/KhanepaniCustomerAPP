// lib/widgets/dashboard/self_reading_card.dart
import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

class SelfReadingCard extends StatelessWidget {
  final VoidCallback onSelfReadingTap;

  const SelfReadingCard({
    super.key,
    required this.onSelfReadingTap,
  });

  Map<String, dynamic> _getNextReadingInfo() {
    final now = NepaliDateTime.now();
    final currentDay = now.day;
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Next reading date is usually around 15th of the month
    int nextDay = 15;
    int nextMonth = currentMonth;
    int nextYear = currentYear;
    
    if (currentDay > 15) {
      if (nextMonth == 12) {
        nextMonth = 1;
        nextYear++;
      } else {
        nextMonth++;
      }
    }
    
    final nextDate = NepaliDateTime(nextYear, nextMonth, nextDay);
    final diffDays = nextDate.difference(now).inDays;
    
    final nepaliMonths = [
      'बैशाख', 'जेठ', 'असार', 'साउन', 
      'भदौ', 'असोज', 'कात्तिक', 'मंसिर', 
      'पुष', 'माघ', 'फागुन', 'चैत'
    ];
    
    final monthName = nepaliMonths[nextMonth - 1];
    final daySuffix = _getDaySuffix(nextDay);
    
    return {
      'month': monthName,
      'day': nextDay,
      'suffix': daySuffix,
      'daysAway': diffDays,
    };
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final readingInfo = _getNextReadingInfo();
    final daysAway = readingInfo['daysAway'] as int;

    return Card(
      color: colorScheme.tertiaryFixed,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Month Name
            Text(
              readingInfo['month']?.toString().toUpperCase() ?? 'साउन',
              style: textTheme.displayLarge?.copyWith(
                color: colorScheme.onTertiaryFixedVariant,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),

            // Middle: Day Number
            Text(
              readingInfo['day'].toString(),
              style: textTheme.displayLarge?.copyWith(
                color: colorScheme.onTertiaryFixedVariant,
                fontSize: 48,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: "Month day... days away"
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${readingInfo['month']} ${readingInfo['day']}${readingInfo['suffix']}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onTertiaryFixedVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: colorScheme.onTertiaryFixedVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              daysAway <= 0 
                                  ? 'Due today!' 
                                  : '$daysAway days away',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onTertiaryFixedVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Self Reading Button
                ElevatedButton(
                  onPressed: onSelfReadingTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Self Reading',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}