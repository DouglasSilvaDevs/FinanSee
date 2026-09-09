import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/transaction_models.dart';

class TransactionsRepository {
  final AppDatabase database;

  TransactionsRepository(this.database);

  Stream<List<FinanceTransaction>> watchTransactions() {
    final query = database.select(database.transactions)
      ..orderBy([
        (table) => OrderingTerm.desc(table.date),
        (table) => OrderingTerm.desc(table.id),
      ]);

    return query.watch();
  }

  Stream<List<TransactionDetails>> watchDetailedTransactions() {
    final query = database.select(database.transactions).join([
      innerJoin(
        database.categories,
        database.categories.id.equalsExp(
          database.transactions.categoryId,
        ),
      ),
      innerJoin(
        database.accounts,
        database.accounts.id.equalsExp(
          database.transactions.accountId,
        ),
      ),
    ]);

    query.orderBy([
      OrderingTerm.desc(
        database.transactions.date,
      ),
      OrderingTerm.desc(
        database.transactions.id,
      ),
    ]);

    return query.watch().map(
      (rows) {
        return rows.map(
          (row) {
            return TransactionDetails(
              transaction: row.readTable(
                database.transactions,
              ),
              category: row.readTable(
                database.categories,
              ),
              account: row.readTable(
                database.accounts,
              ),
            );
          },
        ).toList();
      },
    );
  }

  Stream<List<FinanceTransaction>> watchRecentTransactions({
    int limit = 5,
  }) {
    final query = database.select(database.transactions)
      ..orderBy([
        (table) => OrderingTerm.desc(table.date),
        (table) => OrderingTerm.desc(table.id),
      ])
      ..limit(limit);

    return query.watch();
  }

  Stream<List<FinanceAccount>> watchAccounts() {
    final query = database.select(database.accounts)
      ..orderBy([
        (table) => OrderingTerm.asc(table.name),
      ]);

    return query.watch();
  }

  Stream<List<FinanceCategory>> watchCategoriesByType(
    String type,
  ) {
    final query = database.select(database.categories)
      ..where(
        (table) => table.type.equals(type),
      )
      ..orderBy([
        (table) => OrderingTerm.asc(table.name),
      ]);

    return query.watch();
  }

  Future<FinanceTransaction?> getTransaction(
    int transactionId,
  ) {
    return (database.select(database.transactions)
          ..where(
            (table) => table.id.equals(transactionId),
          ))
        .getSingleOrNull();
  }

  Future<int> createTransaction({
    required String description,
    required int amountInCents,
    required String type,
    required DateTime date,
    required int accountId,
    required int categoryId,
    String? notes,
  }) {
    final cleanNotes = notes?.trim();

    return database.into(database.transactions).insert(
          TransactionsCompanion.insert(
            description: description.trim(),
            amountInCents: amountInCents,
            type: type,
            date: date,
            accountId: accountId,
            categoryId: categoryId,
            notes: cleanNotes == null || cleanNotes.isEmpty ? const Value.absent() : Value(cleanNotes),
          ),
        );
  }

  Future<void> updateTransaction({
    required int transactionId,
    required String description,
    required int amountInCents,
    required String type,
    required DateTime date,
    required int accountId,
    required int categoryId,
    String? notes,
  }) async {
    final cleanNotes = notes?.trim();

    await (database.update(database.transactions)
          ..where(
            (table) => table.id.equals(transactionId),
          ))
        .write(
      TransactionsCompanion(
        description: Value(
          description.trim(),
        ),
        amountInCents: Value(
          amountInCents,
        ),
        type: Value(type),
        date: Value(date),
        accountId: Value(accountId),
        categoryId: Value(categoryId),
        notes: Value(
          cleanNotes == null || cleanNotes.isEmpty ? null : cleanNotes,
        ),
      ),
    );
  }

  Future<int> deleteTransaction(
    int id,
  ) {
    return (database.delete(database.transactions)
          ..where(
            (table) => table.id.equals(id),
          ))
        .go();
  }
}
