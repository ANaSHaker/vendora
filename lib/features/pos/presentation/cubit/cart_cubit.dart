import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/pos_entities.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  static const int _maxUndoSteps = 20;
  final List<CartState> _history = [];

  CartCubit() : super(const CartState());

  void addItem(PosProductEntity product) {
    _saveHistory();
    final existing = state.items.indexWhere((i) => i.productId == product.id);
    List<CartItem> updated;
    if (existing >= 0) {
      updated = List.of(state.items);
      updated[existing] = updated[existing].copyWith(
        quantity: updated[existing].quantity + 1,
      );
    } else {
      updated = [
        ...state.items,
        CartItem(
          productId: product.id,
          productName: product.name,
          sku: product.sku ?? '',
          price: product.price,
          quantity: 1,
        ),
      ];
    }
    emit(state.copyWith(items: updated));
  }

  void removeItem(String productId) {
    _saveHistory();
    emit(state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
    ));
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    _saveHistory();
    final updated = state.items.map((i) {
      return i.productId == productId ? i.copyWith(quantity: quantity) : i;
    }).toList();
    emit(state.copyWith(items: updated));
  }

  void applyLineDiscount(String productId, double discount) {
    _saveHistory();
    final updated = state.items.map((i) {
      return i.productId == productId ? i.copyWith(lineDiscount: discount) : i;
    }).toList();
    emit(state.copyWith(items: updated));
  }

  void setCustomer(PosCustomerEntity? customer) {
    emit(state.copyWith(customer: () => customer));
  }

  void setDiscount(CartDiscount? discount) {
    _saveHistory();
    emit(state.copyWith(discount: () => discount));
  }

  void setNote(String note) {
    emit(state.copyWith(note: note));
  }

  void clear() {
    _history.clear();
    emit(const CartState());
  }

  void undo() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    emit(previous.copyWith(undoCount: state.undoCount + 1));
  }

  void _saveHistory() {
    _history.add(state);
    if (_history.length > _maxUndoSteps) {
      _history.removeAt(0);
    }
  }

  bool get canUndo => _history.isNotEmpty;
}
