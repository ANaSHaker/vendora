import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/usecases/sf_usecases.dart';
import '../../../../core/di/injection.dart';
import '../theme/sf_inherited_theme.dart';
import '../theme/sf_theme_data.dart';
import '../widgets/sf_button.dart';

class SfReservationPage extends StatefulWidget {
  final String slug;
  const SfReservationPage({super.key, required this.slug});

  @override
  State<SfReservationPage> createState() => _SfReservationPageState();
}

class _SfReservationPageState extends State<SfReservationPage> {
  final _formKey = GlobalKey<FormState>();
  final _name    = TextEditingController();
  final _phone   = TextEditingController();
  final _email   = TextEditingController();
  final _notes   = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  int _partySize = 2;
  bool _placing  = false;
  bool _done     = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _email.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) {
      setState(() => _error = 'Please select date and time');
      return;
    }

    setState(() { _placing = true; _error = null; });

    final payload = {
      'customer_name':  _name.text.trim(),
      'customer_phone': _phone.text.trim(),
      'customer_email': _email.text.isEmpty ? null : _email.text.trim(),
      'party_size':     _partySize,
      'date':           '${_date!.year}-${_date!.month.toString().padLeft(2,'0')}-${_date!.day.toString().padLeft(2,'0')}',
      'time':           '${_time!.hour.toString().padLeft(2,'0')}:${_time!.minute.toString().padLeft(2,'0')}',
      'notes':          _notes.text.isEmpty ? null : _notes.text.trim(),
    };

    final res = await getIt<PlaceSfReservationUseCase>()(widget.slug, payload);
    if (!mounted) return;

    res.fold(
      (f) => setState(() { _placing = false; _error = f.message; }),
      (_) => setState(() { _placing = false; _done = true; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final l10n   = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (_done) return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 80, height: 80, decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.event_available_rounded,
                color: Colors.green, size: 48)),
          const SizedBox(height: 24),
          Text(l10n.sfReservationSuccess,
            style: TextStyle(fontSize: 24, fontWeight: t.headingWeight, color: t.text)),
          const SizedBox(height: 20),
          SfButton(label: l10n.sfHome,
              onPressed: () => context.go('/store/${widget.slug}')),
        ]),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 120 : 16, vertical: 40),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.sfReserveTable,
            style: TextStyle(fontSize: 28, fontWeight: t.headingWeight,
                color: t.text, letterSpacing: t.headingLetterSpacing)),
          const SizedBox(height: 28),
          _field(l10n.sfCustomerName, _name, t,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
          const SizedBox(height: 12),
          _field(l10n.sfCustomerPhone, _phone, t,
              type: TextInputType.phone,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
          const SizedBox(height: 12),
          _field(l10n.sfCustomerEmail, _email, t,
              type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          // Party size
          Row(children: [
            Text(l10n.sfPartySize,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: t.text)),
            const SizedBox(width: 16),
            for (final n in [1, 2, 3, 4, 6, 8, 10])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _partySize = n),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _partySize == n ? t.primary : t.surface,
                      borderRadius: BorderRadius.circular(t.radius / 2),
                      border: Border.all(color: _partySize == n ? t.primary : t.border),
                    ),
                    child: Center(child: Text('$n',
                      style: TextStyle(fontSize: 13,
                        color: _partySize == n ? t.primaryFg : t.text,
                        fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _DateTile(
              label: l10n.sfDate,
              value: _date == null
                  ? null
                  : '${_date!.day}/${_date!.month}/${_date!.year}',
              icon: Icons.calendar_today_outlined, t: t,
              onTap: () async {
                final d = await showDatePicker(
                  context: context, initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _date = d);
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _DateTile(
              label: l10n.sfTime,
              value: _time == null ? null : _time!.format(context),
              icon: Icons.access_time_rounded, t: t,
              onTap: () async {
                final ti = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 19, minute: 0));
                if (ti != null) setState(() => _time = ti);
              },
            )),
          ]),
          const SizedBox(height: 12),
          _field(l10n.sfReservationNotes, _notes, t, maxLines: 3),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SfButton(label: l10n.sfConfirmReservation,
              onPressed: _placing ? null : _submit),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, SfThemeData t, {
    TextInputType type = TextInputType.text, int maxLines = 1,
    String? Function(String?)? validator,
  }) => TextFormField(
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

class _DateTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final SfThemeData t;
  final VoidCallback onTap;
  const _DateTile({required this.label, this.value, required this.icon,
    required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.radius),
        border: Border.all(color: t.border),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: t.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(value ?? label,
          style: TextStyle(fontSize: 14,
            color: value != null ? t.text : t.textMuted))),
      ]),
    ),
  );
}
