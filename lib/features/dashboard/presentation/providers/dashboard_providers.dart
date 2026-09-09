import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return DashboardRepository(
    database,
  );
});

final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  final repository = ref.watch(
    dashboardRepositoryProvider,
  );

  return repository.watchSummary();
});

final dashboardRecentTransactionsProvider = StreamProvider<List<DashboardTransaction>>((ref) {
  final repository = ref.watch(
    dashboardRepositoryProvider,
  );

  return repository.watchRecentTransactions(
    limit: 5,
  );
});

final dashboardExpensesByCategoryProvider = StreamProvider<List<ExpenseCategoryTotal>>((ref) {
  final repository = ref.watch(
    dashboardRepositoryProvider,
  );

  return repository.watchExpensesByCategory();
});
