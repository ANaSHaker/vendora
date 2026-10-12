import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/admin_payment_entity.dart';

sealed class AdminBillingState extends Equatable {
  const AdminBillingState();
  @override
  List<Object?> get props => [];
}

class AdminBillingInitial extends AdminBillingState {
  const AdminBillingInitial();
}

class AdminBillingLoading extends AdminBillingState {
  const AdminBillingLoading();
}

class AdminBillingLoaded extends AdminBillingState {
  final List<AdminPaymentEntity> payments;
  final PaginationMeta paymentsMeta;
  final List<AdminInvoiceEntity> invoices;
  final PaginationMeta invoicesMeta;
  final int activeTab; // 0 = payments, 1 = invoices
  final int paymentsPage;
  final int invoicesPage;
  final Map<String, dynamic>? paymentSummary;
  final Map<String, dynamic>? invoiceSummary;
  final String? paymentStatusFilter;
  final String? paymentMethodFilter;
  final String? invoiceStatusFilter;

  const AdminBillingLoaded({
    required this.payments,
    required this.paymentsMeta,
    required this.invoices,
    required this.invoicesMeta,
    this.activeTab = 0,
    this.paymentsPage = 1,
    this.invoicesPage = 1,
    this.paymentSummary,
    this.invoiceSummary,
    this.paymentStatusFilter,
    this.paymentMethodFilter,
    this.invoiceStatusFilter,
  });

  AdminBillingLoaded copyWith({
    List<AdminPaymentEntity>? payments,
    PaginationMeta? paymentsMeta,
    List<AdminInvoiceEntity>? invoices,
    PaginationMeta? invoicesMeta,
    int? activeTab,
    int? paymentsPage,
    int? invoicesPage,
    Map<String, dynamic>? paymentSummary,
    Map<String, dynamic>? invoiceSummary,
    String? paymentStatusFilter,
    bool clearPaymentStatusFilter = false,
    String? paymentMethodFilter,
    bool clearPaymentMethodFilter = false,
    String? invoiceStatusFilter,
    bool clearInvoiceStatusFilter = false,
  }) {
    return AdminBillingLoaded(
      payments: payments ?? this.payments,
      paymentsMeta: paymentsMeta ?? this.paymentsMeta,
      invoices: invoices ?? this.invoices,
      invoicesMeta: invoicesMeta ?? this.invoicesMeta,
      activeTab: activeTab ?? this.activeTab,
      paymentsPage: paymentsPage ?? this.paymentsPage,
      invoicesPage: invoicesPage ?? this.invoicesPage,
      paymentSummary: paymentSummary ?? this.paymentSummary,
      invoiceSummary: invoiceSummary ?? this.invoiceSummary,
      paymentStatusFilter: clearPaymentStatusFilter
          ? null
          : (paymentStatusFilter ?? this.paymentStatusFilter),
      paymentMethodFilter: clearPaymentMethodFilter
          ? null
          : (paymentMethodFilter ?? this.paymentMethodFilter),
      invoiceStatusFilter: clearInvoiceStatusFilter
          ? null
          : (invoiceStatusFilter ?? this.invoiceStatusFilter),
    );
  }

  @override
  List<Object?> get props => [
        payments, paymentsMeta, invoices, invoicesMeta,
        activeTab, paymentsPage, invoicesPage,
        paymentSummary, invoiceSummary,
        paymentStatusFilter, paymentMethodFilter, invoiceStatusFilter,
      ];
}

class AdminBillingError extends AdminBillingState {
  final String message;
  const AdminBillingError(this.message);
  @override
  List<Object?> get props => [message];
}
