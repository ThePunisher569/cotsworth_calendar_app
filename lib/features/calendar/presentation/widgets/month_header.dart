import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_month.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';

/// Month navigation header with current-month red accent and responsive Today pill.
class MonthHeader extends StatelessWidget {
  const MonthHeader({super.key});

  static CotsworthMonth _monthOf(CotsworthDate d) => switch (d) {
    RegularCotsworthDate(:final month) => month,
    LeapDay() => CotsworthMonth.june,
    YearDay() => CotsworthMonth.december,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 430;

    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        final span = state.gregorianSpan;
        final fmt = DateFormat('MMM d');
        final spanStr = isNarrow
            ? '${fmt.format(span.start)} – ${fmt.format(span.end)}'
            : 'Gregorian: ${fmt.format(span.start)} – ${fmt.format(span.end)}, ${state.focusedYear}';
        final isSol = state.focusedMonth.isSol;
        final isCurrentMonth =
            state.focusedYear == state.today.year &&
            state.focusedMonth == _monthOf(state.today);

        final titleColor = isSol
            ? AppTheme.solAccent(context)
            : isCurrentMonth
            ? AppTheme.todayAccent(context)
            : theme.colorScheme.onSurface;

        return Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 10, 8),
          child: Row(
            children: [
              IconButton(
                key: const Key('prev_month_button'),
                tooltip: 'Previous month',
                visualDensity: isNarrow ? VisualDensity.compact : null,
                onPressed: () => context.read<CalendarBloc>().add(
                  const CalendarPreviousMonth(),
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showMonthPicker(context, state),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '${state.focusedMonth.fullName} ${state.focusedYear}',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.tabular(
                                  theme.textTheme.titleLarge?.copyWith(
                                    fontSize: isNarrow ? 18 : 20,
                                    color: titleColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Month ${state.focusedMonth.number} of 13 · $spanStr',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('next_month_button'),
                tooltip: 'Next month',
                visualDensity: isNarrow ? VisualDensity.compact : null,
                onPressed: () =>
                    context.read<CalendarBloc>().add(const CalendarNextMonth()),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                key: const Key('today_pill_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.todayAccent(context).withAlpha(28),
                  foregroundColor: AppTheme.todayAccent(context),
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 10 : 14,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.read<CalendarBloc>().add(
                  const CalendarJumpToToday(),
                ),
                icon: const Icon(Icons.today_rounded, size: 15),
                label: Text(
                  'Today',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.todayAccent(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMonthPicker(BuildContext context, CalendarState state) {
    showDialog<void>(
      context: context,
      builder: (_) => _MonthPickerDialog(
        currentYear: state.focusedYear,
        currentMonth: state.focusedMonth,
        onSelected: (year, month) {
          context.read<CalendarBloc>().add(
            CalendarMonthYearSelected(year: year, month: month),
          );
        },
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.currentYear,
    required this.currentMonth,
    required this.onSelected,
  });

  final int currentYear;
  final CotsworthMonth currentMonth;
  final void Function(int year, CotsworthMonth month) onSelected;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.currentYear;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _year--),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              '$_year',
              textAlign: TextAlign.center,
              style: AppTheme.tabular(theme.textTheme.titleLarge),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _year++),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CotsworthMonth.values.map((m) {
            final isSelected =
                m == widget.currentMonth && _year == widget.currentYear;
            final isSol = m.isSol;
            return ChoiceChip(
              label: Text(m.fullName),
              selected: isSelected,
              backgroundColor: isSol
                  ? AppTheme.solAccent(context).withAlpha(28)
                  : null,
              selectedColor: theme.colorScheme.primary.withAlpha(45),
              onSelected: (_) {
                widget.onSelected(_year, m);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
