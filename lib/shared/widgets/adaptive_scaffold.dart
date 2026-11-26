import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/theme_cubit.dart';
import '../../core/utils/responsive_layout.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/converter/converter_screen.dart';
import '../../features/year_overview/year_overview_screen.dart';
import 'cotsworth_logo.dart';
import 'guest_account_badge.dart';
import 'navigation_cubit.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key});

  static const _destinations = <({IconData icon, String label})>[
    (icon: Icons.calendar_month_rounded, label: 'Home'),
    (icon: Icons.swap_horiz_rounded, label: 'Convert'),
    (icon: Icons.grid_view_rounded, label: 'Year View'),
  ];

  @override
  Widget build(BuildContext context) {
    final screen = ResponsiveLayout.of(context);
    final navState = context.watch<NavigationCubit>().state;
    final isDark = context.watch<ThemeCubit>().isDarkMode;
    final selectedIndex = navState.tabIndex;

    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _buildBody(selectedIndex),
    );

    if (screen == ScreenSizeClass.mobile) {
      return Scaffold(
        appBar: AppBar(
          title: const CotsworthLogo(size: 30, showWordmark: true),
          leading: Builder(
            builder: (ctx) => IconButton(
              key: const Key('drawer_menu_button'),
              tooltip: 'Navigation Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
          actions: [
            IconButton(
              key: const Key('theme_toggle_button'),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        drawer: _buildDrawer(context, selectedIndex, isDark),
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) =>
              context.read<NavigationCubit>().selectIndex(i),
          destinations: _destinations
              .map(
                (d) =>
                    NavigationDestination(icon: Icon(d.icon), label: d.label),
              )
              .toList(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const CotsworthLogo(size: 32, showWordmark: true),
        actions: [
          IconButton(
            key: const Key('theme_toggle_button'),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: GuestAccountBadge(compact: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) =>
                context.read<NavigationCubit>().selectIndex(i),
            extended: screen == ScreenSizeClass.desktop,
            labelType: screen == ScreenSizeClass.tablet
                ? NavigationRailLabelType.selected
                : NavigationRailLabelType.none,
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: isDark
                            ? 'Switch to Light Mode'
                            : 'Switch to Dark Mode',
                        onPressed: () =>
                            context.read<ThemeCubit>().toggleTheme(),
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        tooltip: 'Sign Out',
                        onPressed: () => context.read<AuthCubit>().logout(),
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildBody(int index) {
    return switch (index) {
      0 => const CalendarScreen(key: ValueKey('calendar')),
      1 => const ConverterScreen(key: ValueKey('converter')),
      2 => const YearOverviewScreen(key: ValueKey('year_overview')),
      _ => const CalendarScreen(key: ValueKey('calendar')),
    };
  }

  Drawer _buildDrawer(BuildContext context, int selectedIndex, bool isDark) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: CotsworthLogo(size: 36, showWordmark: true),
            ),
            const Divider(),
            ...List.generate(_destinations.length, (i) {
              final d = _destinations[i];
              return ListTile(
                leading: Icon(d.icon),
                title: Text(d.label),
                selected: selectedIndex == i,
                onTap: () {
                  context.read<NavigationCubit>().selectIndex(i);
                  Navigator.of(context).pop();
                },
              );
            }),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GuestAccountBadge(
                onLogout: () {
                  Navigator.of(context).pop();
                  context.read<AuthCubit>().logout();
                },
              ),
            ),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              title: Text(
                isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              ),
              onTap: () => context.read<ThemeCubit>().toggleTheme(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
