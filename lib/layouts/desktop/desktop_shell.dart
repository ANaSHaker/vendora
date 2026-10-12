import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/injection.dart';
import '../../design_system/theme/app_colors.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
import '../../features/notifications/presentation/cubit/unread_count_cubit.dart';
import 'desktop_sidebar.dart';
import 'desktop_topbar.dart';

class DesktopShell extends StatelessWidget {
  final Widget child;

  const DesktopShell({super.key, required this.child});

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
        body: Row(
          children: [
            const DesktopSidebar(),
            Expanded(
              child: Column(
                children: [
                  const DesktopTopbar(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
