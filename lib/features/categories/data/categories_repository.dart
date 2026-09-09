import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

enum CategorySaveResult {
  saved,
  duplicateName,
  typeChangeBlocked,
  notFound,
}

enum DeleteCategoryResult {
  deleted,
  hasTransactions,
  hasRecurringTransactions,
}

class CategoriesRepository {
  final AppDatabase database;

  CategoriesRepository(
    this.database,
  );

  Stream<List<FinanceCategory>> watchCategories() {
    final query = database.select(database.categories)
      ..orderBy([
        (table) => OrderingTerm.asc(
              table.type,
            ),
        (table) => OrderingTerm.asc(
              table.name,
            ),
      ]);

    return query.watch();
  }

  Future<FinanceCategory?> getCategory(
    int categoryId,
  ) {
    return (database.select(database.categories)
          ..where(
            (table) => table.id.equals(
              categoryId,
            ),
          ))
        .getSingleOrNull();
  }

  Future<CategorySaveResult> createCategory({
    required String name,
    required String type,
    required String icon,
  }) async {
    final normalizedName = name.trim();

    final duplicate = await _hasDuplicateName(
      name: normalizedName,
      type: type,
    );

    if (duplicate) {
      return CategorySaveResult.duplicateName;
    }

    await database.into(database.categories).insert(
          CategoriesCompanion.insert(
            name: normalizedName,
            type: type,
            icon: Value(icon),
          ),
        );

    return CategorySaveResult.saved;
  }

  Future<CategorySaveResult> updateCategory({
    required int categoryId,
    required String name,
    required String type,
    required String icon,
  }) async {
    final current = await getCategory(
      categoryId,
    );

    if (current == null) {
      return CategorySaveResult.notFound;
    }

    final normalizedName = name.trim();

    final duplicate = await _hasDuplicateName(
      name: normalizedName,
      type: type,
      excludeCategoryId: categoryId,
    );

    if (duplicate) {
      return CategorySaveResult.duplicateName;
    }

    //
    // Se estiver alterando o tipo da categoria,
    // precisamos garantir que ela não esteja sendo usada.
    //
    if (current.type != type) {
      final transactionCount = await _countTransactions(
        categoryId,
      );

      final recurringCount = await _countRecurringTransactions(
        categoryId,
      );

      if (transactionCount > 0 || recurringCount > 0) {
        return CategorySaveResult.typeChangeBlocked;
      }
    }

    await (database.update(database.categories)
          ..where(
            (table) => table.id.equals(
              categoryId,
            ),
          ))
        .write(
      CategoriesCompanion(
        name: Value(
          normalizedName,
        ),
        type: Value(
          type,
        ),
        icon: Value(
          icon,
        ),
      ),
    );

    return CategorySaveResult.saved;
  }

  Future<DeleteCategoryResult> deleteCategory(
    int categoryId,
  ) async {
    //
    // Primeiro verificamos transações normais.
    //
    final transactionCount = await _countTransactions(
      categoryId,
    );

    if (transactionCount > 0) {
      return DeleteCategoryResult.hasTransactions;
    }

    //
    // Depois verificamos regras recorrentes.
    //
    final recurringCount = await _countRecurringTransactions(
      categoryId,
    );

    if (recurringCount > 0) {
      return DeleteCategoryResult.hasRecurringTransactions;
    }

    //
    // Se não estiver sendo usada, pode excluir.
    //
    await (database.delete(database.categories)
          ..where(
            (table) => table.id.equals(
              categoryId,
            ),
          ))
        .go();

    return DeleteCategoryResult.deleted;
  }

  Future<bool> _hasDuplicateName({
    required String name,
    required String type,
    int? excludeCategoryId,
  }) async {
    final query = database.select(database.categories)
      ..where(
        (table) => table.type.equals(
          type,
        ),
      );

    final categories = await query.get();

    final normalized = name.trim().toLowerCase();

    return categories.any(
      (category) {
        if (excludeCategoryId != null && category.id == excludeCategoryId) {
          return false;
        }

        return category.name.trim().toLowerCase() == normalized;
      },
    );
  }

  Future<int> _countTransactions(
    int categoryId,
  ) async {
    final countExpression = database.transactions.id.count();

    final query = database.selectOnly(
      database.transactions,
    )
      ..addColumns([
        countExpression,
      ])
      ..where(
        database.transactions.categoryId.equals(
          categoryId,
        ),
      );

    final row = await query.getSingle();

    return row.read(
          countExpression,
        ) ??
        0;
  }

  Future<int> _countRecurringTransactions(
    int categoryId,
  ) async {
    final countExpression = database.recurringTransactions.id.count();

    final query = database.selectOnly(
      database.recurringTransactions,
    )
      ..addColumns([
        countExpression,
      ])
      ..where(
        database.recurringTransactions.categoryId.equals(
          categoryId,
        ),
      );

    final row = await query.getSingle();

    return row.read(
          countExpression,
        ) ??
        0;
  }
}
