import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';
import '../../design_system/theme/app_colors.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
import '../../features/notifications/presentation/cubit/unread_count_cubit.dart';
import 'mobile_bottom_nav.dart';

class MobileShell extends StatelessWidget {
  final Widget child;

  const MobileShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return BlocProvider(
      create: (_) => UnreadCountCubit(
        getCount: getIt<GetUnreadCountUseCase>(),
      )..refresh(),
      child: Scaffold(
        backgroundColor: bg,
        extendBody: true,
        body: child,
        bottomNavigationBar: const MobileBottomNav(),
      ),
    );
  }
}
