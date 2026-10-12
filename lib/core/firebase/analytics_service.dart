import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Central analytics service — call AppAnalytics.instance.logX() from anywhere.
class AppAnalytics {
  AppAnalytics._();
  static final AppAnalytics instance = AppAnalytics._();

  late final FirebaseAnalytics _analytics;
  bool _ready = false;

  void init() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _ready = true;
    } catch (e) {
      debugPrint('[Analytics] init failed: $e');
    }
  }

  Future<void> _log(String name,
      [Map<String, Object>? params]) async {
    if (!_ready) return;
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('[Analytics] logEvent $name failed: $e');
    }
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<void> logLogin({required String method}) =>
      _log('login', {'method': method});

  Future<void> logLogout() => _log('logout');

  Future<void> setUser(String? userId, {String? email}) async {
    if (!_ready) return;
    try {
      await _analytics.setUserId(id: userId);
      if (email != null) {
        await _analytics.setUserProperty(name: 'user_email', value: email);
      }
    } catch (_) {}
  }

  // ─── Screen Tracking ──────────────────────────────────────────────────────

  Future<void> logScreenView(String screen, {String? className}) =>
      _log('screen_view', {
        'firebase_screen': screen,
        if (className != null) 'firebase_screen_class': className,
      });

  // ─── POS ──────────────────────────────────────────────────────────────────

  Future<void> logPosSessionStarted({
    required String branchId,
    required String branchName,
    String? warehouseId,
  }) =>
      _log('pos_session_started', {
        'branch_id': branchId,
        'branch_name': branchName,
        if (warehouseId != null) 'warehouse_id': warehouseId,
      });

  Future<void> logPosItemAdded({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
  }) =>
      _log('pos_item_added', {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'quantity': quantity,
      });

  Future<void> logPosItemRemoved(String productId) =>
      _log('pos_item_removed', {'product_id': productId});

  Future<void> logPosDiscountApplied({
    required String type,
    required double value,
  }) =>
      _log('pos_discount_applied', {'type': type, 'value': value});

  Future<void> logPosOrderPlaced({
    required double total,
    required int itemsCount,
    required String paymentMethod,
  }) =>
      _log('pos_order_placed', {
        'total': total,
        'items_count': itemsCount,
        'payment_method': paymentMethod,
      });

  Future<void> logPosReceiptPrinted() => _log('pos_receipt_printed');

  // ─── Orders ───────────────────────────────────────────────────────────────

  Future<void> logOrderViewed(String orderId) =>
      _log('order_viewed', {'order_id': orderId});

  Future<void> logOrderStatusChanged({
    required String orderId,
    required String from,
    required String to,
  }) =>
      _log('order_status_changed',
          {'order_id': orderId, 'from': from, 'to': to});

  Future<void> logOrderRefunded({
    required String orderId,
    required double amount,
  }) =>
      _log('order_refunded', {'order_id': orderId, 'amount': amount});

  // ─── Products ─────────────────────────────────────────────────────────────

  Future<void> logProductCreated(String productName) =>
      _log('product_created', {'product_name': productName});

  Future<void> logProductUpdated(String productId) =>
      _log('product_updated', {'product_id': productId});

  Future<void> logProductDeleted(String productId) =>
      _log('product_deleted', {'product_id': productId});

  Future<void> logProductImported(int count) =>
      _log('product_imported', {'count': count});

  Future<void> logProductExported() => _log('product_exported');

  // ─── Inventory ────────────────────────────────────────────────────────────

  Future<void> logStockCountCreated() => _log('stock_count_created');

  Future<void> logStockCountPosted(String countId) =>
      _log('stock_count_posted', {'count_id': countId});

  Future<void> logAdjustmentCreated({required String type}) =>
      _log('adjustment_created', {'type': type});

  Future<void> logTransferCreated({
    required String fromWarehouse,
    required String toWarehouse,
  }) =>
      _log('transfer_created', {
        'from_warehouse': fromWarehouse,
        'to_warehouse': toWarehouse,
      });

  Future<void> logWarehouseCreated() => _log('warehouse_created');

  // ─── Customers & Suppliers ────────────────────────────────────────────────

  Future<void> logCustomerCreated() => _log('customer_created');
  Future<void> logSupplierCreated() => _log('supplier_created');
  Future<void> logLedgerViewed(String supplierId) =>
      _log('ledger_viewed', {'supplier_id': supplierId});

  // ─── Reports ──────────────────────────────────────────────────────────────

  Future<void> logReportViewed(String reportType) =>
      _log('report_viewed', {'report_type': reportType});

  Future<void> logReportExported({
    required String reportType,
    required String format,
  }) =>
      _log('report_exported', {'report_type': reportType, 'format': format});

  // ─── Settings ─────────────────────────────────────────────────────────────

  Future<void> logLanguageChanged({
    required String from,
    required String to,
  }) =>
      _log('language_changed', {'from': from, 'to': to});

  Future<void> logThemeChanged({
    required String mode,
    required String color,
  }) =>
      _log('theme_changed', {'mode': mode, 'color': color});

  Future<void> logBranchCreated() => _log('branch_created');

  // ─── Search & Navigation ──────────────────────────────────────────────────

  Future<void> logSearch({
    required String screen,
    required int queryLength,
  }) =>
      _log('search_performed', {
        'screen': screen,
        'query_length': queryLength,
      });

  Future<void> logNotificationTapped({required String type}) =>
      _log('notification_tapped', {'type': type});

  // ─── Errors (lightweight — full errors go to Firestore) ───────────────────

  Future<void> logApiError({
    required String endpoint,
    required String method,
    int? statusCode,
  }) =>
      _log('api_error', {
        'endpoint': endpoint,
        'method': method,
        if (statusCode != null) 'status_code': statusCode,
      });
}
