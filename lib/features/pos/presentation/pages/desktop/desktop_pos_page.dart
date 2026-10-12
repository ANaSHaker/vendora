import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/pos_cubit.dart';
import '../../../services/pos_sound_service.dart';
import '../../cubit/pos_state.dart';
import 'widgets/pos_discount_modal.dart';
import 'widgets/pos_header.dart';
import 'widgets/pos_left_panel.dart';
import 'widgets/pos_payment_modal.dart';
import 'widgets/pos_right_panel.dart';
import 'widgets/pos_setup_dialog.dart';

class DesktopPosPage extends StatelessWidget {
  const DesktopPosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CartCubit(),
        ),
        BlocProvider(
          create: (_) => PosCubit(
            getBranches: getIt(),
            getWarehouses: getIt(),
            getProducts: getIt(),
            getCategories: getIt(),
            createOrder: getIt(),
            storage: getIt(),
          )..initialize(),
        ),
      ],
      child: const _PosScaffold(),
    );
  }
}

class _PosScaffold extends StatefulWidget {
  const _PosScaffold();

  @override
  State<_PosScaffold> createState() => _PosScaffoldState();
}

class _PosScaffoldState extends State<_PosScaffold> {
  final FocusNode _searchFocusNode = FocusNode();

  // Barcode scanner state
  final StringBuffer _barcodeBuffer = StringBuffer();
  DateTime? _lastScanKey;
  Timer? _barcodeTimer;

  // Guard against double-opening dialogs
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _barcodeTimer?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _editableHasFocus() =>
      FocusManager.instance.primaryFocus?.context?.widget is EditableText;

  bool _onHardwareKey(KeyEvent event) {
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;

    final editableHasFocus = _editableHasFocus();
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // ── Barcode scanner collection (only when no text field is focused) ──
    if (!editableHasFocus) {
      final ch = event.character;
      final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter;

      if (!isEnter && ch != null && ch.isNotEmpty) {
        final now = DateTime.now();
        // If gap is >= 150ms → human keystroke, clear buffer and start fresh
        if (_lastScanKey != null &&
            now.difference(_lastScanKey!).inMilliseconds >= 150) {
          _barcodeBuffer.clear();
        }
        _barcodeBuffer.write(ch);
        _lastScanKey = now;
        // Auto-process after 200ms of silence (scanner done without Enter)
        _barcodeTimer?.cancel();
        _barcodeTimer =
            Timer(const Duration(milliseconds: 200), _processBarcode);
        return false; // Let char propagate normally
      }

      if (isEnter && _barcodeBuffer.isNotEmpty) {
        _barcodeTimer?.cancel();
        _processBarcode();
        return false;
      }
    }

    // ── Standard keyboard shortcuts (no text field, no dialog open) ──
    if (!editableHasFocus && !_dialogOpen) {
      // / → focus search field
      if (event.logicalKey == LogicalKeyboardKey.slash && !isCtrl) {
        _searchFocusNode.requestFocus();
        return true;
      }

      // Enter → open payment modal
      if ((event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
          _barcodeBuffer.isEmpty) {
        _openPaymentModal();
        return false;
      }

      // D → open discount modal
      if (event.logicalKey == LogicalKeyboardKey.keyD && !isCtrl) {
        _openDiscountModal();
        return true;
      }

      // Ctrl+Z / Cmd+Z → undo
      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
        context.read<CartCubit>().undo();
        PosSoundService.undo();
        return true;
      }

      // F1–F5 → switch category
      _handleFunctionKey(event.logicalKey);
    }

    // Escape → unfocus search if focused, else let navigator handle
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
        return true;
      }
    }

    return false;
  }

  void _handleFunctionKey(LogicalKeyboardKey key) {
    final categories = context.read<PosCubit>().state.categories;
    final keys = [
      LogicalKeyboardKey.f1,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
    ];
    final idx = keys.indexOf(key);
    if (idx < 0) return;
    if (idx == 0) {
      // F1 → All (clear category filter)
      context.read<PosCubit>().selectCategory(null);
    } else if (idx <= categories.length) {
      context.read<PosCubit>().selectCategory(categories[idx - 1].id);
    }
  }

  void _processBarcode() {
    if (!mounted) return;
    final code = _barcodeBuffer.toString().trim();
    _barcodeBuffer.clear();
    _lastScanKey = null;
    if (code.length < 3) return;

    final products = context.read<PosCubit>().state.products;
    final matches = products.where((p) => p.barcode == code || p.sku == code);
    final product = matches.isEmpty ? null : matches.first;

    final l10n = AppLocalizations.of(context);
    if (product != null) {
      context.read<CartCubit>().addItem(product);
      PosSoundService.scanSuccess();
      AppSnackbar.success(context, '${product.name} — ${l10n.barcodeProductAdded}');
    } else {
      PosSoundService.scanError();
      AppSnackbar.error(context, l10n.productNotFound);
    }
  }

  Future<void> _openPaymentModal() async {
    if (_dialogOpen) return;
    final cart = context.read<CartCubit>().state;
    if (cart.isEmpty) return;
    final posState = context.read<PosCubit>().state;
    if (posState.submitting) return;

    _dialogOpen = true;
    final result = await PosPaymentModal.show(context, total: cart.total);
    _dialogOpen = false;
    if (result == null || !mounted) return;

    await context.read<PosCubit>().submitOrder(
          cart: cart,
          paymentMethod: result.method,
          paymentAmount: result.amount,
        );
    if (!mounted) return;
    // Play success sound only if order was submitted successfully
    if (context.read<PosCubit>().state.lastOrder != null) {
      PosSoundService.orderSuccess();
    }
  }

  Future<void> _openDiscountModal() async {
    if (_dialogOpen) return;
    final cart = context.read<CartCubit>().state;
    if (cart.isEmpty) return;

    _dialogOpen = true;
    final result = await PosDiscountModal.show(context, current: cart.discount);
    _dialogOpen = false;
    if (!mounted) return;
    if (result != null) context.read<CartCubit>().setDiscount(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PosHeader(),
      body: BlocBuilder<PosCubit, PosState>(
        buildWhen: (p, c) => p.isReady != c.isReady,
        builder: (context, state) {
          if (!state.isReady) {
            return const PosSetupOverlay();
          }
          return _PosLayout(searchFocusNode: _searchFocusNode);
        },
      ),
    );
  }
}

class _PosLayout extends StatelessWidget {
  final FocusNode searchFocusNode;

  const _PosLayout({required this.searchFocusNode});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PosLeftPanel(searchFocusNode: searchFocusNode),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
        const SizedBox(
          width: 360,
          child: PosRightPanel(),
        ),
      ],
    );
  }
}
