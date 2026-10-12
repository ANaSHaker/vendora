import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/usecases/sf_usecases.dart';
import '../../../../core/di/injection.dart';
import '../cubit/storefront_cubit.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';
import '../widgets/sf_button.dart';

class SfCheckoutPage extends StatefulWidget {
  final String slug;
  const SfCheckoutPage({super.key, required this.slug});

  @override
  State<SfCheckoutPage> createState() => _SfCheckoutPageState();
}

class _SfCheckoutPageState extends State<SfCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _phone   = TextEditingController();
  final _email   = TextEditingController();
  final _address = TextEditingController();
  final _notes   = TextEditingController();
  bool  _placing  = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _email.dispose();
    _address.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit  = context.read<StorefrontCubit>();
    final state  = cubit.state;
    if (state is! StorefrontLoaded || state.cart.isEmpty) return;

    setState(() { _placing = true; _error = null; });

    final payload = {
      'customer_name':     _name.text.trim(),
      'customer_phone':    _phone.text.trim(),
      'customer_email':    _email.text.trim().isEmpty ? null : _email.text.trim(),
      'delivery_address':  _address.text.trim().isEmpty ? null : _address.text.trim(),
      'notes':             _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'items': state.cart.map((i) => {
        'product_id': i.product.id,
        'quantity':   i.quantity,
      }).toList(),
    };

    final res = await getIt<PlaceSfOrderUseCase>()(widget.slug, payload);
    if (!mounted) return;

    res.fold(
      (f) { setState(() { _placing = false; _error = f.message; }); },
      (order) {
        cubit.clearCart();
        context.go('/store/${widget.slug}/order-success',
            extra: {'reference': order.reference, 'total': order.total});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final l10n   = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return BlocBuilder<StorefrontCubit, StorefrontState>(
      builder: (ctx, state) {
        if (state is! StorefrontLoaded) return const SizedBox.shrink();
        final loaded = state;

        final Widget form = Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.sfCheckout,
              style: TextStyle(fontSize: 26, fontWeight: t.headingWeight,
                  color: t.text, letterSpacing: t.headingLetterSpacing)),
            const SizedBox(height: 24),
            _Field(ctrl: _name, label: l10n.sfCustomerName, t: t,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            _Field(ctrl: _phone, label: l10n.sfCustomerPhone, t: t,
                type: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            _Field(ctrl: _email, label: l10n.sfCustomerEmail, t: t,
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _Field(ctrl: _address, label: l10n.sfDeliveryAddress, t: t, maxLines: 2),
            const SizedBox(height: 12),
            _Field(ctrl: _notes, label: l10n.sfOrderNotes, t: t, maxLines: 3),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SfButton(label: l10n.sfPlaceOrder,
                onPressed: _placing ? null : _place),
          ]),
        );

        final Widget summary = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.radius),
            border: Border.all(color: t.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.sfOrderSummary,
              style: TextStyle(fontSize: 16, fontWeight: t.headingWeight, color: t.text)),
            const SizedBox(height: 16),
            ...loaded.cart.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text('${item.product.name} × ${item.quantity}',
                  style: TextStyle(fontSize: 13, color: t.textMuted))),
                Text('${loaded.vendor.currency} ${item.total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13, color: t.text, fontWeight: FontWeight.w500)),
              ]),
            )),
            Divider(color: t.border, height: 20),
            Row(children: [
              Text(l10n.sfTotal,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text)),
              const Spacer(),
              Text('${loaded.vendor.currency} ${loaded.cartTotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.primary)),
            ]),
          ]),
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 64 : 16, vertical: 32),
          child: isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 6, child: form),
                  const SizedBox(width: 32),
                  SizedBox(width: 320, child: summary),
                ])
              : Column(children: [
                  summary, const SizedBox(height: 24), form]),
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final SfThemeData t;
  final TextInputType type;
  final int maxLines;
  final String? Function(String?)? validator;
  const _Field({
    required this.ctrl, required this.label, required this.t,
    this.type = TextInputType.text, this.maxLines = 1, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl, keyboardType: type, maxLines: maxLines,
    validator: validator,
    style: TextStyle(color: t.text, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: t.textMuted, fontSize: 13),
      filled: true, fillColor: t.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radius),
        borderSide: BorderSide(color: t.border)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radius),
        borderSide: BorderSide(color: t.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.radius),
        borderSide: BorderSide(color: t.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
