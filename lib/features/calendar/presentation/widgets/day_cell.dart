import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';

class DayCell extends StatefulWidget {
  const DayCell({
    super.key,
    required this.cotsworth,
    required this.gregorian,
    required this.isToday,
    required this.isSelected,
    this.onTap,
  });

  final RegularCotsworthDate cotsworth;
  final DateTime gregorian;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<DayCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSol = widget.cotsworth.month.isSol;
    final gregLabel = DateFormat('MMM d').format(widget.gregorian);
    final fullGregLabel = DateFormat('MMMM d, y').format(widget.gregorian);

    DateTime? prevGreg;
    if (widget.cotsworth.day > 1) {
      prevGreg = RegularCotsworthDate(
        year: widget.cotsworth.year,
        month: widget.cotsworth.month,
        day: widget.cotsworth.day - 1,
      ).toGregorian();
    }
    final isMonthBoundary =
        prevGreg != null && prevGreg.month != widget.gregorian.month;

    final semanticLabel =
        '${widget.cotsworth.formatFull()}, ${widget.cotsworth.weekdayName}. '
        'Gregorian equivalent: $fullGregLabel. '
        'Cycle day ${widget.cotsworth.day} of 28.';

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered && !widget.isSelected ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                context
                    .read<CalendarBloc>()
                    .add(CalendarDateSelected(widget.cotsworth));
                widget.onTap?.call();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.isSelected
                      ? theme.colorScheme.primary
                      : widget.isToday
                          ? theme.colorScheme.primaryContainer.withAlpha(130)
                          : _isHovered
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.surfaceContainerLowest,
                  border: Border.all(
                    color: widget.isToday && !widget.isSelected
                        ? theme.colorScheme.primary
                        : _isHovered && !widget.isSelected
                            ? theme.colorScheme.outline
                            : theme.colorScheme.outlineVariant.withAlpha(100),
                    width: widget.isToday && !widget.isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 2,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMonthBoundary)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.tertiary,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                        Text(
                          '${widget.cotsworth.day}',
                          style: AppTheme.tabular(
                            theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: widget.isSelected
                                  ? theme.colorScheme.onPrimary
                                  : isSol
                                      ? AppTheme.solAccent(context)
                                      : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          gregLabel,
                          style: AppTheme.tabular(
                            theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9.5,
                              color: widget.isSelected
                                  ? theme.colorScheme.onPrimary.withAlpha(215)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
