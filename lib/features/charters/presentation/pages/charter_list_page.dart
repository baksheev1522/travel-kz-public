import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/flight_model.dart';
import '../widgets/flight_card.dart';
import '../widgets/flight_filter_chip.dart';

class CharterListPage extends StatefulWidget {
  final String from;
  final String to;
  final String date;
  final String passengers;

  const CharterListPage({
    super.key,
    this.from = 'Алматы',
    this.to = 'Анталья',
    this.date = '29 апр',
    this.passengers = '2 взр',
  });

  @override
  State<CharterListPage> createState() => _CharterListPageState();
}

class _CharterListPageState extends State<CharterListPage> {
  String _selectedFilter = 'Все';
  final _filters = ['Все', 'Прямые', 'Дешёвые', 'Быстрые'];

  List<Flight> get _filtered {
    // Шаг 1 — фильтруем по городу вылета
    var all = Flight.mockFlights.where((f) {
      // Если передано конкретное направление — фильтруем и по нему
      final fromMatch = f.fromCity == widget.from;
      final toMatch = widget.to == 'Любой' || widget.to.isEmpty
          ? true
          : f.toCity == widget.to;
      return fromMatch && toMatch;
    }).toList();

    // Шаг 2 — фильтр по типу
    switch (_selectedFilter) {
      case 'Прямые':
        return all.where((f) => f.type == 'прямой').toList();
      case 'Дешёвые':
        return List.from(all)..sort((a, b) => a.price.compareTo(b.price));
      case 'Быстрые':
        return List.from(all)
          ..sort((a, b) => a.duration.compareTo(b.duration));
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flights = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // ← Показываем город вылета из формы поиска
              '${widget.from} — ${widget.to.isEmpty || widget.to == 'Любой' ? 'Все направления' : widget.to}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.date}, ${widget.passengers}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chips фильтрации по типу
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FlightFilterChip(
                    label: f,
                    selected: _selectedFilter == f,
                    onTap: () => setState(() => _selectedFilter = f),
                  ),
                )).toList(),
              ),
            ),
          ),

          // Счётчик
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Text(
                'Найдено: ${flights.length} рейсов',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
              ),
            ]),
          ),
          const Divider(height: 1),

          // Список
          Expanded(
            child: flights.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.airplanemode_inactive,
                            size: 64, color: AppColors.grey300),
                        const SizedBox(height: 16),
                        Text(
                          'Рейсы из ${widget.from} не найдены',
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Попробуйте выбрать другой город вылета',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.grey500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: flights.length,
                    itemBuilder: (_, i) => FlightCard(flight: flights[i]),
                  ),
          ),
        ],
      ),
    );
  }
}