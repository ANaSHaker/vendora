import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_analytics_entity.dart';
import '../entities/admin_finance_entity.dart';
import '../entities/admin_payment_entity.dart';
import '../entities/admin_plan_entity.dart';
import '../entities/admin_subscription_entity.dart';
import '../entities/admin_vendor_entity.dart';
import '../entities/vendor_create_meta_entity.dart';
import '../repositories/admin_repository.dart';

class GetVendorCreateMetaUseCase {
  final AdminRepository _repo;
  const GetVendorCreateMetaUseCase(this._repo);

  Future<Either<Failure, VendorCreateMetaEntity>> call() =>
      _repo.getVendorCreateMeta();
}

class GetAdminVendorsUseCase {
  final AdminRepository _repo;
  const GetAdminVendorsUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<AdminVendorEntity>>> call({
    String? search,
    String? status,
    String? planId,
    String? subscriptionStatus,
    String? accountStatus,
    int page = 1,
    int? perPage,
  }) =>
      _repo.getVendors(
        search: search,
        status: status,
        planId: planId,
        subscriptionStatus: subscriptionStatus,
        accountStatus: accountStatus,
        page: page,
        perPage: perPage,
      );
}

class GetAdminVendorByIdUseCase {
  final AdminRepository _repo;
  const GetAdminVendorByIdUseCase(this._repo);

  Future<Either<Failure, AdminVendorEntity>> call(String id) =>
      _repo.getVendorById(id);
}

class GetAdminVendorDetailsUseCase {
  final AdminRepository _repo;
  const GetAdminVendorDetailsUseCase(this._repo);

  Future<Either<Failure, AdminVendorEntity>> call(String id) =>
      _repo.getVendorDetails(id);
}

class ToggleAdminVendorStatusUseCase {
  final AdminRepository _repo;
  const ToggleAdminVendorStatusUseCase(this._repo);

  Future<Either<Failure, AdminVendorEntity>> call(String id) =>
      _repo.toggleVendorStatus(id);
}

class CreateAdminVendorUseCase {
  final AdminRepository _repo;
  const CreateAdminVendorUseCase(this._repo);

  Future<Either<Failure, AdminVendorEntity>> call(Map<String, dynamic> data) =>
      _repo.createVendor(data);
}

class UpdateAdminVendorUseCase {
  final AdminRepository _repo;
  const UpdateAdminVendorUseCase(this._repo);

  Future<Either<Failure, AdminVendorEntity>> call(
          String id, Map<String, dynamic> data) =>
      _repo.updateVendor(id, data);
}

class AssignVendorSubscriptionUseCase {
  final AdminRepository _repo;
  const AssignVendorSubscriptionUseCase(this._repo);

  Future<Either<Failure, AdminSubscriptionEntity>> call(
          String vendorId, Map<String, dynamic> data) =>
      _repo.assignVendorSubscription(vendorId, data);
}

class GetAdminPlansUseCase {
  final AdminRepository _repo;
  const GetAdminPlansUseCase(this._repo);

  Future<Either<Failure, List<AdminPlanEntity>>> call() => _repo.getPlans();
}

class CreateAdminPlanUseCase {
  final AdminRepository _repo;
  const CreateAdminPlanUseCase(this._repo);

  Future<Either<Failure, AdminPlanEntity>> call(Map<String, dynamic> data) =>
      _repo.createPlan(data);
}

class UpdateAdminPlanUseCase {
  final AdminRepository _repo;
  const UpdateAdminPlanUseCase(this._repo);

  Future<Either<Failure, AdminPlanEntity>> call(
          String id, Map<String, dynamic> data) =>
      _repo.updatePlan(id, data);
}

class DeleteAdminPlanUseCase {
  final AdminRepository _repo;
  const DeleteAdminPlanUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) => _repo.deletePlan(id);
}

class GetAdminPaymentsUseCase {
  final AdminRepository _repo;
  const GetAdminPaymentsUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<AdminPaymentEntity>>> call(
          {int page = 1, String? status, String? method}) =>
      _repo.getPayments(page: page, status: status, method: method);
}

class GetAdminInvoicesUseCase {
  final AdminRepository _repo;
  const GetAdminInvoicesUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<AdminInvoiceEntity>>> call(
          {int page = 1, String? status}) =>
      _repo.getInvoices(page: page, status: status);
}

class CreateAdminPaymentUseCase {
  final AdminRepository _repo;
  const CreateAdminPaymentUseCase(this._repo);

  Future<Either<Failure, AdminPaymentEntity>> call(Map<String, dynamic> data) =>
      _repo.createPayment(data);
}

class CreateAdminInvoiceUseCase {
  final AdminRepository _repo;
  const CreateAdminInvoiceUseCase(this._repo);

