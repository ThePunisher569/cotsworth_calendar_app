import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_extensions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/navigation_cubit.dart';
import '../../../converter/presentation/bloc/converter_cubit.dart';
import '../bloc/calendar_bloc.dart';

class DayDetailSheet extends StatelessWidget {
  const DayDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<CalendarBloc>().state;
    final date = state.selectedDate;
    final greg = date.toGregorian();
    final gregFmt = DateFormat('EEEE, MMMM d, y');

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.nightlight_round,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Gregorian Equivalent',
              value: gregFmt.format(greg),
            ),
            const SizedBox(height: 12),
            Text(
              'Year Progress (${(date.yearProgress * 100).toStringAsFixed(1)}%)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: date.yearProgress),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Day ${date.dayOfYear} of ${date.totalDaysInYear}'),
                if (date.isLeapYear) _chip('Leap Year'),
                _chip(date.cycleAlignmentLabel),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final text =
                          '${date.formatFull()} = ${gregFmt.format(greg)}';
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied both dates')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Both'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      context.read<ConverterCubit>().openFromCalendar(date);
                      context
                          .read<NavigationCubit>()
                          .select(AppDestination.convert);
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Open in Converter'),
                  ),
                ),
              ],
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
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
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
