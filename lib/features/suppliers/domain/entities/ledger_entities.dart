import 'package:equatable/equatable.dart';

class LedgerEntryEntity extends Equatable {
  final String id;
  final String supplierId;
  final String supplierName;
  final String type;
  final String? referenceId;
  final String? description;
  final double debit;
  final double credit;
  final double balanceAfter;
  final String entryDate;

  const LedgerEntryEntity({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.type,
    this.referenceId,
    this.description,
    required this.debit,
    required this.credit,
    required this.balanceAfter,
    required this.entryDate,
  });

  @override
  List<Object?> get props => [
        id,
        supplierId,
        supplierName,
        type,
        referenceId,
        description,
        debit,
        credit,
        balanceAfter,
        entryDate,
      ];
}

class LedgerSummary extends Equatable {
  final double totalDebit;
  final double totalCredit;
  final double currentBalance;

  const LedgerSummary({
    required this.totalDebit,
    required this.totalCredit,
    required this.currentBalance,
  });

  const LedgerSummary.empty()
      : totalDebit = 0,
        totalCredit = 0,
        currentBalance = 0;

  @override
  List<Object?> get props => [totalDebit, totalCredit, currentBalance];
}
