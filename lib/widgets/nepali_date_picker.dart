// lib/widgets/nepali_date_picker.dart
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class NepaliDatePicker extends StatefulWidget {
  final Function(String) onDateSelected;
  final String initialDate;

  const NepaliDatePicker({
    super.key,
    required this.onDateSelected,
    required this.initialDate,
  });

  @override
  State<NepaliDatePicker> createState() => _NepaliDatePickerState();
}

class _NepaliDatePickerState extends State<NepaliDatePicker> {
  late int selectedYear;
  late int selectedMonth;
  late int selectedDay;
  
  // Current date in BS
  late int currentYear;
  late int currentMonth;
  late int currentDay;

  // Days in each Nepali month (approximate)
  final List<int> _daysInMonth = [31, 32, 31, 32, 31, 30, 30, 29, 30, 29, 30, 30];

  @override
  void initState() {
    super.initState();
    _initializeDates();
  }

  void _initializeDates() {
    // Get current date in BS (simplified)
    final now = DateTime.now();
    int bsYear = now.year + 56;
    int bsMonth = now.month + 8;
    int bsDay = now.day;
    
    if (bsMonth > 12) {
      bsMonth = bsMonth - 12;
      bsYear = bsYear + 1;
    }
    
    if (now.day > 15) {
      bsDay = now.day - 15;
    } else {
      bsDay = now.day + 16;
      if (bsMonth == 1) {
        bsMonth = 12;
        bsYear = bsYear - 1;
      } else {
        bsMonth = bsMonth - 1;
      }
    }
    
    currentYear = bsYear;
    currentMonth = bsMonth;
    currentDay = bsDay;

    // Parse initial date or use current
    if (widget.initialDate.isNotEmpty) {
      try {
        final parts = widget.initialDate.split('/');
        if (parts.length == 3) {
          selectedYear = int.parse(parts[0]);
          selectedMonth = int.parse(parts[1]);
          selectedDay = int.parse(parts[2]);
          return;
        }
      } catch (e) {}
    }
    
    selectedYear = currentYear;
    selectedMonth = currentMonth;
    selectedDay = currentDay;
  }

  int getDaysInMonth(int year, int month) {
    // Simplified - for production use proper Nepali calendar
    return _daysInMonth[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year and Month Selector
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  items: List.generate(100, (index) {
                    final year = currentYear - 50 + index;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Year (BS)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedMonth,
                  items: List.generate(12, (index) {
                    final month = index + 1;
                    return DropdownMenuItem(
                      value: month,
                      child: Text(AppConfig.getNepaliMonth(month)),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value!;
                      // Ensure day is valid for new month
                      final maxDay = getDaysInMonth(selectedYear, selectedMonth);
                      if (selectedDay > maxDay) {
                        selectedDay = maxDay;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day Selector - Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: getDaysInMonth(selectedYear, selectedMonth),
            itemBuilder: (context, index) {
              final day = index + 1;
              final isSelected = day == selectedDay;
              final isToday = day == currentDay && 
                              selectedMonth == currentMonth && 
                              selectedYear == currentYear;

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedDay = day;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? colorScheme.primary 
                        : isToday 
                            ? colorScheme.primaryContainer.withValues(alpha: 0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday 
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
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final selectedDate = '$selectedYear/${selectedMonth.toString().padLeft(2, '0')}/${selectedDay.toString().padLeft(2, '0')}';
                    widget.onDateSelected(selectedDate);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Select'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}