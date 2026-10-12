import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_payment_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_billing_state.dart';

class AdminBillingCubit extends Cubit<AdminBillingState> {
  final GetAdminPaymentsUseCase _getPayments;
  final GetAdminInvoicesUseCase _getInvoices;
  final CreateAdminPaymentUseCase _createPayment;
  final CreateAdminInvoiceUseCase _createInvoice;
  final MarkAdminPaymentPaidUseCase _markPaymentPaid;
  final MarkAdminPaymentFailedUseCase _markPaymentFailed;
  final VoidAdminInvoiceUseCase _voidInvoice;

  AdminBillingCubit({
    required GetAdminPaymentsUseCase getPayments,
    required GetAdminInvoicesUseCase getInvoices,
    required CreateAdminPaymentUseCase createPayment,
    required CreateAdminInvoiceUseCase createInvoice,
    required MarkAdminPaymentPaidUseCase markPaymentPaid,
    required MarkAdminPaymentFailedUseCase markPaymentFailed,
    required VoidAdminInvoiceUseCase voidInvoice,
  })  : _getPayments = getPayments,
        _getInvoices = getInvoices,
        _createPayment = createPayment,
        _createInvoice = createInvoice,
        _markPaymentPaid = markPaymentPaid,
        _markPaymentFailed = markPaymentFailed,
        _voidInvoice = voidInvoice,
        super(const AdminBillingInitial());

  Future<void> load() async {
    emit(const AdminBillingLoading());

    final paymentsResult = await _getPayments(page: 1);
    if (paymentsResult.isLeft()) {
      emit(AdminBillingError(paymentsResult.fold((f) => f.message, (_) => '')));
      return;
    }

    final invoicesResult = await _getInvoices(page: 1);
    if (invoicesResult.isLeft()) {
      emit(AdminBillingError(invoicesResult.fold((f) => f.message, (_) => '')));
      return;
    }

    final payments = paymentsResult.getOrElse(() => throw Exception());
    final invoices = invoicesResult.getOrElse(() => throw Exception());

    emit(AdminBillingLoaded(
      payments: payments.data,
      paymentsMeta: payments.meta,
      invoices: invoices.data,
      invoicesMeta: invoices.meta,
      paymentSummary: payments.summary ?? _buildPaymentSummary(payments.data),
      invoiceSummary: invoices.summary ?? _buildInvoiceSummary(invoices.data),
    ));
  }

  Map<String, dynamic> _buildPaymentSummary(List<AdminPaymentEntity> items) {
    double collected = 0, pending = 0, failed = 0;
    int pendingCount = 0, failedCount = 0;
    for (final p in items) {
      switch (p.status) {
        case 'paid':
          collected += p.amount;
        case 'pending':
          pending += p.amount;
          pendingCount++;
        case 'failed':
          failed += p.amount;
          failedCount++;
      }
    }
    return {
      'collected': collected,
      'pending': pending,
      'failed': failed,
      'pending_count': pendingCount,
      'failed_count': failedCount,
    };
  }

  Map<String, dynamic> _buildInvoiceSummary(List<AdminInvoiceEntity> items) {
    int openCount = 0, overdueCount = 0, paidCount = 0;
    double outstanding = 0, collected = 0;
    for (final i in items) {
      switch (i.status) {
        case 'open':
          openCount++;
          outstanding += i.amount;
        case 'overdue':
          overdueCount++;
          outstanding += i.amount;
        case 'paid':
          paidCount++;
          collected += i.amount;
      }
    }
    return {
      'open_count': openCount,
      'overdue_count': overdueCount,
      'paid_count': paidCount,
      'outstanding': outstanding,
      'collected': collected,
    };
  }

  Future<void> filterPaymentsByStatus(String? status) async {
    final current = state;
    if (current is! AdminBillingLoaded) return;
    final result = await _getPayments(
      page: 1,
      status: status,
      method: current.paymentMethodFilter,
    );
    result.fold(
      (_) {},
      (paginated) => emit(current.copyWith(
        payments: paginated.data,
        paymentsMeta: paginated.meta,
        paymentsPage: 1,
        paymentSummary: paginated.summary ?? _buildPaymentSummary(paginated.data),
        paymentStatusFilter: status,
        clearPaymentStatusFilter: status == null,
      )),
    );
  }

