import 'package:equatable/equatable.dart';

// ─── Sales Report ─────────────────────────────────────────────────────────────

class SalesReportSummaryEntity extends Equatable {
  final double totalSales;
  final double totalRefunds;
  final double netRevenue;
  final int totalOrders;
  final double avgOrderValue;

  const SalesReportSummaryEntity({
    required this.totalSales,
    required this.totalRefunds,
    required this.netRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
  });

  @override
  List<Object?> get props =>
      [totalSales, totalRefunds, netRevenue, totalOrders, avgOrderValue];
}

class SalesByDayEntity extends Equatable {
  final DateTime date;
  final int ordersCount;
  final double totalSales;

  const SalesByDayEntity({
    required this.date,
    required this.ordersCount,
    required this.totalSales,
  });

  @override
  List<Object?> get props => [date, ordersCount, totalSales];
}

class TopSellingProductEntity extends Equatable {
  final String productId;
  final String productName;
  final String? sku;
  final int unitsSold;
  final double totalRevenue;

  const TopSellingProductEntity({
    required this.productId,
    required this.productName,
    this.sku,
    required this.unitsSold,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props =>
      [productId, productName, sku, unitsSold, totalRevenue];
}

class SalesOrderRowEntity extends Equatable {
  final String id;
  final String reference;
  final String status;
  final String? customerName;
  final String paymentMethod;
  final double total;
  final DateTime createdAt;

  const SalesOrderRowEntity({
    required this.id,
    required this.reference,
    required this.status,
    this.customerName,
    required this.paymentMethod,
    required this.total,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, reference, status, customerName, paymentMethod, total, createdAt];
}

class SalesReportEntity extends Equatable {
  final SalesReportSummaryEntity summary;
  final List<SalesByDayEntity> salesByDay;
  final List<TopSellingProductEntity> topProducts;

  const SalesReportEntity({
    required this.summary,
    required this.salesByDay,
    required this.topProducts,
  });

  @override
  List<Object?> get props => [summary, salesByDay, topProducts];
}

// ─── Inventory Report ─────────────────────────────────────────────────────────

class InventoryStockItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String? sku;
  final int onHand;
  final double avgCost;
  final double totalValue;
  final String warehouseName;

  const InventoryStockItemEntity({
    required this.productId,
    required this.productName,
    this.sku,
    required this.onHand,
    required this.avgCost,
    required this.totalValue,
    required this.warehouseName,
  });

  @override
  List<Object?> get props =>
      [productId, productName, sku, onHand, avgCost, totalValue, warehouseName];
}

class InventoryReportEntity extends Equatable {
  final List<InventoryStockItemEntity> items;
  final double totalInventoryValue;

  const InventoryReportEntity({
    required this.items,
    required this.totalInventoryValue,
  });

  @override
  List<Object?> get props => [items, totalInventoryValue];
}

// ─── Financial Report ─────────────────────────────────────────────────────────

class TopProductEntity extends Equatable {
  final String productId;
  final String productName;
  final double revenue;
  final double cogs;
  final double profit;
  final double? marginPercent;

  const TopProductEntity({
    required this.productId,
    required this.productName,
    required this.revenue,
    required this.cogs,
    required this.profit,
    this.marginPercent,
  });

  @override
  List<Object?> get props =>
      [productId, productName, revenue, cogs, profit, marginPercent];
}

class FinancialSummaryEntity extends Equatable {
  final double grossRevenue;
  final double totalCost;
  final double grossProfit;
  final double profitMargin;
  final double totalRefunds;
  final double netRevenue;
  final double totalOrders;
  final String revenueBasis;
  final List<TopProductEntity> topProfitableProducts;
  final List<TopProductEntity> worstMarginProducts;

  const FinancialSummaryEntity({
    required this.grossRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.profitMargin,
    required this.totalRefunds,
    required this.netRevenue,
    required this.totalOrders,
    this.revenueBasis = 'order_total',
    this.topProfitableProducts = const [],
    this.worstMarginProducts = const [],
  });

  @override
  List<Object?> get props => [
        grossRevenue,
        totalCost,
        grossProfit,
        profitMargin,
        totalRefunds,
        netRevenue,
        totalOrders,
        revenueBasis,
        topProfitableProducts,
        worstMarginProducts,
      ];
}

class PnlRowEntity extends Equatable {
  final String label;
  final double amount;
  final bool isSubtotal;

  const PnlRowEntity({
    required this.label,
    required this.amount,
    this.isSubtotal = false,
  });

  @override
  List<Object?> get props => [label, amount, isSubtotal];
}

class FifoProfitRowEntity extends Equatable {
  final String? orderId;
  final String productName;
  final String? sku;
  final int unitsSold;
  final double salePrice;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;

  const FifoProfitRowEntity({
    this.orderId,
    required this.productName,
    this.sku,
    required this.unitsSold,
    required this.salePrice,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
  });

  @override
  List<Object?> get props =>
      [orderId, productName, sku, unitsSold, salePrice, revenue, cost, profit, margin];
}

class FinancialSalesRowEntity extends Equatable {
  final String? orderId;
  final String productName;
  final int qty;
  final double salePrice;
  final double revenue;
  final double unitCost;
  final double totalCost;
  final double profit;
  final double marginPercent;

  const FinancialSalesRowEntity({
    this.orderId,
    required this.productName,
    required this.qty,
    required this.salePrice,
    required this.revenue,
    required this.unitCost,
    required this.totalCost,
    required this.profit,
    required this.marginPercent,
  });

  @override
  List<Object?> get props =>
      [orderId, productName, qty, salePrice, revenue, unitCost, totalCost, profit, marginPercent];
}

class FinancialInventoryRowEntity extends Equatable {
  final String productName;
  final String warehouseName;
  final int qtyOnHand;
  final double avgCost;
  final double totalValue;

  const FinancialInventoryRowEntity({
    required this.productName,
    required this.warehouseName,
    required this.qtyOnHand,
    required this.avgCost,
    required this.totalValue,
  });

  @override
  List<Object?> get props =>
      [productName, warehouseName, qtyOnHand, avgCost, totalValue];
}

class FinancialReportEntity extends Equatable {
  final FinancialSummaryEntity summary;
  final List<PnlRowEntity> pnlRows;
  final List<FifoProfitRowEntity> fifoRows;
  final List<FinancialSalesRowEntity> salesRows;
  final List<FinancialInventoryRowEntity> inventoryRows;

  const FinancialReportEntity({
    required this.summary,
    required this.pnlRows,
    required this.fifoRows,
    this.salesRows = const [],
    this.inventoryRows = const [],
  });

  @override
  List<Object?> get props => [summary, pnlRows, fifoRows, salesRows, inventoryRows];
}

// ─── Inventory Report (multi-tab) ────────────────────────────────────────────

class StockByWarehouseEntity extends Equatable {
  final String productId;
  final String productName;
  final String? sku;
  final String warehouseName;
  final String? branchName;
  final int onHand;
  final int reserved;
  final int available;
  final double avgCost;
  final double totalValue;

  const StockByWarehouseEntity({
    required this.productId,
    required this.productName,
    this.sku,
    required this.warehouseName,
    this.branchName,
    required this.onHand,
    this.reserved = 0,
    int? available,
    required this.avgCost,
    required this.totalValue,
  }) : available = available ?? (onHand - reserved < 0 ? 0 : onHand - reserved);

  @override
  List<Object?> get props =>
      [productId, productName, sku, warehouseName, branchName,
       onHand, reserved, available, avgCost, totalValue];
}

class MovementEntity extends Equatable {
  final String id;
  final String productName;
  final String? sku;
  final String type;
  final int quantity;
  final String? reference;
  final String warehouseName;
  final DateTime createdAt;

  const MovementEntity({
    required this.id,
    required this.productName,
    this.sku,
    required this.type,
    required this.quantity,
    this.reference,
    required this.warehouseName,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, productName, sku, type, quantity, reference, warehouseName, createdAt];
}

class TransferRowEntity extends Equatable {
  final String id;
  final String reference;
  final String status;
  final String fromWarehouse;
  final String toWarehouse;
  final int itemsCount;
  final DateTime createdAt;

  const TransferRowEntity({
    required this.id,
    required this.reference,
    required this.status,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.itemsCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, reference, status, fromWarehouse, toWarehouse, itemsCount, createdAt];
}

class StockCountRowEntity extends Equatable {
  final String id;
  final String reference;
  final String status;
  final String warehouseName;
  final int itemsCount;
  final DateTime createdAt;

  const StockCountRowEntity({
    required this.id,
    required this.reference,
    required this.status,
    required this.warehouseName,
    required this.itemsCount,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, reference, status, warehouseName, itemsCount, createdAt];
}

class InventoryTabReport extends Equatable {
  final List<StockByWarehouseEntity> stock;
  final double totalStockValue;
  final List<MovementEntity> movements;
  final List<TransferRowEntity> transfers;
  final List<StockCountRowEntity> stockCounts;

  const InventoryTabReport({
    this.stock = const [],
    this.totalStockValue = 0.0,
    this.movements = const [],
    this.transfers = const [],
    this.stockCounts = const [],
  });

  @override
  List<Object?> get props =>
      [stock, totalStockValue, movements, transfers, stockCounts];
}
