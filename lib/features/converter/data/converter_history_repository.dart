import '../../../core/calendar_engine/cotsworth_converter.dart';
import '../../../core/calendar_engine/cotsworth_date.dart';
import '../../../core/storage/local_storage_service.dart';

class ConverterHistoryRepository {
  ConverterHistoryRepository(this._storage);

  static const int maxHistoryItems = 5;
  final LocalStorageService _storage;

  List<({CotsworthDate cotsworth, DateTime gregorian})> loadHistory() {
    final raw = _storage.getConverterHistory();
    final results = <({CotsworthDate cotsworth, DateTime gregorian})>[];
    for (final entry in raw) {
      final y = entry['y'];
      final m = entry['m'];
      final d = entry['d'];
      if (y is int && m is int && d is int) {
        try {
          final greg = DateTime(y, m, d);
          final cotsworth = CotsworthConverter.fromGregorian(greg);
          results.add((cotsworth: cotsworth, gregorian: greg));
        } catch (_) {
          // Ignore malformed entries
        }
      }
    }
    return results;
  }

  Future<void> saveHistory(
    List<({CotsworthDate cotsworth, DateTime gregorian})> items,
  ) {
    final serialized = items.take(maxHistoryItems).map((item) {
      return <String, dynamic>{
        'y': item.gregorian.year,
        'm': item.gregorian.month,
        'd': item.gregorian.day,
      };
    }).toList();
    return _storage.saveConverterHistory(serialized);
  }
}
