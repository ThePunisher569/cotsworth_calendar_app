import 'package:intl/intl.dart';

import '../calendar_engine/cotsworth_date.dart';

/// Shared clipboard formatter producing consistent dual-calendar snippets.
abstract final class DateClipboardFormatter {
  static final DateFormat _gregFmt = DateFormat('EEEE, MMMM d, y');

  /// Formats a dual-date snippet matching:
  /// `Actual Calendar Date -> <Gregorian_Date>\n13-Month Calendar equivalent <Cotsworth_Date>`
  static String formatCopyBoth({
    required DateTime gregorian,
    required CotsworthDate cotsworth,
  }) {
    final gregLabel = _gregFmt.format(gregorian);
    final cotsLabel = cotsworth.formatFull();
    return 'Actual Calendar Date -> $gregLabel\n'
        '13-Month Calendar equivalent $cotsLabel';
  }
}
