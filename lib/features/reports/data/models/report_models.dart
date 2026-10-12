import '../../domain/entities/report_entities.dart';

// ─── Sales Report ─────────────────────────────────────────────────────────────

class SalesReportSummaryModel extends SalesReportSummaryEntity {
  const SalesReportSummaryModel({
    required super.totalSales,
    required super.totalRefunds,
    required super.netRevenue,
    required super.totalOrders,
    required super.avgOrderValue,
  });

  static double _n(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  factory SalesReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesReportSummaryModel(
      totalSales: _n(json['total_sales'] ?? json['gross_sales'] ??
          json['total_revenue'] ?? json['gross_revenue'] ?? json['revenue']),
      totalRefunds: _n(json['total_refunds'] ?? json['refunds_amount'] ??
          json['refunds'] ?? json['total_refund']),
      netRevenue: _n(json['net_revenue'] ?? json['net_sales'] ??
          json['net_total']),
      totalOrders: _n(json['total_orders'] ?? json['orders_count'] ??
          json['count'] ?? json['total_count']).toInt(),
      avgOrderValue: _n(json['avg_order_value'] ?? json['average_order_value'] ??
          json['avg_value'] ?? json['average_value']),
    );
  }
}

class SalesByDayModel extends SalesByDayEntity {
  const SalesByDayModel({
    required super.date,
    required super.ordersCount,
    required super.totalSales,
  });

