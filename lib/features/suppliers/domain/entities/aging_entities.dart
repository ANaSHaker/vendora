import 'package:equatable/equatable.dart';

class AgingRowEntity extends Equatable {
  final String supplierId;
  final String supplierName;
  final double current;
  final double bucket1to30;
  final double bucket31to60;
  final double bucket61to90;
  final double over90;
  final double totalBalance;

  const AgingRowEntity({
    required this.supplierId,
    required this.supplierName,
    required this.current,
    required this.bucket1to30,
    required this.bucket31to60,
    required this.bucket61to90,
    required this.over90,
    required this.totalBalance,
  });

  @override
  List<Object?> get props => [
        supplierId,
        supplierName,
        current,
        bucket1to30,
        bucket31to60,
        bucket61to90,
        over90,
        totalBalance,
      ];
}

class AgingTotals extends Equatable {
  final double current;
  final double bucket1to30;
  final double bucket31to60;
  final double bucket61to90;
  final double over90;
  final double totalBalance;

  const AgingTotals({
    required this.current,
    required this.bucket1to30,
    required this.bucket31to60,
    required this.bucket61to90,
    required this.over90,
    required this.totalBalance,
  });

  factory AgingTotals.fromRows(List<AgingRowEntity> rows) {
    double c = 0, b1 = 0, b2 = 0, b3 = 0, o90 = 0, tot = 0;
    for (final r in rows) {
      c   += r.current;
      b1  += r.bucket1to30;
      b2  += r.bucket31to60;
      b3  += r.bucket61to90;
      o90 += r.over90;
      tot += r.totalBalance;
    }
    return AgingTotals(
      current: c,
      bucket1to30: b1,
      bucket31to60: b2,
      bucket61to90: b3,
      over90: o90,
      totalBalance: tot,
    );
  }

  const AgingTotals.empty()
      : current = 0,
        bucket1to30 = 0,
        bucket31to60 = 0,
        bucket61to90 = 0,
        over90 = 0,
        totalBalance = 0;

  @override
  List<Object?> get props =>
      [current, bucket1to30, bucket31to60, bucket61to90, over90, totalBalance];
}
