import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_converter.dart';
import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_extensions.dart';
import '../../../../core/calendar_engine/cotsworth_month.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion_cubit.dart';
import '../../../../shared/widgets/smooth_page_transitions.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_state.dart';
import 'day_cell.dart';

/// 7×4 perpetual grid showing all 28 days of the focused Cotsworth month.
///
/// Memoizes the 28 paired month days by `(year, month)` and wraps the grid
/// in a [RepaintBoundary] so nearby animations never invalidate day tiles.
class CotsworthGrid extends StatefulWidget {
  const CotsworthGrid({super.key, this.onDayTapped});

  final VoidCallback? onDayTapped;

  @override
  State<CotsworthGrid> createState() => _CotsworthGridState();
}

class _CotsworthGridState extends State<CotsworthGrid> {
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  int? _cachedYear;
  CotsworthMonth? _cachedMonth;
  late List<({RegularCotsworthDate cotsworth, DateTime gregorian})> _cachedDays;

  List<({RegularCotsworthDate cotsworth, DateTime gregorian})> _getMonthDays(
    int year,
    CotsworthMonth month,
  ) {
    if (_cachedYear != year || _cachedMonth != month) {
      _cachedYear = year;
      _cachedMonth = month;
      _cachedDays = CotsworthConverter.getMonthDays(year, month);
    }
    return _cachedDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MotionCubit.shouldReduceMotion(context);

    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        final days = _getMonthDays(state.focusedYear, state.focusedMonth);
        final todayGreg = state.today.toGregorian();

        final gridContent = Column(
          key: ValueKey('${state.focusedYear}-${state.focusedMonth.number}'),
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
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
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final aspectRatio = width < 380
                    ? 0.80
                    : width < 520
                    ? 0.88
                    : width < 720
                    ? 0.98
                    : 1.08;
                return Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
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
                        onTap: widget.onDayTapped,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );

        return RepaintBoundary(
          child: reduceMotion
              ? gridContent
              : AnimatedSwitcher(
                  duration: AppMotion.fastDuration,
                  switchInCurve: AppMotion.transitionCurve,
                  switchOutCurve: Curves.easeInCubic,
                  child: gridContent,
                ),
        );
      },
    );
  }
}
