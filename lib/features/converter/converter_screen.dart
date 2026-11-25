import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/calendar_engine/cotsworth_converter.dart';
import '../../core/calendar_engine/cotsworth_date.dart';
import '../../core/calendar_engine/cotsworth_extensions.dart';
import '../../core/calendar_engine/cotsworth_month.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/navigation_cubit.dart';
import '../calendar/presentation/bloc/calendar_bloc.dart';
import '../calendar/presentation/bloc/calendar_event.dart';
import 'presentation/bloc/converter_cubit.dart';
import 'presentation/bloc/converter_state.dart';

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ConverterCubit, ConverterState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Gregorian ↔ Cotsworth Converter',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instant bidirectional conversion with leap-year validation',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<ConversionDirection>(
                          segments: const [
                            ButtonSegment(
                              value: ConversionDirection.gregorianToCotsworth,
                              label: Text('Gregorian → Cotsworth'),
                            ),
                            ButtonSegment(
                              value: ConversionDirection.cotsworthToGregorian,
                              label: Text('Cotsworth → Gregorian'),
                            ),
                          ],
                          selected: {state.direction},
                          onSelectionChanged: (s) => context
                              .read<ConverterCubit>()
                              .setDirection(s.first),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        key: const Key('converter_swap_button'),
                        tooltip: 'Swap direction',
                        onPressed: () =>
                            context.read<ConverterCubit>().swapDirection(),
                        icon: const Icon(Icons.swap_horiz_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.direction ==
                      ConversionDirection.gregorianToCotsworth)
                    _GregorianInputPanel(initialValue: state.gregorianInput)
                  else
                    const _CotsworthInputPanel(),
                  const SizedBox(height: 16),
                  if (state.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (state.result != null) _ResultCard(result: state.result!),
                  if (state.history.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Recent Conversions',
                          style: theme.textTheme.titleSmall,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              context.read<ConverterCubit>().clearHistory(),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...state.history.map(
                      (h) => Card(
                        child: ListTile(
                          dense: true,
                          title: Text(h.cotsworth.formatFull()),
                          subtitle: Text(
                            DateFormat('EEEE, MMM d, y').format(h.gregorian),
                          ),
                          trailing: IconButton(
                            tooltip: 'View on Calendar',
                            icon: const Icon(Icons.calendar_month_outlined),
                            onPressed: () {
                              context
                                  .read<CalendarBloc>()
                                  .add(CalendarJumpToDate(h.cotsworth));
                              context
                                  .read<NavigationCubit>()
                                  .select(AppDestination.home);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GregorianInputPanel extends StatefulWidget {
  const _GregorianInputPanel({required this.initialValue});
  final String initialValue;

  @override
  State<_GregorianInputPanel> createState() => _GregorianInputPanelState();
}

class _GregorianInputPanelState extends State<_GregorianInputPanel> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _GregorianInputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _ctrl.text &&
        widget.initialValue != oldWidget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _applyDate(String iso) {
    _ctrl.text = iso;
    context.read<ConverterCubit>().setGregorianInput(iso);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gregorian Date Input',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('gregorian_input_field'),
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'Date (YYYY-MM-DD)',
                hintText: '2026-06-18',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              onChanged: (v) =>
                  context.read<ConverterCubit>().setGregorianInput(v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Today'),
                  onPressed: () {
                    final now = DateTime.now();
                    final s =
                        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                    _applyDate(s);
                  },
                ),
                ActionChip(
                  label: const Text('Next Leap Day (2028-06-17)'),
                  onPressed: () => _applyDate('2028-06-17'),
                ),
                ActionChip(
                  label: const Text("New Year's Eve (Dec 31)"),
                  onPressed: () => _applyDate('${DateTime.now().year}-12-31'),
                ),
                ActionChip(
                  label: const Text('Pick Date'),
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2200),
                    );
                    if (d != null && mounted) {
                      final s =
                          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      _applyDate(s);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CotsworthInputPanel extends StatefulWidget {
  const _CotsworthInputPanel();

  @override
  State<_CotsworthInputPanel> createState() => _CotsworthInputPanelState();
}

class _CotsworthInputPanelState extends State<_CotsworthInputPanel> {
  late final TextEditingController _yearCtrl;

  @override
  void initState() {
    super.initState();
    final initialYear =
        context.read<ConverterCubit>().state.cotsworthYear ?? DateTime.now().year;
    _yearCtrl = TextEditingController(text: '$initialYear');
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterCubit>().state;
    final cubit = context.read<ConverterCubit>();
    final year = state.cotsworthYear ?? DateTime.now().year;
    if (_yearCtrl.text != '$year' && int.tryParse(_yearCtrl.text) != year) {
      _yearCtrl.text = '$year';
    }
    final isLeap = CotsworthConverter.isLeapYear(year);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cotsworth Date Input', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous year',
                  onPressed: () {
                    final next = (year - 1).clamp(1, 9999);
                    _yearCtrl.text = '$next';
                    cubit.setCotsworthYear(next);
                  },
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('cotsworth_year_field'),
                    controller: _yearCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Year'),
                    onChanged: (v) {
                      final y = int.tryParse(v);
                      if (y != null && y >= 1 && y <= 9999) {
                        cubit.setCotsworthYear(y);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Next year',
                  onPressed: () {
                    final next = (year + 1).clamp(1, 9999);
                    _yearCtrl.text = '$next';
                    cubit.setCotsworthYear(next);
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Tooltip(
              message: isLeap
                  ? 'Select date type'
                  : 'Leap Day is only available in leap years',
              child: SegmentedButton<CotsworthDayType>(
                segments: [
                  const ButtonSegment(
                    value: CotsworthDayType.regular,
                    label: Text('Regular'),
                  ),
                  ButtonSegment(
                    value: CotsworthDayType.leapDay,
                    label: const Text('Leap Day'),
                    enabled: isLeap,
                  ),
                  const ButtonSegment(
                    value: CotsworthDayType.yearDay,
                    label: Text('Year Day'),
                  ),
                ],
                selected: {state.cotsworthDayType},
                onSelectionChanged: (s) => cubit.setCotsworthDayType(s.first),
              ),
            ),
            if (state.cotsworthDayType == CotsworthDayType.regular) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<CotsworthMonth>(
                key: ValueKey(
                  'month_${state.cotsworthMonth ?? CotsworthMonth.january}',
                ),
                initialValue: state.cotsworthMonth ?? CotsworthMonth.january,
                decoration: const InputDecoration(labelText: 'Month'),
                items: CotsworthMonth.values
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          '${m.number}. ${m.fullName}',
                          style: TextStyle(
                            color: m.isSol
                                ? AppTheme.solAccent(context)
                                : null,
                            fontWeight: m.isSol ? FontWeight.w700 : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (m) {
                  if (m != null) cubit.setCotsworthMonth(m);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('day_${state.cotsworthDay.clamp(1, 28)}'),
                initialValue: state.cotsworthDay.clamp(1, 28),
                decoration: const InputDecoration(labelText: 'Day (1–28)'),
                items: List.generate(28, (i) {
                  final d = i + 1;
                  final weekday = const [
                    'Sunday',
                    'Monday',
                    'Tuesday',
                    'Wednesday',
                    'Thursday',
                    'Friday',
                    'Saturday',
                  ][(d - 1) % 7];
                  return DropdownMenuItem(
                    value: d,
                    child: Text('Day $d — $weekday'),
                  );
                }),
                onChanged: (d) {
                  if (d != null) cubit.setCotsworthDay(d);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final ({CotsworthDate cotsworth, DateTime gregorian}) result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gregFmt = DateFormat('EEEE, MMMM d, y');
    final isSol = result.cotsworth is RegularCotsworthDate &&
        (result.cotsworth as RegularCotsworthDate).month.isSol;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Converted Result', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(
              result.cotsworth.formatFull(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSol
                    ? AppTheme.solAccent(context)
                    : result.cotsworth.isIntercalary
                        ? AppTheme.intercalaryAccent(context)
                        : null,
              ),
            ),
            Text(
              result.cotsworth.weekdayLabel,
              style: theme.textTheme.bodyMedium,
            ),
            const Divider(height: 20),
            Text(
              gregFmt.format(result.gregorian),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              result.cotsworth.cycleAlignmentLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final text =
                        '${result.cotsworth.formatFull()} = ${gregFmt.format(result.gregorian)}';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Result'),
                ),
                FilledButton.icon(
                  key: const Key('view_on_calendar_button'),
                  onPressed: () {
                    context
                        .read<CalendarBloc>()
                        .add(CalendarJumpToDate(result.cotsworth));
                    context
                        .read<NavigationCubit>()
                        .select(AppDestination.home);
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('View on Calendar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
