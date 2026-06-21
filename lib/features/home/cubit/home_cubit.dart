import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/services/dynamic_pricing_service.dart';
import '../../../domain/entities/entities.dart';

abstract class HomeState {}
class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<Tour> hotTours;
  final List<Tour> popularTours;
  final List<Destination> destinations;
  final String selectedCity;
  HomeLoaded({
    required this.hotTours,
    required this.popularTours,
    required this.destinations,
    required this.selectedCity,
  });
}
class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}

class HomeCubit extends Cubit<HomeState> {
  final DynamicPricingService _pricing = DynamicPricingService();

  HomeCubit() : super(HomeInitial());

  static const cities = [
    'Алматы', 'Астана', 'Шымкент',
    'Актобе', 'Актау', 'Атырау',
  ];

  String _city = 'Алматы';

  Future<void> load() async {
    emit(HomeLoading());
    try {
      final allTours = await _pricing.getTodaysTours();
      final hotTours = allTours.where((t) => t.isHot).toList();
      emit(HomeLoaded(
        hotTours: hotTours,
        popularTours: allTours,
        destinations: _destinations,
        selectedCity: _city,
      ));
    } catch (e) {
      emit(HomeError('Ошибка загрузки: $e'));
    }
  }

  Future<void> changeCity(String city) async {
    _city = city;
    await load();
  }

  static final _destinations = [
    const Destination(
      id: 'd1', country: 'Турция', city: 'Анталья',
      imageUrl: 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=400',
      minPrice: 350000, toursCount: 124,
    ),
    const Destination(
      id: 'd2', country: 'Египет', city: 'Хургада',
      imageUrl: 'https://images.unsplash.com/photo-1539768942893-daf53e448371?w=400',
      minPrice: 280000, toursCount: 87,
    ),
    const Destination(
      id: 'd3', country: 'Таиланд', city: 'Пхукет',
      imageUrl: 'https://images.unsplash.com/photo-1589394815804-964ed0be2eb5?w=400',
      minPrice: 550000, toursCount: 56,
    ),
    const Destination(
      id: 'd4', country: 'ОАЭ', city: 'Дубай',
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400',
      minPrice: 420000, toursCount: 43,
    ),
    const Destination(
      id: 'd5', country: 'Мальдивы', city: 'Мале',
      imageUrl: 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=400',
      minPrice: 900000, toursCount: 22,
    ),
    const Destination(
      id: 'd6', country: 'Таиланд', city: 'Самуи',
      imageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=400',
      minPrice: 590000, toursCount: 18,
    ),
    const Destination(
      id: 'd7', country: 'Египет', city: 'Шарм-эль-Шейх',
      imageUrl: 'https://images.unsplash.com/photo-1562790879-b8d2e4a21524?w=400',
      minPrice: 320000, toursCount: 64,
    ),
  ];
}