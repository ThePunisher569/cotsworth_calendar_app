import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_state.dart';
import 'day_cell.dart';

/// 7×4 perpetual grid showing all 28 days of the focused Cotsworth month.
///
/// Uses single-letter muted weekday headers (`S M T W T F S`) matching the
/// attached reference calendar widget.
class CotsworthGrid extends StatelessWidget {
  const CotsworthGrid({super.key, this.onDayTapped});

  final VoidCallback? onDayTapped;

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        final days = state.monthDays;
        final todayGreg = state.today.toGregorian();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Column(
            key: ValueKey('${state.focusedYear}-${state.focusedMonth.number}'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: _weekdays
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: AppTheme.tabular(
                                theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final aspectRatio = width < 420
                      ? 0.84
                      : width < 680
                      ? 0.96
                      : 1.08;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 28,
                      itemBuilder: (context, index) {
                        final entry = days[index];
                        final isToday = entry.gregorian.isSameCalendarDate(
                          todayGreg,
                        );
                        final isSelected =
                            state.selectedDate is RegularCotsworthDate &&
                            state.selectedDate == entry.cotsworth;

                        return DayCell(
                          cotsworth: entry.cotsworth,
                          gregorian: entry.gregorian,
                          isToday: isToday,
                          isSelected: isSelected,
                          onTap: onDayTapped,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
