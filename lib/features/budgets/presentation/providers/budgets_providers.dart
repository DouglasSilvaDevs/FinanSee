import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/budgets_repository.dart';
import '../../domain/budget_models.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return BudgetsRepository(
    database,
  );
});

final budgetsProvider =
    StreamProvider.family<List<BudgetProgress>, DateTime>((ref, month) {
  final repository = ref.watch(
    budgetsRepositoryProvider,
  );

  return repository.watchBudgets(
    month: month,
  );
});

final budgetExpenseCategoriesProvider =
    StreamProvider<List<FinanceCategory>>((ref) {
  final repository = ref.watch(
    budgetsRepositoryProvider,
  );

  return repository.watchExpenseCategories();
});
