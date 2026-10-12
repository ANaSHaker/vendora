import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../models/admin_analytics_model.dart';
import '../models/admin_finance_model.dart';
import '../models/admin_payment_model.dart';
import '../models/admin_plan_model.dart';
import '../models/admin_subscription_model.dart';
import '../models/admin_vendor_model.dart';
import '../models/vendor_create_meta_model.dart';

abstract class AdminRemoteDataSource {
  // Vendors
  Future<VendorCreateMetaModel> getVendorCreateMeta();
  Future<PaginatedResponse<AdminVendorModel>> getVendors({
    String? search,
    String? status,
    String? planId,
    String? subscriptionStatus,
    String? accountStatus,
    int page = 1,
    int? perPage,
  });
  Future<AdminVendorModel> getVendorById(String id);
  Future<AdminVendorModel> getVendorFinancials(String id);
  Future<AdminVendorModel> toggleVendorStatus(String id);
  Future<AdminVendorModel> createVendor(Map<String, dynamic> data);
  Future<AdminVendorModel> updateVendor(String id, Map<String, dynamic> data);
  Future<AdminSubscriptionModel> assignVendorSubscription(
      String vendorId, Map<String, dynamic> data);

  // Plans
  Future<List<AdminPlanModel>> getPlans();
  Future<AdminPlanModel> getPlanById(String id);
  Future<AdminPlanModel> createPlan(Map<String, dynamic> data);
  Future<AdminPlanModel> updatePlan(String id, Map<String, dynamic> data);
  Future<void> deletePlan(String id);

  // Billing
  Future<PaginatedResponse<AdminPaymentModel>> getPayments({
    int page = 1,
    String? status,
    String? method,
  });
  Future<PaginatedResponse<AdminInvoiceModel>> getInvoices({
    int page = 1,
    String? status,
  });
  Future<AdminPaymentModel> createPayment(Map<String, dynamic> data);
  Future<AdminInvoiceModel> createInvoice(Map<String, dynamic> data);
  Future<AdminPaymentModel> markPaymentPaid(String id);
  Future<AdminPaymentModel> markPaymentFailed(String id);
  Future<AdminInvoiceModel> voidInvoice(String id);

  // Subscriptions
  Future<PaginatedResponse<AdminSubscriptionModel>> getSubscriptions({
    int page = 1,
    String? status,
    String? vendorId,
  });
  Future<AdminSubscriptionModel> updateSubscription(
      String id, Map<String, dynamic> data);

  // Analytics
  Future<AdminAnalyticsModel> getAnalyticsSummary({int chartDays = 30});

  // Finance
  Future<AdminFinanceSummaryModel> getFinanceSummary({String? from, String? to});
  Future<PaginatedResponse<AdminFinanceEntryModel>> getFinanceEntries({
    String? type,
    String? from,
    String? to,
    String? categoryId,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  });
  Future<AdminFinanceEntryModel> createFinanceEntry(Map<String, dynamic> data);
  Future<AdminFinanceEntryModel> updateFinanceEntry(String id, Map<String, dynamic> data);
  Future<void> voidFinanceEntry(String id);
  Future<List<AdminFinanceCategoryModel>> getFinanceCategories({String? type});
  Future<AdminFinanceCategoryModel> createFinanceCategory(Map<String, dynamic> data);
  Future<AdminFinanceCategoryModel> updateFinanceCategory(String id, Map<String, dynamic> data);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient _client;
  const AdminRemoteDataSourceImpl(this._client);

  // ── Vendors ──────────────────────────────────────────────────────────────

