import 'package:flutter/material.dart';
import '../core/router/route_names.dart';

class NavItem {
  final String routeName;
  final String path;
  final String label;
  final IconData icon;
  final bool exactPath;
  final String l10nKey;

  const NavItem({
    required this.routeName,
    required this.path,
    required this.label,
    required this.icon,
    this.exactPath = false,
    required this.l10nKey,
  });
}

class NavSection {
  final String? title;
  final String? l10nKey;
  final List<NavItem> items;

  const NavSection({this.title, this.l10nKey, required this.items});
}

const List<NavSection> kAppNavSections = [
  NavSection(
    items: [
      NavItem(
        routeName: RouteNames.dashboard,
        path: '/dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_rounded,
        exactPath: true,
        l10nKey: 'dashboard',
      ),
    ],
  ),
  NavSection(
    title: 'Sales',
    l10nKey: 'navSales',
    items: [
      NavItem(
        routeName: RouteNames.pos,
        path: '/pos',
        label: 'POS',
        icon: Icons.point_of_sale_rounded,
        l10nKey: 'pos',
      ),
      NavItem(
        routeName: RouteNames.orders,
        path: '/orders',
        label: 'Orders',
        icon: Icons.receipt_long_rounded,
        l10nKey: 'orders',
      ),
      NavItem(
        routeName: RouteNames.reservations,
        path: '/reservations',
        label: 'Reservations',
        icon: Icons.event_seat_rounded,
        exactPath: true,
        l10nKey: 'reservations',
      ),
      NavItem(
        routeName: RouteNames.reservationSettings,
        path: '/reservations/settings',
        label: 'Reservation Settings',
        icon: Icons.settings_rounded,
        l10nKey: 'reservationSettings',
      ),
      NavItem(
        routeName: RouteNames.reports,
        path: '/reports',
        label: 'Reports',
        icon: Icons.bar_chart_rounded,
        exactPath: true,
        l10nKey: 'reports',
      ),
      NavItem(
        routeName: RouteNames.inventoryReports,
        path: '/reports/inventory',
        label: 'Inventory Reports',
        icon: Icons.assessment_rounded,
        l10nKey: 'inventoryReports',
      ),
      NavItem(
        routeName: RouteNames.financialReports,
        path: '/reports/financial',
        label: 'Financial Reports',
        icon: Icons.account_balance_wallet_rounded,
        l10nKey: 'financialReports',
      ),
    ],
  ),
  NavSection(
    title: 'Catalog',
    l10nKey: 'navCatalog',
    items: [
      NavItem(
        routeName: RouteNames.products,
        path: '/products',
        label: 'Products',
        icon: Icons.inventory_2_rounded,
        l10nKey: 'products',
      ),
      NavItem(
        routeName: RouteNames.categories,
        path: '/categories',
        label: 'Categories',
        icon: Icons.category_rounded,
        l10nKey: 'categories',
      ),
      NavItem(
        routeName: RouteNames.digitalMenu,
        path: '/menu',
        label: 'Digital Menu',
        icon: Icons.restaurant_menu_rounded,
        l10nKey: 'digitalMenu',
      ),
    ],
  ),
  NavSection(
    title: 'Customers',
    l10nKey: 'navCustomers',
    items: [
      NavItem(
        routeName: RouteNames.customers,
        path: '/customers',
        label: 'Customers',
        icon: Icons.people_rounded,
        l10nKey: 'customers',
      ),
    ],
  ),
  NavSection(
    title: 'Purchasing',
    l10nKey: 'navPurchasing',
    items: [
      NavItem(
        routeName: RouteNames.suppliers,
        path: '/suppliers',
        label: 'Suppliers',
        icon: Icons.local_shipping_rounded,
        exactPath: true,
        l10nKey: 'suppliers',
      ),
      NavItem(
        routeName: RouteNames.supplierLedger,
        path: '/suppliers/ledger',
        label: 'Supplier Ledger',
        icon: Icons.menu_book_rounded,
        l10nKey: 'supplierLedger',
      ),
      NavItem(
        routeName: RouteNames.supplierAging,
        path: '/suppliers/aging',
        label: 'Supplier Aging',
        icon: Icons.access_time_rounded,
        l10nKey: 'supplierAgingTitle',
      ),
      NavItem(
        routeName: RouteNames.receipts,
        path: '/receipts',
        label: 'Receipts',
        icon: Icons.inbox_rounded,
        l10nKey: 'receipts',
      ),
    ],
  ),
  NavSection(
    title: 'Inventory',
    l10nKey: 'navInventory',
    items: [
      NavItem(
        routeName: RouteNames.inventory,
        path: '/inventory',
        label: 'Inventory',
        icon: Icons.inventory_2_rounded,
        exactPath: true,
        l10nKey: 'inventory',
      ),
      NavItem(
        routeName: RouteNames.warehouseStock,
        path: '/inventory/warehouse-stock',
        label: 'Stock by Warehouse',
        icon: Icons.store_mall_directory_rounded,
        l10nKey: 'warehouseStock',
      ),
      NavItem(
        routeName: RouteNames.warehouses,
        path: '/warehouses',
        label: 'Warehouses',
        icon: Icons.warehouse_rounded,
        exactPath: true,
        l10nKey: 'warehouses',
      ),
      NavItem(
        routeName: RouteNames.adjustments,
        path: '/adjustments',
        label: 'Adjustments',
        icon: Icons.tune_rounded,
        l10nKey: 'adjustments',
      ),
      NavItem(
        routeName: RouteNames.transfers,
        path: '/transfers',
        label: 'Stock Transfers',
        icon: Icons.swap_horiz_rounded,
        l10nKey: 'transfers',
      ),
      NavItem(
        routeName: RouteNames.stockCounts,
        path: '/stock-counts',
        label: 'Stock Counts',
        icon: Icons.fact_check_rounded,
        l10nKey: 'stockCounts',
      ),
      NavItem(
        routeName: RouteNames.inventoryMovements,
        path: '/inventory/movements',
        label: 'Movements',
        icon: Icons.trending_up_rounded,
        l10nKey: 'movements',
      ),
      NavItem(
        routeName: RouteNames.inventoryCostLayers,
        path: '/inventory/cost-layers',
        label: 'Cost Layers',
        icon: Icons.layers_rounded,
        l10nKey: 'costLayers',
      ),
    ],
  ),
  NavSection(
    title: 'Operations',
    l10nKey: 'navOperations',
    items: [
      NavItem(
        routeName: RouteNames.branches,
        path: '/branches',
        label: 'Branches',
        icon: Icons.account_tree_rounded,
        l10nKey: 'branches',
      ),
      NavItem(
        routeName: RouteNames.users,
        path: '/users',
        label: 'Users',
        icon: Icons.manage_accounts_rounded,
        l10nKey: 'users',
      ),
      NavItem(
        routeName: RouteNames.roles,
        path: '/roles',
        label: 'Roles & Permissions',
        icon: Icons.shield_rounded,
        l10nKey: 'rolesAndPermissions',
      ),
      NavItem(
        routeName: RouteNames.activityLog,
        path: '/activity-log',
        label: 'Activity Log',
        icon: Icons.history_rounded,
        l10nKey: 'activityLog',
      ),
      NavItem(
        routeName: RouteNames.notifications,
        path: '/notifications',
        label: 'Notifications',
        icon: Icons.notifications_rounded,
        l10nKey: 'notifications',
      ),
      NavItem(
        routeName: RouteNames.homepageBuilder,
        path: '/homepage-builder',
        label: 'Homepage Builder',
        icon: Icons.web_rounded,
        l10nKey: 'homepageBuilder',
      ),
      NavItem(
        routeName: RouteNames.storefrontSettings,
        path: '/settings/online-store',
        label: 'Online Store',
        icon: Icons.shopping_bag_rounded,
        l10nKey: 'sfStoreSettings',
      ),
      NavItem(
        routeName: RouteNames.storeSettings,
        path: '/settings/store',
        label: 'Store Settings',
        icon: Icons.storefront_rounded,
        l10nKey: 'storeSettings',
      ),
      NavItem(
        routeName: RouteNames.deviceSettings,
        path: '/settings/devices',
        label: 'Devices',
        icon: Icons.devices_rounded,
        l10nKey: 'devices',
      ),
      NavItem(
        routeName: RouteNames.themes,
        path: '/settings/themes',
        label: 'Themes',
        icon: Icons.palette_rounded,
        l10nKey: 'themes',
      ),
    ],
  ),
];

