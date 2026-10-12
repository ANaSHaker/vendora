import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../../../core/api/api_client.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../domain/entities/pos_entities.dart';

// ─── Label bundle (passed to async PDF builder without BuildContext) ──────────

class _ReceiptLabels {
  final String cashier, warehouse, customer, phone;
  final String subtotal, discount, taxRate, total, change;
  final String note, thankYou;

  const _ReceiptLabels({
    required this.cashier,
    required this.warehouse,
    required this.customer,
    required this.phone,
    required this.subtotal,
    required this.discount,
    required this.taxRate,
    required this.total,
    required this.change,
    required this.note,
    required this.thankYou,
  });

  factory _ReceiptLabels.from(AppLocalizations l) => _ReceiptLabels(
        cashier: l.cashier,
        warehouse: l.warehouseName,
        customer: l.customer,
        phone: l.phone,
        subtotal: l.subtotal,
        discount: l.discount,
        taxRate: l.taxWithRate,
        total: l.total,
        change: l.change,
        note: l.note,
        thankYou: l.thankYou,
      );
}

// ─── Dialog widget ────────────────────────────────────────────────────────────

class PosReceiptDialog extends StatelessWidget {
  final PosOrderEntity order;

  const PosReceiptDialog({super.key, required this.order});

  static Future<void> show(BuildContext context, PosOrderEntity order) {
    return showDialog<void>(
      context: context,
      builder: (_) => PosReceiptDialog(order: order),
    );
  }

  String _qrData() => order.trackingToken != null
      ? '$kApiBaseUrl/track/${order.trackingToken}'
      : order.reference;

  static String _qtyStr(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);

  Future<void> _print(_ReceiptLabels labels) async {
    await Printing.layoutPdf(
      onLayout: (_) => _buildPdf(labels),
      name: order.reference,
    );
  }

  // ── PDF builder ────────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(_ReceiptLabels labels) async {
    final doc = pw.Document();
    final regularFont = await PdfGoogleFonts.notoSansArabicRegular();
    final boldFont = await PdfGoogleFonts.notoSansArabicBold();

    pw.TextStyle txt(int size, {bool isBold = false, PdfColor? color}) =>
        pw.TextStyle(
          font: isBold ? boldFont : regularFont,
          fontSize: size.toDouble(),
          color: color,
        );

    pw.Widget metaRow(String lbl, String val) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(lbl, style: txt(9, color: PdfColors.grey600)),
              pw.Text(val, style: txt(9, isBold: true)),
            ],
          ),
        );

    pw.Widget totRow(String lbl, String val, {bool isBold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(lbl, style: txt(10, isBold: isBold)),
              pw.Text(val, style: txt(10, isBold: isBold)),
            ],
          ),
        );

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 6 * PdfPageFormat.mm,
        ),
        build: (ctx) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            children: [
              // Store + branch header
              if (order.storeName != null)
                pw.Text(order.storeName!,
                    style: txt(14, isBold: true),
                    textAlign: pw.TextAlign.center),
              if (order.branchName != null)
                pw.Text(order.branchName!,
                    style: txt(9), textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.SizedBox(height: 4),
              // Reference + date
              pw.Text(order.reference, style: txt(13, isBold: true)),
              if (order.paidAt != null)
                pw.Text(AppFormatters.dateTime(order.paidAt!),
                    style: txt(9)),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),
              // Meta rows
              if (order.cashierName != null)
                metaRow(labels.cashier, order.cashierName!),
              if (order.warehouseName != null)
                metaRow(labels.warehouse, order.warehouseName!),
              if (order.customerName != null)
                metaRow(labels.customer, order.customerName!),
              if (order.customerPhone != null)
                metaRow(labels.phone, order.customerPhone!),
              if (order.cashierName != null ||
                  order.warehouseName != null ||
                  order.customerName != null)
                pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),
              // Items
              ...order.items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                              child: pw.Text(item.productName,
                                  style: txt(10))),
                          pw.Text(AppFormatters.currency(item.total),
                              style: txt(10, isBold: true)),
                        ],
                      ),
                      pw.Text(
                        '${_qtyStr(item.quantity)} × '
                        '${AppFormatters.currency(item.unitPrice)}'
                        '${item.discount > 0 ? ' (${labels.discount}: ${AppFormatters.currency(item.discount)})' : ''}',
                        style: txt(8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),
              // Totals
              totRow(labels.subtotal, AppFormatters.currency(order.subtotal)),
              if (order.discount > 0)
                totRow(labels.discount,
                    '-${AppFormatters.currency(order.discount)}'),
              if (order.tax > 0)
                totRow(labels.taxRate, AppFormatters.currency(order.tax)),
              pw.SizedBox(height: 2),
              totRow(labels.total, AppFormatters.currency(order.total),
                  isBold: true),
              pw.SizedBox(height: 4),
              pw.Divider(),
              pw.SizedBox(height: 4),
              // Payments
              ...order.payments.map(
                (p) => totRow(
                    p.method.toUpperCase(), AppFormatters.currency(p.amount)),
              ),
              if (order.change > 0)
                totRow(labels.change, AppFormatters.currency(order.change)),
              // Note
              if (order.note != null && order.note!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Divider(),
                pw.SizedBox(height: 4),
                pw.Text('${labels.note}: ${order.note}', style: txt(9)),
              ],
              pw.SizedBox(height: 8),
              // Barcode (Code128)
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: order.reference,
                width: 120,
                height: 28,
                drawText: false,
              ),
              pw.SizedBox(height: 4),
              pw.Text(order.reference, style: txt(8)),
              pw.SizedBox(height: 6),
              // QR — tracking URL if available, else reference
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: _qrData(),
                width: 64,
                height: 64,
              ),
              pw.SizedBox(height: 8),
              pw.Text(labels.thankYou,
                  style: txt(11, isBold: true),
                  textAlign: pw.TextAlign.center),
            ],
          ),
        ),
      ),
    );

    return doc.save();
  }

  // ── Widget build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final labels = _ReceiptLabels.from(l10n);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: cs.primary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.printReceipt, style: AppTextStyles.h6),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _ReceiptPreview(order: order, qrData: _qrData()),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.primary(
                      label: l10n.printReceipt,
                      leading: const Icon(Icons.print_rounded, size: 16),
                      onPressed: () => _print(labels),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Receipt Preview Widget ──────────────────────────────────────────────────