  @override
  Future<VendorCreateMetaModel> getVendorCreateMeta() async {
    final res = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.adminVendorsCreate);
    final body = res.data!;
    final data = body['data'] as Map<String, dynamic>? ?? body;
    return VendorCreateMetaModel.fromJson(data);
  }

  @override
  Future<PaginatedResponse<AdminVendorModel>> getVendors({
    String? search,
    String? status,
    String? planId,
    String? subscriptionStatus,
    String? accountStatus,
    int page = 1,
    int? perPage,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      if (perPage != null) 'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
      if (planId != null && planId.isNotEmpty) 'plan_id': planId,
      if (subscriptionStatus != null && subscriptionStatus.isNotEmpty)
        'subscription_status': subscriptionStatus,
      if (accountStatus != null && accountStatus.isNotEmpty)
        'account_status': accountStatus,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminVendors,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, AdminVendorModel.fromJson);
  }

  @override
  Future<AdminVendorModel> getVendorById(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.adminVendorById(id));
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminVendorModel.fromJson(json);
  }

  @override
  Future<AdminVendorModel> getVendorFinancials(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminVendorById(id),
      queryParameters: {'include': 'financials,subscription,features'},
    );
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminVendorModel.fromJson(json);
  }

  @override
  Future<AdminVendorModel> toggleVendorStatus(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.adminToggleVendor(id), data: {});
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminVendorModel.fromJson(json);
  }

  @override
  Future<AdminVendorModel> createVendor(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.adminVendors, data: data);
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminVendorModel.fromJson(json);
  }

  @override
  Future<AdminVendorModel> updateVendor(
      String id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.adminVendorById(id), data: data);
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminVendorModel.fromJson(json);
  }

  @override
  Future<AdminSubscriptionModel> assignVendorSubscription(
      String vendorId, Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.adminVendorSubscriptions(vendorId),
        data: data);
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminSubscriptionModel.fromJson(json);
  }

  // ── Plans ────────────────────────────────────────────────────────────────

  @override
  Future<List<AdminPlanModel>> getPlans() async {
    final res = await _client.get<Map<String, dynamic>>(ApiEndpoints.adminPlans);
    final body = res.data!;
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AdminPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminPlanModel> getPlanById(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.adminPlanById(id));
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminPlanModel.fromJson(json);
  }

  @override
  Future<AdminPlanModel> createPlan(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.adminPlans, data: data);
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminPlanModel.fromJson(json);
  }

  @override
  Future<AdminPlanModel> updatePlan(
      String id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.adminPlanById(id), data: data);
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminPlanModel.fromJson(json);
  }

  @override
  Future<void> deletePlan(String id) async {
    await _client.delete<Map<String, dynamic>>(ApiEndpoints.adminDeletePlan(id));
  }

  // ── Billing ──────────────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<AdminPaymentModel>> getPayments({
    int page = 1,
    String? status,
    String? method,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminBillingPayments,
      queryParameters: {
        'page': page,
        'per_page': 50,
        if (status != null && status.isNotEmpty) 'status': status,
        if (method != null && method.isNotEmpty) 'method': method,
      },
    );
    return PaginatedResponse.fromJson(res.data!, AdminPaymentModel.fromJson);
  }

  @override
  Future<PaginatedResponse<AdminInvoiceModel>> getInvoices({
    int page = 1,
    String? status,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminBillingInvoices,
      queryParameters: {
        'page': page,
        'per_page': 50,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return PaginatedResponse.fromJson(res.data!, AdminInvoiceModel.fromJson);
  }

  @override
  Future<AdminPaymentModel> createPayment(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.adminBillingPayments, data: data);
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminPaymentModel.fromJson(json);
  }

  @override
  Future<AdminInvoiceModel> createInvoice(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.adminBillingInvoices, data: data);
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminInvoiceModel.fromJson(json);
  }

  @override
  Future<AdminPaymentModel> markPaymentPaid(String id) async {
    final res = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.adminBillingPaymentById(id), data: {'action': 'mark_paid'});
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminPaymentModel.fromJson(json);
  }

  @override
  Future<AdminPaymentModel> markPaymentFailed(String id) async {
    final res = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.adminBillingPaymentById(id), data: {'action': 'mark_failed'});
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminPaymentModel.fromJson(json);
  }

  @override
  Future<AdminInvoiceModel> voidInvoice(String id) async {
    final res = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.adminBillingInvoiceById(id), data: {'status': 'void'});
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminInvoiceModel.fromJson(json);
  }

  // ── Subscriptions ────────────────────────────────────────────────────────

  @override
  Future<PaginatedResponse<AdminSubscriptionModel>> getSubscriptions({
    int page = 1,
    String? status,
    String? vendorId,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminSubscriptions,
      queryParameters: {
        'page': page,
        'per_page': 25,
        if (status != null && status.isNotEmpty) 'status': status,
        if (vendorId != null && vendorId.isNotEmpty) 'vendor_id': vendorId,
      },
    );
    return PaginatedResponse.fromJson(
        res.data!, AdminSubscriptionModel.fromJson);
  }

  @override
  Future<AdminSubscriptionModel> updateSubscription(
      String id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.adminSubscriptionById(id),
        data: data);
    final body = res.data!;
    final json = body['data'] as Map<String, dynamic>? ?? body;
    return AdminSubscriptionModel.fromJson(json);
  }

  // ── Analytics ────────────────────────────────────────────────────────────

  @override
  Future<AdminAnalyticsModel> getAnalyticsSummary({int chartDays = 30}) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminAnalyticsSummary,
      queryParameters: {'chart_days': chartDays},
    );
    return AdminAnalyticsModel.fromJson(res.data!);
  }

  // ── Finance ──────────────────────────────────────────────────────────────

  @override
  Future<AdminFinanceSummaryModel> getFinanceSummary({
    String? from,
    String? to,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminFinanceSummary,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );
    return AdminFinanceSummaryModel.fromJson(res.data!);
  }

  @override
  Future<PaginatedResponse<AdminFinanceEntryModel>> getFinanceEntries({
    String? type,
    String? from,
    String? to,
    String? categoryId,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminFinanceEntries,
      queryParameters: {
        if (type != null) 'type': type,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (categoryId != null) 'category_id': categoryId,
        if (status != null) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      },
    );
    return PaginatedResponse.fromJson(
      res.data!,
      (e) => AdminFinanceEntryModel.fromJson(e),
    );
  }

  @override
  Future<AdminFinanceEntryModel> createFinanceEntry(
      Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.adminFinanceEntries, data: data);
    final body = res.data!;
    return AdminFinanceEntryModel.fromJson(
        body['data'] as Map<String, dynamic>? ?? body);
  }

  @override
  Future<AdminFinanceEntryModel> updateFinanceEntry(
      String id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.adminFinanceEntryById(id), data: data);
    final body = res.data!;
    return AdminFinanceEntryModel.fromJson(
        body['data'] as Map<String, dynamic>? ?? body);
  }

  @override
  Future<void> voidFinanceEntry(String id) async {
    await _client.post<dynamic>(ApiEndpoints.adminFinanceEntryVoid(id));
  }

  @override
  Future<List<AdminFinanceCategoryModel>> getFinanceCategories(
      {String? type}) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminFinanceCategories,
      queryParameters: {if (type != null) 'type': type},
    );
    final body = res.data!;
    final list = (body['data'] ?? body) as List<dynamic>;
    return list
        .map((e) =>
            AdminFinanceCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminFinanceCategoryModel> createFinanceCategory(
      Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.adminFinanceCategories, data: data);
    final body = res.data!;
    return AdminFinanceCategoryModel.fromJson(
        body['data'] as Map<String, dynamic>? ?? body);
  }

  @override
  Future<AdminFinanceCategoryModel> updateFinanceCategory(
      String id, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
        ApiEndpoints.adminFinanceCategoryById(id), data: data);
    final body = res.data!;
    return AdminFinanceCategoryModel.fromJson(
        body['data'] as Map<String, dynamic>? ?? body);
  }
}
