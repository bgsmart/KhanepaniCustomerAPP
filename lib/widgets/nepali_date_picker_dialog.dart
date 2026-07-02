// lib/widgets/nepali_date_picker_dialog.dart
import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

class NepaliDatePickerDialog extends StatefulWidget {
  final NepaliDateTime initialDate;
  final NepaliDateTime firstDate;
  final NepaliDateTime lastDate;
  final Function(NepaliDateTime) onDateSelected;

  const NepaliDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
  });

  @override
  State<NepaliDatePickerDialog> createState() => _NepaliDatePickerDialogState();
}

class _NepaliDatePickerDialogState extends State<NepaliDatePickerDialog> {
  late int selectedYear;
  late int selectedMonth;
  late int selectedDay;

  final List<String> _nepaliDays = ['आइत', 'सोम', 'मंगल', 'बुध', 'बिहि', 'शुक्र', 'शनि'];
  final List<String> _nepaliMonths = [
    'बैशाख', 'जेठ', 'असार', 'साउन', 
    'भदौ', 'असोज', 'कात्तिक', 'मंसिर', 
    'पुष', 'माघ', 'फागुन', 'चैत'
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;
  }

  int getDaysInMonth(int year, int month) {
    try {
      final date = NepaliDateTime(year, month, 1);
      final nextMonth = month == 12 ? 1 : month + 1;
      final nextYear = month == 12 ? year + 1 : year;
      final nextDate = NepaliDateTime(nextYear, nextMonth, 1);
      final diff = nextDate.difference(date).inDays;
      return diff.toInt();
    } catch (e) {
      final daysInMonth = [31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30];
      return daysInMonth[month - 1];
    }
  }

  int getFirstDayOfMonth(int year, int month) {
    try {
      final date = NepaliDateTime(year, month, 1);
      return date.weekday % 7;
    } catch (e) {
      final refDate = NepaliDateTime(2080, 1, 1);
      final targetDate = NepaliDateTime(year, month, 1);
      final diffDays = targetDate.difference(refDate).inDays;
      return (diffDays % 7).toInt();
    }
  }

  void _previousMonth() {
    setState(() {
      if (selectedMonth == 1) {
        selectedMonth = 12;
        selectedYear--;
      } else {
        selectedMonth--;
      }
      final maxDay = getDaysInMonth(selectedYear, selectedMonth);
      if (selectedDay > maxDay) {
        selectedDay = maxDay;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (selectedMonth == 12) {
        selectedMonth = 1;
        selectedYear++;
      } else {
        selectedMonth++;
      }
      final maxDay = getDaysInMonth(selectedYear, selectedMonth);
      if (selectedDay > maxDay) {
        selectedDay = maxDay;
      }
    });
  }

  void _selectDate(int day) {
    setState(() {
      selectedDay = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final daysInMonth = getDaysInMonth(selectedYear, selectedMonth);
    final firstDayOfWeek = getFirstDayOfMonth(selectedYear, selectedMonth);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'मिति चयन गर्नुहोस्',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Month/Year Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: _previousMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  '${_nepaliMonths[selectedMonth - 1]} ${selectedYear.toString()}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  onPressed: _nextMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Day Headers
            Row(
              children: _nepaliDays.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: firstDayOfWeek + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstDayOfWeek) {
                  return const SizedBox();
                }
                final day = index - firstDayOfWeek + 1;
                final isSelected = day == selectedDay;
                final isToday = day == NepaliDateTime.now().day &&
                    selectedMonth == NepaliDateTime.now().month &&
                    selectedYear == NepaliDateTime.now().year;

                return InkWell(
                  onTap: () => _selectDate(day),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday
                              ? colorScheme.primaryContainer.withValues(alpha: 0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: colorScheme.primary, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'रद्द गर्नुहोस्',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final selectedDate = NepaliDateTime(
                      selectedYear,
                      selectedMonth,
                      selectedDay,
                    );
                    widget.onDateSelected(selectedDate);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'पुष्टि गर्नुहोस्',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white,
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