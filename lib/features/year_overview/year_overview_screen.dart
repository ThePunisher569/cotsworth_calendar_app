import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/calendar_engine/cotsworth_converter.dart';
import '../../core/calendar_engine/cotsworth_month.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/navigation_cubit.dart';
import '../calendar/presentation/bloc/calendar_bloc.dart';
import '../calendar/presentation/bloc/calendar_event.dart';

class YearOverviewScreen extends StatefulWidget {
  const YearOverviewScreen({super.key});

  @override
  State<YearOverviewScreen> createState() => _YearOverviewScreenState();
}

class _YearOverviewScreenState extends State<YearOverviewScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = ResponsiveLayout.of(context);
    final crossCount = switch (screen) {
      ScreenSizeClass.mobile => 2,
      ScreenSizeClass.tablet => 3,
      ScreenSizeClass.desktop => 4,
    };
    final isLeap = CotsworthConverter.isLeapYear(_year);
    final fmt = DateFormat('MMM d');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '$_year',
                style: AppTheme.tabular(
                  theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _year++),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              if (isLeap)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Chip(
                    label: const Text('Leap Year'),
                    backgroundColor:
                        AppTheme.intercalaryAccent(context).withAlpha(30),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 13,
            itemBuilder: (context, i) {
              final month = CotsworthMonth.fromNumber(i + 1);
              final span =
                  CotsworthConverter.getMonthGregorianSpan(_year, month);
              final isSol = month.isSol;

              return Card(
                color:
                    isSol ? AppTheme.solAccent(context).withAlpha(20) : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    context.read<CalendarBloc>().add(
                          CalendarMonthYearSelected(year: _year, month: month),
                        );
                    context
                        .read<NavigationCubit>()
                        .select(AppDestination.home);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          month.fullName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSol
                                ? AppTheme.solAccent(context)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${fmt.format(span.start)} – ${fmt.format(span.end)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Month ${month.number}',
                              style: theme.textTheme.labelSmall,
                            ),
                            const Spacer(),
                            if (month == CotsworthMonth.june && isLeap)
                              _pill(
                                'Leap Day',
                                AppTheme.intercalaryAccent(context),
                              ),
                            if (month == CotsworthMonth.december)
                              _pill(
                                'Year Day',
                                AppTheme.intercalaryAccent(context),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
