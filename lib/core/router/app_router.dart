import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/admin_login_page.dart';
import '../../features/auth/presentation/pages/desktop_login_page.dart';
import '../../features/auth/presentation/pages/mobile_login_page.dart';
import '../../features/dashboard/presentation/pages/desktop/desktop_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/mobile/mobile_dashboard_page.dart';
import '../../features/pos/presentation/pages/desktop/desktop_pos_page.dart';
import '../../features/pos/presentation/pages/mobile/mobile_pos_page.dart';
import '../../features/orders/presentation/pages/desktop/desktop_orders_page.dart';
import '../../features/orders/presentation/pages/mobile/mobile_orders_page.dart';
import '../../features/orders/presentation/pages/tracking/order_tracking_page.dart';
import '../../features/products/presentation/pages/desktop/desktop_categories_page.dart';
import '../../features/products/presentation/pages/desktop/desktop_products_page.dart';
import '../../features/products/presentation/pages/mobile/mobile_categories_page.dart';
import '../../features/products/presentation/pages/mobile/mobile_products_page.dart';
import '../../features/customers/presentation/pages/desktop/desktop_customers_page.dart';
import '../../features/customers/presentation/pages/mobile/mobile_customers_page.dart';
import '../../features/reports/presentation/pages/desktop/desktop_financial_reports_page.dart';
import '../../features/reports/presentation/pages/desktop/desktop_inventory_reports_page.dart';
import '../../features/reports/presentation/pages/desktop/desktop_reports_page.dart';
import '../../features/reports/presentation/pages/mobile/mobile_financial_reports_page.dart';
import '../../features/reports/presentation/pages/mobile/mobile_inventory_reports_page.dart';
import '../../features/reports/presentation/pages/mobile/mobile_reports_page.dart';
// ─── Inventory ────────────────────────────────────────────────────────────────
import '../../features/inventory/presentation/pages/desktop/desktop_inventory_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_warehouse_stock_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_movements_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_cost_layers_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_warehouses_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_stock_counts_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_stock_count_create_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_stock_count_detail_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_adjustments_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_transfers_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_transfer_create_page.dart';
import '../../features/inventory/presentation/pages/desktop/desktop_transfer_detail_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_inventory_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_warehouse_stock_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_movements_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_cost_layers_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_warehouses_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_stock_counts_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_adjustments_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_transfers_page.dart';
// ─── Suppliers ────────────────────────────────────────────────────────────────
import '../../features/suppliers/presentation/pages/desktop/desktop_suppliers_page.dart';
import '../../features/suppliers/presentation/pages/desktop/desktop_supplier_ledger_page.dart';
import '../../features/suppliers/presentation/pages/desktop/desktop_supplier_aging_page.dart';
import '../../features/suppliers/presentation/pages/mobile/mobile_suppliers_page.dart';
import '../../features/suppliers/presentation/pages/mobile/mobile_supplier_ledger_page.dart';
import '../../features/suppliers/presentation/pages/mobile/mobile_supplier_aging_page.dart';
// ─── Devices ──────────────────────────────────────────────────────────────────
import '../../features/devices/presentation/pages/desktop/desktop_devices_page.dart';
import '../../features/devices/presentation/pages/mobile/mobile_devices_page.dart';
// ─── Branches ─────────────────────────────────────────────────────────────────
import '../../features/branches/presentation/pages/desktop/desktop_branches_page.dart';
import '../../features/branches/presentation/pages/mobile/mobile_branches_page.dart';
// ─── Users ────────────────────────────────────────────────────────────────────
import '../../features/users/presentation/pages/desktop/desktop_users_page.dart';
import '../../features/users/presentation/pages/mobile/mobile_users_page.dart';
// ─── Roles ────────────────────────────────────────────────────────────────────
import '../../features/roles/presentation/pages/desktop/desktop_roles_page.dart';
import '../../features/roles/presentation/pages/mobile/mobile_roles_page.dart';
// ─── Notifications ────────────────────────────────────────────────────────────
import '../../features/notifications/presentation/pages/desktop/desktop_notifications_page.dart';
import '../../features/notifications/presentation/pages/mobile/mobile_notifications_page.dart';
// ─── Activity Log ─────────────────────────────────────────────────────────────
import '../../features/activity_log/presentation/pages/desktop/desktop_activity_log_page.dart';
import '../../features/activity_log/presentation/pages/mobile/mobile_activity_log_page.dart';
// ─── Reservations ─────────────────────────────────────────────────────────────
import '../../features/reservations/presentation/pages/desktop/desktop_reservations_page.dart';
import '../../features/reservations/presentation/pages/desktop/desktop_reservation_settings_page.dart';
import '../../features/reservations/presentation/pages/mobile/mobile_reservations_page.dart';
import '../../features/reservations/presentation/pages/mobile/mobile_reservation_settings_page.dart';
// ─── Receipts ─────────────────────────────────────────────────────────────────
import '../../features/receipts/presentation/pages/desktop/desktop_receipts_page.dart';
import '../../features/receipts/presentation/pages/mobile/mobile_receipts_page.dart';
// ─── Homepage Builder ─────────────────────────────────────────────────────────
import '../../features/homepage_builder/presentation/pages/desktop/desktop_homepage_builder_page.dart';
import '../../features/homepage_builder/presentation/pages/mobile/mobile_homepage_builder_page.dart';
// ─── Settings ─────────────────────────────────────────────────────────────────
import '../../features/settings/presentation/pages/desktop/desktop_themes_page.dart';
import '../../features/settings/presentation/pages/mobile/mobile_themes_page.dart';
import '../../features/store_settings/presentation/pages/desktop/desktop_store_settings_page.dart';
import '../../features/store_settings/presentation/pages/mobile/mobile_store_settings_page.dart';
// ─── Inventory Mobile Pages ───────────────────────────────────────────────────
import '../../features/inventory/presentation/pages/mobile/mobile_transfer_create_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_transfer_detail_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_stock_count_create_page.dart';
import '../../features/inventory/presentation/pages/mobile/mobile_stock_count_detail_page.dart';
// ─── Public Booking ────────────────────────────────────────────────────────────
import '../../features/public_booking/presentation/pages/public_booking_page.dart';
// ─── Digital Menu ──────────────────────────────────────────────────────────────
import '../../features/digital_menu/presentation/pages/desktop/desktop_menu_page.dart';
import '../../features/digital_menu/presentation/pages/mobile/mobile_menu_page.dart';
import '../../features/digital_menu/presentation/pages/public/public_menu_page.dart';
import '../../layouts/admin/admin_shell.dart';
import '../../layouts/desktop/desktop_shell.dart';
import '../../layouts/mobile/mobile_shell.dart';
// ─── Admin Pages ───────────────────────────────────────────────────────────────
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_vendors_page.dart';
import '../../features/admin/presentation/pages/admin_plans_page.dart';
import '../../features/admin/presentation/pages/admin_billing_page.dart';
import '../../features/admin/presentation/pages/admin_finance_page.dart';
import '../../features/admin/presentation/pages/admin_subscriptions_page.dart';
import '../../features/admin/presentation/pages/admin_analytics_page.dart';
import '../../features/admin/presentation/pages/admin_logs_page.dart';
// ─── Storefront ────────────────────────────────────────────────────────────────
import '../../features/storefront/presentation/pages/storefront_shell.dart';
import '../../features/storefront/presentation/pages/sf_home_page.dart';
import '../../features/storefront/presentation/pages/sf_products_page.dart';
import '../../features/storefront/presentation/pages/sf_product_detail_page.dart';
import '../../features/storefront/presentation/pages/sf_cart_page.dart';
import '../../features/storefront/presentation/pages/sf_checkout_page.dart';
import '../../features/storefront/presentation/pages/sf_order_success_page.dart';
import '../../features/storefront/presentation/pages/sf_order_tracking_page.dart';
import '../../features/storefront/presentation/pages/sf_reservation_page.dart';
import '../../features/storefront/presentation/pages/sf_about_page.dart';
import '../../features/storefront/presentation/pages/sf_contact_page.dart';
import '../../features/storefront/presentation/settings/sf_settings_page.dart';
import 'route_names.dart';

