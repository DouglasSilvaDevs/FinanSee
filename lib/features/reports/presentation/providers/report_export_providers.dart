import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/report_export_repository.dart';
import '../../data/report_export_service.dart';
import '../../domain/report_export_data.dart';

final reportExportRepositoryProvider = Provider<ReportExportRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return ReportExportRepository(
    database,
  );
});

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return ReportExportService();
});

final monthlyReportExportProvider =
    FutureProvider.family<MonthlyReportExportData, DateTime>(
  (ref, month) async {
    final repository = ref.watch(
      reportExportRepositoryProvider,
    );

    return repository.getMonthlyReport(
      month,
    );
  },
);
