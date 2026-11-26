import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/calendar_engine/cotsworth_converter.dart';
import '../../core/calendar_engine/cotsworth_date.dart';
import '../../core/calendar_engine/cotsworth_month.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/navigation_cubit.dart';
import '../calendar/presentation/bloc/calendar_bloc.dart';
import '../calendar/presentation/bloc/calendar_event.dart';

/// Year overview displaying all 13 Cotsworth months with compact 7×4 mini-calendars,
/// inspired directly by the dark iOS multi-month reference widget.
class YearOverviewScreen extends StatefulWidget {
  const YearOverviewScreen({super.key});

  @override
  State<YearOverviewScreen> createState() => _YearOverviewScreenState();
}

class _YearOverviewScreenState extends State<YearOverviewScreen> {
  int? _selectedYear;

  static CotsworthMonth? _monthOf(CotsworthDate d) => switch (d) {
    RegularCotsworthDate(:final month) => month,
    LeapDay() => CotsworthMonth.june,
    YearDay() => CotsworthMonth.december,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = ResponsiveLayout.of(context);
    final calendarToday = context.watch<CalendarBloc>().state.today;
    final year = _selectedYear ?? calendarToday.year;

    final crossCount = switch (screen) {
      ScreenSizeClass.mobile => 2,
      ScreenSizeClass.tablet => 3,
      ScreenSizeClass.desktop => 4,
    };
    final isLeap = CotsworthConverter.isLeapYear(year);
    final fmt = DateFormat('MMM d');
    final todayMonth = _monthOf(calendarToday);
    final todayDay = calendarToday is RegularCotsworthDate
        ? calendarToday.day
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous year',
                onPressed: () =>
                    setState(() => _selectedYear = (year - 1).clamp(1, 9999)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '$year',
                style: AppTheme.tabular(
                  theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next year',
                onPressed: () =>
                    setState(() => _selectedYear = (year + 1).clamp(1, 9999)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              if (isLeap)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.intercalaryAccent(context).withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.intercalaryAccent(context)
                            .withAlpha(80),
                      ),
                    ),
                    child: Text(
                      'Leap Year',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.intercalaryAccent(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              mainAxisExtent: screen == ScreenSizeClass.mobile ? 182 : 190,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 13,
            itemBuilder: (context, i) {
              final month = CotsworthMonth.fromNumber(i + 1);
              final span = CotsworthConverter.getMonthGregorianSpan(
                year,
                month,
              );
              final isSol = month.isSol;
              final isCurrentMonth =
                  year == calendarToday.year && month == todayMonth;

              return _MiniMonthCard(
                year: year,
                month: month,
                spanLabel:
                    '${fmt.format(span.start)} – ${fmt.format(span.end)}',
                isSol: isSol,
                isCurrentMonth: isCurrentMonth,
                todayDay: isCurrentMonth ? todayDay : null,
                intercalaryLabel: month == CotsworthMonth.june && isLeap
                    ? 'Leap Day'
                    : month == CotsworthMonth.december
                    ? 'Year Day'
                    : null,
                onTap: () {
                  context.read<CalendarBloc>().add(
                    CalendarMonthYearSelected(year: year, month: month),
                  );
                  context.read<NavigationCubit>().select(AppDestination.home);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MiniMonthCard extends StatelessWidget {
  const _MiniMonthCard({
    required this.year,
    required this.month,
    required this.spanLabel,
    required this.isSol,
    required this.isCurrentMonth,
    required this.todayDay,
    required this.intercalaryLabel,
    required this.onTap,
  });

  final int year;
  final CotsworthMonth month;
  final String spanLabel;
  final bool isSol;
  final bool isCurrentMonth;
  final int? todayDay;
  final String? intercalaryLabel;
  final VoidCallback onTap;

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayColor = AppTheme.todayAccent(context);
    final headerColor = isSol
        ? AppTheme.solAccent(context)
        : isCurrentMonth
        ? todayColor
        : theme.colorScheme.onSurface;

    return Card(
      color: isSol
          ? AppTheme.solAccent(context).withAlpha(14)
          : theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isCurrentMonth
              ? todayColor.withAlpha(110)
              : theme.colorScheme.outlineVariant,
          width: isCurrentMonth ? 1.25 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      month.shortName.toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: headerColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (intercalaryLabel != null)
                    _pill(
                      intercalaryLabel!,
                      AppTheme.intercalaryAccent(context),
                    )
                  else
                    Text(
                      'M${month.number}',
                      style: AppTheme.tabular(
                        theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              // Weekday header row
              Row(
                children: _weekdays
                    .map(
                      (w) => Expanded(
                        child: Center(
                          child: Text(
                            w,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 4),
              // Compact 4 rows × 7 days perpetual grid
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (week) {
                    return Row(
                      children: List.generate(7, (wd) {
                        final day = week * 7 + wd + 1;
                        final isToday = day == todayDay;
                        final isWeekend = wd == 0 || wd == 6;

                        return Expanded(
                          child: Center(
                            child: Container(
                              width: 17,
                              height: 17,
                              alignment: Alignment.center,
                              decoration: isToday
                                  ? BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: todayColor,
                                    )
                                  : null,
                              child: Text(
                                '$day',
                                style: AppTheme.tabular(
                                  theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9.5,
                                    height: 1.0,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isToday
                                        ? Colors.white
                                        : isWeekend
                                        ? theme.colorScheme.onSurfaceVariant
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                spanLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.1,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8.5,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
