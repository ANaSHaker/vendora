import 'package:flutter_bloc/flutter_bloc.dart';

class DesktopSidebarCubit extends Cubit<bool> {
  DesktopSidebarCubit() : super(false);

  void toggle() => emit(!state);
}
