import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/calendar_engine/cotsworth_date.dart';
import '../../core/calendar_engine/cotsworth_extensions.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/cotsworth_logo.dart';
import 'presentation/bloc/calendar_bloc.dart';
import 'presentation/bloc/calendar_event.dart';
import 'presentation/bloc/calendar_state.dart';
import 'presentation/widgets/cotsworth_grid.dart';
import 'presentation/widgets/day_detail_sheet.dart';
import 'presentation/widgets/intercalary_banner.dart';
import 'presentation/widgets/month_header.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  void _openDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<CalendarBloc>(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: DayDetailSheet(
              onAfterNavigate: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final calendarBody = Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final bloc = context.read<CalendarBloc>();
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          bloc.add(const CalendarPreviousMonth());
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          bloc.add(const CalendarNextMonth());
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.keyT) {
          bloc.add(const CalendarJumpToToday());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Home H1 Heading + Logo + 28-Day Cycle Alignment Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const CotsworthLogo(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Cotsworth 13-Month Calendar',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: isDesktop ? 26 : 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '12 Months + Sol · 28-Day Lunar & Menstrual Cycle Aligned',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Floating iOS-style calendar widget card containing MonthHeader + Grid
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
                child: Column(
                  children: [
                    const MonthHeader(),
                    const SizedBox(height: 4),
                    CotsworthGrid(
                      onDayTapped: isDesktop
                          ? null
                          : () => _openDetailsBottomSheet(context),
                    ),
                  ],
                ),
              ),
            ),
            IntercalaryBanner(
              onBannerTapped: isDesktop
                  ? null
                  : () => _openDetailsBottomSheet(context),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: calendarBody),
          const VerticalDivider(width: 1),
          const Expanded(
            flex: 2,
            child: SingleChildScrollView(child: DayDetailSheet()),
          ),
        ],
      );
    }

    // Mobile & Tablet: Selected-date summary bar at bottom that expands into modal sheet
    return Column(
      children: [
        Expanded(child: calendarBody),
        _MobileSummaryBar(onTap: () => _openDetailsBottomSheet(context)),
      ],
    );
  }
}

class _MobileSummaryBar extends StatelessWidget {
  const _MobileSummaryBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        final date = state.selectedDate;
        final gregStr = DateFormat('EEE, MMM d, y').format(date.toGregorian());
        final cyclePhase = date is RegularCotsworthDate
            ? date.cyclePhase.title
            : date.cycleAlignmentLabel;

        return Material(
          color: theme.colorScheme.surfaceContainer,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.75,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(28),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event_note_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${date.formatFull()} · $gregStr',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cyclePhase,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.expand_less_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
