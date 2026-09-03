import '../../models/category.dart';
import '../../services/category_api_service.dart';

/// Thin pass-through over `CategoryApiService` — single call, no
/// merging/filtering — exists to give `CategoryProvider` an injectable
/// data-source seam for testing.
class CategoryRepository {
  CategoryRepository({CategoryApiService? apiService}) : _apiService = apiService ?? CategoryApiService();

  final CategoryApiService _apiService;

  Future<List<Category>> fetchCategories() => _apiService.fetchCategories();
}
