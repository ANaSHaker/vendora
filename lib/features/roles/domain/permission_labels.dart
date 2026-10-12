// Static Arabic translation map for backend permission module labels and permission names.
// Keys match the `key` field returned by GET /api/permissions.
// Falls back to the backend-provided English label when no translation exists.
abstract final class PermissionLabels {
  // ── Module label translations ──────────────────────────────────────────────
  static const Map<String, String> moduleLabels = {
    'dashboard':        'لوحة التحكم',
    'pos':              'نقطة البيع',
    'orders':           'الطلبات',
    'products':         'المنتجات',
    'categories':       'الفئات',
    'customers':        'العملاء',
    'suppliers':        'الموردون',
    'inventory':        'المخزون',
    'warehouses':       'المستودعات',
    'transfers':        'التحويلات',
    'stock_counts':     'جرد المخزون',
    'adjustments':      'التسويات',
    'reports':          'التقارير',
    'settings':         'الإعدادات',
    'branches':         'الفروع',
    'users':            'الموظفون',
    'roles':            'الأدوار',
    'devices':          'الأجهزة',
    'notifications':    'الإشعارات',
    'activity_log':     'سجل النشاط',
  };

  // ── Permission name translations ───────────────────────────────────────────
  static const Map<String, String> permissionLabels = {
    // Dashboard
    'dashboard.view':              'عرض لوحة التحكم',

    // POS
    'pos.access':                  'استخدام نقطة البيع',

    // Orders
    'orders.view':                 'عرض الطلبات',
    'orders.create':               'إنشاء طلبات',
    'orders.update_status':        'تحديث حالة الطلب',
    'orders.refund':               'استرداد الطلبات',
    'orders.void':                 'إلغاء الطلبات',
    'orders.discount':             'تطبيق خصومات',
    'orders.delete':               'حذف الطلبات',

    // Products
    'products.view':               'عرض المنتجات',
    'products.create':             'إضافة المنتجات',
    'products.edit':               'تعديل المنتجات',
    'products.delete':             'حذف المنتجات',
    'products.import':             'استيراد المنتجات',
    'products.export':             'تصدير المنتجات',

    // Categories
    'categories.view':             'عرض الفئات',
    'categories.create':           'إضافة الفئات',
    'categories.edit':             'تعديل الفئات',
    'categories.delete':           'حذف الفئات',

    // Customers
    'customers.view':              'عرض العملاء',
    'customers.create':            'إضافة العملاء',
    'customers.edit':              'تعديل العملاء',
    'customers.delete':            'حذف العملاء',

    // Suppliers
    'suppliers.view':              'عرض الموردين',
    'suppliers.create':            'إضافة الموردين',
    'suppliers.edit':              'تعديل الموردين',
    'suppliers.delete':            'حذف الموردين',

    // Inventory
    'inventory.view':              'عرض المخزون',
    'inventory.adjust':            'تعديل المخزون',
    'inventory.transfer':          'تحويل المخزون',
    'inventory.count':             'جرد المخزون',

    // Warehouses
    'warehouses.view':             'عرض المستودعات',
    'warehouses.create':           'إضافة المستودعات',
    'warehouses.edit':             'تعديل المستودعات',
    'warehouses.delete':           'حذف المستودعات',

    // Transfers
    'transfers.view':              'عرض التحويلات',
    'transfers.create':            'إنشاء تحويلات',
    'transfers.approve':           'اعتماد التحويلات',
    'transfers.delete':            'حذف التحويلات',

    // Stock Counts
    'stock_counts.view':           'عرض جرد المخزون',
    'stock_counts.create':         'إنشاء جرد مخزون',
    'stock_counts.post':           'ترحيل الجرد',
    'stock_counts.delete':         'حذف الجرد',

    // Adjustments
    'adjustments.view':            'عرض التسويات',
    'adjustments.create':          'إنشاء تسويات',
    'adjustments.approve':         'اعتماد التسويات',
    'adjustments.delete':          'حذف التسويات',

    // Reports
    'reports.view':                'عرض التقارير',
    'reports.export':              'تصدير التقارير',
    'reports.financial':           'التقارير المالية',

    // Settings
    'settings.view':               'عرض الإعدادات',
    'settings.edit':               'تعديل الإعدادات',
    'settings.branding':           'إعدادات العلامة التجارية',
    'settings.store':              'إعدادات المتجر',

    // Branches
    'branches.view':               'عرض الفروع',
    'branches.create':             'إضافة فروع',
    'branches.edit':               'تعديل الفروع',
    'branches.delete':             'حذف الفروع',

    // Users
    'users.view':                  'عرض الموظفين',
    'users.create':                'إضافة الموظفين',
    'users.edit':                  'تعديل الموظفين',
    'users.delete':                'حذف الموظفين',

    // Roles
    'roles.view':                  'عرض الأدوار',
    'roles.create':                'إضافة الأدوار',
    'roles.edit':                  'تعديل الأدوار',
    'roles.delete':                'حذف الأدوار',

    // Devices
    'devices.view':                'عرض الأجهزة',
    'devices.manage':              'إدارة الأجهزة',

    // Activity Log
    'activity_log.view':           'عرض سجل النشاط',
  };

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String translateModule(String key, String fallbackLabel) =>
      moduleLabels[key] ?? fallbackLabel;

  static String translatePermission(String name, String fallbackLabel) =>
      permissionLabels[name] ?? fallbackLabel;
}
