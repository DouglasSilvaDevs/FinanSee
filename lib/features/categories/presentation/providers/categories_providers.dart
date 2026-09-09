import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/categories_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return CategoriesRepository(
    database,
  );
});

final allCategoriesProvider = StreamProvider<List<FinanceCategory>>((ref) {
  final repository = ref.watch(
    categoriesRepositoryProvider,
  );

  return repository.watchCategories();
});
