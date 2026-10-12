import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_analytics_entity.dart';
import '../../domain/entities/admin_finance_entity.dart';
import '../../domain/entities/admin_payment_entity.dart';
import '../../domain/entities/admin_plan_entity.dart';
import '../../domain/entities/admin_subscription_entity.dart';
import '../../domain/entities/admin_vendor_entity.dart';
import '../../domain/entities/vendor_create_meta_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _remote;

  const AdminRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, VendorCreateMetaEntity>> getVendorCreateMeta() =>
      _wrap(() => _remote.getVendorCreateMeta());

  @override
  Future<Either<Failure, PaginatedResponse<AdminVendorEntity>>> getVendors({
    String? search,
    String? status,
    String? planId,
    String? subscriptionStatus,
    String? accountStatus,
    int page = 1,
    int? perPage,
  }) =>
      _wrap(() => _remote.getVendors(
            search: search,
            status: status,
            planId: planId,
            subscriptionStatus: subscriptionStatus,
            accountStatus: accountStatus,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, AdminVendorEntity>> getVendorById(String id) =>
      _wrap(() => _remote.getVendorById(id));

  @override
  Future<Either<Failure, AdminVendorEntity>> getVendorDetails(String id) =>
      _wrap(() => _remote.getVendorFinancials(id));

  @override
  Future<Either<Failure, AdminVendorEntity>> toggleVendorStatus(String id) =>
      _wrap(() => _remote.toggleVendorStatus(id));

  @override
  Future<Either<Failure, AdminVendorEntity>> createVendor(Map<String, dynamic> data) =>
      _wrap(() => _remote.createVendor(data));

  @override
  Future<Either<Failure, AdminVendorEntity>> updateVendor(
          String id, Map<String, dynamic> data) =>
      _wrap(() => _remote.updateVendor(id, data));

  @override
  Future<Either<Failure, AdminSubscriptionEntity>> assignVendorSubscription(
          String vendorId, Map<String, dynamic> data) =>
      _wrap(() => _remote.assignVendorSubscription(vendorId, data));

  @override
  Future<Either<Failure, List<AdminPlanEntity>>> getPlans() =>
      _wrap(() => _remote.getPlans());

  @override
  Future<Either<Failure, AdminPlanEntity>> getPlanById(String id) =>
      _wrap(() => _remote.getPlanById(id));

  @override
  Future<Either<Failure, AdminPlanEntity>> createPlan(Map<String, dynamic> data) =>
      _wrap(() => _remote.createPlan(data));

  @override
  Future<Either<Failure, AdminPlanEntity>> updatePlan(
          String id, Map<String, dynamic> data) =>
      _wrap(() => _remote.updatePlan(id, data));

  @override
  Future<Either<Failure, void>> deletePlan(String id) =>
      _wrap(() => _remote.deletePlan(id));

  @override
  Future<Either<Failure, PaginatedResponse<AdminPaymentEntity>>> getPayments({
    int page = 1,
    String? status,
    String? method,
  }) =>
      _wrap(() => _remote.getPayments(page: page, status: status, method: method));

  @override
  Future<Either<Failure, PaginatedResponse<AdminInvoiceEntity>>> getInvoices({
    int page = 1,
    String? status,
  }) =>
      _wrap(() => _remote.getInvoices(page: page, status: status));

  @override
  Future<Either<Failure, AdminPaymentEntity>> createPayment(
          Map<String, dynamic> data) =>
      _wrap(() => _remote.createPayment(data));

  @override
  Future<Either<Failure, AdminInvoiceEntity>> createInvoice(
          Map<String, dynamic> data) =>
      _wrap(() => _remote.createInvoice(data));

  @override
  Future<Either<Failure, AdminPaymentEntity>> markPaymentPaid(String id) =>
      _wrap(() => _remote.markPaymentPaid(id));

  @override
  Future<Either<Failure, AdminPaymentEntity>> markPaymentFailed(String id) =>
      _wrap(() => _remote.markPaymentFailed(id));

  @override
  Future<Either<Failure, AdminInvoiceEntity>> voidInvoice(String id) =>
      _wrap(() => _remote.voidInvoice(id));

  @override
  Future<Either<Failure, PaginatedResponse<AdminSubscriptionEntity>>>
      getSubscriptions({int page = 1, String? status, String? vendorId}) =>
          _wrap(() => _remote.getSubscriptions(
              page: page, status: status, vendorId: vendorId));

  @override
  Future<Either<Failure, AdminSubscriptionEntity>> updateSubscription(
          String id, Map<String, dynamic> data) =>
      _wrap(() => _remote.updateSubscription(id, data));

  @override
  Future<Either<Failure, AdminAnalyticsEntity>> getAnalyticsSummary(
          {int chartDays = 30}) =>
      _wrap(() => _remote.getAnalyticsSummary(chartDays: chartDays));

  @override
  Future<Either<Failure, AdminFinanceSummaryEntity>> getFinanceSummary(
          {String? from, String? to}) =>
      _wrap(() => _remote.getFinanceSummary(from: from, to: to));

  @override
  Future<Either<Failure, PaginatedResponse<AdminFinanceEntryEntity>>>
      getFinanceEntries({
    String? type,
    String? from,
    String? to,
    String? categoryId,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) =>
          _wrap(() => _remote.getFinanceEntries(
                type: type, from: from, to: to,
                categoryId: categoryId, status: status, search: search,
                page: page, perPage: perPage,
              ));

  @override
  Future<Either<Failure, AdminFinanceEntryEntity>> createFinanceEntry(
          Map<String, dynamic> data) =>
      _wrap(() => _remote.createFinanceEntry(data));

  @override
  Future<Either<Failure, AdminFinanceEntryEntity>> updateFinanceEntry(
          String id, Map<String, dynamic> data) =>
      _wrap(() => _remote.updateFinanceEntry(id, data));

  @override
  Future<Either<Failure, void>> voidFinanceEntry(String id) =>
      _wrap(() => _remote.voidFinanceEntry(id));

  @override
  Future<Either<Failure, List<AdminFinanceCategoryEntity>>>
      getFinanceCategories({String? type}) =>
          _wrap(() => _remote.getFinanceCategories(type: type));

  @override
  Future<Either<Failure, AdminFinanceCategoryEntity>> createFinanceCategory(
          Map<String, dynamic> data) =>
      _wrap(() => _remote.createFinanceCategory(data));

  @override
  Future<Either<Failure, AdminFinanceCategoryEntity>> updateFinanceCategory(
          String id, Map<String, dynamic> data) =>
      _wrap(() => _remote.updateFinanceCategory(id, data));

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
      if (error is UnauthorizedException) return const Left(UnauthorizedFailure());
      if (error is ForbiddenException) return const Left(ForbiddenFailure());
      if (error is NetworkException) return Left(NetworkFailure(error.message));
      if (error is ServerException) {
        return Left(ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
