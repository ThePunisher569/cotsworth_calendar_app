import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_state.dart';
import 'day_cell.dart';

class CotsworthGrid extends StatelessWidget {
  const CotsworthGrid({super.key, this.onDayTapped});

  final VoidCallback? onDayTapped;

  static const _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        final days = state.monthDays;
        final todayGreg = state.today.toGregorian();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
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
                                  fontWeight: FontWeight.w700,
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
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio:
                        MediaQuery.sizeOf(context).width < 600 ? 0.8 : 0.95,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 28,
                  itemBuilder: (context, index) {
                    final entry = days[index];
                    final isToday =
                        entry.gregorian.isSameCalendarDate(todayGreg);
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
              ),
            ],
          ),
        );
      },
    );
  }
}
