import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/reports_repository.dart';
import '../../domain/report_models.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return ReportsRepository(
    database,
  );
});

final reportMonthSummaryProvider = StreamProvider.family<ReportMonthSummary, DateTime>((ref, month) {
  final repository = ref.watch(
    reportsRepositoryProvider,
  );

  return repository.watchMonthSummary(
    month: month,
  );
});

final reportCategoriesProvider = StreamProvider.family<List<ReportCategoryTotal>, DateTime>((ref, month) {
  final repository = ref.watch(
    reportsRepositoryProvider,
  );

  return repository.watchExpenseCategories(
    month: month,
  );
});

final reportSixMonthsProvider = StreamProvider.family<List<MonthlyFinancialData>, DateTime>((ref, month) {
  final repository = ref.watch(
    reportsRepositoryProvider,
  );

  return repository.watchLastSixMonths(
    referenceDate: month,
  );
});
