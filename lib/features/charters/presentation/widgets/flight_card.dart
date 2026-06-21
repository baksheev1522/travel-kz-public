import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../models/flight_model.dart';

class FlightCard extends StatelessWidget {
  final Flight flight;

  const FlightCard({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    final f = flight;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.charterDetail, extra: f),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: f.tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t == 'Самый дешёвый'
                      ? const Color(0xFFE8F5E9)
                      : t == 'Чартерный рейс'
                          ? const Color(0xFFE3F2FD)
                          : AppColors.grey100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: t == 'Самый дешёвый'
                        ? const Color(0xFF2E7D32)
                        : t == 'Чартерный рейс'
                            ? const Color(0xFF1565C0)
                            : AppColors.grey700,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),

            // Route
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.departureTime,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey900,
                        )),
                    Text(f.from,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500)),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.grey300)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.flight,
                                color: Color(0xFF7B1FA2), size: 20),
                          ),
                          Expanded(child: Divider(color: AppColors.grey300)),
                        ],
                      ),
                      Text(
                        '${f.duration} | ${f.type}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(f.arrivalTime,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey900,
                        )),
                    Text(f.to,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (f.seatsLeft <= 4)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Осталось мало мест',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Divider(height: 1),
            const SizedBox(height: 10),

            // Price + cashback
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Кешбэк ${f.formattedCashback} ₸',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${f.formattedPrice} ₸',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.grey900,
                      ),
                    ),
                    Text('2 взр',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.grey500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}