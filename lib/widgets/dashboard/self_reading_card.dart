// lib/widgets/dashboard/self_reading_card.dart
import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

class SelfReadingCard extends StatelessWidget {
  final VoidCallback onSelfReadingTap;
  final String? nextReadingDate;

  const SelfReadingCard({
    super.key,
    required this.onSelfReadingTap,
    this.nextReadingDate,
  });

  Map<String, dynamic> _parseNextReadingDate() {
    // If no date provided, use default calculation
    if (nextReadingDate == null || nextReadingDate!.isEmpty) {
      return _getDefaultReadingInfo();
    }

    try {
      // Parse date format like "2083/04/08"
      final parts = nextReadingDate!.split('/');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);

        final now = NepaliDateTime.now();
        final nextDate = NepaliDateTime(year, month, day);
        final diffDays = nextDate.difference(now).inDays;

        final nepaliMonths = [
          'बैशाख', 'जेठ', 'असार', 'श्रावण',
          'भदौ', 'असोज', 'कात्तिक', 'मंसिर',
          'पुष', 'माघ', 'फागुन', 'चैत'
        ];

        final monthName = nepaliMonths[month - 1];
        final daySuffix = _getDaySuffix(day);

        return {
          'month': monthName,
          'day': day,
          'suffix': daySuffix,
          'daysAway': diffDays,
          'year': year,
          'fullDate': nextReadingDate,
        };
      }
    } catch (e) {
      // If parsing fails, use default calculation
      debugPrint('Error parsing nextReadingDate: $e');
    }

    return _getDefaultReadingInfo();
  }

  Map<String, dynamic> _getDefaultReadingInfo() {
    final now = NepaliDateTime.now();
    final currentDay = now.day;

    // Default: Next reading date is around 15th of next month
    int nextDay = 15;
    int nextMonth = now.month;
    int nextYear = now.year;

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
      'year': nextYear,
      'fullDate':
          '$nextYear/${nextMonth.toString().padLeft(2, '0')}/${nextDay.toString().padLeft(2, '0')}',
    };
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getDaysAwayText(int daysAway) {
    if (daysAway < 0) {
      return 'Overdue';
    } else if (daysAway == 0) {
      return 'Due today!';
    } else if (daysAway == 1) {
      return 'Tomorrow';
    } else {
      return '$daysAway days away';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final readingInfo = _parseNextReadingDate();
    final bool isOverdue = (readingInfo['daysAway'] as int) < 0;
    final bool isUrgent = (readingInfo['daysAway'] as int) <= 1 && !isOverdue;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.tertiaryFixed,
            colorScheme.tertiaryFixed.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Calendar-style date block
            _CalendarDateBlock(
              month: readingInfo['month']?.toString() ?? '',
              day: readingInfo['day'].toString(),
              suffix: readingInfo['suffix']?.toString() ?? '',
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(width: 18),

            // Middle: Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEXT SELF READING',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onTertiaryFixedVariant
                          .withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${readingInfo['month']} ${readingInfo['day']}${readingInfo['suffix']}',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onTertiaryFixedVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Days-away pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.withValues(alpha: 0.18)
                          : isUrgent
                              ? Colors.orange.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverdue
                              ? Icons.error_outline
                              : Icons.timer_outlined,
                          size: 13,
                          color: isOverdue
                              ? const Color.fromARGB(255, 242, 234, 5)
                              : isUrgent
                                  ? Colors.orange.shade800
                                  : colorScheme.onTertiaryFixedVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDaysAwayText(readingInfo['daysAway'] as int),
                          style: textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? Colors.red.shade700
                                : isUrgent
                                    ? Colors.orange.shade800
                                    : colorScheme.onTertiaryFixedVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right: Self Reading button, vertically centered
            ElevatedButton(
              onPressed: onSelfReadingTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                elevation: 0,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_outlined, size: 18),
                  SizedBox(height: 4),
                  Text(
                    'Self\nReading',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small block styled like a torn calendar page, showing month + day.
class _CalendarDateBlock extends StatelessWidget {
  final String month;
  final String day;
  final String suffix;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _CalendarDateBlock({
    required this.month,
    required this.day,
    required this.suffix,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 232, 239, 231),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top red "month" strip — mimics a paper calendar header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: colorScheme.error,
            child: Text(
              month.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onError,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Two little "binder ring" notches for the calendar look
          Transform.translate(
            offset: const Offset(0, -3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                2,
                (_) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryFixed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Day number
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day,
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    height: 1,
                  ),
                ),
                Text(
                  suffix,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}