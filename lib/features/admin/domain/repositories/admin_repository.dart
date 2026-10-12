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

abstract class AdminRepository {
  Future<Either<Failure, VendorCreateMetaEntity>> getVendorCreateMeta();
  Future<Either<Failure, PaginatedResponse<AdminVendorEntity>>> getVendors({
    String? search,
    String? status,
    String? planId,
    String? subscriptionStatus,
    String? accountStatus,
    int page = 1,
    int? perPage,
  });
  Future<Either<Failure, AdminVendorEntity>> getVendorById(String id);
  Future<Either<Failure, AdminVendorEntity>> getVendorDetails(String id);
  Future<Either<Failure, AdminVendorEntity>> toggleVendorStatus(String id);
  Future<Either<Failure, AdminVendorEntity>> createVendor(Map<String, dynamic> data);
  Future<Either<Failure, AdminVendorEntity>> updateVendor(String id, Map<String, dynamic> data);
  Future<Either<Failure, AdminSubscriptionEntity>> assignVendorSubscription(
      String vendorId, Map<String, dynamic> data);

  Future<Either<Failure, List<AdminPlanEntity>>> getPlans();
  Future<Either<Failure, AdminPlanEntity>> getPlanById(String id);
  Future<Either<Failure, AdminPlanEntity>> createPlan(Map<String, dynamic> data);
  Future<Either<Failure, AdminPlanEntity>> updatePlan(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deletePlan(String id);

  Future<Either<Failure, PaginatedResponse<AdminPaymentEntity>>> getPayments({
    int page = 1,
    String? status,
    String? method,
  });
  Future<Either<Failure, PaginatedResponse<AdminInvoiceEntity>>> getInvoices({
    int page = 1,
    String? status,
  });
  Future<Either<Failure, AdminPaymentEntity>> createPayment(Map<String, dynamic> data);
  Future<Either<Failure, AdminInvoiceEntity>> createInvoice(Map<String, dynamic> data);
  Future<Either<Failure, AdminPaymentEntity>> markPaymentPaid(String id);
  Future<Either<Failure, AdminPaymentEntity>> markPaymentFailed(String id);
  Future<Either<Failure, AdminInvoiceEntity>> voidInvoice(String id);

  Future<Either<Failure, PaginatedResponse<AdminSubscriptionEntity>>>
      getSubscriptions({int page = 1, String? status, String? vendorId});
  Future<Either<Failure, AdminSubscriptionEntity>> updateSubscription(
      String id, Map<String, dynamic> data);

  Future<Either<Failure, AdminAnalyticsEntity>> getAnalyticsSummary({int chartDays = 30});

  Future<Either<Failure, AdminFinanceSummaryEntity>> getFinanceSummary({String? from, String? to});
  Future<Either<Failure, PaginatedResponse<AdminFinanceEntryEntity>>> getFinanceEntries({
    String? type, String? from, String? to,
    String? categoryId, String? status, String? search,
    int page = 1, int perPage = 50,
  });
  Future<Either<Failure, AdminFinanceEntryEntity>> createFinanceEntry(Map<String, dynamic> data);
  Future<Either<Failure, AdminFinanceEntryEntity>> updateFinanceEntry(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> voidFinanceEntry(String id);
  Future<Either<Failure, List<AdminFinanceCategoryEntity>>> getFinanceCategories({String? type});
  Future<Either<Failure, AdminFinanceCategoryEntity>> createFinanceCategory(Map<String, dynamic> data);
  Future<Either<Failure, AdminFinanceCategoryEntity>> updateFinanceCategory(String id, Map<String, dynamic> data);
}
