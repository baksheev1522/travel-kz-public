import 'package:get_it/get_it.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/home/cubit/home_cubit.dart';
import '../../features/search/cubit/search_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Auth
  getIt.registerFactory<AuthBloc>(() => AuthBloc());

  // Home
  getIt.registerFactory<HomeCubit>(() => HomeCubit());

  // Search
  getIt.registerFactory<SearchCubit>(() => SearchCubit());
}