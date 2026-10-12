import '../../domain/entities/ledger_entities.dart';

class LedgerEntryModel extends LedgerEntryEntity {
  const LedgerEntryModel({
    required super.id,
    required super.supplierId,
    required super.supplierName,
    required super.type,
    super.referenceId,
    super.description,
    required super.debit,
    required super.credit,
    required super.balanceAfter,
    required super.entryDate,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return LedgerEntryModel(
      id: json['id']?.toString() ?? '',
      supplierId: json['supplier_id']?.toString() ?? '',
      supplierName: json['supplier_name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      referenceId: json['reference_id']?.toString(),
      description: json['description'] as String?,
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      entryDate: json['entry_date'] as String? ?? '',
    );
  }
}

class LedgerSummaryModel extends LedgerSummary {
  const LedgerSummaryModel({
    required super.totalDebit,
    required super.totalCredit,
    required super.currentBalance,
  });

  factory LedgerSummaryModel.fromJson(Map<String, dynamic> json) {
    return LedgerSummaryModel(
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
