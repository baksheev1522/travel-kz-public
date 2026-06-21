import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/tour_model.dart';
import '../../../domain/entities/entities.dart';

abstract class SearchState {}
class SearchInitial extends SearchState {
  final TourSearchFilter filter;
  SearchInitial({this.filter = const TourSearchFilter()});
}
class SearchLoading extends SearchState {}
class SearchLoaded extends SearchState {
  final List<Tour> tours;
  final TourSearchFilter filter;
  SearchLoaded({required this.tours, required this.filter});
}
class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  TourSearchFilter get filter {
    final s = state;
    if (s is SearchInitial) return s.filter;
    if (s is SearchLoaded)  return s.filter;
    return const TourSearchFilter();
  }

  void updateFilter(TourSearchFilter f) => emit(SearchInitial(filter: f));

  Future<void> search() async {
    final f = filter;
    emit(SearchLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    var tours = TourModel.mockList;
    if (f.destinationCountry != null) {
      tours = tours
          .where((t) => t.country == f.destinationCountry)
          .toList();
    }
    if (f.hotOnly == true) {
      tours = tours.where((t) => t.isHot).toList();
    }
    if (f.starsMin != null) {
      tours = tours.where((t) => t.stars >= f.starsMin!).toList();
    }
    emit(SearchLoaded(tours: tours, filter: f));
  }

  void reset() => emit(SearchInitial());
}