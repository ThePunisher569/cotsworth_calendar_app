/// The 13 months of the International Fixed Calendar (Cotsworth Calendar).
///
/// Every month contains exactly 28 days (4 weeks of 7 days), totaling 364
/// regular days per year. [sol] is the 7th month inserted between [june] and
/// [july].
enum CotsworthMonth {
  january(1, 'January', 'Jan'),
  february(2, 'February', 'Feb'),
  march(3, 'March', 'Mar'),
  april(4, 'April', 'Apr'),
  may(5, 'May', 'May'),
  june(6, 'June', 'Jun'),
  sol(7, 'Sol', 'Sol'),
  july(8, 'July', 'Jul'),
  august(9, 'August', 'Aug'),
  september(10, 'September', 'Sep'),
  october(11, 'October', 'Oct'),
  november(12, 'November', 'Nov'),
  december(13, 'December', 'Dec');

  const CotsworthMonth(this.number, this.fullName, this.shortName);

  /// 1-indexed month number (1 = January .. 7 = Sol .. 13 = December).
  final int number;

  /// Full English month name.
  final String fullName;

  /// Abbreviated 3-letter month name.
  final String shortName;

  /// Returns `true` if this month is the 7th month, Sol.
  bool get isSol => this == CotsworthMonth.sol;

  /// Returns the [CotsworthMonth] for a 1-indexed [number] in `1..13`.
  static CotsworthMonth fromNumber(int number) {
    if (number < 1 || number > 13) {
      throw RangeError.range(number, 1, 13, 'number');
    }
    return values[number - 1];
  }

  /// Returns the previous month and whether the year rolled back.
  ({CotsworthMonth month, int yearDelta}) previous() {
    if (number == 1) {
      return (month: CotsworthMonth.december, yearDelta: -1);
    }
    return (month: fromNumber(number - 1), yearDelta: 0);
  }

  /// Returns the next month and whether the year rolled forward.
  ({CotsworthMonth month, int yearDelta}) next() {
    if (number == 13) {
      return (month: CotsworthMonth.january, yearDelta: 1);
    }
    return (month: fromNumber(number + 1), yearDelta: 0);
  }
}
