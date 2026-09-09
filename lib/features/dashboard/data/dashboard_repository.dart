import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  final AppDatabase database;

  DashboardRepository(this.database);

  Stream<DashboardSummary> watchSummary({
    DateTime? referenceDate,
  }) {
    final date = referenceDate ?? DateTime.now();

    final monthStart = DateTime(
      date.year,
      date.month,
      1,
    );

    final nextMonthStart = date.month == 12
        ? DateTime(
            date.year + 1,
            1,
            1,
          )
        : DateTime(
            date.year,
            date.month + 1,
            1,
          );

    final query = database.customSelect(
      '''
      SELECT

        COALESCE(
          (
            SELECT SUM(initial_balance_in_cents)
            FROM accounts
          ),
          0
        )
        +
        COALESCE(
          (
            SELECT SUM(
              CASE
                WHEN type = 'income'
                  THEN amount_in_cents

                WHEN type = 'expense'
                  THEN -amount_in_cents

                ELSE 0
              END
            )
            FROM transactions
          ),
          0
        )
        AS total_balance_in_cents,

        COALESCE(
          (
            SELECT SUM(amount_in_cents)
            FROM transactions
            WHERE type = 'income'
              AND date >= ?
              AND date < ?
          ),
          0
        )
        AS income_this_month_in_cents,

        COALESCE(
          (
            SELECT SUM(amount_in_cents)
            FROM transactions
            WHERE type = 'expense'
              AND date >= ?
              AND date < ?
          ),
          0
        )
        AS expense_this_month_in_cents
      ''',
      variables: [
        Variable.withDateTime(monthStart),
        Variable.withDateTime(nextMonthStart),
        Variable.withDateTime(monthStart),
        Variable.withDateTime(nextMonthStart),
      ],
      readsFrom: {
        database.accounts,
        database.transactions,
      },
    );

    return query.watchSingle().map(
      (row) {
        return DashboardSummary(
          totalBalanceInCents: row.read<int>(
            'total_balance_in_cents',
          ),
          incomeThisMonthInCents: row.read<int>(
            'income_this_month_in_cents',
          ),
          expenseThisMonthInCents: row.read<int>(
            'expense_this_month_in_cents',
          ),
        );
      },
    );
  }

  Stream<List<ExpenseCategoryTotal>> watchExpensesByCategory({
    DateTime? referenceDate,
  }) {
    final date = referenceDate ?? DateTime.now();

    final monthStart = DateTime(
      date.year,
      date.month,
      1,
    );

    final nextMonthStart = date.month == 12
        ? DateTime(
            date.year + 1,
            1,
            1,
          )
        : DateTime(
            date.year,
            date.month + 1,
            1,
          );

    final query = database.customSelect(
      '''
    SELECT
      c.id AS category_id,
      c.name AS category_name,
      c.icon AS category_icon,
      SUM(t.amount_in_cents) AS total_in_cents

    FROM transactions t

    INNER JOIN categories c
      ON c.id = t.category_id

    WHERE t.type = 'expense'
      AND t.date >= ?
      AND t.date < ?

    GROUP BY
      c.id,
      c.name,
      c.icon

    ORDER BY total_in_cents DESC
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
            return ExpenseCategoryTotal(
              categoryId: row.read<int>(
                'category_id',
              ),
              categoryName: row.read<String>(
                'category_name',
              ),
              icon: row.readNullable<String>(
                'category_icon',
              ),
              totalInCents: row.read<int>(
                'total_in_cents',
              ),
            );
          },
        ).toList();
      },
    );
  }

  Stream<List<DashboardTransaction>> watchRecentTransactions({
    int limit = 5,
  }) {
    final query = database.select(database.transactions).join([
      innerJoin(
        database.categories,
        database.categories.id.equalsExp(
          database.transactions.categoryId,
        ),
      ),
    ]);

    query.orderBy([
      OrderingTerm.desc(
        database.transactions.date,
      ),
    ]);

    query.limit(limit);

    return query.watch().map(
      (rows) {
        return rows.map(
          (row) {
            final transaction = row.readTable(
              database.transactions,
            );

            final category = row.readTable(
              database.categories,
            );

            return DashboardTransaction(
              transaction: transaction,
              category: category,
            );
          },
        ).toList();
      },
    );
  }
}
