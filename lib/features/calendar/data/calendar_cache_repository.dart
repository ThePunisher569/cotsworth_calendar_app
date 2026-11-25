import '../../../core/calendar_engine/cotsworth_month.dart';
import '../../../core/storage/local_storage_service.dart';

class CalendarCacheRepository {
  CalendarCacheRepository(this._storage);
  final LocalStorageService _storage;

  ({int year, CotsworthMonth month})? getLastViewedMonth() {
    final cached = _storage.getLastViewedMonth();
    if (cached == null) return null;
    return (
      year: cached.year,
      month: CotsworthMonth.fromNumber(cached.monthNumber),
    );
  }

  Future<void> saveLastViewedMonth(int year, CotsworthMonth month) =>
      _storage.saveLastViewedMonth(year, month.number);
}
