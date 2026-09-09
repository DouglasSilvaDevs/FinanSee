import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/report_export_data.dart';

class ReportExportRepository {
  final AppDatabase database;

  ReportExportRepository(
    this.database,
  );

  Future<MonthlyReportExportData> getMonthlyReport(
    DateTime selectedMonth,
  ) async {
    final start = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );

    final end = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      1,
    );

    final query = database
        .select(
      database.transactions,
    )
        .join([
      innerJoin(
        database.accounts,
        database.accounts.id.equalsExp(
          database.transactions.accountId,
        ),
      ),
      innerJoin(
        database.categories,
        database.categories.id.equalsExp(
          database.transactions.categoryId,
        ),
      ),
    ])
      ..where(
        database.transactions.date.isBiggerOrEqualValue(
              start,
            ) &
            database.transactions.date.isSmallerThanValue(
              end,
            ),
      )
      ..orderBy([
        OrderingTerm.asc(
          database.transactions.date,
        ),
        OrderingTerm.asc(
          database.transactions.id,
        ),
      ]);

    final rows = await query.get();

    final transactions = <ReportExportTransaction>[];

    final categoryTotals = <int, _CategoryAccumulator>{};

    var incomeInCents = 0;
    var expenseInCents = 0;

    for (final row in rows) {
      final transaction = row.readTable(
        database.transactions,
      );

      final account = row.readTable(
        database.accounts,
      );

      final category = row.readTable(
        database.categories,
      );

      transactions.add(
        ReportExportTransaction(
          id: transaction.id,
          description: transaction.description,
          amountInCents: transaction.amountInCents,
          type: transaction.type,
          date: transaction.date,
          accountName: account.name,
          categoryName: category.name,
          notes: transaction.notes,
        ),
      );

      if (transaction.type == 'income') {
        incomeInCents += transaction.amountInCents.abs();

        continue;
      }

      if (transaction.type == 'expense') {
        final amount = transaction.amountInCents.abs();

        expenseInCents += amount;

        final existing = categoryTotals[category.id];

        if (existing == null) {
          categoryTotals[category.id] = _CategoryAccumulator(
            categoryId: category.id,
            categoryName: category.name,
            amountInCents: amount,
          );
        } else {
          existing.amountInCents += amount;
        }
      }
    }

    final expensesByCategory = categoryTotals.values
        .map(
          (item) => ReportExportCategoryTotal(
            categoryId: item.categoryId,
            categoryName: item.categoryName,
            amountInCents: item.amountInCents,
          ),
        )
        .toList()
      ..sort(
        (a, b) => b.amountInCents.compareTo(
          a.amountInCents,
        ),
      );

    return MonthlyReportExportData(
      year: selectedMonth.year,
      month: selectedMonth.month,
      incomeInCents: incomeInCents,
      expenseInCents: expenseInCents,
      transactions: transactions,
      expenseCategories: expensesByCategory,
    );
  }
}

class _CategoryAccumulator {
  final int categoryId;
  final String categoryName;

  int amountInCents;

  _CategoryAccumulator({
    required this.categoryId,
    required this.categoryName,
    required this.amountInCents,
  });
}