  factory SalesByDayModel.fromJson(Map<String, dynamic> json) {
    return SalesByDayModel(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopSellingProductModel extends TopSellingProductEntity {
  const TopSellingProductModel({
    required super.productId,
    required super.productName,
    super.sku,
    required super.unitsSold,
    required super.totalRevenue,
  });

  factory TopSellingProductModel.fromJson(Map<String, dynamic> json) {
    return TopSellingProductModel(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? '',
      sku: json['sku'] as String?,
      unitsSold: (json['units_sold'] as num?)?.toInt() ??
          (json['total_qty'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalesOrderRowModel extends SalesOrderRowEntity {
  const SalesOrderRowModel({
    required super.id,
    required super.reference,
    required super.status,
    super.customerName,
    required super.paymentMethod,
    required super.total,
    required super.createdAt,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory SalesOrderRowModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return SalesOrderRowModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String? ?? json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? '',
      customerName: customer?['name'] as String? ?? json['customer_name'] as String?,
      paymentMethod: json['payment_method'] as String? ?? '',
      total: _num(json['total'] ?? json['grand_total']),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? json['paid_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SalesReportModel extends SalesReportEntity {
  const SalesReportModel({
    required super.summary,
    required super.salesByDay,
    required super.topProducts,
  });

  factory SalesReportModel.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ??
        json['data'] as Map<String, dynamic>? ?? {};
    final salesJson = json['sales_by_day'] as List<dynamic>? ??
        json['sales_per_day'] as List<dynamic>? ??
        json['daily_sales'] as List<dynamic>? ?? [];
    final productsJson = json['top_products'] as List<dynamic>? ??
        json['top_selling'] as List<dynamic>? ?? [];

    return SalesReportModel(
      summary: SalesReportSummaryModel.fromJson(summaryJson),
      salesByDay: salesJson
          .map((e) => SalesByDayModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topProducts: productsJson
          .map((e) => TopSellingProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Inventory Report ─────────────────────────────────────────────────────────

class InventoryStockItemModel extends InventoryStockItemEntity {
  const InventoryStockItemModel({
    required super.productId,
    required super.productName,
    super.sku,
    required super.onHand,
    required super.avgCost,
    required super.totalValue,
    required super.warehouseName,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory InventoryStockItemModel.fromJson(Map<String, dynamic> json) {
    final onHand = _num(json['on_hand'] ?? json['quantity'] ?? json['qty']).toInt();
    final avgCost = _num(json['avg_cost'] ?? json['average_cost'] ?? json['cost']);
    return InventoryStockItemModel(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String? ??
          json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      onHand: onHand,
      avgCost: avgCost,
      totalValue: _num(json['total_value'] ?? json['value']) > 0
          ? _num(json['total_value'] ?? json['value'])
          : onHand * avgCost,
      warehouseName: json['warehouse_name'] as String? ??
          (json['warehouse'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    );
  }
}

class InventoryReportModel extends InventoryReportEntity {
  const InventoryReportModel({
    required super.items,
    required super.totalInventoryValue,
  });

  factory InventoryReportModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ??
        json['stock'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((e) => InventoryStockItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (json['total_value'] as num?)?.toDouble() ??
        items.fold<double>(0.0, (s, i) => s + i.totalValue);

    return InventoryReportModel(items: items, totalInventoryValue: total);
  }
}

// ─── Financial Report ─────────────────────────────────────────────────────────

class TopProductModel extends TopProductEntity {
  const TopProductModel({
    required super.productId,
    required super.productName,
    required super.revenue,
    required super.cogs,
    required super.profit,
    super.marginPercent,
  });

  static double _n(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    final revenue = _n(json['revenue']);
    final cogs = _n(json['cogs'] ?? json['total_cost'] ?? json['cost']);
    final profit = _n(json['profit']) != 0.0 ? _n(json['profit']) : revenue - cogs;
    final margin = (json['margin_percent'] as num?)?.toDouble() ??
        (revenue > 0 ? (profit / revenue) * 100 : null);
    return TopProductModel(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? json['name'] as String? ?? '',
      revenue: revenue,
      cogs: cogs,
      profit: profit,
      marginPercent: margin,
    );
  }
}

class FinancialSummaryModel extends FinancialSummaryEntity {
  const FinancialSummaryModel({
    required super.grossRevenue,
    required super.totalCost,
    required super.grossProfit,
    required super.profitMargin,
    required super.totalRefunds,
    required super.netRevenue,
    required super.totalOrders,
    super.revenueBasis,
    super.topProfitableProducts,
    super.worstMarginProducts,
  });

  static double _n(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    final grossRevenue = _n(json['total_revenue'] ?? json['gross_revenue'] ??
        json['total_sales'] ?? json['revenue']);
    final totalCost = _n(json['total_cogs'] ?? json['total_cost'] ??
        json['cost_of_goods_sold'] ?? json['cost_of_goods']);
    final grossProfit = _n(json['total_profit'] ?? json['gross_profit']) != 0.0
        ? _n(json['total_profit'] ?? json['gross_profit'])
        : grossRevenue - totalCost;
    final margin = grossRevenue > 0 ? (grossProfit / grossRevenue) * 100 : 0.0;
    final totalRefunds = _n(json['total_refunds'] ?? json['refunds']);

    List<TopProductEntity> parseTopList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((e) => TopProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return FinancialSummaryModel(
      grossRevenue: grossRevenue,
      totalCost: totalCost,
      grossProfit: grossProfit,
      profitMargin: _n(json['profit_margin'] ?? json['gross_margin']) != 0.0
          ? _n(json['profit_margin'] ?? json['gross_margin'])
          : margin,
      totalRefunds: totalRefunds,
      netRevenue: _n(json['net_revenue']) != 0.0
          ? _n(json['net_revenue'])
          : grossRevenue - totalRefunds,
      totalOrders: _n(json['total_orders'] ?? json['orders_count']),
      revenueBasis: json['revenue_basis'] as String? ?? 'order_total',
      topProfitableProducts:
          parseTopList(json['top_profitable_products'] ?? json['top_products']),
      worstMarginProducts:
          parseTopList(json['worst_margin_products'] ?? json['worst_products']),
    );
  }
}

class PnlRowModel extends PnlRowEntity {
  const PnlRowModel({
    required super.label,
    required super.amount,
    super.isSubtotal,
  });

  factory PnlRowModel.fromJson(Map<String, dynamic> json) {
    return PnlRowModel(
      label: json['label'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isSubtotal: json['is_subtotal'] as bool? ?? false,
    );
  }

  static double _n(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  /// Converts the flat P&L object `{revenue, cost_of_goods_sold, gross_profit, gross_margin}`
  /// returned by the backend into a list of labeled rows.
  static List<PnlRowModel> fromPnlObject(Map<String, dynamic> json) {
    final revenue = _n(json['revenue'] ?? json['total_revenue']);
    final cogs = _n(json['cost_of_goods_sold'] ?? json['total_cogs'] ?? json['cogs']);
    final grossProfit = _n(json['gross_profit'] ?? json['total_profit']) != 0.0
        ? _n(json['gross_profit'] ?? json['total_profit'])
        : revenue - cogs;
    final margin = _n(json['gross_margin'] ?? json['gross_margin_ratio']) != 0.0
        ? _n(json['gross_margin'] ?? json['gross_margin_ratio'])
        : (revenue > 0 ? (grossProfit / revenue) * 100 : 0.0);
    return [
      PnlRowModel(label: 'revenue', amount: revenue),
      PnlRowModel(label: 'cogs', amount: cogs),
      PnlRowModel(label: 'grossProfit', amount: grossProfit, isSubtotal: true),
      PnlRowModel(label: 'grossMargin', amount: margin),
    ];
  }
}

class FifoProfitRowModel extends FifoProfitRowEntity {
  const FifoProfitRowModel({
    super.orderId,
    required super.productName,
    super.sku,
    required super.unitsSold,
    required super.salePrice,
    required super.revenue,
    required super.cost,
    required super.profit,
    required super.margin,
  });

  static double _n(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  factory FifoProfitRowModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final revenue = _n(json['revenue'] ?? json['line_revenue']);
    final cost = _n(json['cost'] ?? json['actual_fifo_cost']);
    final profit = _n(json['profit']) != 0.0 ? _n(json['profit']) : revenue - cost;
    final margin = _n(json['margin']) != 0.0
        ? _n(json['margin'])
        : (revenue > 0 ? (profit / revenue) * 100 : 0.0);

    return FifoProfitRowModel(
      orderId: json['order_id']?.toString(),
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      sku: product?['sku'] as String? ?? json['sku'] as String?,
      unitsSold: (_n(json['units_sold'] ?? json['qty'])).toInt(),
      salePrice: _n(json['sale_price'] ?? json['unit_price']),
      revenue: revenue,
      cost: cost,
      profit: profit,
      margin: margin,
    );
  }
}

class FinancialSalesRowModel extends FinancialSalesRowEntity {
  const FinancialSalesRowModel({
    super.orderId,
    required super.productName,
    required super.qty,
    required super.salePrice,
    required super.revenue,
    required super.unitCost,
    required super.totalCost,
    required super.profit,
    required super.marginPercent,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory FinancialSalesRowModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final revenue = _num(json['revenue'] ?? json['total_revenue'] ?? json['line_revenue']);
    final totalCost = _num(json['total_cost'] ?? json['actual_fifo_cost'] ?? json['cost']);
    final profit = _num(json['profit']) > 0 ? _num(json['profit']) : revenue - totalCost;
    final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
    return FinancialSalesRowModel(
      orderId: json['order_id']?.toString(),
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      qty: (_num(json['qty'] ?? json['quantity'] ?? json['units_sold'])).toInt(),
      salePrice: _num(json['sale_price'] ?? json['unit_price']),
      revenue: revenue,
      unitCost: _num(json['unit_cost'] ?? json['avg_cost']),
      totalCost: totalCost,
      profit: profit,
      marginPercent: _num(json['margin_percent'] ?? json['margin']) > 0
          ? _num(json['margin_percent'] ?? json['margin'])
          : margin,
    );
  }
}

class FinancialInventoryRowModel extends FinancialInventoryRowEntity {
  const FinancialInventoryRowModel({
    required super.productName,
    required super.warehouseName,
    required super.qtyOnHand,
    required super.avgCost,
    required super.totalValue,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory FinancialInventoryRowModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final onHand = _num(json['qty_on_hand'] ?? json['on_hand'] ?? json['quantity']).toInt();
    final avgCost = _num(json['avg_cost'] ?? json['average_cost'] ?? json['cost']);
    return FinancialInventoryRowModel(
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      warehouseName: warehouse?['name'] as String? ??
          json['warehouse_name'] as String? ?? '',
      qtyOnHand: onHand,
      avgCost: avgCost,
      totalValue: _num(json['total_value'] ?? json['value']) > 0
          ? _num(json['total_value'] ?? json['value'])
          : onHand * avgCost,
    );
  }
}

class FinancialReportModel extends FinancialReportEntity {
  const FinancialReportModel({
    required super.summary,
    required super.pnlRows,
    required super.fifoRows,
    super.salesRows,
    super.inventoryRows,
  });
}

// ─── Inventory Tab Models ─────────────────────────────────────────────────────

class StockByWarehouseModel extends StockByWarehouseEntity {
  const StockByWarehouseModel({
    required super.productId,
    required super.productName,
    super.sku,
    required super.warehouseName,
    super.branchName,
    required super.onHand,
    super.reserved,
    super.available,
    required super.avgCost,
    required super.totalValue,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory StockByWarehouseModel.fromJson(Map<String, dynamic> json) {
    final product  = json['product']   is Map ? json['product']   as Map<String, dynamic> : null;
    final warehouse= json['warehouse'] is Map ? json['warehouse'] as Map<String, dynamic> : null;
    final branch   = json['branch']    is Map ? json['branch']    as Map<String, dynamic> : null;
    // financial/inventory uses qty_on_hand; inventory/stock uses current_stock
    final onHand = _num(
      json['qty_on_hand'] ?? json['on_hand'] ?? json['quantity'] ??
      json['qty'] ?? json['current_stock'] ?? json['stock_quantity']
    ).toInt();
    final reserved = _num(json['reserved'] ?? json['committed'] ?? 0).toInt();
    final available = _num(
      json['available'] ?? json['available_qty'] ?? json['available_quantity']
    ).toInt();
    final avgCost = _num(
      json['avg_cost'] ?? json['average_cost'] ?? json['cost'] ??
      json['unit_cost'] ?? json['purchase_price']
    );
    final tv = _num(json['total_value'] ?? json['value'] ?? json['total']);
    return StockByWarehouseModel(
      productId: product?['id']?.toString() ??
          json['product_id']?.toString() ?? json['id']?.toString() ?? '',
      productName: product?['name'] as String? ??
          json['product_name'] as String? ?? json['name'] as String? ?? '',
      sku: product?['sku'] as String? ?? json['sku'] as String?,
      warehouseName: warehouse?['name'] as String? ??
          json['warehouse_name'] as String? ?? '',
      branchName: branch?['name'] as String? ??
          json['branch_name'] as String? ??
          (json['branch'] is String ? json['branch'] as String : null),
      onHand: onHand,
      reserved: reserved,
      available: available > 0 ? available : null,
      avgCost: avgCost,
      totalValue: tv > 0 ? tv : onHand * avgCost,
    );
  }
}

class MovementModel extends MovementEntity {
  const MovementModel({
    required super.id,
    required super.productName,
    super.sku,
    required super.type,
    required super.quantity,
    super.reference,
    required super.warehouseName,
    required super.createdAt,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory MovementModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    return MovementModel(
      id: json['id']?.toString() ?? '',
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      sku: product?['sku'] as String? ?? json['sku'] as String?,
      type: json['type'] as String? ?? json['movement_type'] as String? ?? '',
      quantity: _num(json['quantity'] ?? json['qty']).toInt(),
      reference: json['reference'] as String? ?? json['ref'] as String?,
      warehouseName: warehouse?['name'] as String? ?? json['warehouse_name'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TransferRowModel extends TransferRowEntity {
  const TransferRowModel({
    required super.id,
    required super.reference,
    required super.status,
    required super.fromWarehouse,
    required super.toWarehouse,
    required super.itemsCount,
    required super.createdAt,
  });

  factory TransferRowModel.fromJson(Map<String, dynamic> json) {
    final from = json['from_warehouse'] as Map<String, dynamic>?;
    final to = json['to_warehouse'] as Map<String, dynamic>?;
    final items = json['items'] as List<dynamic>? ?? json['transfer_items'] as List<dynamic>? ?? [];
    return TransferRowModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String? ?? json['ref'] as String? ?? '',
      status: json['status'] as String? ?? '',
      fromWarehouse: from?['name'] as String? ?? json['from_warehouse_name'] as String? ?? '',
      toWarehouse: to?['name'] as String? ?? json['to_warehouse_name'] as String? ?? '',
      itemsCount: items.length > 0 ? items.length : (json['items_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class StockCountRowModel extends StockCountRowEntity {
  const StockCountRowModel({
    required super.id,
    required super.reference,
    required super.status,
    required super.warehouseName,
    required super.itemsCount,
    required super.createdAt,
  });

  factory StockCountRowModel.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final items = json['items'] as List<dynamic>? ?? json['count_items'] as List<dynamic>? ?? [];
    return StockCountRowModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String? ?? json['ref'] as String? ?? '',
      status: json['status'] as String? ?? '',
      warehouseName: warehouse?['name'] as String? ?? json['warehouse_name'] as String? ?? '',
      itemsCount: items.length > 0 ? items.length : (json['items_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
