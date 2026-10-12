import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/sf_entities.dart';
import '../../domain/usecases/sf_usecases.dart';
import '../../../../core/di/injection.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';
import '../widgets/sf_button.dart';

class SfOrderTrackingPage extends StatefulWidget {
  final String slug;
  final String? reference;
  const SfOrderTrackingPage({super.key, required this.slug, this.reference});

  @override
  State<SfOrderTrackingPage> createState() => _SfOrderTrackingPageState();
}

class _SfOrderTrackingPageState extends State<SfOrderTrackingPage> {
  final _ctrl = TextEditingController();
  SfOrderStatus? _status;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.reference != null) {
      _ctrl.text = widget.reference!;
      _load(widget.reference!);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _load(String ref) async {
    setState(() { _loading = true; _error = null; _status = null; });
    final res = await getIt<GetSfOrderStatusUseCase>()(widget.slug, ref);
    res.fold(
      (f) => _error = f.message,
      (v) => _status = v,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t    = StorefrontTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 120 : 16, vertical: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.sfTrackOrder,
          style: TextStyle(fontSize: 28, fontWeight: t.headingWeight,
              color: t.text, letterSpacing: t.headingLetterSpacing)),
        const SizedBox(height: 8),
        Text(l10n.sfTrackHint,
          style: TextStyle(fontSize: 14, color: t.textMuted)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: t.text),
              decoration: InputDecoration(
                hintText: l10n.sfOrderRef,
                hintStyle: TextStyle(color: t.textMuted),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (v) { if (v.trim().isNotEmpty) _load(v.trim()); },
            ),
          ),
          const SizedBox(width: 12),
          SfButton(
            label: l10n.sfOrderTracking,
            onPressed: _loading
                ? null
                : () { if (_ctrl.text.trim().isNotEmpty) _load(_ctrl.text.trim()); },
          ),
        ]),
        const SizedBox(height: 32),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null) Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red))),
        if (_status != null) _StatusCard(status: _status!, t: t, l10n: l10n),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SfOrderStatus status;
  final SfThemeData t;
  final AppLocalizations l10n;
  const _StatusCard({required this.status, required this.t, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status.status.toLowerCase()) {
      'pending'    => Colors.orange,
      'confirmed'  => Colors.blue,
      'processing' => Colors.indigo,
      'shipped'    => Colors.teal,
      'delivered'  => Colors.green,
      'cancelled'  => Colors.red,
      _            => t.primary,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radius),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.sfOrderRef,
              style: TextStyle(fontSize: 12, color: t.textMuted, fontWeight: FontWeight.w600)),
            Text(status.reference,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.text)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(t.buttonRadius.clamp(4, 20)),
            ),
            child: Text(
              status.status.toUpperCase(),
              style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Divider(color: t.border),
        const SizedBox(height: 16),
        Text(l10n.sfOrderItems,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.text)),
        const SizedBox(height: 10),
        ...status.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Expanded(child: Text('${item.name} × ${item.quantity}',
              style: TextStyle(fontSize: 13, color: t.textMuted))),
            Text('${item.price.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 13, color: t.text, fontWeight: FontWeight.w500)),
          ]),
        )),
        Divider(color: t.border, height: 20),
        Row(children: [
          Text(l10n.sfTotal, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: t.text)),
          const Spacer(),
          Text(status.total.toStringAsFixed(2),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.primary)),
        ]),
      ]),
    );
  }
}
