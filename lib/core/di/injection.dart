import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/admin_login_usecase.dart';
import '../../features/auth/domain/usecases/admin_logout_usecase.dart';
import '../../features/auth/domain/usecases/get_admin_current_user_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_usecase.dart';
import '../../features/pos/data/datasources/pos_remote_datasource.dart';
import '../../features/pos/data/repositories/pos_repository_impl.dart';
import '../../features/pos/domain/repositories/pos_repository.dart';
import '../../features/pos/domain/usecases/pos_usecases.dart';
import '../../features/products/data/datasources/products_remote_datasource.dart';
import '../../features/products/data/repositories/products_repository_impl.dart';
import '../../features/products/domain/repositories/products_repository.dart';
import '../../features/products/domain/usecases/products_usecases.dart';
import '../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/domain/usecases/orders_usecases.dart';
import '../../features/reports/data/datasources/reports_remote_datasource.dart';
import '../../features/reports/data/repositories/reports_repository_impl.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/domain/usecases/reports_usecases.dart';
import '../../features/customers/data/datasources/customers_remote_datasource.dart';
import '../../features/customers/data/repositories/customers_repository_impl.dart';
import '../../features/customers/domain/repositories/customers_repository.dart';
import '../../features/customers/domain/usecases/customers_usecases.dart';
// ─── Inventory ────────────────────────────────────────────────────────────────
import '../../features/inventory/data/datasources/inventory_remote_datasource.dart';
import '../../features/inventory/data/datasources/warehouse_remote_datasource.dart';
import '../../features/inventory/data/datasources/cost_layer_remote_datasource.dart';
import '../../features/inventory/data/datasources/stock_count_remote_datasource.dart';
import '../../features/inventory/data/datasources/adjustment_remote_datasource.dart';
import '../../features/inventory/data/datasources/transfer_remote_datasource.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/data/repositories/warehouse_repository_impl.dart';
import '../../features/inventory/data/repositories/cost_layer_repository_impl.dart';
import '../../features/inventory/data/repositories/stock_count_repository_impl.dart';
import '../../features/inventory/data/repositories/adjustment_repository_impl.dart';
import '../../features/inventory/data/repositories/transfer_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/domain/repositories/warehouse_repository.dart';
import '../../features/inventory/domain/repositories/cost_layer_repository.dart';
import '../../features/inventory/domain/repositories/stock_count_repository.dart';
import '../../features/inventory/domain/repositories/adjustment_repository.dart';
import '../../features/inventory/domain/repositories/transfer_repository.dart';
import '../../features/inventory/domain/usecases/inventory_usecases.dart';
import '../../features/inventory/domain/usecases/warehouse_usecases.dart';
import '../../features/inventory/domain/usecases/cost_layer_usecases.dart';
import '../../features/inventory/domain/usecases/stock_count_usecases.dart';
import '../../features/inventory/domain/usecases/adjustment_usecases.dart';
import '../../features/inventory/domain/usecases/transfer_usecases.dart';
// ─── Suppliers ────────────────────────────────────────────────────────────────
import '../../features/suppliers/data/datasources/suppliers_remote_datasource.dart';
import '../../features/suppliers/data/datasources/ledger_remote_datasource.dart';
import '../../features/suppliers/data/datasources/aging_remote_datasource.dart';
import '../../features/suppliers/data/repositories/suppliers_repository_impl.dart';
import '../../features/suppliers/data/repositories/aging_repository_impl.dart';
import '../../features/suppliers/domain/repositories/suppliers_repository.dart';
import '../../features/suppliers/domain/usecases/suppliers_usecases.dart';
import '../../features/suppliers/domain/usecases/ledger_usecases.dart';
import '../../features/suppliers/domain/usecases/aging_usecases.dart';
// ─── Devices ──────────────────────────────────────────────────────────────────
import '../../features/devices/data/datasources/devices_remote_datasource.dart';
import '../../features/devices/data/repositories/devices_repository_impl.dart';
import '../../features/devices/domain/repositories/devices_repository.dart';
import '../../features/devices/domain/usecases/devices_usecases.dart';
// ─── Branches ─────────────────────────────────────────────────────────────────
import '../../features/branches/data/datasources/branches_remote_datasource.dart';
import '../../features/branches/data/repositories/branches_repository_impl.dart';
import '../../features/branches/domain/repositories/branches_repository.dart';
import '../../features/branches/domain/usecases/branches_usecases.dart';
// ─── Notifications ────────────────────────────────────────────────────────────
import '../../features/notifications/data/datasources/notifications_remote_datasource.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/notifications_usecases.dart';
// ─── Activity Log ─────────────────────────────────────────────────────────────
import '../../features/activity_log/data/datasources/activity_log_remote_datasource.dart';
import '../../features/activity_log/data/repositories/activity_log_repository_impl.dart';
import '../../features/activity_log/domain/repositories/activity_log_repository.dart';
import '../../features/activity_log/domain/usecases/activity_log_usecases.dart';
// ─── Users ────────────────────────────────────────────────────────────────────
import '../../features/users/data/datasources/users_remote_datasource.dart';
import '../../features/users/data/repositories/users_repository_impl.dart';
import '../../features/users/domain/repositories/users_repository.dart';
import '../../features/users/domain/usecases/users_usecases.dart';
// ─── Roles ────────────────────────────────────────────────────────────────────
import '../../features/roles/data/datasources/roles_remote_datasource.dart';
import '../../features/roles/data/repositories/roles_repository_impl.dart';
import '../../features/roles/domain/repositories/roles_repository.dart';
import '../../features/roles/domain/usecases/roles_usecases.dart';
// ─── Reservations ─────────────────────────────────────────────────────────────
import '../../features/reservations/data/datasources/reservations_remote_datasource.dart';
import '../../features/reservations/data/repositories/reservations_repository_impl.dart';
import '../../features/reservations/domain/repositories/reservations_repository.dart';
import '../../features/reservations/domain/usecases/reservations_usecases.dart';
// ─── Public Booking ───────────────────────────────────────────────────────────
import '../../features/public_booking/data/datasources/public_booking_remote_datasource.dart';
import '../../features/public_booking/data/repositories/public_booking_repository_impl.dart';
import '../../features/public_booking/domain/repositories/public_booking_repository.dart';
import '../../features/public_booking/domain/usecases/public_booking_usecases.dart';
// ─── Storefront ───────────────────────────────────────────────────────────────
import '../../features/storefront/data/datasources/sf_remote_datasource.dart';
import '../../features/storefront/data/repositories/sf_repository_impl.dart';
import '../../features/storefront/domain/repositories/storefront_repository.dart';
import '../../features/storefront/domain/usecases/sf_usecases.dart';
// ─── Digital Menu ─────────────────────────────────────────────────────────────
import '../../features/digital_menu/data/datasources/menu_firestore_datasource.dart';
import '../../features/digital_menu/data/repositories/menu_repository_impl.dart';
import '../../features/digital_menu/domain/repositories/menu_repository.dart';
import '../../features/digital_menu/domain/usecases/menu_usecases.dart';
// ─── Receipts ─────────────────────────────────────────────────────────────────
import '../../features/receipts/data/datasources/receipt_remote_datasource.dart';
import '../../features/receipts/data/repositories/receipt_repository_impl.dart';
import '../../features/receipts/domain/repositories/receipt_repository.dart';
import '../../features/receipts/domain/usecases/receipt_usecases.dart';
// ─── Homepage Builder ─────────────────────────────────────────────────────────
import '../../features/homepage_builder/data/datasources/homepage_builder_remote_datasource.dart';
import '../../features/homepage_builder/data/repositories/homepage_builder_repository_impl.dart';
import '../../features/homepage_builder/domain/repositories/homepage_builder_repository.dart';
import '../../features/homepage_builder/domain/usecases/homepage_builder_usecases.dart';
// ─── Store Settings ───────────────────────────────────────────────────────────
import '../../features/store_settings/data/datasources/store_settings_remote_datasource.dart';
import '../../features/store_settings/data/repositories/store_settings_repository_impl.dart';
import '../../features/store_settings/domain/repositories/store_settings_repository.dart';
import '../../features/store_settings/domain/usecases/store_settings_usecases.dart';
// ─── Admin ────────────────────────────────────────────────────────────────────
import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/domain/usecases/admin_usecases.dart';

