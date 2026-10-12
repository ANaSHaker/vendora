// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

// dart format off

// ignore_for_file: directives_ordering
// ignore_for_file: no_leading_underscores_for_library_prefixes

part of 'injection.dart';

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

extension GetItInjectableX on GetIt {
  GetIt init({
    String? environment,
    EnvironmentFilter? environmentFilter,
  }) {
    final gh = GetItHelper(
      this,
      environment,
      environmentFilter,
    );

    // ─── Core ──────────────────────────────────────────────────────────────
    gh.lazySingleton<SecureStorage>(() => SecureStorage());
    gh.lazySingleton<LocalStorage>(() => LocalStorage(get<SharedPreferences>()));
    gh.lazySingleton<ApiClient>(() => ApiClient(get<SecureStorage>()));

    // ─── Auth ──────────────────────────────────────────────────────────────
    gh.lazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(get<ApiClient>(), get<SecureStorage>()),
    );
    gh.lazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(get<AuthRemoteDataSource>()),
    );
    gh.lazySingleton<LoginUseCase>(
      () => LoginUseCase(get<AuthRepository>()),
    );
    gh.lazySingleton<LogoutUseCase>(
      () => LogoutUseCase(get<AuthRepository>()),
    );
    gh.lazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(get<AuthRepository>()),
    );
    gh.lazySingleton<AdminLoginUseCase>(
      () => AdminLoginUseCase(get<AuthRepository>()),
    );
    gh.lazySingleton<AdminLogoutUseCase>(
      () => AdminLogoutUseCase(get<AuthRepository>()),
    );
    gh.lazySingleton<GetAdminCurrentUserUseCase>(
      () => GetAdminCurrentUserUseCase(get<AuthRepository>()),
    );
    gh.lazySingleton<AuthCubit>(
      () => AuthCubit(
        login: get<LoginUseCase>(),
        logout: get<LogoutUseCase>(),
        getCurrentUser: get<GetCurrentUserUseCase>(),
        getAdminCurrentUser: get<GetAdminCurrentUserUseCase>(),
        adminLogin: get<AdminLoginUseCase>(),
        adminLogout: get<AdminLogoutUseCase>(),
        storage: get<SecureStorage>(),
        localStorage: get<LocalStorage>(),
        authDs: get<AuthRemoteDataSource>(),
      ),
    );

    // ─── Dashboard ─────────────────────────────────────────────────────────
    gh.lazySingleton<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(get<DashboardRemoteDataSource>()),
    );
    gh.lazySingleton<GetDashboardUseCase>(
      () => GetDashboardUseCase(get<DashboardRepository>()),
    );

    // ─── POS ───────────────────────────────────────────────────────────────
    gh.lazySingleton<PosRemoteDataSource>(
      () => PosRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<PosRepository>(
      () => PosRepositoryImpl(get<PosRemoteDataSource>()),
    );
    gh.lazySingleton<GetBranchesUseCase>(
      () => GetBranchesUseCase(get<PosRepository>()),
    );
    gh.lazySingleton<GetWarehousesUseCase>(
      () => GetWarehousesUseCase(get<PosRepository>()),
    );
    gh.lazySingleton<GetPosProductsUseCase>(
      () => GetPosProductsUseCase(get<PosRepository>()),
    );
    gh.lazySingleton<GetPosCategoriesUseCase>(
      () => GetPosCategoriesUseCase(get<PosRepository>()),
    );
    gh.lazySingleton<SearchPosCustomersUseCase>(
      () => SearchPosCustomersUseCase(get<PosRepository>()),
    );
    gh.lazySingleton<CreatePosCustomerUseCase>(
      () => CreatePosCustomerUseCase(get<PosRepository>()),
    );
    gh.lazySingleton<CreateOrderUseCase>(
      () => CreateOrderUseCase(get<PosRepository>()),
    );

    // ─── Products ──────────────────────────────────────────────────────────────
    gh.lazySingleton<ProductsRemoteDataSource>(
      () => ProductsRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<ProductsRepository>(
      () => ProductsRepositoryImpl(get<ProductsRemoteDataSource>()),
    );
    gh.lazySingleton<GetProductsUseCase>(
      () => GetProductsUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<CreateProductUseCase>(
      () => CreateProductUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<UpdateProductUseCase>(
      () => UpdateProductUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<DeleteProductUseCase>(
      () => DeleteProductUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<GetCategoriesUseCase>(
      () => GetCategoriesUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<CreateCategoryUseCase>(
      () => CreateCategoryUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<UpdateCategoryUseCase>(
      () => UpdateCategoryUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<DeleteCategoryUseCase>(
      () => DeleteCategoryUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<ExportCategoriesUseCase>(
      () => ExportCategoriesUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<ImportCategoriesUseCase>(
      () => ImportCategoriesUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<ExportProductsUseCase>(
      () => ExportProductsUseCase(get<ProductsRepository>()),
    );
    gh.lazySingleton<ImportProductsUseCase>(
      () => ImportProductsUseCase(get<ProductsRepository>()),
    );

    // ─── Orders ────────────────────────────────────────────────────────────
    gh.lazySingleton<OrdersRemoteDataSource>(
      () => OrdersRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<OrdersRepository>(
      () => OrdersRepositoryImpl(get<OrdersRemoteDataSource>()),
    );
    gh.lazySingleton<GetOrdersUseCase>(
      () => GetOrdersUseCase(get<OrdersRepository>()),
    );
    gh.lazySingleton<GetOrderByIdUseCase>(
      () => GetOrderByIdUseCase(get<OrdersRepository>()),
    );
    gh.lazySingleton<GetOrderByTokenUseCase>(
      () => GetOrderByTokenUseCase(get<OrdersRepository>()),
    );
    gh.lazySingleton<UpdateOrderStatusUseCase>(
      () => UpdateOrderStatusUseCase(get<OrdersRepository>()),
    );
    gh.lazySingleton<UpdateFulfillmentStatusUseCase>(
      () => UpdateFulfillmentStatusUseCase(get<OrdersRepository>()),
    );
    gh.lazySingleton<RefundOrderUseCase>(
      () => RefundOrderUseCase(get<OrdersRepository>()),
    );
    gh.lazySingleton<DownloadInvoiceUseCase>(
      () => DownloadInvoiceUseCase(get<OrdersRepository>()),
    );
    gh.lazySingleton<GetNetRevenueUseCase>(
      () => GetNetRevenueUseCase(get<OrdersRepository>()),
    );

    // ─── Reports ───────────────────────────────────────────────────────────
    gh.lazySingleton<ReportsRemoteDataSource>(
      () => ReportsRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<ReportsRepository>(
      () => ReportsRepositoryImpl(get<ReportsRemoteDataSource>()),
    );
    gh.lazySingleton<GetSalesReportUseCase>(
      () => GetSalesReportUseCase(get<ReportsRepository>()),
    );
    gh.lazySingleton<GetSalesOrdersUseCase>(
      () => GetSalesOrdersUseCase(get<ReportsRepository>()),
    );
    gh.lazySingleton<GetInventoryTabReportUseCase>(
      () => GetInventoryTabReportUseCase(get<ReportsRepository>()),
    );
    gh.lazySingleton<GetFinancialReportUseCase>(
      () => GetFinancialReportUseCase(get<ReportsRepository>()),
    );
    gh.lazySingleton<ExportReportUseCase>(
      () => ExportReportUseCase(get<ReportsRepository>()),
    );

    // ─── Customers ─────────────────────────────────────────────────────────
    gh.lazySingleton<CustomersRemoteDataSource>(
      () => CustomersRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<CustomersRepository>(
      () => CustomersRepositoryImpl(get<CustomersRemoteDataSource>()),
    );
    gh.lazySingleton<GetCustomersUseCase>(
      () => GetCustomersUseCase(get<CustomersRepository>()),
    );
    gh.lazySingleton<GetCustomerByIdUseCase>(
      () => GetCustomerByIdUseCase(get<CustomersRepository>()),
    );
    gh.lazySingleton<CreateCustomerUseCase>(
      () => CreateCustomerUseCase(get<CustomersRepository>()),
    );
    gh.lazySingleton<UpdateCustomerUseCase>(
      () => UpdateCustomerUseCase(get<CustomersRepository>()),
    );
    gh.lazySingleton<DeleteCustomerUseCase>(
      () => DeleteCustomerUseCase(get<CustomersRepository>()),
    );

    // ─── Inventory — Stock Balance & Movements ─────────────────────────────
    gh.lazySingleton<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<InventoryRepository>(
      () => InventoryRepositoryImpl(get<InventoryRemoteDataSource>()),
    );
    gh.lazySingleton<GetInventoryStockUseCase>(
      () => GetInventoryStockUseCase(get<InventoryRepository>()),
    );
    gh.lazySingleton<GetInventoryMovementsUseCase>(
      () => GetInventoryMovementsUseCase(get<InventoryRepository>()),
    );
    gh.lazySingleton<GetInventoryWarehouseOptionsUseCase>(
      () => GetInventoryWarehouseOptionsUseCase(get<InventoryRepository>()),
    );

    // ─── Inventory — Warehouses ────────────────────────────────────────────
    gh.lazySingleton<WarehouseRemoteDataSource>(
      () => WarehouseRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<WarehouseRepository>(
      () => WarehouseRepositoryImpl(get<WarehouseRemoteDataSource>()),
    );
    gh.lazySingleton<GetManagedWarehousesUseCase>(
      () => GetManagedWarehousesUseCase(get<WarehouseRepository>()),
    );
    gh.lazySingleton<CreateWarehouseUseCase>(
      () => CreateWarehouseUseCase(get<WarehouseRepository>()),
    );
    gh.lazySingleton<UpdateWarehouseUseCase>(
      () => UpdateWarehouseUseCase(get<WarehouseRepository>()),
    );
    gh.lazySingleton<DeleteWarehouseUseCase>(
      () => DeleteWarehouseUseCase(get<WarehouseRepository>()),
    );

    // ─── Inventory — Cost Layers ───────────────────────────────────────────
    gh.lazySingleton<CostLayerRemoteDataSource>(
      () => CostLayerRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<CostLayerRepository>(
      () => CostLayerRepositoryImpl(get<CostLayerRemoteDataSource>()),
    );
    gh.lazySingleton<GetCostLayersUseCase>(
      () => GetCostLayersUseCase(get<CostLayerRepository>()),
    );

    // ─── Inventory — Stock Counts ──────────────────────────────────────────
    gh.lazySingleton<StockCountRemoteDataSource>(
      () => StockCountRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<StockCountRepository>(
      () => StockCountRepositoryImpl(get<StockCountRemoteDataSource>()),
    );
    gh.lazySingleton<GetStockCountsUseCase>(
      () => GetStockCountsUseCase(get<StockCountRepository>()),
    );
    gh.lazySingleton<GetStockCountByIdUseCase>(
      () => GetStockCountByIdUseCase(get<StockCountRepository>()),
    );
    gh.lazySingleton<CreateStockCountUseCase>(
      () => CreateStockCountUseCase(get<StockCountRepository>()),
    );
    gh.lazySingleton<PostStockCountUseCase>(
      () => PostStockCountUseCase(get<StockCountRepository>()),
    );
    gh.lazySingleton<DeleteStockCountUseCase>(
      () => DeleteStockCountUseCase(get<StockCountRepository>()),
    );

    // ─── Inventory — Adjustments ───────────────────────────────────────────
    gh.lazySingleton<AdjustmentRemoteDataSource>(
      () => AdjustmentRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<AdjustmentRepository>(
      () => AdjustmentRepositoryImpl(get<AdjustmentRemoteDataSource>()),
    );
    gh.lazySingleton<GetAdjustmentsUseCase>(
      () => GetAdjustmentsUseCase(get<AdjustmentRepository>()),
    );
    gh.lazySingleton<CreateAdjustmentUseCase>(
      () => CreateAdjustmentUseCase(get<AdjustmentRepository>()),
    );
    gh.lazySingleton<UpdateAdjustmentUseCase>(
      () => UpdateAdjustmentUseCase(get<AdjustmentRepository>()),
    );
    gh.lazySingleton<ApproveAdjustmentUseCase>(
      () => ApproveAdjustmentUseCase(get<AdjustmentRepository>()),
    );
    gh.lazySingleton<PostAdjustmentUseCase>(
      () => PostAdjustmentUseCase(get<AdjustmentRepository>()),
    );
    gh.lazySingleton<CancelAdjustmentUseCase>(
      () => CancelAdjustmentUseCase(get<AdjustmentRepository>()),
    );
    gh.lazySingleton<DeleteAdjustmentUseCase>(
      () => DeleteAdjustmentUseCase(get<AdjustmentRepository>()),
    );

    // ─── Inventory — Transfers ─────────────────────────────────────────────
    gh.lazySingleton<TransferRemoteDataSource>(
      () => TransferRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<TransferRepository>(
      () => TransferRepositoryImpl(get<TransferRemoteDataSource>()),
    );
    gh.lazySingleton<GetTransfersUseCase>(
      () => GetTransfersUseCase(get<TransferRepository>()),
    );
    gh.lazySingleton<GetTransferByIdUseCase>(
      () => GetTransferByIdUseCase(get<TransferRepository>()),
    );
    gh.lazySingleton<CreateTransferUseCase>(
      () => CreateTransferUseCase(get<TransferRepository>()),
    );
    gh.lazySingleton<ApproveTransferUseCase>(
      () => ApproveTransferUseCase(get<TransferRepository>()),
    );
    gh.lazySingleton<PostTransferUseCase>(
      () => PostTransferUseCase(get<TransferRepository>()),
    );
    gh.lazySingleton<ReceiveTransferUseCase>(
      () => ReceiveTransferUseCase(get<TransferRepository>()),
    );
    gh.lazySingleton<DeleteTransferUseCase>(
      () => DeleteTransferUseCase(get<TransferRepository>()),
    );

    // ─── Suppliers ─────────────────────────────────────────────────────────
    gh.lazySingleton<SuppliersRemoteDataSource>(
      () => SuppliersRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<LedgerRemoteDataSource>(
      () => LedgerRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<SuppliersRepository>(
      () => SuppliersRepositoryImpl(get<SuppliersRemoteDataSource>()),
    );
    gh.lazySingleton<LedgerRepository>(
      () => LedgerRepositoryImpl(get<LedgerRemoteDataSource>()),
    );
    gh.lazySingleton<GetSuppliersUseCase>(
      () => GetSuppliersUseCase(get<SuppliersRepository>()),
    );
    gh.lazySingleton<GetSupplierByIdUseCase>(
      () => GetSupplierByIdUseCase(get<SuppliersRepository>()),
    );
    gh.lazySingleton<CreateSupplierUseCase>(
      () => CreateSupplierUseCase(get<SuppliersRepository>()),
    );
    gh.lazySingleton<UpdateSupplierUseCase>(
      () => UpdateSupplierUseCase(get<SuppliersRepository>()),
    );
    gh.lazySingleton<DeleteSupplierUseCase>(
      () => DeleteSupplierUseCase(get<SuppliersRepository>()),
    );
    gh.lazySingleton<GetSupplierLedgerUseCase>(
      () => GetSupplierLedgerUseCase(get<LedgerRepository>()),
    );
    gh.lazySingleton<AgingRemoteDataSource>(
      () => AgingRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<AgingRepository>(
      () => AgingRepositoryImpl(get<AgingRemoteDataSource>()),
    );
    gh.lazySingleton<GetSupplierAgingUseCase>(
      () => GetSupplierAgingUseCase(get<AgingRepository>()),
    );
    gh.lazySingleton<ExportSupplierAgingUseCase>(
      () => ExportSupplierAgingUseCase(get<AgingRepository>()),
    );

    // ─── Devices ──────────────────────────────────────────────────────────────
    gh.lazySingleton<DevicesRemoteDataSource>(
      () => DevicesRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<DevicesRepository>(
      () => DevicesRepositoryImpl(get<DevicesRemoteDataSource>()),
    );
    gh.lazySingleton<GetDeviceSessionsUseCase>(
      () => GetDeviceSessionsUseCase(get<DevicesRepository>()),
    );
    gh.lazySingleton<LogoutDeviceUseCase>(
      () => LogoutDeviceUseCase(get<DevicesRepository>()),
    );
    gh.lazySingleton<LogoutAllDevicesUseCase>(
      () => LogoutAllDevicesUseCase(get<DevicesRepository>()),
    );
    gh.lazySingleton<BlockDeviceUseCase>(
      () => BlockDeviceUseCase(get<DevicesRepository>()),
    );

    // ─── Branches ─────────────────────────────────────────────────────────────
    gh.lazySingleton<BranchesRemoteDataSource>(
      () => BranchesRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<BranchesRepository>(
      () => BranchesRepositoryImpl(get<BranchesRemoteDataSource>()),
    );
    gh.lazySingleton<GetManagedBranchesUseCase>(
      () => GetManagedBranchesUseCase(get<BranchesRepository>()),
    );
    gh.lazySingleton<CreateBranchUseCase>(
      () => CreateBranchUseCase(get<BranchesRepository>()),
    );
    gh.lazySingleton<UpdateBranchUseCase>(
      () => UpdateBranchUseCase(get<BranchesRepository>()),
    );
    gh.lazySingleton<DeleteBranchUseCase>(
      () => DeleteBranchUseCase(get<BranchesRepository>()),
    );

    // ─── Notifications ─────────────────────────────────────────────────────────
    gh.lazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(get<NotificationsRemoteDataSource>()),
    );
    gh.lazySingleton<GetNotificationsUseCase>(
      () => GetNotificationsUseCase(get<NotificationsRepository>()),
    );
    gh.lazySingleton<GetUnreadCountUseCase>(
      () => GetUnreadCountUseCase(get<NotificationsRepository>()),
    );
    gh.lazySingleton<MarkNotificationReadUseCase>(
      () => MarkNotificationReadUseCase(get<NotificationsRepository>()),
    );
    gh.lazySingleton<MarkAllNotificationsReadUseCase>(
      () => MarkAllNotificationsReadUseCase(get<NotificationsRepository>()),
    );

    // ─── Activity Log ──────────────────────────────────────────────────────────
    gh.lazySingleton<ActivityLogRemoteDataSource>(
      () => ActivityLogRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<ActivityLogRepository>(
      () => ActivityLogRepositoryImpl(get<ActivityLogRemoteDataSource>()),
    );
    gh.lazySingleton<GetActivityLogUseCase>(
      () => GetActivityLogUseCase(get<ActivityLogRepository>()),
    );
    gh.lazySingleton<GetActivityLogUsersUseCase>(
      () => GetActivityLogUsersUseCase(get<ActivityLogRepository>()),
    );

    // ─── Users ─────────────────────────────────────────────────────────────────
    gh.lazySingleton<UsersRemoteDataSource>(
      () => UsersRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<UsersRepository>(
      () => UsersRepositoryImpl(get<UsersRemoteDataSource>()),
    );
    gh.lazySingleton<GetUsersUseCase>(
      () => GetUsersUseCase(get<UsersRepository>()),
    );
    gh.lazySingleton<GetUserByIdUseCase>(
      () => GetUserByIdUseCase(get<UsersRepository>()),
    );
    gh.lazySingleton<CreateUserUseCase>(
      () => CreateUserUseCase(get<UsersRepository>()),
    );
    gh.lazySingleton<UpdateUserUseCase>(
      () => UpdateUserUseCase(get<UsersRepository>()),
    );
    gh.lazySingleton<DeleteUserUseCase>(
      () => DeleteUserUseCase(get<UsersRepository>()),
    );

    // ─── Roles ─────────────────────────────────────────────────────────────────
    gh.lazySingleton<RolesRemoteDataSource>(
      () => RolesRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<RolesRepository>(
      () => RolesRepositoryImpl(get<RolesRemoteDataSource>()),
    );
    gh.lazySingleton<GetRolesUseCase>(
      () => GetRolesUseCase(get<RolesRepository>()),
    );
    gh.lazySingleton<CreateRoleUseCase>(
      () => CreateRoleUseCase(get<RolesRepository>()),
    );
    gh.lazySingleton<UpdateRoleUseCase>(
      () => UpdateRoleUseCase(get<RolesRepository>()),
    );
    gh.lazySingleton<DeleteRoleUseCase>(
      () => DeleteRoleUseCase(get<RolesRepository>()),
    );
    gh.lazySingleton<CloneRoleUseCase>(
      () => CloneRoleUseCase(get<RolesRepository>()),
    );
    gh.lazySingleton<GetPermissionsUseCase>(
      () => GetPermissionsUseCase(get<RolesRepository>()),
    );

    // ─── Reservations ─────────────────────────────────────────────────────────
    gh.lazySingleton<ReservationsRemoteDataSource>(
      () => ReservationsRemoteDataSourceImpl(get<ApiClient>()),
    );
    gh.lazySingleton<ReservationsRepository>(
      () => ReservationsRepositoryImpl(get<ReservationsRemoteDataSource>()),
    );
    gh.lazySingleton<GetReservationsUseCase>(
      () => GetReservationsUseCase(get<ReservationsRepository>()),
    );
    gh.lazySingleton<GetReservationByIdUseCase>(
      () => GetReservationByIdUseCase(get<ReservationsRepository>()),
    );
    gh.lazySingleton<CreateReservationUseCase>(
      () => CreateReservationUseCase(get<ReservationsRepository>()),
    );
    gh.lazySingleton<UpdateReservationStatusUseCase>(
      () => UpdateReservationStatusUseCase(get<ReservationsRepository>()),
    );
    gh.lazySingleton<DeleteReservationUseCase>(
      () => DeleteReservationUseCase(get<ReservationsRepository>()),
    );
    gh.lazySingleton<GetReservationSettingsUseCase>(
      () => GetReservationSettingsUseCase(get<ReservationsRepository>()),
    );
    gh.lazySingleton<SaveReservationSettingsUseCase>(
      () => SaveReservationSettingsUseCase(get<ReservationsRepository>()),
    );
    gh.lazySingleton<CreateReservationExceptionUseCase>(
      () => CreateReservationExceptionUseCase(get<ReservationsRepository>()),
    );
    gh.lazySingleton<DeleteReservationExceptionUseCase>(
      () => DeleteReservationExceptionUseCase(get<ReservationsRepository>()),
    );

    return this;
  }
}
