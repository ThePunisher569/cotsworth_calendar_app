import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_month.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';

class MonthHeader extends StatelessWidget {
  const MonthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        final span = state.gregorianSpan;
        final fmt = DateFormat('MMM d');
        final spanStr =
            'Gregorian: ${fmt.format(span.start)} – ${fmt.format(span.end)}, ${state.focusedYear}';
        final isSol = state.focusedMonth.isSol;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              IconButton(
                key: const Key('prev_month_button'),
                tooltip: 'Previous month',
                onPressed: () => context
                    .read<CalendarBloc>()
                    .add(const CalendarPreviousMonth()),
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
                                    color: isSol
                                        ? AppTheme.solAccent(context)
                                        : null,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded, size: 20),
                          ],
                        ),
                        Text(
                          'Month ${state.focusedMonth.number} of 13 · $spanStr',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
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
                onPressed: () => context
                    .read<CalendarBloc>()
                    .add(const CalendarNextMonth()),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                key: const Key('today_pill_button'),
                onPressed: () => context
                    .read<CalendarBloc>()
                    .add(const CalendarJumpToToday()),
                icon: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Today'),
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
              style: theme.textTheme.titleLarge,
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
                  ? AppTheme.solAccent(context).withAlpha(30)
                  : null,
              selectedColor: theme.colorScheme.primaryContainer,
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