part 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.init();

  // Inventory branch options (not in generated config)
  if (!getIt.isRegistered<GetInventoryBranchOptionsUseCase>()) {
    getIt.registerLazySingleton(
      () => GetInventoryBranchOptionsUseCase(getIt<InventoryRepository>()),
    );
  }

  // Warehouse set-default (not in generated config)
  if (!getIt.isRegistered<SetDefaultWarehouseUseCase>()) {
    getIt.registerLazySingleton(
      () => SetDefaultWarehouseUseCase(getIt<WarehouseRepository>()),
    );
  }

  // Cost layer consumptions (not in generated config)
  if (!getIt.isRegistered<GetCostLayerConsumptionsUseCase>()) {
    getIt.registerLazySingleton(
      () => GetCostLayerConsumptionsUseCase(getIt<CostLayerRepository>()),
    );
  }

  // Adjustment by ID (not in generated config)
  if (!getIt.isRegistered<GetAdjustmentByIdUseCase>()) {
    getIt.registerLazySingleton(
      () => GetAdjustmentByIdUseCase(getIt<AdjustmentRepository>()),
    );
  }

  // Transfer by ID (not in generated config)
  if (!getIt.isRegistered<GetTransferByIdUseCase>()) {
    getIt.registerLazySingleton(
      () => GetTransferByIdUseCase(getIt<TransferRepository>()),
    );
  }

  // Stock count by ID (not in generated config)
  if (!getIt.isRegistered<GetStockCountByIdUseCase>()) {
    getIt.registerLazySingleton(
      () => GetStockCountByIdUseCase(getIt<StockCountRepository>()),
    );
  }

  // Digital Menu (Firestore — no auth interceptor needed)
  if (!getIt.isRegistered<MenuFirestoreDataSource>()) {
    getIt.registerLazySingleton<MenuFirestoreDataSource>(
      () => MenuFirestoreDataSourceImpl(),
    );
    getIt.registerLazySingleton<MenuRepository>(
      () => MenuRepositoryImpl(getIt<MenuFirestoreDataSource>()),
    );
    getIt.registerLazySingleton(() => GetMenuSettingsUseCase(getIt<MenuRepository>()));
    getIt.registerLazySingleton(() => GetMenuProductConfigsUseCase(getIt<MenuRepository>()));
    getIt.registerLazySingleton(() => SaveMenuSettingsUseCase(getIt<MenuRepository>()));
    getIt.registerLazySingleton(() => SaveMenuProductConfigsUseCase(getIt<MenuRepository>()));
    getIt.registerLazySingleton(() => GetPublicMenuBySlugUseCase(getIt<MenuRepository>()));
    getIt.registerLazySingleton(() => GetPublicMenuProductsUseCase(getIt<MenuRepository>()));
    getIt.registerLazySingleton(() => UploadMenuLogoUseCase(getIt<MenuRepository>()));
  }

  // Receipts
  if (!getIt.isRegistered<ReceiptRemoteDataSource>()) {
    getIt.registerLazySingleton<ReceiptRemoteDataSource>(
      () => ReceiptRemoteDataSourceImpl(getIt<ApiClient>()),
    );
    getIt.registerLazySingleton<ReceiptRepository>(
      () => ReceiptRepositoryImpl(getIt<ReceiptRemoteDataSource>()),
    );
    getIt.registerLazySingleton(
        () => GetReceiptsUseCase(getIt<ReceiptRepository>()));
    getIt.registerLazySingleton(
        () => GetReceiptByIdUseCase(getIt<ReceiptRepository>()));
    getIt.registerLazySingleton(
        () => PostReceiptUseCase(getIt<ReceiptRepository>()));
    getIt.registerLazySingleton(
        () => CancelReceiptUseCase(getIt<ReceiptRepository>()));
  }

  // Homepage Builder
  if (!getIt.isRegistered<HomepageBuilderRemoteDataSource>()) {
    getIt.registerLazySingleton<HomepageBuilderRemoteDataSource>(
      () => HomepageBuilderRemoteDataSourceImpl(getIt<ApiClient>()),
    );
    getIt.registerLazySingleton<HomepageBuilderRepository>(
      () => HomepageBuilderRepositoryImpl(getIt<HomepageBuilderRemoteDataSource>()),
    );
    getIt.registerLazySingleton(
        () => GetHomepageLayoutUseCase(getIt<HomepageBuilderRepository>()));
    getIt.registerLazySingleton(
        () => SaveHomepageLayoutUseCase(getIt<HomepageBuilderRepository>()));
  }

  // Store Settings
  if (!getIt.isRegistered<StoreSettingsRemoteDataSource>()) {
    getIt.registerLazySingleton<StoreSettingsRemoteDataSource>(
      () => StoreSettingsRemoteDataSourceImpl(getIt<ApiClient>()),
    );
    getIt.registerLazySingleton<StoreSettingsRepository>(
      () => StoreSettingsRepositoryImpl(getIt<StoreSettingsRemoteDataSource>()),
    );
    getIt.registerLazySingleton(
        () => GetStoreSettingsUseCase(getIt<StoreSettingsRepository>()));
    getIt.registerLazySingleton(
        () => UpdateStoreSettingsUseCase(getIt<StoreSettingsRepository>()));
  }

  // Admin
  if (!getIt.isRegistered<AdminRemoteDataSource>()) {
    getIt.registerLazySingleton<AdminRemoteDataSource>(
      () => AdminRemoteDataSourceImpl(getIt<ApiClient>()),
    );
    getIt.registerLazySingleton<AdminRepository>(
      () => AdminRepositoryImpl(getIt<AdminRemoteDataSource>()),
    );
    getIt.registerLazySingleton(
        () => GetAdminVendorsUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetVendorCreateMetaUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminVendorByIdUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => ToggleAdminVendorStatusUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => CreateAdminVendorUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => UpdateAdminVendorUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminPlansUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => CreateAdminPlanUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => UpdateAdminPlanUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminPaymentsUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminInvoicesUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminAnalyticsUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminVendorDetailsUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => DeleteAdminPlanUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => CreateAdminPaymentUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => CreateAdminInvoiceUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => MarkAdminPaymentPaidUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => MarkAdminPaymentFailedUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => VoidAdminInvoiceUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminSubscriptionsUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => AssignVendorSubscriptionUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => UpdateAdminSubscriptionUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminFinanceSummaryUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminFinanceEntriesUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => CreateAdminFinanceEntryUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => UpdateAdminFinanceEntryUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => VoidAdminFinanceEntryUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => GetAdminFinanceCategoriesUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => CreateAdminFinanceCategoryUseCase(getIt<AdminRepository>()));
    getIt.registerLazySingleton(
        () => UpdateAdminFinanceCategoryUseCase(getIt<AdminRepository>()));
  }

  // Supplier Ledger extra usecases (not in generated config)
  if (!getIt.isRegistered<RecordSupplierPaymentUseCase>()) {
    getIt.registerLazySingleton(
      () => RecordSupplierPaymentUseCase(getIt<LedgerRepository>()),
    );
  }
  if (!getIt.isRegistered<ExportSupplierLedgerUseCase>()) {
    getIt.registerLazySingleton(
      () => ExportSupplierLedgerUseCase(getIt<LedgerRepository>()),
    );
  }

  // Public Booking (manual registration — no auth interceptor needed)
  if (!getIt.isRegistered<PublicBookingRemoteDataSource>()) {
    getIt.registerLazySingleton<PublicBookingRemoteDataSource>(
      () => PublicBookingRemoteDataSourceImpl(getIt<ApiClient>()),
    );
    getIt.registerLazySingleton<PublicBookingRepository>(
      () => PublicBookingRepositoryImpl(getIt<PublicBookingRemoteDataSource>()),
    );
    getIt.registerLazySingleton(() => GetPublicBookingInfoUseCase(getIt<PublicBookingRepository>()));
    getIt.registerLazySingleton(() => GetBookingClosedDatesUseCase(getIt<PublicBookingRepository>()));
    getIt.registerLazySingleton(() => GetBookingSlotsUseCase(getIt<PublicBookingRepository>()));
    getIt.registerLazySingleton(() => CreateBookingUseCase(getIt<PublicBookingRepository>()));
  }

  // Storefront
  if (!getIt.isRegistered<SfRemoteDataSource>()) {
    getIt.registerLazySingleton<SfRemoteDataSource>(
        () => SfRemoteDataSourceImpl(getIt<ApiClient>()));
    getIt.registerLazySingleton<StorefrontRepository>(
        () => StorefrontRepositoryImpl(getIt<SfRemoteDataSource>()));
    getIt.registerLazySingleton(() => GetStorefrontUseCase(getIt<StorefrontRepository>()));
    getIt.registerLazySingleton(() => GetSfCategoriesUseCase(getIt<StorefrontRepository>()));
    getIt.registerLazySingleton(() => GetSfProductsUseCase(getIt<StorefrontRepository>()));
    getIt.registerLazySingleton(() => GetSfProductUseCase(getIt<StorefrontRepository>()));
    getIt.registerLazySingleton(() => PlaceSfOrderUseCase(getIt<StorefrontRepository>()));
    getIt.registerLazySingleton(() => GetSfOrderStatusUseCase(getIt<StorefrontRepository>()));
    getIt.registerLazySingleton(() => PlaceSfReservationUseCase(getIt<StorefrontRepository>()));
    getIt.registerLazySingleton(() => GetStorefrontSettingsUseCase(getIt<StorefrontRepository>()));
    getIt.registerLazySingleton(() => UpdateStorefrontSettingsUseCase(getIt<StorefrontRepository>()));
  }
}