  Future<void> filterPaymentsByMethod(String? method) async {
    final current = state;
    if (current is! AdminBillingLoaded) return;
    final result = await _getPayments(
      page: 1,
      status: current.paymentStatusFilter,
      method: method,
    );
    result.fold(
      (_) {},
      (paginated) => emit(current.copyWith(
        payments: paginated.data,
        paymentsMeta: paginated.meta,
        paymentsPage: 1,
        paymentSummary: paginated.summary ?? _buildPaymentSummary(paginated.data),
        paymentMethodFilter: method,
        clearPaymentMethodFilter: method == null,
      )),
    );
  }

  Future<void> filterInvoicesByStatus(String? status) async {
    final current = state;
    if (current is! AdminBillingLoaded) return;
    final result = await _getInvoices(page: 1, status: status);
    result.fold(
      (_) {},
      (paginated) => emit(current.copyWith(
        invoices: paginated.data,
        invoicesMeta: paginated.meta,
        invoicesPage: 1,
        invoiceSummary: paginated.summary ?? _buildInvoiceSummary(paginated.data),
        invoiceStatusFilter: status,
        clearInvoiceStatusFilter: status == null,
      )),
    );
  }

  Future<void> changePaymentsPage(int page) async {
    final current = state;
    if (current is! AdminBillingLoaded) return;
    final result = await _getPayments(
      page: page,
      status: current.paymentStatusFilter,
      method: current.paymentMethodFilter,
    );
    result.fold(
      (_) {},
      (paginated) => emit(current.copyWith(
        payments: paginated.data,
        paymentsMeta: paginated.meta,
        paymentsPage: page,
      )),
    );
  }

  Future<void> changeInvoicesPage(int page) async {
    final current = state;
    if (current is! AdminBillingLoaded) return;
    final result = await _getInvoices(page: page, status: current.invoiceStatusFilter);
    result.fold(
      (_) {},
      (paginated) => emit(current.copyWith(
        invoices: paginated.data,
        invoicesMeta: paginated.meta,
        invoicesPage: page,
      )),
    );
  }

  Future<bool> createPayment(Map<String, dynamic> data) async {
    final result = await _createPayment(data);
    return result.fold(
      (_) => false,
      (payment) {
        final current = state;
        if (current is AdminBillingLoaded) {
          final payments = [payment, ...current.payments];
          emit(current.copyWith(
            payments: payments,
            paymentSummary: _buildPaymentSummary(payments),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> createInvoice(Map<String, dynamic> data) async {
    final result = await _createInvoice(data);
    return result.fold(
      (_) => false,
      (invoice) {
        final current = state;
        if (current is AdminBillingLoaded) {
          final invoices = [invoice, ...current.invoices];
          emit(current.copyWith(
            invoices: invoices,
            invoiceSummary: _buildInvoiceSummary(invoices),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> markPaymentPaid(String id) async {
    final result = await _markPaymentPaid(id);
    return result.fold(
      (_) => false,
      (updated) {
        final current = state;
        if (current is AdminBillingLoaded) {
          final payments = current.payments.map((p) => p.id == id ? updated : p).toList();
          emit(current.copyWith(
            payments: payments,
            paymentSummary: _buildPaymentSummary(payments),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> markPaymentFailed(String id) async {
    final result = await _markPaymentFailed(id);
    return result.fold(
      (_) => false,
      (updated) {
        final current = state;
        if (current is AdminBillingLoaded) {
          final payments = current.payments.map((p) => p.id == id ? updated : p).toList();
          emit(current.copyWith(
            payments: payments,
            paymentSummary: _buildPaymentSummary(payments),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> voidInvoice(String id) async {
    final result = await _voidInvoice(id);
    return result.fold(
      (_) => false,
      (updated) {
        final current = state;
        if (current is AdminBillingLoaded) {
          final invoices = current.invoices.map((i) => i.id == id ? updated : i).toList();
          emit(current.copyWith(
            invoices: invoices,
            invoiceSummary: _buildInvoiceSummary(invoices),
          ));
        }
        return true;
      },
    );
  }

  void setActiveTab(int tab) {
    final current = state;
    if (current is AdminBillingLoaded) {
      emit(current.copyWith(activeTab: tab));
    }
  }
}
