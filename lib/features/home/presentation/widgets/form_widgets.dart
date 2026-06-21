import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  const HomeTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -4,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeFormField extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final VoidCallback onTap;

  const HomeFormField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: 3),
            Text(
              value.isNotEmpty ? value : (hint ?? label),
              style: AppTextStyles.titleMedium.copyWith(
                color: value.isNotEmpty ? AppColors.grey900 : AppColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const CounterButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.grey200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon, size: 18,
          color: onTap != null ? Colors.white : AppColors.grey400,
        ),
      ),
    );
  }
}