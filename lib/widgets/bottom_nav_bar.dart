// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              Icons.dashboard,
              'Home',
              0,
              filled: currentIndex == 0,
            ),
            _buildNavItem(
              context,
              Icons.history,
              'History',
              1,
              filled: currentIndex == 1,
            ),
            _buildNavItem(
              context,
              Icons.camera_alt,
              'Reading',
              2,
              filled: currentIndex == 2,
              isCenter: true,
            ),
            _buildNavItem(
              context,
              Icons.receipt_long,
              'Bills',
              3,
              filled: currentIndex == 3,
            ),
            _buildNavItem(
              context,
              Icons.support_agent,
              'Support',
              4,
              filled: currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index, {
    bool filled = false,
    bool isCenter = false,
  }) {
    final isSelected = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    if (isCenter) {
      return GestureDetector(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.secondaryContainer : colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? colorScheme.onSecondaryContainer 
                    : colorScheme.onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}