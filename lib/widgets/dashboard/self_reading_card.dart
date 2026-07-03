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
          'बैशाख', 'जेठ', 'असार', 'साउन',
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final readingInfo = _parseNextReadingDate();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Calendar-style date block with white background
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
                    'NEXT READING DATE',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${readingInfo['month']} ${readingInfo['day']}${readingInfo['suffix']}',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${readingInfo['daysAway']} days away',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
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

            // Right: Self Reading button
            ElevatedButton(
              onPressed: onSelfReadingTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.1),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 22),
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
      width: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top color strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.error,
                  colorScheme.errorContainer,
                ],
              ),
            ),
            child: Text(
              month.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Day number
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day,
                  style: textTheme.displaySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1,
                  ),
                ),
                Text(
                  suffix,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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