  Future<Either<Failure, AdminInvoiceEntity>> call(Map<String, dynamic> data) =>
      _repo.createInvoice(data);
}

class MarkAdminPaymentPaidUseCase {
  final AdminRepository _repo;
  const MarkAdminPaymentPaidUseCase(this._repo);

  Future<Either<Failure, AdminPaymentEntity>> call(String id) =>
      _repo.markPaymentPaid(id);
}

class MarkAdminPaymentFailedUseCase {
  final AdminRepository _repo;
  const MarkAdminPaymentFailedUseCase(this._repo);

  Future<Either<Failure, AdminPaymentEntity>> call(String id) =>
      _repo.markPaymentFailed(id);
}

class VoidAdminInvoiceUseCase {
  final AdminRepository _repo;
  const VoidAdminInvoiceUseCase(this._repo);

  Future<Either<Failure, AdminInvoiceEntity>> call(String id) =>
      _repo.voidInvoice(id);
}

class GetAdminSubscriptionsUseCase {
  final AdminRepository _repo;
  const GetAdminSubscriptionsUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<AdminSubscriptionEntity>>> call(
          {int page = 1, String? status, String? vendorId}) =>
      _repo.getSubscriptions(page: page, status: status, vendorId: vendorId);
}

class UpdateAdminSubscriptionUseCase {
  final AdminRepository _repo;
  const UpdateAdminSubscriptionUseCase(this._repo);

  Future<Either<Failure, AdminSubscriptionEntity>> call(
          String id, Map<String, dynamic> data) =>
      _repo.updateSubscription(id, data);
}

class GetAdminAnalyticsUseCase {
  final AdminRepository _repo;
  const GetAdminAnalyticsUseCase(this._repo);

  Future<Either<Failure, AdminAnalyticsEntity>> call({int chartDays = 30}) =>
      _repo.getAnalyticsSummary(chartDays: chartDays);
}

// ── Finance ──────────────────────────────────────────────────────────────────

class GetAdminFinanceSummaryUseCase {
  final AdminRepository _repo;
  const GetAdminFinanceSummaryUseCase(this._repo);
  Future<Either<Failure, AdminFinanceSummaryEntity>> call({String? from, String? to}) =>
      _repo.getFinanceSummary(from: from, to: to);
}

class GetAdminFinanceEntriesUseCase {
  final AdminRepository _repo;
  const GetAdminFinanceEntriesUseCase(this._repo);
  Future<Either<Failure, PaginatedResponse<AdminFinanceEntryEntity>>> call({
    String? type, String? from, String? to,
    String? categoryId, String? status, String? search,
    int page = 1, int perPage = 50,
  }) => _repo.getFinanceEntries(
        type: type, from: from, to: to,
        categoryId: categoryId, status: status, search: search,
        page: page, perPage: perPage,
      );
}

class CreateAdminFinanceEntryUseCase {
  final AdminRepository _repo;
  const CreateAdminFinanceEntryUseCase(this._repo);
  Future<Either<Failure, AdminFinanceEntryEntity>> call(Map<String, dynamic> data) =>
      _repo.createFinanceEntry(data);
}

class UpdateAdminFinanceEntryUseCase {
  final AdminRepository _repo;
  const UpdateAdminFinanceEntryUseCase(this._repo);
  Future<Either<Failure, AdminFinanceEntryEntity>> call(String id, Map<String, dynamic> data) =>
      _repo.updateFinanceEntry(id, data);
}

class VoidAdminFinanceEntryUseCase {
  final AdminRepository _repo;
  const VoidAdminFinanceEntryUseCase(this._repo);
  Future<Either<Failure, void>> call(String id) => _repo.voidFinanceEntry(id);
}

class GetAdminFinanceCategoriesUseCase {
  final AdminRepository _repo;
  const GetAdminFinanceCategoriesUseCase(this._repo);
  Future<Either<Failure, List<AdminFinanceCategoryEntity>>> call({String? type}) =>
      _repo.getFinanceCategories(type: type);
}

class CreateAdminFinanceCategoryUseCase {
  final AdminRepository _repo;
  const CreateAdminFinanceCategoryUseCase(this._repo);
  Future<Either<Failure, AdminFinanceCategoryEntity>> call(Map<String, dynamic> data) =>
      _repo.createFinanceCategory(data);
}

class UpdateAdminFinanceCategoryUseCase {
  final AdminRepository _repo;
  const UpdateAdminFinanceCategoryUseCase(this._repo);
  Future<Either<Failure, AdminFinanceCategoryEntity>> call(String id, Map<String, dynamic> data) =>
      _repo.updateFinanceCategory(id, data);
}