const double _kDesktopBreakpoint = 900;

Widget _appShell(BuildContext context, Widget child) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= _kDesktopBreakpoint) {
    return DesktopShell(child: child);
  }
  return MobileShell(child: child);
}

Widget _loginPage(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width >= _kDesktopBreakpoint
      ? const DesktopLoginPage()
      : const MobileLoginPage();
}

class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthNotifier(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _AuthNotifier(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isAuth = authState is AuthAuthenticated;
      final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
      final loc = state.uri.path;

      // Public routes — never redirect
      if (loc.startsWith('/track/')) return null;
      if (loc.startsWith('/book/')) return null;
      if (loc.startsWith('/menu/')) return null;

      if (!isAuth) {
        if (loc.startsWith('/admin') && loc != '/admin/login') {
          return '/admin/login';
        }
        if (loc != '/login' && loc != '/admin/login') return '/login';
        return null;
      }

      // Authenticated — redirect away from login pages
      if (loc == '/login') return isAdmin ? '/admin' : '/dashboard';
      if (loc == '/admin/login') return isAdmin ? '/admin' : '/dashboard';

      // Vendor user accessing admin routes
      if (loc.startsWith('/admin') && !isAdmin) return '/dashboard';

      return null;
    },
    routes: [
      // ─── Public Tracking ──────────────────────────────────────────────
      GoRoute(
        path: '/track/:token',
        name: RouteNames.orderTracking,
        builder: (_, state) => OrderTrackingPage(
          token: state.pathParameters['token'] ?? '',
          initialRef: state.uri.queryParameters['ref'],
        ),
      ),

      // ─── Public Booking ───────────────────────────────────────────────
      GoRoute(
        path: '/book/:slug',
        name: RouteNames.publicBooking,
        builder: (_, state) => PublicBookingPage(
          slug: state.pathParameters['slug'] ?? '',
        ),
      ),

      // ─── Public Menu (no auth) ────────────────────────────────────────
      GoRoute(
        path: '/menu/:slug',
        name: RouteNames.publicMenu,
        builder: (_, state) => PublicMenuPage(
          slug: state.pathParameters['slug'] ?? '',
        ),
      ),

      // ─── Online Storefront (public, no auth) ──────────────────────────
      ShellRoute(
        builder: (_, state, child) {
          final slug = state.pathParameters['slug'] ?? '';
          return StorefrontPage(slug: slug, child: child);
        },
        routes: [
          GoRoute(
            path: '/store/:slug',
            name: RouteNames.storefront,
            builder: (_, state) =>
                SfHomePage(slug: state.pathParameters['slug'] ?? ''),
            routes: [
              GoRoute(
                path: 'products',
                name: RouteNames.storefrontProducts,
                builder: (_, state) =>
                    SfProductsPage(slug: state.pathParameters['slug'] ?? ''),
                routes: [
                  GoRoute(
                    path: ':productId',
                    name: RouteNames.storefrontProduct,
                    builder: (_, state) => SfProductDetailPage(
                      slug: state.pathParameters['slug'] ?? '',
                      productId: state.pathParameters['productId'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'cart',
                name: RouteNames.storefrontCart,
                builder: (_, state) =>
                    SfCartPage(slug: state.pathParameters['slug'] ?? ''),
              ),
              GoRoute(
                path: 'checkout',
                name: RouteNames.storefrontCheckout,
                builder: (_, state) =>
                    SfCheckoutPage(slug: state.pathParameters['slug'] ?? ''),
              ),
              GoRoute(
                path: 'order-success',
                name: RouteNames.storefrontSuccess,
                builder: (_, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return SfOrderSuccessPage(
                    slug: state.pathParameters['slug'] ?? '',
                    reference: extra?['reference'] as String?,
                    total: extra?['total'] as double?,
                  );
                },
              ),
              GoRoute(
                path: 'track/:ref',
                name: RouteNames.storefrontTrack,
                builder: (_, state) => SfOrderTrackingPage(
                  slug: state.pathParameters['slug'] ?? '',
                  reference: state.pathParameters['ref'],
                ),
              ),
              GoRoute(
                path: 'lookup',
                name: RouteNames.storefrontLookup,
                builder: (_, state) => SfOrderTrackingPage(
                  slug: state.pathParameters['slug'] ?? '',
                ),
              ),
              GoRoute(
                path: 'about',
                name: RouteNames.storefrontAbout,
                builder: (_, __) => const SfAboutPage(),
              ),
              GoRoute(
                path: 'contact',
                name: RouteNames.storefrontContact,
                builder: (_, __) => const SfContactPage(),
              ),
              GoRoute(
                path: 'reservations',
                name: RouteNames.storefrontReservations,
                builder: (_, state) =>
                    SfReservationPage(slug: state.pathParameters['slug'] ?? ''),
              ),
            ],
          ),
        ],
      ),

      // ─── Auth ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, __) => _loginPage(context),
      ),
      GoRoute(
        path: '/admin/login',
        name: RouteNames.adminLogin,
        builder: (_, __) => const AdminLoginPage(),
      ),

      // ─── POS (full-screen, outside shell) ─────────────────────────────
      GoRoute(
        path: '/pos',
        name: RouteNames.pos,
        builder: (context, __) {
          final width = MediaQuery.sizeOf(context).width;
          return width >= _kDesktopBreakpoint
              ? const DesktopPosPage()
              : const MobilePosPage();
        },
      ),

      // ─── Main App Shell ───────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => _appShell(context, child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopDashboardPage()
                  : const MobileDashboardPage();
            },
          ),
          GoRoute(
            path: '/products',
            name: RouteNames.products,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopProductsPage()
                  : const MobileProductsPage();
            },
          ),
          GoRoute(
            path: '/categories',
            name: RouteNames.categories,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopCategoriesPage()
                  : const MobileCategoriesPage();
            },
          ),
          GoRoute(
            path: '/menu',
            name: RouteNames.digitalMenu,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopMenuPage()
                  : const MobileMenuPage();
            },
          ),
          GoRoute(
            path: '/orders',
            name: RouteNames.orders,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopOrdersPage()
                  : const MobileOrdersPage();
            },
          ),
          GoRoute(
            path: '/receipts',
            name: RouteNames.receipts,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopReceiptsPage()
                  : const MobileReceiptsPage();
            },
          ),
          GoRoute(
            path: '/reservations',
            name: RouteNames.reservations,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopReservationsPage()
                  : const MobileReservationsPage();
            },
          ),
          GoRoute(
            path: '/reservations/settings',
            name: RouteNames.reservationSettings,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopReservationSettingsPage()
                  : const MobileReservationSettingsPage();
            },
          ),
          // ─── Inventory ────────────────────────────────────────────────
          GoRoute(
            path: '/inventory',
            name: RouteNames.inventory,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopInventoryPage()
                  : const MobileInventoryPage();
            },
          ),
          GoRoute(
            path: '/inventory/warehouse-stock',
            name: RouteNames.warehouseStock,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopWarehouseStockPage()
                  : const MobileWarehouseStockPage();
            },
          ),
          GoRoute(
            path: '/inventory/movements',
            name: RouteNames.inventoryMovements,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopMovementsPage()
                  : const MobileMovementsPage();
            },
          ),
          GoRoute(
            path: '/inventory/cost-layers',
            name: RouteNames.inventoryCostLayers,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopCostLayersPage()
                  : const MobileCostLayersPage();
            },
          ),
          GoRoute(
            path: '/warehouses',
            name: RouteNames.warehouses,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopWarehousesPage()
                  : const MobileWarehousesPage();
            },
          ),
          GoRoute(
            path: '/warehouses/create',
            name: RouteNames.warehouseCreate,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopWarehousesPage()
                  : const MobileWarehousesPage();
            },
          ),
          GoRoute(
            path: '/warehouses/:id/edit',
            name: RouteNames.warehouseEdit,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopWarehousesPage()
                  : const MobileWarehousesPage();
            },
          ),
          GoRoute(
            path: '/transfers',
            name: RouteNames.transfers,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopTransfersPage()
                  : const MobileTransfersPage();
            },
          ),
          GoRoute(
            path: '/transfers/create',
            name: RouteNames.transferCreate,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopTransferCreatePage()
                  : const MobileTransferCreatePage();
            },
          ),
          GoRoute(
            path: '/transfers/:id',
            name: RouteNames.transferDetail,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? DesktopTransferDetailPage(id: id)
                  : MobileTransferDetailPage(id: id);
            },
          ),
          GoRoute(
            path: '/stock-counts',
            name: RouteNames.stockCounts,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopStockCountsPage()
                  : const MobileStockCountsPage();
            },
          ),
          GoRoute(
            path: '/stock-counts/create',
            name: RouteNames.stockCountCreate,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopStockCountCreatePage()
                  : const MobileStockCountCreatePage();
            },
          ),
          GoRoute(
            path: '/stock-counts/:id',
            name: RouteNames.stockCountDetail,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? DesktopStockCountDetailPage(id: id)
                  : MobileStockCountDetailPage(id: id);
            },
          ),
          GoRoute(
            path: '/adjustments',
            name: RouteNames.adjustments,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopAdjustmentsPage()
                  : const MobileAdjustmentsPage();
            },
          ),
          GoRoute(
            path: '/customers',
            name: RouteNames.customers,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopCustomersPage()
                  : const MobileCustomersPage();
            },
          ),
          // ─── Suppliers ────────────────────────────────────────────────
          GoRoute(
            path: '/suppliers',
            name: RouteNames.suppliers,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopSuppliersPage()
                  : const MobileSuppliersPage();
            },
          ),
          GoRoute(
            path: '/suppliers/ledger',
            name: RouteNames.supplierLedger,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopSupplierLedgerPage()
                  : const MobileSupplierLedgerPage();
            },
          ),
          GoRoute(
            path: '/suppliers/:id/ledger',
            name: RouteNames.supplierDetail,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopSupplierLedgerPage()
                  : const MobileSupplierLedgerPage();
            },
          ),
          GoRoute(
            path: '/suppliers/aging',
            name: RouteNames.supplierAging,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopSupplierAgingPage()
                  : const MobileSupplierAgingPage();
            },
          ),
          // ─── Reports ──────────────────────────────────────────────────
          GoRoute(
            path: '/reports',
            name: RouteNames.reports,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopReportsPage()
                  : const MobileReportsPage();
            },
          ),
          GoRoute(
            path: '/reports/financial',
            name: RouteNames.financialReports,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopFinancialReportsPage()
                  : const MobileFinancialReportsPage();
            },
          ),
          GoRoute(
            path: '/reports/inventory',
            name: RouteNames.inventoryReports,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopInventoryReportsPage()
                  : const MobileInventoryReportsPage();
            },
          ),
          GoRoute(
            path: '/branches',
            name: RouteNames.branches,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopBranchesPage()
                  : const MobileBranchesPage();
            },
          ),
          GoRoute(
            path: '/users',
            name: RouteNames.users,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopUsersPage()
                  : const MobileUsersPage();
            },
          ),
          GoRoute(
            path: '/roles',
            name: RouteNames.roles,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopRolesPage()
                  : const MobileRolesPage();
            },
          ),
          GoRoute(
            path: '/settings/online-store',
            name: RouteNames.storefrontSettings,
            builder: (_, __) => const SfSettingsPage(),
          ),
          GoRoute(
            path: '/homepage-builder',
            name: RouteNames.homepageBuilder,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopHomepageBuilderPage()
                  : const MobileHomepageBuilderPage();
            },
          ),
          GoRoute(
            path: '/settings/store',
            name: RouteNames.storeSettings,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopStoreSettingsPage()
                  : const MobileStoreSettingsPage();
            },
          ),
          GoRoute(
            path: '/settings/devices',
            name: RouteNames.deviceSettings,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopDevicesPage()
                  : const MobileDevicesPage();
            },
          ),
          GoRoute(
            path: '/settings/themes',
            name: RouteNames.themes,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopThemesPage()
                  : const MobileThemesPage();
            },
          ),
          GoRoute(
            path: '/notifications',
            name: RouteNames.notifications,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopNotificationsPage()
                  : const MobileNotificationsPage();
            },
          ),
          GoRoute(
            path: '/activity-log',
            name: RouteNames.activityLog,
            builder: (context, __) {
              final width = MediaQuery.sizeOf(context).width;
              return width >= _kDesktopBreakpoint
                  ? const DesktopActivityLogPage()
                  : const MobileActivityLogPage();
            },
          ),
        ],
      ),

      // ─── Admin Shell ─────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: RouteNames.adminDashboard,
            builder: (_, __) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/vendors',
            name: RouteNames.adminVendors,
            builder: (_, __) => const AdminVendorsPage(),
          ),
          GoRoute(
            path: '/admin/vendors/create',
            name: RouteNames.adminVendorCreate,
            builder: (_, __) => const AdminVendorsPage(),
          ),
          GoRoute(
            path: '/admin/vendors/:id/edit',
            name: RouteNames.adminVendorEdit,
            builder: (_, __) => const AdminVendorsPage(),
          ),
          GoRoute(
            path: '/admin/plans',
            name: RouteNames.adminPlans,
            builder: (_, __) => const AdminPlansPage(),
          ),
          GoRoute(
            path: '/admin/billing',
            name: RouteNames.adminBilling,
            builder: (_, __) => const AdminBillingPage(),
          ),
          GoRoute(
            path: '/admin/finance',
            name: RouteNames.adminFinance,
            builder: (_, __) => const AdminFinancePage(),
          ),
          GoRoute(
            path: '/admin/subscriptions',
            name: RouteNames.adminSubscriptions,
            builder: (_, __) => const AdminSubscriptionsPage(),
          ),
          GoRoute(
            path: '/admin/analytics',
            name: RouteNames.adminAnalytics,
            builder: (_, __) => const AdminAnalyticsPage(),
          ),
          GoRoute(
            path: '/admin/logs',
            name: RouteNames.adminLogs,
            builder: (_, __) => const AdminLogsPage(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: RouteNames.adminSystemSettings,
            builder: (_, __) => const AdminSystemSettingsPage(),
          ),
        ],
      ),
    ],
  );
}