const List<NavSection> kAdminNavSections = [
  NavSection(
    title: 'Overview',
    l10nKey: 'overview',
    items: [
      NavItem(
        routeName: RouteNames.adminDashboard,
        path: '/admin',
        label: 'Dashboard',
        icon: Icons.dashboard_rounded,
        exactPath: true,
        l10nKey: 'dashboard',
      ),
    ],
  ),
  NavSection(
    title: 'Tenants',
    l10nKey: 'tenants',
    items: [
      NavItem(
        routeName: RouteNames.adminVendors,
        path: '/admin/vendors',
        label: 'Vendors',
        icon: Icons.store_rounded,
        l10nKey: 'vendors',
      ),
      NavItem(
        routeName: RouteNames.adminSubscriptions,
        path: '/admin/subscriptions',
        label: 'Subscriptions',
        icon: Icons.card_membership_rounded,
        l10nKey: 'subscriptions',
      ),
      NavItem(
        routeName: RouteNames.adminPlans,
        path: '/admin/plans',
        label: 'Plans',
        icon: Icons.workspace_premium_rounded,
        l10nKey: 'plans',
      ),
    ],
  ),
  NavSection(
    title: 'Financial',
    l10nKey: 'financial',
    items: [
      NavItem(
        routeName: RouteNames.adminBilling,
        path: '/admin/billing',
        label: 'Billing',
        icon: Icons.payments_rounded,
        l10nKey: 'billing',
      ),
      NavItem(
        routeName: RouteNames.adminFinance,
        path: '/admin/finance',
        label: 'Finance',
        icon: Icons.account_balance_rounded,
        l10nKey: 'adminFinanceTitle',
      ),
    ],
  ),
  NavSection(
    title: 'Insights',
    l10nKey: 'insights',
    items: [
      NavItem(
        routeName: RouteNames.adminAnalytics,
        path: '/admin/analytics',
        label: 'Analytics',
        icon: Icons.insights_rounded,
        l10nKey: 'analytics',
      ),
    ],
  ),
  NavSection(
    title: 'System',
    l10nKey: 'system',
    items: [
      NavItem(
        routeName: RouteNames.adminLogs,
        path: '/admin/logs',
        label: 'System Logs',
        icon: Icons.history_rounded,
        l10nKey: 'systemLogs',
      ),
      NavItem(
        routeName: RouteNames.adminSystemSettings,
        path: '/admin/settings',
        label: 'System Settings',
        icon: Icons.settings_rounded,
        l10nKey: 'systemSettings',
      ),
    ],
  ),
];
