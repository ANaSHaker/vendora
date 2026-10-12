import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/cubit/locale_cubit.dart';
import 'core/cubit/theme_cubit.dart';
import 'core/di/injection.dart';
import 'core/firebase/analytics_service.dart';
import 'core/firebase/error_reporter.dart';
import 'core/firebase/notification_service.dart';
import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage.dart';
import 'design_system/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'firebase_options.dart';
import 'layouts/desktop/desktop_sidebar_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppAnalytics.instance.init();
  await AppErrorReporter.instance.init();
  await AppNotificationService.instance.init();
  await configureDependencies();
  await getIt<AuthCubit>().checkAuth();
  runApp(const VendoraApp());
}

class VendoraApp extends StatelessWidget {
  const VendoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(getIt<LocalStorage>())),
        BlocProvider(create: (_) => LocaleCubit(getIt<LocalStorage>())),
        BlocProvider(create: (_) => DesktopSidebarCubit()),
        BlocProvider.value(value: getIt<AuthCubit>()),
      ],
      child: const _VendoraRouter(),
    );
  }
}

class _VendoraRouter extends StatefulWidget {
  const _VendoraRouter();

  @override
  State<_VendoraRouter> createState() => _VendoraRouterState();
}

class _VendoraRouterState extends State<_VendoraRouter> {
  late final _router = buildRouter(getIt<AuthCubit>());

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final locale = context.watch<LocaleCubit>().state;

    return MaterialApp.router(
      title: 'Vendora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLight(primary: themeState.primaryColor),
      darkTheme: AppTheme.buildDark(primary: themeState.primaryColor),
      themeMode: themeState.mode,
      locale: locale,
      supportedLocales: LocaleCubit.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