class _ReceiptPreview extends StatelessWidget {
  final PosOrderEntity order;
  final String qrData;

  const _ReceiptPreview({required this.order, required this.qrData});

  static String _qtyStr(double qty) =>
      qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ── Store header ──
          if (order.storeName != null) ...[
            Text(
              order.storeName!,
              style: AppTextStyles.labelLg.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
          ],
          if (order.branchName != null)
            Text(
              order.branchName!,
              style: AppTextStyles.bodyXs
                  .copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.sm),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          // ── Reference + date ──
          Text(
            order.reference,
            style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
          ),
          if (order.paidAt != null)
            Text(
              AppFormatters.dateTime(order.paidAt!),
              style: AppTextStyles.bodyXs
                  .copyWith(color: AppColors.mutedForeground),
            ),
          const SizedBox(height: AppSpacing.sm),
          // ── Meta rows ──
          if (order.cashierName != null)
            _MetaRow(label: l10n.cashier, value: order.cashierName!),
          if (order.warehouseName != null)
            _MetaRow(label: l10n.warehouseName, value: order.warehouseName!),
          if (order.customerName != null)
            _MetaRow(label: l10n.customer, value: order.customerName!),
          if (order.customerPhone != null)
            _MetaRow(label: l10n.phone, value: order.customerPhone!),
          if (order.cashierName != null ||
              order.warehouseName != null ||
              order.customerName != null)
            const SizedBox(height: AppSpacing.sm),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          // ── Items ──
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.productName,
                            style: AppTextStyles.labelSm),
                      ),
                      Text(AppFormatters.currency(item.total),
                          style: AppTextStyles.labelSm),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${_qtyStr(item.quantity)} × '
                        '${AppFormatters.currency(item.unitPrice)}',
                        style: AppTextStyles.bodyXs
                            .copyWith(color: AppColors.mutedForeground),
                      ),
                      if (item.discount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(- ${AppFormatters.currency(item.discount)})',
                          style: AppTextStyles.bodyXs.copyWith(
                              color: Colors.red.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          // ── Totals ──
          _TotalRow(
            label: l10n.subtotal,
            value: AppFormatters.currency(order.subtotal),
          ),
          if (order.discount > 0)
            _TotalRow(
              label: l10n.discount,
              value: '-${AppFormatters.currency(order.discount)}',
              valueColor: Colors.red.shade700,
            ),
          if (order.tax > 0)
            _TotalRow(
              label: l10n.taxWithRate,
              value: AppFormatters.currency(order.tax),
            ),
          const SizedBox(height: AppSpacing.xs),
          _TotalRow(
            label: l10n.total,
            value: AppFormatters.currency(order.total),
            bold: true,
            valueColor: cs.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _DashedDivider(),
          const SizedBox(height: AppSpacing.sm),
          // ── Payments ──
          ...order.payments.map(
            (p) => _TotalRow(
              label: p.method.toUpperCase(),
              value: AppFormatters.currency(p.amount),
            ),
          ),
          if (order.change > 0)
            _TotalRow(
              label: l10n.change,
              value: AppFormatters.currency(order.change),
              valueColor: AppColors.success,
              bold: true,
            ),
          // ── Note ──
          if (order.note != null && order.note!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const _DashedDivider(),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${l10n.note}: ${order.note}',
                style: AppTextStyles.bodyXs.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ],
          // ── QR code ──
          const SizedBox(height: AppSpacing.md),
          QrImageView(
            data: qrData,
            size: 80,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            order.reference,
            style: AppTextStyles.bodyXs
                .copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Thank you ──
          Text(
            '— ${l10n.thankYou} —',
            style: AppTextStyles.bodyXs
                .copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodyXs
                  .copyWith(color: AppColors.mutedForeground)),
          Text(value, style: AppTextStyles.labelXs),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTextStyles.labelSm : AppTextStyles.bodyXs;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: style.copyWith(
              color: valueColor,
              fontWeight: bold ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 4.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.only(right: gap),
              color: AppColors.border,
            ),
          ),
        );
      },
    );
  }
}
