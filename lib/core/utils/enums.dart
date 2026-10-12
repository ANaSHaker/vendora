enum OrderStatus {
  paid,
  refunded,
  partialRefund,
  cancelled;

  static OrderStatus fromString(String value) {
    return switch (value) {
      'paid'           => paid,
      'refunded'       => refunded,
      'partial_refund' => partialRefund,
      'cancelled'      => cancelled,
      _                => paid,
    };
  }
}

enum FulfillmentStatus {
  preparing,
  ready,
  completed,
  cancelled;

  static FulfillmentStatus fromString(String value) {
    return switch (value) {
      'preparing' => preparing,
      'ready'     => ready,
      'completed' => completed,
      'cancelled' => cancelled,
      _           => preparing,
    };
  }
}

enum OrderChannel {
  pos,
  online;

  static OrderChannel fromString(String value) =>
      value == 'online' ? online : pos;
}

enum TransferStatus {
  draft,
  approved,
  inTransit,
  received,
  cancelled;

  static TransferStatus fromString(String value) {
    return switch (value) {
      'draft'      => draft,
      'approved'   => approved,
      'in_transit' => inTransit,
      'received'   => received,
      'cancelled'  => cancelled,
      _            => draft,
    };
  }
}

enum AdjustmentStatus {
  draft,
  approved,
  posted,
  cancelled;

  static AdjustmentStatus fromString(String value) {
    return switch (value) {
      'draft'     => draft,
      'approved'  => approved,
      'posted'    => posted,
      'cancelled' => cancelled,
      _           => draft,
    };
  }
}

enum ReceiptStatus {
  draft,
  posted,
  cancelled;

  static ReceiptStatus fromString(String value) {
    return switch (value) {
      'draft'     => draft,
      'posted'    => posted,
      'cancelled' => cancelled,
      _           => draft,
    };
  }
}

enum StockMovementType {
  saleIssue,
  goodsReceipt,
  adjustmentIn,
  adjustmentOut,
  transferOut,
  transferIn,
  returnToStock;

  static StockMovementType fromString(String value) {
    return switch (value) {
      'sale_issue'      => saleIssue,
      'goods_receipt'   => goodsReceipt,
      'adjustment_in'   => adjustmentIn,
      'adjustment_out'  => adjustmentOut,
      'transfer_out'    => transferOut,
      'transfer_in'     => transferIn,
      'return_to_stock' => returnToStock,
      _                 => saleIssue,
    };
  }
}

enum PaymentMethod {
  cash,
  card,
  wallet,
  voucher,
  other;

  static PaymentMethod fromString(String value) {
    return switch (value) {
      'cash'    => cash,
      'card'    => card,
      'wallet'  => wallet,
      'voucher' => voucher,
      _         => other,
    };
  }
}

enum VendorStatus {
  active,
  suspended,
  inactive;

  static VendorStatus fromString(String value) {
    return switch (value) {
      'active'    => active,
      'suspended' => suspended,
      'inactive'  => inactive,
      _           => inactive,
    };
  }
}

enum ThemeMode {
  light,
  dark,
  system;

  static ThemeMode fromString(String value) {
    return switch (value) {
      'light'  => light,
      'dark'   => dark,
      _        => system,
    };
  }
}
