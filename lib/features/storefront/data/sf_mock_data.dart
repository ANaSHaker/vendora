import '../domain/entities/sf_entities.dart';

// Realistic mock data shown when backend isn't returning products yet.
// Images: picsum.photos — stable, no CORS issues on Flutter web.

class SfMockData {
  static const _c1 = SfCategory(id: 'c1', name: 'الأكثر مبيعاً',  productCount: 12,
      imageUrl: 'https://picsum.photos/seed/cat1/200/200');
  static const _c2 = SfCategory(id: 'c2', name: 'وصل حديثاً',      productCount: 8,
      imageUrl: 'https://picsum.photos/seed/cat2/200/200');
  static const _c3 = SfCategory(id: 'c3', name: 'عروض خاصة',       productCount: 5,
      imageUrl: 'https://picsum.photos/seed/cat3/200/200');
  static const _c4 = SfCategory(id: 'c4', name: 'المجموعة المميزة', productCount: 7,
      imageUrl: 'https://picsum.photos/seed/cat4/200/200');
  static const _c5 = SfCategory(id: 'c5', name: 'كل المنتجات',      productCount: 32,
      imageUrl: 'https://picsum.photos/seed/cat5/200/200');

  static List<SfCategory> get categories => [_c1, _c2, _c3, _c4, _c5];

  static List<SfProduct> get featuredProducts => [
    SfProduct(
      id: 'p1', name: 'منتج مميز ١', isFeatured: true,
      description: 'وصف تفصيلي للمنتج الأول — جودة عالية وسعر مناسب.',
      price: 149.0, stock: 20, category: _c1,
      images: [SfProductImage(id: 'i1', url: 'https://picsum.photos/seed/prod1/400/400')],
    ),
    SfProduct(
      id: 'p2', name: 'منتج مميز ٢', isFeatured: true,
      description: 'تصميم أنيق ومواصفات ممتازة تناسب جميع الأذواق.',
      price: 89.0, oldPrice: 120.0, stock: 15, category: _c2,
      images: [SfProductImage(id: 'i2', url: 'https://picsum.photos/seed/prod2/400/400')],
    ),
    SfProduct(
      id: 'p3', name: 'منتج مميز ٣', isFeatured: true,
      description: 'الخيار الأمثل للعملاء الباحثين عن الجودة.',
      price: 210.0, stock: 6, category: _c1,
      images: [SfProductImage(id: 'i3', url: 'https://picsum.photos/seed/prod3/400/400')],
    ),
    SfProduct(
      id: 'p4', name: 'منتج مميز ٤', isFeatured: true,
      description: 'منتج حصري بكميات محدودة.',
      price: 320.0, oldPrice: 400.0, stock: 0, category: _c3,
      images: [SfProductImage(id: 'i4', url: 'https://picsum.photos/seed/prod4/400/400')],
    ),
  ];

  static List<SfProduct> get allProducts => [
    ...featuredProducts,
    SfProduct(
      id: 'p5', name: 'منتج ٥',
      description: 'جودة ممتازة بسعر معقول.',
      price: 55.0, stock: 30, category: _c2,
      images: [SfProductImage(id: 'i5', url: 'https://picsum.photos/seed/prod5/400/400')],
    ),
    SfProduct(
      id: 'p6', name: 'منتج ٦',
      description: 'قيمة ممتازة مقابل السعر.',
      price: 75.0, stock: 18, category: _c4,
      images: [SfProductImage(id: 'i6', url: 'https://picsum.photos/seed/prod6/400/400')],
    ),
    SfProduct(
      id: 'p7', name: 'منتج ٧',
      description: 'الأكثر مبيعاً هذا الشهر.',
      price: 99.0, oldPrice: 130.0, stock: 25, category: _c1,
      images: [SfProductImage(id: 'i7', url: 'https://picsum.photos/seed/prod7/400/400')],
    ),
    SfProduct(
      id: 'p8', name: 'منتج ٨',
      description: 'خامات فاخرة وتصنيع احترافي.',
      price: 180.0, stock: 10, category: _c3,
      images: [SfProductImage(id: 'i8', url: 'https://picsum.photos/seed/prod8/400/400')],
    ),
  ];
}
