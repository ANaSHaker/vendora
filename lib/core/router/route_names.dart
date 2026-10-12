abstract final class RouteNames {
  // Auth
  static const String login      = 'login';
  static const String adminLogin = 'admin-login';

  // Main App
  static const String dashboard  = 'dashboard';
  static const String pos        = 'pos';

  // Products
  static const String products    = 'products';
  static const String categories  = 'categories';
  static const String digitalMenu = 'digital-menu';
  static const String publicMenu  = 'public-menu';

  // Orders
  static const String orders     = 'orders';
  static const String receipts   = 'receipts';

  // Inventory
  static const String inventory          = 'inventory';
  static const String warehouseStock     = 'warehouse-stock';
  static const String inventoryMovements = 'inventory-movements';
  static const String inventoryCostLayers= 'inventory-cost-layers';
  static const String inventoryWarehouses= 'inventory-warehouses';
  static const String warehouses         = 'warehouses';
  static const String warehouseCreate    = 'warehouse-create';
  static const String warehouseEdit      = 'warehouse-edit';
  static const String transfers          = 'transfers';
  static const String transferCreate     = 'transfer-create';
  static const String transferDetail     = 'transfer-detail';
  static const String stockCounts        = 'stock-counts';
  static const String stockCountCreate   = 'stock-count-create';
  static const String stockCountDetail   = 'stock-count-detail';
  static const String adjustments        = 'adjustments';

  // Customers
  static const String customers  = 'customers';

  // Suppliers
  static const String suppliers       = 'suppliers';
  static const String supplierLedger  = 'supplier-ledger';
  static const String supplierDetail  = 'supplier-detail';
  static const String supplierAging   = 'supplier-aging';

  // Reports
  static const String reports          = 'reports';
  static const String financialReports = 'financial-reports';
  static const String inventoryReports = 'inventory-reports';

  // Org
  static const String branches = 'branches';
  static const String users    = 'users';
  static const String roles    = 'roles';

  // Homepage Builder
  static const String homepageBuilder = 'homepage-builder';

  // Settings
  static const String storeSettings   = 'store-settings';
  static const String deviceSettings  = 'device-settings';
  static const String themes          = 'themes';

  // Reservations
  static const String reservations        = 'reservations';
  static const String reservationSettings = 'reservation-settings';

  // Tracking (public)
  static const String orderTracking  = 'order-tracking';

  // Public Booking (public)
  static const String publicBooking  = 'public-booking';

  // Storefront (public, no auth)
  static const String storefront           = 'storefront';
  static const String storefrontProducts   = 'storefront-products';
  static const String storefrontProduct    = 'storefront-product';
  static const String storefrontCart       = 'storefront-cart';
  static const String storefrontCheckout   = 'storefront-checkout';
  static const String storefrontSuccess    = 'storefront-success';
  static const String storefrontTrack      = 'storefront-track';
  static const String storefrontLookup     = 'storefront-lookup';
  static const String storefrontAbout      = 'storefront-about';
  static const String storefrontContact    = 'storefront-contact';
  static const String storefrontReservations = 'storefront-reservations';

  // Storefront Settings (auth)
  static const String storefrontSettings  = 'storefront-settings';

  // Notifications & Activity
  static const String notifications = 'notifications';
  static const String activityLog   = 'activity-log';

  // Admin
  static const String adminDashboard   = 'admin-dashboard';
  static const String adminVendors     = 'admin-vendors';
  static const String adminVendorCreate= 'admin-vendor-create';
  static const String adminVendorEdit  = 'admin-vendor-edit';
  static const String adminPlans       = 'admin-plans';
  static const String adminBilling     = 'admin-billing';
  static const String adminAnalytics   = 'admin-analytics';
  static const String adminSubscriptions = 'admin-subscriptions';
  static const String adminFinance       = 'admin-finance';
  static const String adminLogs          = 'admin-logs';
  static const String adminSystemSettings= 'admin-system-settings';
}
