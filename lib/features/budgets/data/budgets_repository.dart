import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/budget_models.dart';

enum BudgetSaveResult {
  saved,
  duplicate,
  notFound,
}

class BudgetsRepository {
  final AppDatabase database;

  BudgetsRepository(
    this.database,
  );

  Stream<List<BudgetProgress>> watchBudgets({
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
        b.id AS budget_id,
        b.category_id,
        b.limit_in_cents,

        c.name AS category_name,
        c.icon AS category_icon,

        COALESCE(
          SUM(
            CASE
              WHEN t.type = 'expense'
                THEN t.amount_in_cents
              ELSE 0
            END
          ),
          0
        ) AS spent_in_cents

      FROM budgets b

      INNER JOIN categories c
        ON c.id = b.category_id

      LEFT JOIN transactions t
        ON t.category_id = b.category_id
        AND t.type = 'expense'
        AND t.date >= ?
        AND t.date < ?

      WHERE b.year = ?
        AND b.month = ?

      GROUP BY
        b.id,
        b.category_id,
        b.limit_in_cents,
        c.name,
        c.icon

      ORDER BY c.name ASC
      ''',
      variables: [
        Variable.withDateTime(
          monthStart,
        ),
        Variable.withDateTime(
          nextMonthStart,
        ),
        Variable.withInt(
          month.year,
        ),
        Variable.withInt(
          month.month,
        ),
      ],
      readsFrom: {
        database.budgets,
        database.categories,
        database.transactions,
      },
    );

    return query.watch().map(
      (rows) {
        return rows.map(
          (row) {
            return BudgetProgress(
              budgetId: row.read<int>(
                'budget_id',
              ),
              categoryId: row.read<int>(
                'category_id',
              ),
              categoryName: row.read<String>(
                'category_name',
              ),
              categoryIcon: row.readNullable<String>(
                'category_icon',
              ),
              limitInCents: row.read<int>(
                'limit_in_cents',
              ),
              spentInCents: row.read<int>(
                'spent_in_cents',
              ),
            );
          },
        ).toList();
      },
    );
  }

  Stream<List<FinanceCategory>> watchExpenseCategories() {
    final query = database.select(database.categories)
      ..where(
        (table) => table.type.equals(
          'expense',
        ),
      )
      ..orderBy([
        (table) => OrderingTerm.asc(
              table.name,
            ),
      ]);

    return query.watch();
  }

  Future<MonthlyBudget?> getBudget(
    int budgetId,
  ) {
    return (database.select(database.budgets)
          ..where(
            (table) => table.id.equals(
              budgetId,
            ),
          ))
        .getSingleOrNull();
  }

  Future<BudgetSaveResult> createBudget({
    required int categoryId,
    required int year,
    required int month,
    required int limitInCents,
  }) async {
    final duplicate = await _budgetExists(
      categoryId: categoryId,
      year: year,
      month: month,
    );

    if (duplicate) {
      return BudgetSaveResult.duplicate;
    }

    await database.into(database.budgets).insert(
          BudgetsCompanion.insert(
            categoryId: categoryId,
            year: year,
            month: month,
            limitInCents: limitInCents,
          ),
        );

    return BudgetSaveResult.saved;
  }

  Future<BudgetSaveResult> updateBudget({
    required int budgetId,
    required int categoryId,
    required int year,
    required int month,
    required int limitInCents,
  }) async {
    final current = await getBudget(
      budgetId,
    );

    if (current == null) {
      return BudgetSaveResult.notFound;
    }

    final duplicate = await _budgetExists(
      categoryId: categoryId,
      year: year,
      month: month,
      excludeBudgetId: budgetId,
    );

    if (duplicate) {
      return BudgetSaveResult.duplicate;
    }

    await (database.update(database.budgets)
          ..where(
            (table) => table.id.equals(
              budgetId,
            ),
          ))
        .write(
      BudgetsCompanion(
        categoryId: Value(
          categoryId,
        ),
        year: Value(year),
        month: Value(month),
        limitInCents: Value(
          limitInCents,
        ),
      ),
    );

    return BudgetSaveResult.saved;
  }

  Future<void> deleteBudget(
    int budgetId,
  ) async {
    await (database.delete(database.budgets)
          ..where(
            (table) => table.id.equals(
              budgetId,
            ),
          ))
        .go();
  }

  Future<bool> _budgetExists({
    required int categoryId,
    required int year,
    required int month,
    int? excludeBudgetId,
  }) async {
    final query = database.select(database.budgets)
      ..where(
        (table) {
          var expression = table.categoryId.equals(
                categoryId,
              ) &
              table.year.equals(
                year,
              ) &
              table.month.equals(
                month,
              );

          if (excludeBudgetId != null) {
            expression &= table.id.isNotValue(
              excludeBudgetId,
            );
          }

          return expression;
        },
      );

    return (await query.get()).isNotEmpty;
  }
}
