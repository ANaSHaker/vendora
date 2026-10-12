import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/product_entities.dart';
import '../models/product_models.dart';

abstract class ProductsRemoteDataSource {
  Future<PaginatedResponse<ProductModel>> getProducts({
    String? search,
    String? categoryId,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  });

  Future<ProductModel> createProduct(ProductFormData data);
  Future<ProductModel> updateProduct(String id, ProductFormData data);
  Future<void> deleteProduct(String id);

  Future<List<int>> exportProducts();
  Future<List<int>> exportProductsTemplate();
  Future<Map<String, dynamic>> importProducts(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  });

  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory(CategoryFormData data);
  Future<CategoryModel> updateCategory(String id, CategoryFormData data);
  Future<void> deleteCategory(String id);

  Future<List<int>> exportCategories();
  Future<List<int>> exportCategoriesTemplate();
  Future<Map<String, dynamic>> importCategories(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  });
}

class ProductsRemoteDataSourceImpl implements ProductsRemoteDataSource {
  final ApiClient _client;

  const ProductsRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<ProductModel>> getProducts({
    String? search,
    String? categoryId,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
      if (isActive != null) 'is_active': isActive ? 1 : 0,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, ProductModel.fromJson);
  }

  Object _buildProductPayload(String id, ProductFormData data) {
    final fields =
        ProductModel(id: id, name: data.name, price: data.price).toJson(data);
    if (data.imageBytes != null && data.imageBytes!.isNotEmpty) {
      return FormData.fromMap({
        ...fields,
        'image': MultipartFile.fromBytes(
          data.imageBytes!,
          filename: 'product_image.jpg',
        ),
      });
    }
    return fields;
  }

  @override
  Future<ProductModel> createProduct(ProductFormData data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.products,
      data: _buildProductPayload('', data),
    );
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return ProductModel.fromJson(json);
  }

  @override
  Future<ProductModel> updateProduct(String id, ProductFormData data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.productById(id),
      data: _buildProductPayload(id, data),
    );
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return ProductModel.fromJson(json);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.productById(id));
  }

  @override
  Future<List<int>> exportProducts() async {
    final res = await _client.get<List<int>>(
      ApiEndpoints.exportProducts,
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }

  @override
  Future<List<int>> exportProductsTemplate() async {
    final res = await _client.get<List<int>>(
      ApiEndpoints.exportProducts,
      queryParameters: {'template': 1},
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }

  @override
  Future<Map<String, dynamic>> importProducts(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'duplicate_mode': duplicateMode,
    });
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.importProducts,
      data: formData,
    );
    final body = res.data ?? {};
    return body['data'] as Map<String, dynamic>? ?? body;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final res =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.categories);
    final body = res.data!;
    final raw = body['data'] as List<dynamic>? ??
        (body.values.firstWhere((v) => v is List, orElse: () => <dynamic>[])
            as List<dynamic>);
    return raw
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CategoryModel> createCategory(CategoryFormData data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.categories,
      data: CategoryModel(id: '', name: data.name).toJson(data),
    );
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return CategoryModel.fromJson(json);
  }

  @override
  Future<CategoryModel> updateCategory(String id, CategoryFormData data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.categoryById(id),
      data: CategoryModel(id: id, name: data.name).toJson(data),
    );
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return CategoryModel.fromJson(json);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.categoryById(id));
  }

  @override
  Future<List<int>> exportCategories() async {
    final res = await _client.get<List<int>>(
      ApiEndpoints.exportCategories,
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }

  @override
  Future<List<int>> exportCategoriesTemplate() async {
    final res = await _client.get<List<int>>(
      ApiEndpoints.exportCategories,
      queryParameters: {'template': 1},
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }

  @override
  Future<Map<String, dynamic>> importCategories(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'duplicate_mode': duplicateMode,
    });
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.importCategories,
      data: formData,
    );
    final body = res.data ?? {};
    return body['data'] as Map<String, dynamic>? ?? body;
  }
}
