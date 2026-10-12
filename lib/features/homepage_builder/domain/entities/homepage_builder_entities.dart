import 'package:equatable/equatable.dart';

enum SectionType { hero, featuredProducts, categories, cta }

extension SectionTypeExt on SectionType {
  String get key => switch (this) {
        SectionType.hero             => 'hero',
        SectionType.featuredProducts => 'featured_products',
        SectionType.categories       => 'categories',
        SectionType.cta              => 'cta',
      };

  static SectionType fromKey(String key) => switch (key) {
        'hero'              => SectionType.hero,
        'featured_products' => SectionType.featuredProducts,
        'categories'        => SectionType.categories,
        'cta'               => SectionType.cta,
        _                   => SectionType.hero,
      };
}

class HomepageSection extends Equatable {
  final String id;
  final SectionType type;
  final Map<String, dynamic> settings;

  const HomepageSection({
    required this.id,
    required this.type,
    required this.settings,
  });

  HomepageSection copyWith({Map<String, dynamic>? settings}) =>
      HomepageSection(id: id, type: type, settings: settings ?? this.settings);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.key,
        'settings': settings,
      };

  @override
  List<Object?> get props => [id, type, settings];
}

// Default settings per section type
Map<String, dynamic> defaultSettings(SectionType type) => switch (type) {
      SectionType.hero => {
          'title':       'Welcome to Our Store',
          'subtitle':    'Discover our collection of premium products.',
          'button_text': 'Shop Now',
        },
      SectionType.featuredProducts => {
          'title':    'Featured Products',
          'subtitle': 'Handpicked just for you',
          'count':    8,
        },
      SectionType.categories => {
          'title': 'Shop by Category',
        },
      SectionType.cta => {
          'title':                'Ready to shop?',
          'description':          'Explore our latest arrivals and place your order in minutes.',
          'primary_button_text':  'Start Shopping',
          'secondary_button_text':'Contact Us',
        },
    };
