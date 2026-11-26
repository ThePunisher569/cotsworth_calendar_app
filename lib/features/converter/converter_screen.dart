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
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Gregorian → Cotsworth',
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: ConversionDirection.cotsworthToGregorian,
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Cotsworth → Gregorian',
                                  maxLines: 1,
                                ),
                              ),
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
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainer,
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
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
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
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
                          'RECENT CONVERSIONS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              context.read<ConverterCubit>().clearHistory(),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...state.history.map(
                      (h) => Card(
                        child: ListTile(
                          dense: true,
                          title: Text(
                            h.cotsworth.formatFull(),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('EEEE, MMM d, y').format(h.gregorian),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'View on Calendar',
                            icon: Icon(
                              Icons.calendar_month_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () {
                              context.read<CalendarBloc>().add(
                                CalendarJumpToDate(h.cotsworth),
                              );
                              context.read<NavigationCubit>().select(
                                AppDestination.home,
                              );
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
    final theme = Theme.of(context);
    final now = context.read<ConverterCubit>().now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GREGORIAN DATE INPUT',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('gregorian_input_field'),
              controller: _ctrl,
              style: AppTheme.tabular(theme.textTheme.bodyLarge),
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
                  onPressed: () => _applyDate('${now.year}-12-31'),
                ),
                ActionChip(
                  label: const Text('Pick Date'),
                  avatar: const Icon(Icons.date_range_rounded, size: 18),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: now,
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
  final FocusNode _yearFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ConverterCubit>();
    final initialYear = cubit.state.cotsworthYear ?? cubit.now().year;
    _yearCtrl = TextEditingController(text: '$initialYear');
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterCubit>().state;
    final cubit = context.read<ConverterCubit>();
    final year = state.cotsworthYear ?? cubit.now().year;
    final isLeap = CotsworthConverter.isLeapYear(year);
    final theme = Theme.of(context);

    return BlocListener<ConverterCubit, ConverterState>(
      listenWhen: (prev, curr) => prev.cotsworthYear != curr.cotsworthYear,
      listener: (context, nextState) {
        final nextYear = nextState.cotsworthYear;
        if (nextYear == null) return;
        // Never overwrite while user is actively editing the year text field.
        if (!_yearFocus.hasFocus && _yearCtrl.text != '$nextYear') {
          _yearCtrl.text = '$nextYear';
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COTSWORTH DATE INPUT',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
                      focusNode: _yearFocus,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: AppTheme.tabular(theme.textTheme.titleMedium),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(labelText: 'Year'),
                      onChanged: (v) {
                        final y = int.tryParse(v);
                        if (y != null && y >= 1 && y <= 9999) {
                          // Only record history once a realistic 4-digit year is typed.
                          cubit.setCotsworthYear(
                            y,
                            recordHistory: v.length == 4,
                          );
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
                child: SizedBox(
                  width: double.infinity,
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
                    onSelectionChanged: (s) =>
                        cubit.setCotsworthDayType(s.first),
                  ),
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
    final isSol =
        result.cotsworth is RegularCotsworthDate &&
        (result.cotsworth as RegularCotsworthDate).month.isSol;

    final accent = isSol
        ? AppTheme.solAccent(context)
        : result.cotsworth.isIntercalary
        ? AppTheme.intercalaryAccent(context)
        : theme.colorScheme.primary;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent.withAlpha(110), width: 1.25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONVERTED RESULT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 0.9,
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.cotsworth.formatFull(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSol || result.cotsworth.isIntercalary
                    ? accent
                    : theme.colorScheme.onSurface,
              ),
            ),
            Text(
              result.cotsworth.weekdayLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
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
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: const Text('Copy Result'),
                ),
                FilledButton.icon(
                  key: const Key('view_on_calendar_button'),
                  onPressed: () {
                    context.read<CalendarBloc>().add(
                      CalendarJumpToDate(result.cotsworth),
                    );
                    context.read<NavigationCubit>().select(AppDestination.home);
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 17),
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
