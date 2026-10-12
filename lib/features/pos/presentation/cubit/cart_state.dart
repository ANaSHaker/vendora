import 'package:equatable/equatable.dart';
import '../../domain/entities/pos_entities.dart';

enum DiscountType { flat, percent }

class CartDiscount extends Equatable {
  final DiscountType type;
  final double value;

  const CartDiscount({required this.type, required this.value});

  @override
  List<Object?> get props => [type, value];
}

class CartItem extends Equatable {
  final String productId;
  final String productName;
  final String sku;
  final double price;
  final double quantity;
  final double lineDiscount;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.price,
    required this.quantity,
    this.lineDiscount = 0,
  });

  double get total {
    final net = (price - lineDiscount).clamp(0.0, double.infinity);
    return (net * quantity * 100).round() / 100;
  }

  CartItem copyWith({double? quantity, double? lineDiscount}) => CartItem(
        productId: productId,
        productName: productName,
        sku: sku,
        price: price,
        quantity: quantity ?? this.quantity,
        lineDiscount: lineDiscount ?? this.lineDiscount,
      );

  @override
  List<Object?> get props => [productId, productName, sku, price, quantity, lineDiscount];
}

class CartState extends Equatable {
  final List<CartItem> items;
  final PosCustomerEntity? customer;
  final CartDiscount? discount;
  final String note;
  final int undoCount;

  const CartState({
    this.items = const [],
    this.customer,
    this.discount,
    this.note = '',
    this.undoCount = 0,
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.total);

  double get discountAmount {
    if (discount == null || subtotal == 0) return 0.0;
    final raw = discount!.type == DiscountType.percent
        ? subtotal * discount!.value / 100
        : discount!.value;
    return raw.clamp(0.0, subtotal);
  }

  double get taxableAmount =>
      (subtotal - discountAmount).clamp(0.0, double.infinity);

  double get taxAmount => (taxableAmount * 0.15 * 100).round() / 100;

  double get total => ((taxableAmount + taxAmount) * 100).round() / 100;

  int get itemCount =>
      items.fold(0, (sum, item) => sum + item.quantity.toInt());

  double quantityOf(String productId) =>
      items.firstWhere(
        (i) => i.productId == productId,
        orElse: () => const CartItem(
          productId: '',
          productName: '',
          sku: '',
          price: 0,
          quantity: 0,
        ),
      ).quantity;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  CartState copyWith({
    List<CartItem>? items,
    PosCustomerEntity? Function()? customer,
    CartDiscount? Function()? discount,
    String? note,
    int? undoCount,
  }) {
    return CartState(
      items: items ?? this.items,
      customer: customer != null ? customer() : this.customer,
      discount: discount != null ? discount() : this.discount,
      note: note ?? this.note,
      undoCount: undoCount ?? this.undoCount,
    );
  }

  @override
  List<Object?> get props => [items, customer, discount, note, undoCount];
}
