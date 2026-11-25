import 'package:flutter_bloc/flutter_bloc.dart';

enum AppDestination {
  home(0, 'Home', 'Home'),
  convert(1, 'Convert', 'Convert'),
  yearView(2, 'Year View', 'Year View');

  const AppDestination(this.tabIndex, this.label, this.tooltip);
  final int tabIndex;
  final String label;
  final String tooltip;

  static AppDestination fromIndex(int i) {
    if (i < 0 || i >= values.length) return home;
    return values[i];
  }
}

class NavigationCubit extends Cubit<AppDestination> {
  NavigationCubit() : super(AppDestination.home);
  void select(AppDestination d) => emit(d);
  void selectIndex(int i) => emit(AppDestination.fromIndex(i));
}
