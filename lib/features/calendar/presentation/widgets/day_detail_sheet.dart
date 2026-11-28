import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_clipboard_formatter.dart';
import '../../../../shared/navigation/navigation_cubit.dart';
import '../../../converter/presentation/bloc/converter_cubit.dart';
import '../bloc/calendar_bloc.dart';

/// Detail panel showing full Cotsworth & 28-day cycle metadata for the selected day.
///
/// Embedded directly on desktop, or opened inside a modal bottom sheet on
/// mobile/tablet with [onAfterNavigate] closing the sheet automatically.
class DayDetailSheet extends StatelessWidget {
  const DayDetailSheet({super.key, this.onAfterNavigate});

  final VoidCallback? onAfterNavigate;

  static final DateFormat _gregFmt = DateFormat('EEEE, MMMM d, y');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = context.select<CalendarBloc, CotsworthDate>(
      (bloc) => bloc.state.selectedDate,
    );
    final greg = date.toGregorian();

    return Card(
      margin: const EdgeInsetsDirectional.all(12),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.all(7),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.nightlight_round,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Date & 28-Day Cycle Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _InfoRow(
              label: 'Cotsworth Date',
              value: date.isIntercalary
                  ? '${date.formatFull()} · Blank Day'
                  : '${date.weekdayLabel}, ${date.formatFull()}',
              accent: date is RegularCotsworthDate && date.month.isSol
                  ? AppTheme.solAccent(context)
                  : date.isIntercalary
                  ? AppTheme.intercalaryAccent(context)
                  : null,
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Gregorian Equivalent',
              value: _gregFmt.format(greg),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YEAR PROGRESS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(date.yearProgress * 100).toStringAsFixed(1)}%',
                  style: AppTheme.tabular(
                    theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: date.yearProgress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Divider(height: 26),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Day ${date.dayOfYear} of ${date.totalDaysInYear}'),
                if (date.isLeapYear) _chip('Leap Year'),
                _chip(date.cycleAlignmentLabel),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final copyBtn = OutlinedButton.icon(
                  key: const Key('copy_both_button'),
                  onPressed: () {
                    final text = DateClipboardFormatter.formatCopyBoth(
                      gregorian: greg,
                      cotsworth: date,
                    );
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Copied both dates'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 3),
                        ),
                      );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: const Text('Copy Both'),
                );
                final convertBtn = FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withAlpha(32),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    context.read<ConverterCubit>().openFromCalendar(date);
                    context.read<NavigationCubit>().select(
                      AppDestination.convert,
                    );
                    onAfterNavigate?.call();
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                  label: const Text('Open in Converter'),
                );

                if (constraints.maxWidth < 330) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [copyBtn, const SizedBox(height: 8), convertBtn],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: copyBtn),
                    const SizedBox(width: 8),
                    Expanded(child: convertBtn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.accent});
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ),
      ],
    );
  }
}
