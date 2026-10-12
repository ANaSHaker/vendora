class ApiResponse<T> {
  final T data;
  final String? message;

  const ApiResponse({required this.data, this.message});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    return ApiResponse(
      data: fromData(json['data']),
      message: json['message'] as String?,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta meta;
  final Map<String, dynamic>? summary;

  const PaginatedResponse({required this.data, required this.meta, this.summary});

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawData = json['data'] as List<dynamic>? ?? [];
    final rawMeta = json['meta'] as Map<String, dynamic>? ?? {};

    return PaginatedResponse(
      data: rawData
          .map((e) => fromItem(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(rawMeta),
      summary: json['summary'] as Map<String, dynamic>?,
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMore;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMore,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    final current = (json['current_page'] as num?)?.toInt() ?? 1;
    final last    = (json['last_page'] as num?)?.toInt() ?? 1;
    return PaginationMeta(
      currentPage: current,
      lastPage: last,
      perPage: (json['per_page'] as num?)?.toInt() ?? 15,
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasMore: current < last,
    );
  }

  static PaginationMeta empty() => const PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
        hasMore: false,
      );
}
