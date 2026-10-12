abstract final class ApiEndpoints {
  static const String _base = '/api';

  // ─── Auth ─────────────────────────────────────────────────────────────────
  static const String login          = '$_base/auth/login';
  static const String logout         = '$_base/auth/logout';
  static const String me             = '$_base/auth/me';
  static const String adminLogin     = '$_base/admin/auth/login';
  static const String adminLogout    = '$_base/admin/auth/logout';
  static const String adminMe        = '$_base/admin/auth/me';

  // ─── Dashboard ────────────────────────────────────────────────────────────
  static const String dashboard      = '$_base/dashboard';

  // ─── Products ─────────────────────────────────────────────────────────────
  static const String products       = '$_base/products';
  static String productById(String id) => '$products/$id';
  static String productOptions(String id) => '$products/$id/options';
  static const String exportProducts = '$_base/export/products';
  static const String importProducts = '$_base/import/products';

  // ─── Categories ───────────────────────────────────────────────────────────
  static const String categories          = '$_base/categories';
  static const String categoriesTree      = '$_base/categories/tree';
  static String categoryById(String id)   => '$categories/$id';
  static const String exportCategories    = '$_base/export/categories';
  static const String importCategories    = '$_base/import/categories';

  // ─── Orders ───────────────────────────────────────────────────────────────
  static const String orders         = '$_base/orders';
  static String orderById(String id)      => '$orders/$id';
  static String orderStatus(String id)      => '$orders/$id/status';
  static String orderFulfillment(String id) => '$orders/$id/fulfillment';
  static String orderByToken(String token)  => '$orders/track/$token';
  static String orderTrackSearch(String slug, String ref) =>
      '$orders/track/$slug?reference=${Uri.encodeComponent(ref)}';
  static String orderRefunds(String id)   => '$orders/$id/refunds';
  static String orderInvoice(String id)   => '$orders/$id/invoice';

  // ─── Receipts (Goods Receipts) ────────────────────────────────────────────
  static const String receipts       = '$_base/receipts';
  static String receiptById(String id)    => '$receipts/$id';
  static String postReceipt(String id)    => '$receipts/$id/post';
  static String cancelReceipt(String id)  => '$receipts/$id/cancel';

  // ─── Inventory ────────────────────────────────────────────────────────────
  static const String inventoryStock      = '$_base/inventory/stock';
  static const String inventoryMovements  = '$_base/inventory/movements';
  static const String inventoryCostLayers = '$_base/inventory/cost-layers';
  static const String inventoryWarehouses = '$_base/inventory/warehouses';
  static const String inventoryLowStock   = '$_base/inventory/low-stock';
  static String costLayerConsumptions(String id) =>
      '$_base/inventory/cost-layers/$id/consumptions';

  // ─── Warehouses ───────────────────────────────────────────────────────────
  static const String warehouses     = '$_base/warehouses';
  static String warehouseById(String id)  => '$warehouses/$id';
  static String setDefaultWarehouse(String id) => '$warehouses/$id/set-default';

  // ─── Transfers ────────────────────────────────────────────────────────────
  static const String transfers      = '$_base/transfers';
  static String transferById(String id)   => '$transfers/$id';
  static String approveTransfer(String id) => '$transfers/$id/approve';
  static String postTransfer(String id)   => '$transfers/$id/post';
  static String receiveTransfer(String id) => '$transfers/$id/receive';

  // ─── Stock Counts ─────────────────────────────────────────────────────────
  static const String stockCounts    = '$_base/stock-counts';
  static String stockCountById(String id) => '$stockCounts/$id';
  static String postStockCount(String id) => '$stockCounts/$id/post';

  // ─── Adjustments ──────────────────────────────────────────────────────────
  static const String adjustments    = '$_base/adjustments';
  static String adjustmentById(String id)    => '$adjustments/$id';
  static String cancelAdjustment(String id)  => '$adjustments/$id/cancel';
  static String approveAdjustment(String id) => '$adjustments/$id/approve';
  static String postAdjustment(String id)    => '$adjustments/$id/post';

  // ─── Customers ────────────────────────────────────────────────────────────
  static const String customers      = '$_base/customers';
  static String customerById(String id)   => '$customers/$id';

  // ─── Suppliers ────────────────────────────────────────────────────────────
  static const String suppliers      = '$_base/suppliers';
  static String supplierById(String id)   => '$suppliers/$id';
  static const String suppliersLedger = '$_base/suppliers/ledger';
  static const String suppliersAging  = '$_base/suppliers/aging';
  static String supplierLedger(String id)  => '$suppliers/$id/ledger';
  static String supplierPayments(String id) => '$suppliers/$id/payments';

  // ─── Reports ──────────────────────────────────────────────────────────────
  static const String reportsSummary          = '$_base/reports/summary';
  static const String reportsSales            = '$_base/reports/sales';
  static const String reportsProducts         = '$_base/reports/products';
  static const String reportsFinancialPnl     = '$_base/reports/financial/pnl';
  static const String reportsFinancialSales   = '$_base/reports/financial/sales';
  static const String reportsFinancialInventory = '$_base/reports/financial/inventory';
  static const String reportsFinancialFifo    = '$_base/reports/financial/fifo-profit';
  static const String reportsFinancialSummary = '$_base/reports/financial/summary';

  // ─── Export ───────────────────────────────────────────────────────────────
  static const String exportSalesXls          = '$_base/export/reports/sales';
  static const String exportProductsXls       = '$_base/export/reports/products';
  static const String exportSalesPdf          = '$_base/export/pdf/sales';
  static const String exportOrdersPdf         = '$_base/export/pdf/orders';
  static const String exportFinancialPnlXls   = '$_base/export/reports/financial/pnl';
  static const String exportFinancialSalesXls = '$_base/export/reports/financial/sales';
  static const String exportFinancialInventoryXls = '$_base/export/reports/financial/inventory';
  static const String exportFinancialFifoXls  = '$_base/export/reports/financial/fifo-profit';
  static const String exportInventoryStockXls = '$_base/export/reports/inventory/stock';
  static const String exportInventoryMovXls   = '$_base/export/reports/inventory/movements';
  static const String exportSuppliersLedgerXls = '$_base/export/suppliers/ledger';
  static const String exportSuppliersAgingXls  = '$_base/export/suppliers/aging';

  // ─── Branches ─────────────────────────────────────────────────────────────
  static const String branches       = '$_base/branches';
  static String branchById(String id)     => '$branches/$id';

  // ─── Users & Roles ────────────────────────────────────────────────────────
  static const String users          = '$_base/users';
  static String userById(String id)       => '$users/$id';
  static const String roles          = '$_base/roles';

  // ─── Homepage Builder ─────────────────────────────────────────────────────
  static const String vendorPageHome    = '$_base/vendor/page/home';

  // ─── Settings ─────────────────────────────────────────────────────────────
  static const String vendorBranding    = '$_base/vendor/branding';
  static const String vendorSettings    = '$_base/vendor/settings';
  static const String storeSettings     = '$_base/vendor/store-settings';
  static const String devices           = '$_base/settings/devices';
  static const String logoutAllDevices  = '$_base/settings/devices/logout-all';
  static String logoutDevice(String id)  => '$_base/settings/devices/$id/logout';
  static String blockDevice(String id)   => '$_base/settings/devices/$id/block';
  static String unblockDevice(String id) => '$_base/settings/devices/$id/unblock';

  // ─── Notifications ────────────────────────────────────────────────────────
  static const String notifications    = '$_base/notifications';
  static const String unreadCount      = '$_base/notifications/unread-count';
  static const String readAllNotifications = '$_base/notifications/read-all';
  static String readNotification(String id) => '$_base/notifications/$id/read';

  // ─── Activity Log ─────────────────────────────────────────────────────────
  static const String activityLog      = '$_base/activity-log';
  static const String activityLogUsers = '$_base/activity-log/users';

  // ─── Reservations ──────────────────────────────────────────────────────────
  static const String reservations         = '$_base/reservations';
  static String reservationById(String id) => '$reservations/$id';
  static String reservationStatus(String id) => '$reservations/$id/status';
  static const String reservationSettings         = '$_base/reservations/settings';
  static const String reservationSettingsGeneral  = '$_base/reservations/settings/general';
  static const String reservationSettingsSchedule = '$_base/reservations/settings/schedule';
  static const String reservationSettingsSlots    = '$_base/reservations/settings/time-slots';
  static const String reservationExceptions       = '$_base/reservations/settings/exceptions';
  static String reservationExceptionById(String id) => '$reservationExceptions/$id';

  // ─── Public Storefront (no auth) ──────────────────────────────────────────────
  static String storefrontVendor(String slug)     => '/store/$slug';
  static String storefrontCategories(String slug) => '/store/$slug/categories';
  static String storefrontProducts(String slug)   => '/store/$slug/products';
  static String storefrontProduct(String slug, String id) => '/store/$slug/products/$id';
  static String storefrontOrders(String slug)     => '/store/$slug/orders';
  static String storefrontOrderStatus(String slug, String ref) =>
      '/store/$slug/orders/$ref';
  static String storefrontHomepageLayout(String slug) => '/store/$slug/page/home';
  static String storefrontReservations(String slug)   => '/store/$slug/reservations';

  // ─── Public Booking (no auth) ─────────────────────────────────────────────────
  static String bookingInfo(String slug)        => '/api/booking/$slug';
  static String bookingClosedDates(String slug) => '/api/booking/$slug/closed-dates';
  static String bookingSlots(String slug)       => '/api/booking/$slug/slots';
  static String createBooking(String slug)      => '/api/booking/$slug';

  // ─── Admin ────────────────────────────────────────────────────────────────
  static const String adminVendors     = '$_base/admin/vendors';
  static const String adminVendorsCreate = '$adminVendors/create';
  static String adminVendorById(String id) => '$adminVendors/$id';
  static String adminToggleVendor(String id) => '$adminVendors/$id/toggle-status';
  static const String adminPlans       = '$_base/admin/plans';
  static String adminPlanById(String id)    => '$adminPlans/$id';
  static const String adminFeatures    = '$_base/admin/features';
  static const String adminSubscriptions = '$_base/admin/subscriptions';
  static String adminSubscriptionById(String id) => '$adminSubscriptions/$id';
  static String adminVendorSubscriptions(String id) =>
      '$adminVendors/$id/subscriptions';
  static const String adminBillingPayments = '$_base/admin/billing/payments';
  static String adminBillingPaymentById(String id) => '$adminBillingPayments/$id';
  static const String adminBillingInvoices = '$_base/admin/billing/invoices';
  static String adminBillingInvoiceById(String id) => '$adminBillingInvoices/$id';
  static String adminBillingInvoiceMarkPaid(String id) =>
      '$adminBillingInvoices/$id/mark-paid';
  static String adminBillingInvoiceVoid(String id) =>
      '$adminBillingInvoices/$id/void';
  static String adminDeletePlan(String id) => '$adminPlans/$id';
  static const String adminAnalyticsSummary = '$_base/admin/analytics/summary';

  // Finance
  static const String adminFinanceSummary    = '$_base/admin/finance/summary';
  static const String adminFinanceEntries    = '$_base/admin/finance/entries';
  static const String adminFinanceCategories = '$_base/admin/finance/categories';
  static String adminFinanceEntryVoid(String id) => '$adminFinanceEntries/$id/void';
  static String adminFinanceEntryById(String id) => '$adminFinanceEntries/$id';
  static String adminFinanceCategoryById(String id) => '$adminFinanceCategories/$id';
}
