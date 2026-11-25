import 'package:equatable/equatable.dart';
import '../../../../core/calendar_engine/cotsworth_date.dart';
import '../../../../core/calendar_engine/cotsworth_month.dart';

enum ConversionDirection { gregorianToCotsworth, cotsworthToGregorian }

enum CotsworthDayType { regular, leapDay, yearDay }

class ConverterState extends Equatable {
  const ConverterState({
    this.direction = ConversionDirection.gregorianToCotsworth,
    this.gregorianInput = '',
    this.cotsworthYear,
    this.cotsworthMonth,
    this.cotsworthDay = 1,
    this.cotsworthDayType = CotsworthDayType.regular,
    this.result,
    this.error,
    this.history = const [],
  });

  final ConversionDirection direction;
  final String gregorianInput;
  final int? cotsworthYear;
  final CotsworthMonth? cotsworthMonth;
  final int cotsworthDay;
  final CotsworthDayType cotsworthDayType;
  final ({CotsworthDate cotsworth, DateTime gregorian})? result;
  final String? error;
  final List<({CotsworthDate cotsworth, DateTime gregorian})> history;

  ConverterState copyWith({
    ConversionDirection? direction,
    String? gregorianInput,
    int? cotsworthYear,
    CotsworthMonth? cotsworthMonth,
    int? cotsworthDay,
    CotsworthDayType? cotsworthDayType,
    ({CotsworthDate cotsworth, DateTime gregorian})? result,
    String? error,
    List<({CotsworthDate cotsworth, DateTime gregorian})>? history,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return ConverterState(
      direction: direction ?? this.direction,
      gregorianInput: gregorianInput ?? this.gregorianInput,
      cotsworthYear: cotsworthYear ?? this.cotsworthYear,
      cotsworthMonth: cotsworthMonth ?? this.cotsworthMonth,
      cotsworthDay: cotsworthDay ?? this.cotsworthDay,
      cotsworthDayType: cotsworthDayType ?? this.cotsworthDayType,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
        direction,
        gregorianInput,
        cotsworthYear,
        cotsworthMonth,
        cotsworthDay,
        cotsworthDayType,
        result,
        error,
        history,
      ];
}
