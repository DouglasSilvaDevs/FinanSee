import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/report_models.dart';

class ReportsRepository {
  final AppDatabase database;

  ReportsRepository(this.database);

  Stream<List<MonthlyFinancialData>> watchLastSixMonths({
    required DateTime referenceDate,
  }) {
    final normalizedReference = DateTime(
      referenceDate.year,
      referenceDate.month,
      1,
    );

    final firstMonth = DateTime(
      normalizedReference.year,
      normalizedReference.month - 5,
      1,
    );

    final nextMonth = DateTime(
      normalizedReference.year,
      normalizedReference.month + 1,
      1,
    );

    final query = database.customSelect(
      '''
      SELECT *
      FROM transactions
      WHERE date >= ?
        AND date < ?
      ORDER BY date ASC
      ''',
      variables: [
        Variable.withDateTime(firstMonth),
        Variable.withDateTime(nextMonth),
      ],
      readsFrom: {
        database.transactions,
      },
    );

    return query.watch().map(
      (rows) {
        final transactions = rows.map(
          (row) {
            return database.transactions.map(
              row.data,
            );
          },
        ).toList();

        final months = List.generate(
          6,
          (index) {
            final month = DateTime(
              firstMonth.year,
              firstMonth.month + index,
              1,
            );

            var income = 0;
            var expense = 0;

            for (final transaction in transactions) {
              final sameMonth = transaction.date.year == month.year && transaction.date.month == month.month;

              if (!sameMonth) {
                continue;
              }

              if (transaction.type == 'income') {
                income += transaction.amountInCents;
              }

              if (transaction.type == 'expense') {
                expense += transaction.amountInCents;
              }
            }

            return MonthlyFinancialData(
              month: month,
              incomeInCents: income,
              expenseInCents: expense,
            );
          },
        );

        return months;
      },
    );
  }

  Stream<ReportMonthSummary> watchMonthSummary({
    required DateTime month,
  }) {
    final monthStart = DateTime(
      month.year,
      month.month,
      1,
    );

    final nextMonthStart = DateTime(
      month.year,
      month.month + 1,
      1,
    );

    final query = database.customSelect(
      '''
      SELECT
        COALESCE(
          SUM(
            CASE
              WHEN type = 'income'
              THEN amount_in_cents
              ELSE 0
            END
          ),
          0
        ) AS income,

        COALESCE(
          SUM(
            CASE
              WHEN type = 'expense'
              THEN amount_in_cents
              ELSE 0
            END
          ),
          0
        ) AS expense

      FROM transactions

      WHERE date >= ?
        AND date < ?
      ''',
      variables: [
        Variable.withDateTime(monthStart),
        Variable.withDateTime(nextMonthStart),
      ],
      readsFrom: {
        database.transactions,
      },
    );

    return query.watchSingle().map(
      (row) {
        return ReportMonthSummary(
          incomeInCents: row.read<int>(
            'income',
          ),
          expenseInCents: row.read<int>(
            'expense',
          ),
        );
      },
    );
  }

  Stream<List<ReportCategoryTotal>> watchExpenseCategories({
    required DateTime month,
  }) {
    final monthStart = DateTime(
      month.year,
      month.month,
      1,
    );

    final nextMonthStart = DateTime(
      month.year,
      month.month + 1,
      1,
    );

    final query = database.customSelect(
      '''
      SELECT
        c.id AS category_id,
        c.name AS category_name,
        SUM(t.amount_in_cents) AS total

      FROM transactions t

      INNER JOIN categories c
        ON c.id = t.category_id

      WHERE t.type = 'expense'
        AND t.date >= ?
        AND t.date < ?

      GROUP BY
        c.id,
        c.name

      ORDER BY total DESC
      ''',
      variables: [
        Variable.withDateTime(monthStart),
        Variable.withDateTime(nextMonthStart),
      ],
      readsFrom: {
        database.transactions,
        database.categories,
      },
    );

    return query.watch().map(
      (rows) {
        return rows.map(
          (row) {
            return ReportCategoryTotal(
              categoryId: row.read<int>(
                'category_id',
              ),
              categoryName: row.read<String>(
                'category_name',
              ),
              totalInCents: row.read<int>(
                'total',
              ),
            );
          },
        ).toList();
      },
    );
  }
}
