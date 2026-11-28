import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/motion_cubit.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/utils/responsive_layout.dart';
import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/widgets/account_sign_out_dialog.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/converter/converter_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/year_overview/year_overview_screen.dart';
import '../navigation/navigation_cubit.dart';
import 'cotsworth_logo.dart';
import 'guest_account_badge.dart';
import 'smooth_page_transitions.dart';

/// Responsive application shell supporting Mobile, Tablet, and Desktop/Web.
///
/// On Mobile, places the animated [CotsworthLogo] cleanly in the leading/title
/// area and locates the navigation drawer trigger on the trailing (right) side
/// of the [AppBar], opening [Scaffold.endDrawer].
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, this.enableAutoSkyFetch = true});

  final bool enableAutoSkyFetch;

  static const _destinations = <({IconData icon, String label})>[
    (icon: Icons.calendar_month_rounded, label: 'Home'),
    (icon: Icons.swap_horiz_rounded, label: 'Convert'),
    (icon: Icons.grid_view_rounded, label: 'Year View'),
  ];

  void _openProfile(BuildContext context) {
    context.read<AuthCubit>().clearMessages();
    final reduce = MotionCubit.shouldReduceMotion(context, listen: false);
    Navigator.of(context).push(
      SmoothSlideFadeRoute<void>(
        reduceMotion: reduce,
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = ResponsiveLayout.of(context);
    final selectedIndex = context.select<NavigationCubit, int>(
      (cubit) => cubit.state.tabIndex,
    );
    final isDark = context.select<ThemeCubit, bool>(
      (cubit) => cubit.isDarkMode,
    );
    final reduceMotion = context.select<MotionCubit, bool>(
      (cubit) => cubit.state,
    );
    final user = context.select<AuthCubit, AuthUser?>((cubit) {
      final s = cubit.state;
      return s is AuthAuthenticated ? s.user : null;
    });

    final body = SmoothViewSwitcher(child: _buildBody(selectedIndex));

    if (screen == ScreenSizeClass.mobile) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: const CotsworthLogo(size: 30, showWordmark: true),
          actions: [
            IconButton(
              key: const Key('theme_toggle_button'),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
            Builder(
              builder: (ctx) => IconButton(
                key: const Key('drawer_menu_button'),
                tooltip: 'Navigation Menu',
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        endDrawer: _buildEndDrawer(
          context,
          selectedIndex: selectedIndex,
          isDark: isDark,
          reduceMotion: reduceMotion,
          user: user,
        ),
        body: SafeArea(top: false, child: body),
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

    final isExtended = screen == ScreenSizeClass.desktop;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
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
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: GuestAccountBadge(
              key: const Key('account_badge_compact'),
              username: user?.username ?? 'Guest',
              email: user?.email,
              isGuest: user?.isGuest ?? true,
              emailVerified: user?.emailVerified ?? false,
              compact: true,
              onTap: () => AccountSignOutDialog.show(context),
            ),
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
            extended: isExtended,
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
                alignment: AlignmentDirectional.bottomCenter,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 16),
                  child: SizedBox(
                    width: isExtended ? 228 : 64,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: isExtended
                          ? CrossAxisAlignment.stretch
                          : CrossAxisAlignment.center,
                      children: [
                        const Divider(indent: 14, endIndent: 14),
                        const SizedBox(height: 8),
                        _RailActionButton(
                          extended: isExtended,
                          icon: reduceMotion
                              ? Icons.motion_photos_off_outlined
                              : Icons.animation_rounded,
                          label: reduceMotion ? 'Motion Off' : 'Motion On',
                          tooltip: reduceMotion
                              ? 'Enable Animations'
                              : 'Reduce Motion',
                          active: !reduceMotion,
                          onTap: () => context.read<MotionCubit>().toggle(),
                        ),
                        const SizedBox(height: 6),
                        _RailActionButton(
                          extended: isExtended,
                          icon: isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          label: isDark ? 'Light Mode' : 'Dark Mode',
                          tooltip: isDark
                              ? 'Switch to Light Mode'
                              : 'Switch to Dark Mode',
                          onTap: () => context.read<ThemeCubit>().toggleTheme(),
                        ),
                        const SizedBox(height: 6),
                        _RailActionButton(
                          key: const Key('rail_sign_out_button'),
                          extended: isExtended,
                          icon: Icons.logout_rounded,
                          label: 'Sign Out',
                          tooltip: 'Sign Out',
                          destructive: true,
                          onTap: () => AccountSignOutDialog.show(context),
                        ),
                      ],
                    ),
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
      0 => CalendarScreen(
        key: const ValueKey('calendar'),
        enableAutoSkyFetch: enableAutoSkyFetch,
      ),
      1 => const ConverterScreen(key: ValueKey('converter')),
      2 => const YearOverviewScreen(key: ValueKey('year_overview')),
      _ => CalendarScreen(
        key: const ValueKey('calendar'),
        enableAutoSkyFetch: enableAutoSkyFetch,
      ),
    };
  }

  Drawer _buildEndDrawer(
    BuildContext context, {
    required int selectedIndex,
    required bool isDark,
    required bool reduceMotion,
    required AuthUser? user,
  }) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.all(16),
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
            ListTile(
              key: const Key('drawer_profile_tile'),
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Profile & Account'),
              onTap: () {
                Navigator.of(context).pop();
                _openProfile(context);
              },
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: GuestAccountBadge(
                username: user?.username ?? 'Guest',
                email: user?.email,
                isGuest: user?.isGuest ?? true,
                emailVerified: user?.emailVerified ?? false,
                onTap: () {
                  Navigator.of(context).pop();
                  AccountSignOutDialog.show(context);
                },
                onLogout: () {
                  Navigator.of(context).pop();
                  context.read<AuthCubit>().logout();
                },
              ),
            ),
            SwitchListTile.adaptive(
              secondary: Icon(
                reduceMotion
                    ? Icons.motion_photos_off_outlined
                    : Icons.animation_rounded,
              ),
              title: const Text('Reduce Motion'),
              value: reduceMotion,
              onChanged: (v) => context.read<MotionCubit>().setReduceMotion(v),
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

/// Cohesive themed pill button for the trailing [NavigationRail] utility actions.
class _RailActionButton extends StatelessWidget {
  const _RailActionButton({
    super.key,
    required this.extended,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.destructive = false,
  });

  final bool extended;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color fgColor;
    final Color bgColor;
    final Color borderColor;

    if (destructive) {
      fgColor = theme.colorScheme.primary;
      bgColor = theme.colorScheme.primary.withAlpha(24);
      borderColor = theme.colorScheme.primary.withAlpha(70);
    } else if (active) {
      fgColor = theme.colorScheme.onSurface;
      bgColor = theme.colorScheme.surfaceContainerHigh;
      borderColor = theme.colorScheme.outlineVariant;
    } else {
      fgColor = theme.colorScheme.onSurfaceVariant;
      bgColor = theme.colorScheme.surfaceContainer;
      borderColor = theme.colorScheme.outlineVariant;
    }

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: extended ? 14 : 8),
        child: Material(
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: SizedBox(
              width: extended ? double.infinity : 48,
              height: 42,
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: extended ? 14 : 0,
                ),
                child: Row(
                  mainAxisAlignment: extended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 19, color: fgColor),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 13,
                            color: fgColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
