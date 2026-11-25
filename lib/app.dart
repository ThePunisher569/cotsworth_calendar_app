import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'core/storage/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/calendar/data/calendar_cache_repository.dart';
import 'features/calendar/presentation/bloc/calendar_bloc.dart';
import 'features/converter/data/converter_history_repository.dart';
import 'features/converter/presentation/bloc/converter_cubit.dart';
import 'shared/widgets/adaptive_scaffold.dart';
import 'shared/widgets/navigation_cubit.dart';

class CotsworthApp extends StatelessWidget {
  const CotsworthApp({super.key, required this.storage});

  final LocalStorageService storage;

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository(storage);
    final calendarCache = CalendarCacheRepository(storage);
    final converterHistory = ConverterHistoryRepository(storage);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalStorageService>.value(value: storage),
        RepositoryProvider<AuthRepository>.value(value: authRepo),
        RepositoryProvider<CalendarCacheRepository>.value(value: calendarCache),
        RepositoryProvider<ConverterHistoryRepository>.value(
          value: converterHistory,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(storage)),
          BlocProvider(create: (_) => AuthCubit(authRepo)),
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(create: (_) => CalendarBloc(calendarCache)),
          BlocProvider(create: (_) => ConverterCubit(converterHistory)),
        ],
        child: Builder(
          builder: (context) {
            final themeMode = context.watch<ThemeCubit>().state;
            return MaterialApp(
              title: 'Cotsworth Calendar',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              home: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  if (authState is AuthAuthenticated) {
                    return const AdaptiveScaffold();
                  }
                  return const LoginScreen();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
