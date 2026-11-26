import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';

/// Single day tile inside the 7×4 perpetual Cotsworth grid.
///
/// Styled after the dark iOS calendar widget:
/// - Today rendered with a crisp coral-red circular highlight around the date
/// - Weekend columns (Sun/Sat) subtly dimmed (`onSurfaceVariant`) vs crisp white Mon–Fri
/// - Subtle Gregorian sub-label (`MMM d`) and month-boundary dot
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
    final isWeekend =
        widget.cotsworth.weekdayIndex == 0 ||
        widget.cotsworth.weekdayIndex == 6;
    final gregLabel = DateFormat('MMM d').format(widget.gregorian);
    final fullGregLabel = DateFormat('MMMM d, y').format(widget.gregorian);

    // Gregorian month transition occurs on the 1st of a Gregorian month.
    final isMonthBoundary =
        widget.cotsworth.day > 1 && widget.gregorian.day == 1;

    final semanticLabel =
        '${widget.cotsworth.formatFull()}, ${widget.cotsworth.weekdayName}. '
        'Gregorian equivalent: $fullGregLabel. '
        'Cycle day ${widget.cotsworth.day} of 28.';

    final todayColor = AppTheme.todayAccent(context);

    final Color tileBg;
    final Color numberColor;
    final Color gregColor;

    if (widget.isSelected && !widget.isToday) {
      tileBg = todayColor.withAlpha(30);
      numberColor = todayColor;
      gregColor = todayColor.withAlpha(200);
    } else if (_isHovered && !widget.isToday) {
      tileBg = theme.colorScheme.surfaceContainerHigh;
      numberColor = isSol
          ? AppTheme.solAccent(context)
          : theme.colorScheme.onSurface;
      gregColor = theme.colorScheme.onSurfaceVariant;
    } else {
      tileBg = Colors.transparent;
      numberColor = widget.isToday
          ? Colors.white
          : isSol
          ? AppTheme.solAccent(context)
          : isWeekend
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurface;
      gregColor = widget.isToday
          ? todayColor
          : theme.colorScheme.onSurfaceVariant.withAlpha(190);
    }

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered && !widget.isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                context.read<CalendarBloc>().add(
                  CalendarDateSelected(widget.cotsworth),
                );
                widget.onTap?.call();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: tileBg,
                  border: widget.isSelected && !widget.isToday
                      ? Border.all(color: todayColor.withAlpha(140), width: 1.5)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
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
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isToday
                                  ? todayColor
                                  : theme.colorScheme.tertiary,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isToday
                                ? todayColor
                                : Colors.transparent,
                          ),
                          child: Text(
                            '${widget.cotsworth.day}',
                            style: AppTheme.tabular(
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: widget.isToday || widget.isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: numberColor,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gregLabel,
                          style: AppTheme.tabular(
                            theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9.5,
                              fontWeight: widget.isToday
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              letterSpacing: 0.1,
                              color: gregColor,
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
