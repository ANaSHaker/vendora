import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, String> _strings;

  const AppLocalizations(this.locale, this._strings);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('ar'), <String, String>{});
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isAr => locale.languageCode == 'ar';

  String t(String key) => _strings[key] ?? key;

  // ─── App ────────────────────────────────────────────────────────────────────
  String get appName => t('appName');

  // ─── Common ─────────────────────────────────────────────────────────────────
  String get save           => t('save');
  String get cancel         => t('cancel');
  String get actions        => t('actions');
  String get apply          => t('apply');
  String get applyChanges   => t('applyChanges');
  String get reset          => t('reset');
  String get retry          => t('retry');
  String get close          => t('close');
  String get back           => t('back');
  String get next           => t('next');
  String get confirm        => t('confirm');
  String get delete         => t('delete');
  String get edit           => t('edit');
  String get add            => t('add');
  String get search         => t('search');
  String get filter         => t('filter');
  String get loading        => t('loading');
  String get noData         => t('noData');
  String get error          => t('error');
  String get success        => t('success');
  String get optional       => t('optional');
  String get required       => t('required');
  String get all            => t('all');
  String get none           => t('none');
  String get yes            => t('yes');
  String get no             => t('no');
  String get change         => t('change');

  // ─── Auth ────────────────────────────────────────────────────────────────────
  String get signIn             => t('signIn');
  String get signOut            => t('signOut');
  String get welcomeBack        => t('welcomeBack');
  String get signInSubtitle     => t('signInSubtitle');
  String get emailAddress       => t('emailAddress');
  String get password           => t('password');
  String get forgotPassword     => t('forgotPassword');
  String get invalidCredentials => t('invalidCredentials');

  // ─── Navigation ──────────────────────────────────────────────────────────────
  String get dashboard          => t('dashboard');
  String get pos                => t('pos');
  String get orders             => t('orders');
  String get products           => t('products');
  String get categories         => t('categories');
  String get customers          => t('customers');
  String get inventory          => t('inventory');
  String get inventoryMovements => t('inventoryMovements');
  String get costLayers         => t('costLayers');
  String get warehouses         => t('warehouses');
  String get transfers          => t('transfers');
  String get stockCounts        => t('stockCounts');
  String get adjustments        => t('adjustments');
  String get suppliers          => t('suppliers');
  String get supplierLedger          => t('supplierLedger');
  String get supplierLedgerSubtitle  => t('supplierLedgerSubtitle');
  String get supplierLedgerDateFrom  => t('supplierLedgerDateFrom');
  String get supplierLedgerDateTo    => t('supplierLedgerDateTo');
  String get supplierLedgerExport    => t('supplierLedgerExport');
  String get supplierLedgerColReference => t('supplierLedgerColReference');
  String get supplierLedgerNoEntries => t('supplierLedgerNoEntries');
  String get supplierPaymentTitle   => t('supplierPaymentTitle');
  String get supplierPaymentAmount  => t('supplierPaymentAmount');
  String get supplierPaymentMethod  => t('supplierPaymentMethod');
  String get supplierPaymentReference => t('supplierPaymentReference');
  String get supplierPaymentNotes   => t('supplierPaymentNotes');
  String get supplierPaymentDate    => t('supplierPaymentDate');
  String get supplierPaymentSubmit  => t('supplierPaymentSubmit');
  String get supplierPaymentMethodCash    => t('supplierPaymentMethodCash');
  String get supplierPaymentMethodBank    => t('supplierPaymentMethodBank');
  String get supplierPaymentMethodCard    => t('supplierPaymentMethodCard');
  String get supplierPaymentMethodCheque  => t('supplierPaymentMethodCheque');
  String get supplierPaymentMethodOther   => t('supplierPaymentMethodOther');
  String get supplierPaymentSuccess => t('supplierPaymentSuccess');
  String get supplierPaymentFailed  => t('supplierPaymentFailed');
  String get supplierPaymentAmountRequired => t('supplierPaymentAmountRequired');
  String get supplierPaymentAmountInvalid  => t('supplierPaymentAmountInvalid');
  String get supplierRecordPayment  => t('supplierRecordPayment');
  // Aging
  String get supplierAgingTitle       => t('supplierAgingTitle');
  String get supplierAgingSubtitle    => t('supplierAgingSubtitle');
  String get supplierAgingExport      => t('supplierAgingExport');
  String get supplierAgingAsOf        => t('supplierAgingAsOf');
  String get supplierAgingNote        => t('supplierAgingNote');
  String get supplierAgingColSupplier => t('supplierAgingColSupplier');
  String get supplierAgingColCurrent  => t('supplierAgingColCurrent');
  String get supplierAgingCol1_30     => t('supplierAgingCol1_30');
  String get supplierAgingCol31_60    => t('supplierAgingCol31_60');
  String get supplierAgingCol61_90    => t('supplierAgingCol61_90');
  String get supplierAgingColOver90   => t('supplierAgingColOver90');
  String get supplierAgingColTotal    => t('supplierAgingColTotal');
  String get supplierAgingNoData      => t('supplierAgingNoData');

  // Homepage Builder
  String get homepageBuilder          => t('homepageBuilder');
  String get hbTitle                  => t('hbTitle');
  String get hbAddSection             => t('hbAddSection');
  String get hbLayoutTitle            => t('hbLayoutTitle');
  String get hbSectionsCount          => t('hbSectionsCount');
  String get hbSectionsCountOne       => t('hbSectionsCountOne');
  String get hbSaveLayout             => t('hbSaveLayout');
  String get hbSaved                  => t('hbSaved');
  String get hbSettings               => t('hbSettings');
  String get hbSelectSectionHint      => t('hbSelectSectionHint');
  String get hbEmptyTitle             => t('hbEmptyTitle');
  String get hbEmptyDesc              => t('hbEmptyDesc');
  String get hbMoveUp                 => t('hbMoveUp');
  String get hbMoveDown               => t('hbMoveDown');
  String get hbDeleteSection          => t('hbDeleteSection');
  String get hbFieldTitle             => t('hbFieldTitle');
  String get hbFieldSubtitle          => t('hbFieldSubtitle');
  String get hbFieldButtonText        => t('hbFieldButtonText');
  String get hbFieldProductsToShow    => t('hbFieldProductsToShow');
  String get hbFieldDescription       => t('hbFieldDescription');
  String get hbFieldPrimaryButton     => t('hbFieldPrimaryButton');
  String get hbFieldSecondaryButton   => t('hbFieldSecondaryButton');
  String get hbSectionHeroLabel       => t('hbSectionHeroLabel');
  String get hbSectionHeroDesc        => t('hbSectionHeroDesc');
  String get hbSectionFeaturedLabel   => t('hbSectionFeaturedLabel');
  String get hbSectionFeaturedDesc    => t('hbSectionFeaturedDesc');
  String get hbSectionCategoriesLabel => t('hbSectionCategoriesLabel');
  String get hbSectionCategoriesDesc  => t('hbSectionCategoriesDesc');
  String get hbSectionCtaLabel        => t('hbSectionCtaLabel');
  String get hbSectionCtaDesc         => t('hbSectionCtaDesc');
  String get hbDefaultHeroButton      => t('hbDefaultHeroButton');
  String get hbDefaultCatA            => t('hbDefaultCatA');
  String get hbDefaultCatB            => t('hbDefaultCatB');
  String get hbDefaultCatC            => t('hbDefaultCatC');

  // ── Storefront (sf) ───────────────────────────────────────────────────────
  String get sfHome               => t('sfHome');
  String get sfProducts           => t('sfProducts');
  String get sfCategories         => t('sfCategories');
  String get sfAbout              => t('sfAbout');
  String get sfContact            => t('sfContact');
  String get sfReservations       => t('sfReservations');
  String get sfCart               => t('sfCart');
  String get sfCheckout           => t('sfCheckout');
  String get sfOrderSuccess       => t('sfOrderSuccess');
  String get sfOrderTracking      => t('sfOrderTracking');
  String get sfOrderLookup        => t('sfOrderLookup');
  String get sfAddToCart          => t('sfAddToCart');
  String get sfViewDetails        => t('sfViewDetails');
  String get sfShopNow            => t('sfShopNow');
  String get sfSearch             => t('sfSearch');
  String get sfFilterByCategory   => t('sfFilterByCategory');
  String get sfAllCategories      => t('sfAllCategories');
  String get sfNoProducts         => t('sfNoProducts');
  String get sfCartEmpty          => t('sfCartEmpty');
  String get sfCartEmptyHint      => t('sfCartEmptyHint');
  String get sfContinueShopping   => t('sfContinueShopping');
  String get sfOrderSummary       => t('sfOrderSummary');
  String get sfSubtotal           => t('sfSubtotal');
  String get sfDeliveryFee        => t('sfDeliveryFee');
  String get sfTotal              => t('sfTotal');
  String get sfPlaceOrder         => t('sfPlaceOrder');
  String get sfCustomerName       => t('sfCustomerName');
  String get sfCustomerPhone      => t('sfCustomerPhone');
  String get sfCustomerEmail      => t('sfCustomerEmail');
  String get sfDeliveryAddress    => t('sfDeliveryAddress');
  String get sfOrderNotes         => t('sfOrderNotes');
  String get sfOrderRef           => t('sfOrderRef');
  String get sfOrderStatus        => t('sfOrderStatus');
  String get sfOrderDate          => t('sfOrderDate');
  String get sfOrderItems         => t('sfOrderItems');
  String get sfTrackOrder         => t('sfTrackOrder');
  String get sfTrackHint          => t('sfTrackHint');
  String get sfLookupHint         => t('sfLookupHint');
  String get sfPhoneOrEmail       => t('sfPhoneOrEmail');
  String get sfLookupSearch       => t('sfLookupSearch');
  String get sfAboutTitle         => t('sfAboutTitle');
  String get sfContactTitle       => t('sfContactTitle');
  String get sfReserveTable       => t('sfReserveTable');
  String get sfPartySize          => t('sfPartySize');
  String get sfDate               => t('sfDate');
  String get sfTime               => t('sfTime');
  String get sfReservationNotes   => t('sfReservationNotes');
  String get sfConfirmReservation => t('sfConfirmReservation');
  String get sfReservationSuccess => t('sfReservationSuccess');
  String get sfFeaturedProducts   => t('sfFeaturedProducts');
  String get sfNewArrivals        => t('sfNewArrivals');
  String get sfSpecialOffers      => t('sfSpecialOffers');
  String get sfStoreSettings         => t('sfStoreSettings');
  String get sfStoreActive           => t('sfStoreActive');
  String get sfStoreActiveOn         => t('sfStoreActiveOn');
  String get sfStoreActiveOff        => t('sfStoreActiveOff');
  String get sfStoreUnavailable      => t('sfStoreUnavailable');
  String get sfStoreUnavailableHint  => t('sfStoreUnavailableHint');
  String get sfRetry                 => t('sfRetry');
  String get sfTheme                 => t('sfTheme');
  String get sfDarkMode              => t('sfDarkMode');
  String get sfDarkModeOn            => t('sfDarkModeOn');
  String get sfDarkModeOff           => t('sfDarkModeOff');
  String get sfPrimaryColor          => t('sfPrimaryColor');
  String get sfSectionVisibility     => t('sfSectionVisibility');
  String get sfStoreUrl              => t('sfStoreUrl');
  String get sfPreviewStore          => t('sfPreviewStore');
  String get sfReservationsSection   => t('sfReservationsSection');
  String get sfEnableReservations    => t('sfEnableReservations');
  String get sfReservationsOn        => t('sfReservationsOn');
  String get sfReservationsOff       => t('sfReservationsOff');

  String get reports            => t('reports');
  String get financialReports   => t('financialReports');
  String get inventoryReports   => t('inventoryReports');
  String get branches           => t('branches');
  String get users              => t('users');
  String get storeSettings      => t('storeSettings');
  String get devices            => t('devices');
  String get themes             => t('themes');
  String get notifications           => t('notifications');
  String get activityLog             => t('activityLog');
  String get activityLogSubtitle     => t('activityLogSubtitle');
  String get allEmployees            => t('allEmployees');
  String get allActions              => t('allActions');

  // ─── POS ─────────────────────────────────────────────────────────────────────
  String get pointOfSale              => t('pointOfSale');
  String get escToExit                => t('escToExit');
  String get selectBranch             => t('selectBranch');
  String get selectBranchSubtitle     => t('selectBranchSubtitle');
  String get selectWarehouse          => t('selectWarehouse');
  String get selectWarehouseSubtitle  => t('selectWarehouseSubtitle');
  String get noWarehouses             => t('noWarehouses');
  String get noWarehousesSubtitle     => t('noWarehousesSubtitle');
  String get continueWithoutWarehouse => t('continueWithoutWarehouse');
  String get failedToLoadBranches     => t('failedToLoadBranches');
  String get checkConnectionRetry     => t('checkConnectionRetry');
  String get cart                     => t('cart');
  String get emptyCart                => t('emptyCart');
  String get addItems                 => t('addItems');
  String get addCustomer              => t('addCustomer');
  String get searchCustomer           => t('searchCustomer');
  String get subtotal                 => t('subtotal');
  String get discount                 => t('discount');
  String get tax                      => t('tax');
  String get total                    => t('total');
  String get addDiscount              => t('addDiscount');
  String get removeDiscount           => t('removeDiscount');
  String get charge                   => t('charge');
  String get payment                  => t('payment');
  String get paymentMethod            => t('paymentMethod');
  String get cash                     => t('cash');
  String get card                     => t('card');
  String get bankTransfer             => t('bankTransfer');
  String get amountTendered           => t('amountTendered');
  String get cashChange               => t('cashChange');
  String get orderDiscount            => t('orderDiscount');
  String get percentage               => t('percentage');
  String get fixedAmount              => t('fixedAmount');
  String get searchProducts           => t('searchProducts');
  String get noProductsFound          => t('noProductsFound');
  String get noProductsInCategory     => t('noProductsInCategory');
  String get orderSuccess             => t('orderSuccess');
  String get orderFailed              => t('orderFailed');
  String get switchBranch             => t('switchBranch');
  String get switchWarehouse          => t('switchWarehouse');
  String get undo                     => t('undo');
  String get clearCart                => t('clearCart');
  String get noCustomersFound         => t('noCustomersFound');
  String get autoPrint                => t('autoPrint');
  String get autoPrintHint            => t('autoPrintHint');
  String get outOfStock               => t('outOfStock');
  String get printReceipt             => t('printReceipt');
  String get orderSettings            => t('orderSettings');
  String get printInvoice             => t('printInvoice');
  String get defaultOrderStatus       => t('defaultOrderStatus');
  String get defaultOrderStatusHint   => t('defaultOrderStatusHint');
  String get confirmRefund            => t('confirmRefund');
  String get confirmRefundMessage     => t('confirmRefundMessage');
  String get refundSuccess            => t('refundSuccess');
  String get invoiceError             => t('invoiceError');
  String get orderNote                => t('orderNote');
  String get orderNoteHint            => t('orderNoteHint');
  String get orderComplete            => t('orderComplete');
  String get newOrder                 => t('newOrder');
  String get createCustomer           => t('createCustomer');
  String get customerNameLabel        => t('customerNameLabel');
  String get customerPhoneLabel       => t('customerPhoneLabel');
  String get productNotFound          => t('productNotFound');
  String get barcodeProductAdded      => t('barcodeProductAdded');
  String get online                   => t('online');
  String get offline                  => t('offline');
  String get kbShortcutsHint          => t('kbShortcutsHint');
  String get thankYou                 => t('thankYou');

  // ─── Order Status ─────────────────────────────────────────────────────────────
  String get statusPending    => t('statusPending');
  String get statusProcessing => t('statusProcessing');
  String get statusCompleted  => t('statusCompleted');

  String get statusPaid               => t('statusPaid');
  String get statusRefunded           => t('statusRefunded');
  String get statusPartiallyRefunded  => t('statusPartiallyRefunded');
  String get statusVoid               => t('statusVoid');
  String get statusCancelled          => t('statusCancelled');
  String get paidAt                   => t('paidAt');
  String get shippingAddress          => t('shippingAddress');
  String get refundHistory            => t('refundHistory');
  String get splitPayments            => t('splitPayments');
  String get allFulfillments          => t('allFulfillments');
  String get voucher                  => t('voucher');
  String get guestCheckout            => t('guestCheckout');

  String statusLabel(String status) => switch (status) {
    'pending'            => statusPending,
    'processing'         => statusProcessing,
    'completed'          => statusCompleted,
    'paid'               => statusPaid,
    'refunded'           => statusRefunded,
    'partially_refunded' => statusPartiallyRefunded,
    'void'               => statusVoid,
    'cancelled'          => statusCancelled,
    _                    => status,
  };

  // ─── Theme Picker ─────────────────────────────────────────────────────────────
  String get appearance          => t('appearance');
  String get livePreview         => t('livePreview');
  String get livePreviewHint     => t('livePreviewHint');
  String get mode                => t('mode');
  String get light               => t('light');
  String get dark                => t('dark');
  String get posDefaultStatus    => t('posDefaultStatus');
  String get posDefaultStatusHint=> t('posDefaultStatusHint');
  String get primaryColor        => t('primaryColor');

  // ─── Color Names ─────────────────────────────────────────────────────────────
  String get colorNavy   => t('colorNavy');
  String get colorBlue   => t('colorBlue');
  String get colorGreen  => t('colorGreen');
  String get colorOrange => t('colorOrange');
  String get colorPurple => t('colorPurple');
  String get colorRed    => t('colorRed');
  String get colorBlack  => t('colorBlack');
  String get colorWhite  => t('colorWhite');

  // ─── Language ─────────────────────────────────────────────────────────────────
  String get language => t('language');
  String get arabic   => t('arabic');
  String get english  => t('english');
  String get french   => t('french');
  String get italian  => t('italian');
  String get german   => t('german');

  // ─── Dashboard ───────────────────────────────────────────────────────────────
  String get totalRevenue              => t('totalRevenue');
  String get totalOrders               => t('totalOrders');
  String get totalCustomers            => t('totalCustomers');
  String get totalSales                => t('totalSales');
  String get netRevenue                => t('netRevenue');
  String get totalRefunds              => t('totalRefunds');
  String get avgOrderValue             => t('avgOrderValue');
  String get salesOverview             => t('salesOverview');
  String get salesPerDay               => t('salesPerDay');
  String get recentOrders              => t('recentOrders');
  String get noRecentOrders            => t('noRecentOrders');
  String get topProducts               => t('topProducts');
  String get topCustomers              => t('topCustomers');
  String get noProductsYet             => t('noProductsYet');
  String get salesDataWillAppearHere   => t('salesDataWillAppearHere');
  String get noCustomersYet            => t('noCustomersYet');
  String get customerDataWillAppearHere=> t('customerDataWillAppearHere');
  String get today                     => t('today');
  String get thisWeek                  => t('thisWeek');
  String get thisMonth                 => t('thisMonth');
  String get customRange               => t('customRange');
  String get failedToLoadDashboard     => t('failedToLoadDashboard');
  String get failedToLoad              => t('failedToLoad');
  String get receipts                  => t('receipts');
  String get stockByWarehouse          => t('stockByWarehouse');
  String get movements                 => t('movements');

  // ─── Nav sections ────────────────────────────────────────────────────────────
  String get navSales      => t('navSales');
  String get navCatalog    => t('navCatalog');
  String get navCustomers  => t('navCustomers');
  String get navPurchasing => t('navPurchasing');
  String get navInventory  => t('navInventory');
  String get navOperations => t('navOperations');
  String get overview      => t('overview');
  String get tenants       => t('tenants');
  String get financial     => t('financial');
  String get insights      => t('insights');

  // ─── POS extras ──────────────────────────────────────────────────────────────
  String get totalDue              => t('totalDue');
  String get enterValidAmount      => t('enterValidAmount');
  String get amountLessThanTotal   => t('amountLessThanTotal');
  String get percentLabel          => t('percentLabel');
  String get amountLabel           => t('amountLabel');
  String get percentCannotExceed100=> t('percentCannotExceed100');
  String get remove                => t('remove');
  String get taxWithRate           => t('taxWithRate');
  String get discountFlat          => t('discountFlat');
  String get searchByNameOrSku     => t('searchByNameOrSku');
  String get noProductsAvailable   => t('noProductsAvailable');

  // ─── Orders ──────────────────────────────────────────────────────────────────
  String get reference          => t('reference');
  String get orderStatus        => t('orderStatus');
  String get allStatuses        => t('allStatuses');
  String get orderItems         => t('orderItems');
  String get quantity           => t('quantity');
  String get unitPrice          => t('unitPrice');
  String get noOrdersFound      => t('noOrdersFound');
  String get noOrdersYet        => t('noOrdersYet');
  String get ordersWillAppearHere => t('ordersWillAppearHere');
  String get searchOrders       => t('searchOrders');
  String get filterByStatus     => t('filterByStatus');
  String get orderDetail        => t('orderDetail');
  String get paymentInfo        => t('paymentInfo');
  String get branch             => t('branch');
  String get cashier            => t('cashier');
  String get note               => t('note');
  String get showing            => t('showing');
  String get results            => t('results');
  String get ofTotal            => t('ofTotal');
  String get page               => t('page');
  String get previous           => t('previous');
  String get nextPage           => t('nextPage');
  String get itemsCount         => t('itemsCount');

  String showingPagination(int start, int end, int total) =>
      '${t('showing')} $start–$end ${t('ofTotal')} $total';
  String get orderRefund        => t('orderRefund');
  String get updateStatus       => t('updateStatus');
  String get customer           => t('customer');
  String get noCustomer         => t('noCustomer');
  String get dateCreated        => t('dateCreated');
  String get wallet             => t('wallet');
  String get other              => t('other');
  String get refundItems        => t('refundItems');
  String get estimatedRefund    => t('estimatedRefund');
  String get refundReason       => t('refundReason');
  String get refundReasonHint   => t('refundReasonHint');
  String get reasonRequired     => t('reasonRequired');
  String get noItemsSelected    => t('noItemsSelected');
  String get selectPaymentMethod => t('selectPaymentMethod');

  String get changeOrderStatus    => t('changeOrderStatus');

  // ─── Channel & Fulfillment ───────────────────────────────────────────────────
  String get channel              => t('channel');
  String get channelPos           => t('channelPos');
  String get channelOnline        => t('channelOnline');
  String get allChannels          => t('allChannels');
  String get fulfillmentStatus    => t('fulfillmentStatus');
  String get fulfillPreparing     => t('fulfillPreparing');
  String get fulfillReady         => t('fulfillReady');
  String get fulfillCompleted     => t('fulfillCompleted');
  String get fulfillPreparingDesc => t('fulfillPreparingDesc');
  String get fulfillReadyDesc     => t('fulfillReadyDesc');
  String get fulfillCompletedDesc => t('fulfillCompletedDesc');
  String get fulfillCancelled     => t('fulfillCancelled');
  String get changeFulfillment    => t('changeFulfillment');
  String get noFulfillmentStatus  => t('noFulfillmentStatus');

  // ─── Tracking ────────────────────────────────────────────────────────────────
  String get trackingLink         => t('trackingLink');
  String get copyLink             => t('copyLink');
  String get linkCopied           => t('linkCopied');
  String get noTrackingLink       => t('noTrackingLink');
  String get orderTracking        => t('orderTracking');
  String get trackYourOrder       => t('trackYourOrder');
  String get orderNotFound        => t('orderNotFound');
  String get orderNotFoundDesc    => t('orderNotFoundDesc');
  String get trackingTokenLabel   => t('trackingTokenLabel');
  String get orderStatus2         => t('orderStatus2');
  String get shareWithCustomer    => t('shareWithCustomer');
  String get trackingSubtitle     => t('trackingSubtitle');
  String get enterOrderHint       => t('enterOrderHint');
  String get trackOrderBtn        => t('trackOrderBtn');
  String get orderProgress        => t('orderProgress');
  String get itemsOrdered         => t('itemsOrdered');
  String get orderSummary         => t('orderSummary');
  String get poweredByVendora     => t('poweredByVendora');
  String get staffControls        => t('staffControls');
  String get manageOrder          => t('manageOrder');
  String get trackingUnavailable      => t('trackingUnavailable');
  String get trackingUnavailableDesc  => t('trackingUnavailableDesc');
  String get orderedOn            => t('orderedOn');

  // ─── Reports ─────────────────────────────────────────────────────────────────
  String get salesReport         => t('salesReport');
  String get financialReport     => t('financialReport');
  String get inventoryReport     => t('inventoryReport');
  String get dateRange           => t('dateRange');
  String get grossRevenue        => t('grossRevenue');
  String get totalCost           => t('totalCost');
  String get grossProfit         => t('grossProfit');
  String get profitMargin        => t('profitMargin');
  String get topSellingProducts  => t('topSellingProducts');
  String get inventoryValue      => t('inventoryValue');
  String get stockLevel          => t('stockLevel');
  String get totalValue          => t('totalValue');
  String get pnl                 => t('pnl');
  String get revenue             => t('revenue');
  String get expenses            => t('expenses');
  String get profit              => t('profit');
  String get fifoProfit          => t('fifoProfit');
  String get costOfGoods         => t('costOfGoods');
  String get generateReport      => t('generateReport');
  String get exportReport        => t('exportReport');
  String get noDataForPeriod     => t('noDataForPeriod');
  String get salesByDay          => t('salesByDay');
  String get productName         => t('productName');
  String get unitsSold           => t('unitsSold');
  String get sku                 => t('sku');
  String get onHand              => t('onHand');
  String get avgCost             => t('avgCost');
  String get warehouseName       => t('warehouseName');
  String get financialSummary    => t('financialSummary');
  String get pnlReport           => t('pnlReport');
  String get fifoReport          => t('fifoReport');
  String get selectPeriod        => t('selectPeriod');
  String get orderId             => t('orderId');
  String get topProfitable       => t('topProfitable');
  String get worstMargin         => t('worstMargin');
  String get salePrice           => t('salePrice');
  String get colMargin           => t('colMargin');
  String get colFifoCost         => t('colFifoCost');
  String get colLineRevenue      => t('colLineRevenue');
  String get revenueBasisLabel   => t('revenueBasisLabel');
  String get basisLineItems      => t('basisLineItems');
  String get basisOrderTotal     => t('basisOrderTotal');
  String get exportPnl           => t('exportPnl');
  String get exportSales         => t('exportSales');
  String get exportInventory     => t('exportInventory');
  String get exportFifo          => t('exportFifo');
  String get topProfitableChart  => t('topProfitableChart');
  String get allBranches         => t('allBranches');
  String get allProducts         => t('allProducts');
  String get refundNote          => t('refundNote');
  String get inventoryValuationAt => t('inventoryValuationAt');
  String get printPdf            => t('printPdf');
  String get colSalePrice        => t('colSalePrice');

  // ─── Products ────────────────────────────────────────────────────────────────
  String get addProduct           => t('addProduct');
  String get editProduct          => t('editProduct');
  String get deleteProduct        => t('deleteProduct');
  String get productDeleted       => t('productDeleted');
  String get productDeleteFailed  => t('productDeleteFailed');
  String get colName              => t('colName');
  String get colSku               => t('colSku');
  String get colCategory          => t('colCategory');
  String get colShowInStore       => t('colShowInStore');
  String get colUnit              => t('colUnit');
  String get colPrice             => t('colPrice');
  String get colStock             => t('colStock');
  String get colStatus            => t('colStatus');
  String get filterAll            => t('filterAll');
  String get filterActive         => t('filterActive');
  String get filterInactive       => t('filterInactive');
  String get allCategories        => t('allCategories');
  String get exportFile           => t('exportFile');
  String get downloadTemplate     => t('downloadTemplate');
  String get uploadFile           => t('uploadFile');
  String get importing            => t('importing');
  String get duplicateSkip        => t('duplicateSkip');
  String get duplicateUpdate      => t('duplicateUpdate');
  String get importSummary        => t('importSummary');
  String get productCreated       => t('productCreated');
  String get productUpdated       => t('productUpdated');
  String get noSku                => t('noSku');
  String get active               => t('active');
  String get inactive             => t('inactive');
  String get saving               => t('saving');
  String get colActions           => t('colActions');
  String get noProductsYetAction  => t('noProductsYetAction');
  String get importCounts         => t('importCounts');
  String get createProduct        => t('createProduct');
  String get basicInfo            => t('basicInfo');
  String get visibilityTab        => t('visibilityTab');
  String get trackStock           => t('trackStock');
  String get productImage         => t('productImage');
  String get pickImage            => t('pickImage');
  String get changeImage          => t('changeImage');

  // ─── Categories ──────────────────────────────────────────────────────────────
  String get addCategory          => t('addCategory');
  String get editCategory         => t('editCategory');
  String get deleteCategory       => t('deleteCategory');
  String get confirmDelete        => t('confirmDelete');
  String get categoryDeleted      => t('categoryDeleted');
  String get noCategoriesYet      => t('noCategoriesYet');
  String get categoryName         => t('categoryName');
  String get categoryNameHint     => t('categoryNameHint');
  String get parentCategory       => t('parentCategory');
  String get noParent             => t('noParent');
  String get sortOrder            => t('sortOrder');
  String get sortOrderHint        => t('sortOrderHint');
  String get activeLabel          => t('activeLabel');
  String get activeHint           => t('activeHint');
  String get saveChanges          => t('saveChanges');
  String get createCategory       => t('createCategory');
  String get colParent              => t('colParent');
  String get colProducts            => t('colProducts');
  String get colOrder               => t('colOrder');
  String get searchCategories       => t('searchCategories');
  String get categoryDeleteFailed   => t('categoryDeleteFailed');
  String get categoryHasProducts    => t('categoryHasProducts');
  String get categoryChildrenMoved  => t('categoryChildrenMoved');
  String get categoryTotal          => t('categoryTotal');
  String get categoryMatchingCount  => t('categoryMatchingCount');
  String get categoryImportFailed   => t('categoryImportFailed');
  String get categoryImportSummary  => t('categoryImportSummary');
  String get categoryImportCounts   => t('categoryImportCounts');

  // ─── Customers ───────────────────────────────────────────────────────────────
  String get addCustomerAction     => t('addCustomerAction');
  String get editCustomer          => t('editCustomer');
  String get deleteCustomer        => t('deleteCustomer');
  String get customerCreated       => t('customerCreated');
  String get customerUpdated       => t('customerUpdated');
  String get customerDeleted       => t('customerDeleted');
  String get customerDeleteFailed  => t('customerDeleteFailed');
  String get searchCustomers       => t('searchCustomers');
  String get noCustomersYetAction  => t('noCustomersYetAction');
  String get colCustomer           => t('colCustomer');
  String get colPhone              => t('colPhone');
  String get colOrders             => t('colOrders');
  String get colTotalSpent         => t('colTotalSpent');
  String get colLoyaltyPoints      => t('colLoyaltyPoints');
  String get fullName              => t('fullName');
  String get phone                 => t('phone');
  String get email                 => t('email');
  String get notes                 => t('notes');
  String get loyaltyPoints         => t('loyaltyPoints');
  String get totalSpent            => t('totalSpent');
  String get lastOrder             => t('lastOrder');
  String get recentOrdersLabel     => t('recentOrdersLabel');
  String get contactInfo           => t('contactInfo');
  String get customerSaveFailed    => t('customerSaveFailed');

  // ─── Roles & Permissions ─────────────────────────────────────────────────────
  String get rolesAndPermissions  => t('rolesAndPermissions');
  String get rolesSubtitle        => t('rolesSubtitle');
  String get newRole              => t('newRole');
  String get searchRoles          => t('searchRoles');
  String get roleEmployees        => t('roleEmployees');
  String get rolePermissions      => t('rolePermissions');
  String get roleSystem           => t('roleSystem');
  String get roleOwner            => t('roleOwner');
  String get editRole             => t('editRole');
  String get editRoleTitle        => t('editRoleTitle');
  String get editRoleSubtitle     => t('editRoleSubtitle');
  String get selectAll            => t('selectAll');
  String get deselectAll          => t('deselectAll');
  String get searchPermissions    => t('searchPermissions');
  String get deleteRoleTitle      => t('deleteRoleTitle');
  String get deleteRoleMsg        => t('deleteRoleMsg');
  String get roleDeleted          => t('roleDeleted');
  String get roleCloningSuccess   => t('roleCloningSuccess');
  String get roleName             => t('roleName');
  String get roleDescription      => t('roleDescription');
  String get roleNameRequired     => t('roleNameRequired');
  String get createRole           => t('createRole');
  String get roleCreated          => t('roleCreated');
  String get roleUpdated          => t('roleUpdated');
  String get permissionsCount     => t('permissionsCount');
  String get allPermissions       => t('allPermissions');
  String get noRolesFound         => t('noRolesFound');
  String get noRolesFoundSubtitle => t('noRolesFoundSubtitle');
  String get selectAllModule      => t('selectAllModule');
  String get cloneRole            => t('cloneRole');
  String get deleteRoleAction     => t('deleteRole');

  // ─── Reservations ────────────────────────────────────────────────────────────
  String get reservations               => t('reservations');
  String get reservationSettings        => t('reservationSettings');
  String get newReservation             => t('newReservation');
  String get reservationDetails         => t('reservationDetails');
  String get reservationSubtitle        => t('reservationSubtitle');
  String get reservationSettingsSubtitle => t('reservationSettingsSubtitle');
  String get reservationDate            => t('reservationDate');
  String get reservationTime            => t('reservationTime');
  String get reservationPartySize       => t('reservationPartySize');
  String get reservationTable           => t('reservationTable');
  String get reservationNotes           => t('reservationNotes');
  String get statusNoShow               => t('statusNoShow');
  String get statusOnHold               => t('statusOnHold');
  String get confirmedToday             => t('confirmedToday');
  String get pendingToday               => t('pendingToday');
  String get upcomingReservations       => t('upcomingReservations');
  String get totalReservations          => t('totalReservations');
  String get enableReservations         => t('enableReservations');
  String get enableReservationsDesc     => t('enableReservationsDesc');
  String get autoConfirmRes             => t('autoConfirmRes');
  String get autoConfirmResDesc         => t('autoConfirmResDesc');
  String get allowCancellationRes       => t('allowCancellationRes');
  String get allowCancellationResDesc   => t('allowCancellationResDesc');
  String get requirePhoneRes            => t('requirePhoneRes');
  String get requirePhoneResDesc        => t('requirePhoneResDesc');
  String get requireEmailRes            => t('requireEmailRes');
  String get requireEmailResDesc        => t('requireEmailResDesc');
  String get tabGeneral                 => t('tabGeneral');
  String get tabAvailability            => t('tabAvailability');
  String get tabPeriods                 => t('tabPeriods');
  String get tabAppearance              => t('tabAppearance');
  String get tabAdvanced                => t('tabAdvanced');
  String get searchReservations         => t('searchReservations');
  String get noReservationsFound        => t('noReservationsFound');
  String get navReservations            => t('navReservations');
  String get comingSoon                 => t('comingSoon');
  String get confirmReservation         => t('confirmReservation');
  String get completeReservation        => t('completeReservation');
  String get cancelReservation          => t('cancelReservation');
  String get markNoShow                 => t('markNoShow');

  // Periods tab
  String get slotDuration               => t('slotDuration');
  String get slotDuration15             => t('slotDuration15');
  String get slotDuration30             => t('slotDuration30');
  String get slotDuration60             => t('slotDuration60');
  String get bufferTime                 => t('bufferTime');
  String get bufferTimeHint             => t('bufferTimeHint');
  String get minAdvanceHours            => t('minAdvanceHours');
  String get minAdvanceHoursHint        => t('minAdvanceHoursHint');
  String get maxAdvanceDays             => t('maxAdvanceDays');
  String get maxAdvanceDaysHint         => t('maxAdvanceDaysHint');

  // Availability tab
  String get availabilitySchedule       => t('availabilitySchedule');
  String get availabilityHint           => t('availabilityHint');
  String get openTime                   => t('openTime');
  String get closeTime                  => t('closeTime');
  String get maxGuestsPerSlot           => t('maxGuestsPerSlot');
  String get dayOpen                    => t('dayOpen');
  String get dayClosed                  => t('dayClosed');
  String get daySunday                  => t('daySunday');
  String get dayMonday                  => t('dayMonday');
  String get dayTuesday                 => t('dayTuesday');
  String get dayWednesday               => t('dayWednesday');
  String get dayThursday                => t('dayThursday');
  String get dayFriday                  => t('dayFriday');
  String get daySaturday                => t('daySaturday');

  // Reservation detail panel
  String get guests                     => t('guests');
  String get source                     => t('source');
  String get timeline                   => t('timeline');
  String get internalNotes              => t('internalNotes');
  String get bookingCreated             => t('bookingCreated');
  String get addInternalNote            => t('addInternalNote');

  // Exceptions / closure days
  String get closureDaysExceptions      => t('closureDaysExceptions');
  String get closureDaysExceptionsHint  => t('closureDaysExceptionsHint');
  String get addException               => t('addException');
  String get noExceptions               => t('noExceptions');
  String get closedAllDay               => t('closedAllDay');
  String get exceptionDate              => t('exceptionDate');
  String get exceptionReason            => t('exceptionReason');
  String get customHours                => t('customHours');

  // ─── Booking Link Card ────────────────────────────────────────────────────────
  String get bookingLinkTitle     => t('bookingLinkTitle');
  String get bookingLinkSubtitle  => t('bookingLinkSubtitle');
  String get bookingLinkCopy      => t('bookingLinkCopy');
  String get bookingLinkQr        => t('bookingLinkQr');
  String get bookingLinkOpen      => t('bookingLinkOpen');
  String get bookingLinkCopied    => t('bookingLinkCopied');
  String get bookingLinkOpenFailed => t('bookingLinkOpenFailed');
  String get bookingQrTitle       => t('bookingQrTitle');

  // ─── Public Booking ───────────────────────────────────────────────────────────
  String get pbHeroTitle          => t('pbHeroTitle');
  String get pbHeroAt             => t('pbHeroAt');
  String get pbStep1Title         => t('pbStep1Title');
  String get pbStep1Subtitle      => t('pbStep1Subtitle');
  String get pbStep1Continue      => t('pbStep1Continue');
  String get pbStep2Title         => t('pbStep2Title');
  String get pbStep2Subtitle      => t('pbStep2Subtitle');
  String get pbStep2Continue      => t('pbStep2Continue');
  String get pbStep3Title         => t('pbStep3Title');
  String get pbStep3Subtitle      => t('pbStep3Subtitle');
  String get pbAvailableTimes     => t('pbAvailableTimes');
  String get pbBack               => t('pbBack');
  String get pbGuestsLabel        => t('pbGuestsLabel');
  String get pbNoSlotsAvailable   => t('pbNoSlotsAvailable');
  String get pbFullLabel          => t('pbFullLabel');
  String get pbFieldName          => t('pbFieldName');
  String get pbFieldNameHint      => t('pbFieldNameHint');
  String get pbFieldPhone         => t('pbFieldPhone');
  String get pbFieldPhoneHint     => t('pbFieldPhoneHint');
  String get pbFieldEmail         => t('pbFieldEmail');
  String get pbFieldEmailHint     => t('pbFieldEmailHint');
  String get pbFieldRequest       => t('pbFieldRequest');
  String get pbFieldRequestHint   => t('pbFieldRequestHint');
  String get pbSubmit             => t('pbSubmit');
  String get pbSubmitting         => t('pbSubmitting');
  String get pbErrorRequired      => t('pbErrorRequired');
  String get pbErrorDate          => t('pbErrorDate');
  String get pbErrorTime          => t('pbErrorTime');
  String get pbErrorInvalidEmail  => t('pbErrorInvalidEmail');
  String get pbSuccessTitle       => t('pbSuccessTitle');
  String get pbSuccessSubtitle    => t('pbSuccessSubtitle');
  String get pbSuccessRef         => t('pbSuccessRef');
  String get pbSuccessDate        => t('pbSuccessDate');
  String get pbSuccessTime        => t('pbSuccessTime');
  String get pbSuccessGuests      => t('pbSuccessGuests');
  String get pbSuccessName        => t('pbSuccessName');
  String get pbSuccessPhone       => t('pbSuccessPhone');
  String get pbSuccessNote        => t('pbSuccessNote');
  String get pbBookAnother        => t('pbBookAnother');
  String get pbUnavailableTitle   => t('pbUnavailableTitle');
  String get pbUnavailableBody    => t('pbUnavailableBody');
  String get pbNotFoundTitle      => t('pbNotFoundTitle');
  String get pbNotFoundBody       => t('pbNotFoundBody');

  // ─── Admin ──────────────────────────────────────────────────────────────────
  String get adminPanel => t('adminPanel');
  String get vendors    => t('vendors');
  String get plans      => t('plans');
  String get billing    => t('billing');
  String get analytics  => t('analytics');

  // ─── Errors ──────────────────────────────────────────────────────────────────
  String get networkError          => t('networkError');
  String get serverError           => t('serverError');
  String get unexpectedError       => t('unexpectedError');
  String get tryAgain              => t('tryAgain');
  String get noInternetConnection  => t('noInternetConnection');

  // ─── Common actions ───────────────────────────────────────────────────────────
  String get actionFailed  => t('actionFailed');
  String get actionSuccess => t('actionSuccess');
  String get selectType    => t('selectType');
  String get addItem       => t('addItem');
  String get days          => t('days');
  String get adjust        => t('adjust');

  // ─── Generic form labels ──────────────────────────────────────────────────────
  String get labelName        => t('labelName');
  String get labelCode        => t('labelCode');
  String get labelType        => t('labelType');
  String get labelDate        => t('labelDate');
  String get labelReference   => t('labelReference');
  String get labelWarehouse   => t('labelWarehouse');
  String get labelFromWarehouse => t('labelFromWarehouse');
  String get labelToWarehouse => t('labelToWarehouse');
  String get labelItems       => t('labelItems');
  String get labelQty         => t('labelQty');
  String get labelProductName => t('labelProductName');
  String get labelUnitCost    => t('labelUnitCost');
  String get nameRequired     => t('nameRequired');
  String get codeRequired     => t('codeRequired');
  String get itemsRequired    => t('itemsRequired');
  String get referencePlaceholder   => t('referencePlaceholder');
  String get productNamePlaceholder => t('productNamePlaceholder');
  String get isDefault    => t('isDefault');
  String get isDefaultHint => t('isDefaultHint');

  // ─── Table columns ────────────────────────────────────────────────────────────
  String get colProduct      => t('colProduct');
  String get colOnHand       => t('colOnHand');
  String get colAvailable    => t('colAvailable');
  String get colReserved     => t('colReserved');
  String get colAvgCost      => t('colAvgCost');
  String get colWarehouse    => t('colWarehouse');
  String get colBranch       => t('colBranch');
  String get colReference    => t('colReference');
  String get colQtyIn        => t('colQtyIn');
  String get colQtyOut       => t('colQtyOut');
  String get colOrigQty      => t('colOrigQty');
  String get colRemainingQty => t('colRemainingQty');
  String get colUnitCost     => t('colUnitCost');
  String get colCreated      => t('colCreated');

  // ─── Inventory Stock ──────────────────────────────────────────────────────────
  String get inventoryStock       => t('inventoryStock');
  String get inventoryItemsTotal  => t('inventoryItemsTotal');
  String get searchInventory      => t('searchInventory');
  String get allWarehouses        => t('allWarehouses');
  String get noInventoryItems     => t('noInventoryItems');
  String get chipTotalItems       => t('chipTotalItems');
  String get chipTotalOnHand      => t('chipTotalOnHand');
  String get chipTotalAvailable   => t('chipTotalAvailable');

  // ─── Warehouses ───────────────────────────────────────────────────────────────
  String get warehousesTitle          => t('warehousesTitle');
  String get warehousesTotal          => t('warehousesTotal');
  String get newWarehouse             => t('newWarehouse');
  String get searchWarehouses         => t('searchWarehouses');
  String get addFirstWarehouse        => t('addFirstWarehouse');
  String get deleteWarehouseTitle     => t('deleteWarehouseTitle');
  String get warehouseTypeRetail      => t('warehouseTypeRetail');
  String get warehouseTypeKitchen     => t('warehouseTypeKitchen');
  String get warehouseTypeFreezer     => t('warehouseTypeFreezer');
  String get warehouseTypeDamaged     => t('warehouseTypeDamaged');
  String get warehouseTypeReturns     => t('warehouseTypeReturns');
  String get warehouseNamePlaceholder => t('warehouseNamePlaceholder');
  String get warehouseCodePlaceholder => t('warehouseCodePlaceholder');
  String get createWarehouse          => t('createWarehouse');
  String get warehouseRequired        => t('warehouseRequired');
  String get warehouseSameError       => t('warehouseSameError');

  // ─── Inventory Movements ──────────────────────────────────────────────────────
  String get noMovements          => t('noMovements');
  String get searchMovements      => t('searchMovements');
  String get allMovementTypes     => t('allMovementTypes');
  String get summaryTotalMovements => t('summaryTotalMovements');
  String get summaryTotalQtyIn    => t('summaryTotalQtyIn');
  String get summaryTotalQtyOut   => t('summaryTotalQtyOut');
  String get movementsTotal       => t('movementsTotal');

  // ─── Cost Layers ──────────────────────────────────────────────────────────────
  String get noCostLayers    => t('noCostLayers');
  String get searchCostLayers => t('searchCostLayers');
  String get costLayersTitle => t('costLayersTitle');
  String get costLayersTotal => t('costLayersTotal');
  String get statusFull      => t('statusFull');
  String get statusPartial   => t('statusPartial');
  String get statusExhausted => t('statusExhausted');

  // ─── Stock Counts ─────────────────────────────────────────────────────────────
  String get searchStockCounts   => t('searchStockCounts');
  String get noStockCounts       => t('noStockCounts');
  String get stockCountsTotal    => t('stockCountsTotal');
  String get postCountTitle      => t('postCountTitle');
  String get deleteStockCountTitle => t('deleteStockCountTitle');
  String get stockCountDetail    => t('stockCountDetail');

  // ─── Inventory Status extras ─────────────────────────────────────────────────
  String get statusDraft     => t('statusDraft');
  String get statusApproved  => t('statusApproved');
  String get statusPosted    => t('statusPosted');
  String get statusInTransit => t('statusInTransit');
  String get statusReceived  => t('statusReceived');
  String get statusDamaged   => t('statusDamaged');

  // ─── Adjustments ─────────────────────────────────────────────────────────────
  String get noAdjustments        => t('noAdjustments');
  String get createAdjustment     => t('createAdjustment');
  String get editAdjustment       => t('editAdjustment');
  String get adjustmentUpdated    => t('adjustmentUpdated');
  String get adjustmentsTotal     => t('adjustmentsTotal');
  String get deleteAdjustmentTitle  => t('deleteAdjustmentTitle');
  String get approveAdjustmentTitle => t('approveAdjustmentTitle');
  String get postAdjustmentTitle    => t('postAdjustmentTitle');
  String get cancelAdjustmentTitle  => t('cancelAdjustmentTitle');

  // ─── Transfers ────────────────────────────────────────────────────────────────
  String get noTransfers        => t('noTransfers');
  String get createTransfer     => t('createTransfer');
  String get transfersTotal     => t('transfersTotal');
  String get transferCreated    => t('transferCreated');
  String get searchTransfers    => t('searchTransfers');
  String get deleteTransferTitle   => t('deleteTransferTitle');
  String get approveTransferTitle  => t('approveTransferTitle');
  String get shipTransferTitle     => t('shipTransferTitle');
  String get receiveTransferTitle  => t('receiveTransferTitle');

  // ─── Suppliers ────────────────────────────────────────────────────────────────
  // ─── Devices ──────────────────────────────────────────────────────────────────
  String get deviceSessionsTitle    => t('deviceSessionsTitle');
  String get deviceSessionsSubtitle => t('deviceSessionsSubtitle');
  String get logoutAllDevices       => t('logoutAllDevices');
  String get logoutThisDevice       => t('logoutThisDevice');
  String get blockDevice            => t('blockDevice');
  String get unblock                => t('unblock');
  String get thisDevice             => t('thisDevice');
  String get unknownDevice          => t('unknownDevice');
  String get noDeviceSessions       => t('noDeviceSessions');
  String get deviceLoggedOut        => t('deviceLoggedOut');
  String get allDevicesLoggedOut    => t('allDevicesLoggedOut');
  String get deviceBlocked          => t('deviceBlocked');
  String get deviceUnblocked        => t('deviceUnblocked');
  String get statusActive           => t('statusActive');
  String get statusInactive         => t('statusInactive');
  String get statusBlocked          => t('statusBlocked');
  String get colDevice              => t('colDevice');
  String get colUser                => t('colUser');
  String get colLocation            => t('colLocation');
  String get colIpAddress           => t('colIpAddress');
  String get colLastLogin           => t('colLastLogin');

  // ─── Suppliers ────────────────────────────────────────────────────────────────
  String get addWarehouse       => t('addWarehouse');
  String get editWarehouse      => t('editWarehouse');
  String get deleteWarehouse    => t('deleteWarehouse');
  String get warehouseCreated   => t('warehouseCreated');
  String get warehouseUpdated   => t('warehouseUpdated');
  String get warehouseDeleted   => t('warehouseDeleted');
  String get warehouseDeleteFailed => t('warehouseDeleteFailed');
  String get warehouseSaveFailed   => t('warehouseSaveFailed');
  String get noWarehousesYet    => t('noWarehousesYet');

  // ─── Supplier Ledger ──────────────────────────────────────────────────────────
  String get addSupplier         => t('addSupplier');
  String get editSupplier        => t('editSupplier');
  String get deleteSupplier      => t('deleteSupplier');
  String get supplierCreated     => t('supplierCreated');
  String get supplierUpdated     => t('supplierUpdated');
  String get supplierDeleted     => t('supplierDeleted');
  String get supplierDeleteFailed => t('supplierDeleteFailed');
  String get supplierSaveFailed  => t('supplierSaveFailed');
  String get searchSuppliers     => t('searchSuppliers');
  String get noSuppliersYet      => t('noSuppliersYet');
  String get supplierName        => t('supplierName');
  String get taxNo               => t('taxNo');
  String get openingBalance      => t('openingBalance');
  String get balance             => t('balance');
  String get debit               => t('debit');
  String get credit              => t('credit');
  String get currentBalance      => t('currentBalance');
  String get totalDebit          => t('totalDebit');
  String get totalCredit         => t('totalCredit');
  String get allTypes            => t('allTypes');
  String get noSupplierSelected  => t('noSupplierSelected');
  String get selectSupplier      => t('selectSupplier');

  // ── Admin Finance ────────────────────────────────────────────────────────────
  String get adminFinanceTitle          => t('adminFinanceTitle');
  String get adminFinanceSubtitle       => t('adminFinanceSubtitle');
  String get adminFinanceTabAll         => t('adminFinanceTabAll');
  String get adminFinanceTabRevenue     => t('adminFinanceTabRevenue');
  String get adminFinanceTabExpense     => t('adminFinanceTabExpense');
  String get adminFinanceTabCategories  => t('adminFinanceTabCategories');
  String get adminFinanceSummaryRevenue => t('adminFinanceSummaryRevenue');
  String get adminFinanceSummaryExpense => t('adminFinanceSummaryExpense');
  String get adminFinanceSummaryNet     => t('adminFinanceSummaryNet');
  String get adminFinanceSummaryPending => t('adminFinanceSummaryPending');
  String get adminFinanceMonthlyTrend   => t('adminFinanceMonthlyTrend');
  String get adminFinanceAddRevenue     => t('adminFinanceAddRevenue');
  String get adminFinanceAddExpense     => t('adminFinanceAddExpense');
  String get adminFinanceAddCategory    => t('adminFinanceAddCategory');
  String get adminFinanceCreateEntry    => t('adminFinanceCreateEntry');
  String get adminFinanceEditEntry      => t('adminFinanceEditEntry');
  String get adminFinanceCreateCategory => t('adminFinanceCreateCategory');
  String get adminFinanceEditCategory   => t('adminFinanceEditCategory');
  String get adminFinanceBillingLocked  => t('adminFinanceBillingLocked');
  String get adminFinanceTypeLabel      => t('adminFinanceTypeLabel');
  String get adminFinanceCategoryLabel  => t('adminFinanceCategoryLabel');
  String get adminFinanceCategoryName   => t('adminFinanceCategoryName');
  String get adminFinanceSelectCategory => t('adminFinanceSelectCategory');
  String get adminFinanceAmountLabel    => t('adminFinanceAmountLabel');
  String get adminFinanceDateLabel      => t('adminFinanceDateLabel');
  String get adminFinanceTitleLabel     => t('adminFinanceTitleLabel');
  String get adminFinanceStatusLabel    => t('adminFinanceStatusLabel');
  String get adminFinancePaymentMethodLabel => t('adminFinancePaymentMethodLabel');
  String get adminFinanceVendorLabel    => t('adminFinanceVendorLabel');
  String get adminFinanceSelectVendor   => t('adminFinanceSelectVendor');
  String get adminFinanceReferenceLabel => t('adminFinanceReferenceLabel');
  String get adminFinanceRecurringLabel => t('adminFinanceRecurringLabel');
  String get adminFinanceDescriptionLabel => t('adminFinanceDescriptionLabel');
  String get adminFinanceNotesLabel     => t('adminFinanceNotesLabel');
  String get adminFinanceColorLabel     => t('adminFinanceColorLabel');
  String get adminFinanceStatusConfirmed => t('adminFinanceStatusConfirmed');
  String get adminFinanceStatusPending  => t('adminFinanceStatusPending');
  String get adminFinanceStatusVoid     => t('adminFinanceStatusVoid');
  String get adminFinanceAllCategories  => t('adminFinanceAllCategories');
  String get adminFinanceAllStatuses    => t('adminFinanceAllStatuses');
  String get adminFinanceAllTypes       => t('adminFinanceAllTypes');
  String get adminFinanceSearchPlaceholder => t('adminFinanceSearchPlaceholder');
  String get adminFinanceLoadFailed     => t('adminFinanceLoadFailed');
  String get adminFinanceNoEntries      => t('adminFinanceNoEntries');
  String get adminFinanceNoCategories   => t('adminFinanceNoCategories');
  String get adminFinanceVoid           => t('adminFinanceVoid');
  String get adminFinanceSystemBadge    => t('adminFinanceSystemBadge');
  String get adminFinancePaymentCash    => t('adminFinancePaymentCash');
  String get adminFinancePaymentCard    => t('adminFinancePaymentCard');
  String get adminFinancePaymentBankTransfer => t('adminFinancePaymentBankTransfer');
  String get adminFinancePaymentOnline  => t('adminFinancePaymentOnline');
  String get adminFinancePaymentStripe  => t('adminFinancePaymentStripe');
  String get adminFinancePaymentOther   => t('adminFinancePaymentOther');
  String get adminFinanceRecurringNone  => t('adminFinanceRecurringNone');
  String get adminFinanceRecurringMonthly => t('adminFinanceRecurringMonthly');
  String get adminFinanceRecurringYearly => t('adminFinanceRecurringYearly');
  String get adminFinanceSaveSuccess    => t('adminFinanceSaveSuccess');
  String get adminFinanceSaveFailed     => t('adminFinanceSaveFailed');
  String get adminFinanceVoidSuccess    => t('adminFinanceVoidSuccess');
  String get adminFinanceVoidFailed     => t('adminFinanceVoidFailed');
}

// ─── Delegate ────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  // Non-static so it reloads when the delegate is recreated (full restart)
  // Use a module-level cache to avoid re-reading on every build
  static final Map<String, Map<String, String>> _cache = {};

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en', 'fr', 'it', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final code = locale.languageCode;
    if (!_cache.containsKey(code)) {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cache[code] = map.map((k, v) => MapEntry(k, v.toString()));
    }
    return AppLocalizations(locale, _cache[code]!);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
