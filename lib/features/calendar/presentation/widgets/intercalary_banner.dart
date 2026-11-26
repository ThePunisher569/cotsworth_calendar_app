import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';

/// Banner cards for intercalary days (Leap Day after June, Year Day after December).
class IntercalaryBanner extends StatelessWidget {
  const IntercalaryBanner({super.key, this.onBannerTapped});

  final VoidCallback? onBannerTapped;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        final banners = <Widget>[];

        if (state.showLeapDayBanner) {
          banners.add(
            _buildBanner(
              context: context,
              title: 'Leap Day',
              subtitle:
                  'Intercalary Day (No Weekday) · Gregorian: June 17, ${state.focusedYear}',
              date: LeapDay(year: state.focusedYear),
              isSelected:
                  state.selectedDate is LeapDay &&
                  state.selectedDate.year == state.focusedYear,
            ),
          );
        }

        if (state.showYearDayBanner) {
          banners.add(
            _buildBanner(
              context: context,
              title: 'Year Day',
              subtitle:
                  'Intercalary Day (No Weekday) · Gregorian: December 31, ${state.focusedYear}',
              date: YearDay(year: state.focusedYear),
              isSelected:
                  state.selectedDate is YearDay &&
                  state.selectedDate.year == state.focusedYear,
            ),
          );
        }

        if (banners.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(children: banners),
        );
      },
    );
  }

  Widget _buildBanner({
    required BuildContext context,
    required String title,
    required String subtitle,
    required CotsworthDate date,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final accent = AppTheme.intercalaryAccent(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<CalendarBloc>().add(CalendarDateSelected(date));
            onBannerTapped?.call();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? accent.withAlpha(32)
                  : theme.colorScheme.surfaceContainer,
              border: Border.all(
                color: isSelected ? accent : theme.colorScheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    title == 'Leap Day'
                        ? Icons.add_circle_outline_rounded
                        : Icons.celebration_outlined,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
