import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'core/storage/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/motion_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/calendar/data/calendar_cache_repository.dart';
import 'features/calendar/presentation/bloc/calendar_bloc.dart';
import 'features/calendar/presentation/bloc/sky_cubit.dart';
import 'features/converter/data/converter_history_repository.dart';
import 'features/converter/presentation/bloc/converter_cubit.dart';
import 'features/splash/splash_screen.dart';
import 'shared/navigation/navigation_cubit.dart';
import 'shared/widgets/adaptive_scaffold.dart';
import 'shared/widgets/smooth_page_transitions.dart';

class CotsworthApp extends StatefulWidget {
  const CotsworthApp({
    super.key,
    required this.storage,
    this.showSplash = true,
    this.enableAutoSkyFetch = true,
  });

  final LocalStorageService storage;
  final bool showSplash;
  final bool enableAutoSkyFetch;

  @override
  State<CotsworthApp> createState() => _CotsworthAppState();
}

class _CotsworthAppState extends State<CotsworthApp> {
  late bool _splashComplete;
  late final AuthRepository _authRepo;
  late final CalendarCacheRepository _calendarCache;
  late final ConverterHistoryRepository _converterHistory;

  @override
  void initState() {
    super.initState();
    _splashComplete = !widget.showSplash;
    _authRepo = AuthRepository(widget.storage);
    _calendarCache = CalendarCacheRepository(widget.storage);
    _converterHistory = ConverterHistoryRepository(widget.storage);
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalStorageService>.value(value: widget.storage),
        RepositoryProvider<AuthRepository>.value(value: _authRepo),
        RepositoryProvider<CalendarCacheRepository>.value(
          value: _calendarCache,
        ),
        RepositoryProvider<ConverterHistoryRepository>.value(
          value: _converterHistory,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(widget.storage)),
          BlocProvider(create: (_) => MotionCubit(widget.storage)),
          BlocProvider(
            create: (ctx) => SkyCubit(
              storage: widget.storage,
              themeCubit: ctx.read<ThemeCubit>(),
            ),
          ),
          BlocProvider(create: (_) => AuthCubit(_authRepo)),
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(create: (_) => CalendarBloc(_calendarCache)),
          BlocProvider(create: (_) => ConverterCubit(_converterHistory)),
        ],
        child: BlocSelector<ThemeCubit, ThemeMode, ThemeMode>(
          selector: (mode) => mode,
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'Cotsworth Calendar',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              home: !_splashComplete
                  ? SplashScreen(
                      onCompleted: () {
                        if (mounted) {
                          setState(() => _splashComplete = true);
                        }
                      },
                    )
                  : BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        return SmoothViewSwitcher(
                          child: authState is AuthAuthenticated
                              ? AdaptiveScaffold(
                                  key: const ValueKey('shell'),
                                  enableAutoSkyFetch: widget.enableAutoSkyFetch,
                                )
                              : const LoginScreen(key: ValueKey('login')),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}
