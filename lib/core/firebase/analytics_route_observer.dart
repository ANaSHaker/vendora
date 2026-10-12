import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'analytics_service.dart';
import 'error_reporter.dart';

/// Attach to GoRouter to auto-track every screen view.
class AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) _track(previousRoute);
  }

  void _track(Route route) {
    final name = route.settings.name ?? _routeName(route);
    if (name.isEmpty || name.startsWith('_')) return;
    AppAnalytics.instance.logScreenView(name);
    AppErrorReporter.instance.setScreen(name);
  }

  String _routeName(Route route) {
    final str = route.settings.toString();
    return str.contains('"') ? str.split('"')[1] : str;
  }
}

/// GoRouter listener that tracks route changes.
class GoRouterAnalyticsListener extends ChangeNotifier {
  GoRouterAnalyticsListener(GoRouter router) {
    router.routerDelegate.addListener(() {
      final location = router.state.uri.toString();
      AppAnalytics.instance.logScreenView(location);
      AppErrorReporter.instance.setScreen(location);
    });
  }
}
