import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/recurring_models.dart';

class RecurringTransactionsRepository {
  final AppDatabase database;

  RecurringTransactionsRepository(
    this.database,
  );

  Stream<List<RecurringTransactionDetails>> watchRecurringTransactions() {
    final query = database.select(database.recurringTransactions).join([
      innerJoin(
        database.accounts,
        database.accounts.id.equalsExp(
          database.recurringTransactions.accountId,
        ),
      ),
      innerJoin(
        database.categories,
        database.categories.id.equalsExp(
          database.recurringTransactions.categoryId,
        ),
      ),
    ]);

    query.orderBy([
      OrderingTerm.desc(
        database.recurringTransactions.isActive,
      ),
      OrderingTerm.asc(
        database.recurringTransactions.dayOfMonth,
      ),
      OrderingTerm.asc(
        database.recurringTransactions.description,
      ),
    ]);

    return query.watch().map(
      (rows) {
        return rows.map(
          (row) {
            return RecurringTransactionDetails(
              rule: row.readTable(
                database.recurringTransactions,
              ),
              account: row.readTable(
                database.accounts,
              ),
              category: row.readTable(
                database.categories,
              ),
            );
          },
        ).toList();
      },
    );
  }

  Future<RecurringTransactionRule?> getRule(
    int id,
  ) {
    return (database.select(
      database.recurringTransactions,
    )..where(
            (table) => table.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<int> createRule({
    required String description,
    required int amountInCents,
    required String type,
    required int dayOfMonth,
    required int accountId,
    required int categoryId,
    String? notes,
  }) async {
    final now = DateTime.now();

    final id = await database.into(database.recurringTransactions).insert(
          RecurringTransactionsCompanion.insert(
            description: description.trim(),
            amountInCents: amountInCents,
            type: type,
            dayOfMonth: dayOfMonth,
            accountId: accountId,
            categoryId: categoryId,
            startsAt: DateTime(
              now.year,
              now.month,
              1,
            ),
            notes: _notesValue(notes),
          ),
        );

    await generateDueTransactions();

    return id;
  }

  Future<void> updateRule({
    required int id,
    required String description,
    required int amountInCents,
    required String type,
    required int dayOfMonth,
    required int accountId,
    required int categoryId,
    String? notes,
  }) async {
    await (database.update(
      database.recurringTransactions,
    )..where(
            (table) => table.id.equals(id),
          ))
        .write(
      RecurringTransactionsCompanion(
        description: Value(
          description.trim(),
        ),
        amountInCents: Value(
          amountInCents,
        ),
        type: Value(type),
        dayOfMonth: Value(
          dayOfMonth,
        ),
        accountId: Value(
          accountId,
        ),
        categoryId: Value(
          categoryId,
        ),
        notes: Value(
          _cleanNotes(notes),
        ),
      ),
    );

    await generateDueTransactions();
  }

  Future<void> setActive({
    required int id,
    required bool active,
  }) async {
    if (active) {
      final now = DateTime.now();

      await (database.update(
        database.recurringTransactions,
      )..where(
              (table) => table.id.equals(id),
            ))
          .write(
        RecurringTransactionsCompanion(
          isActive: const Value(true),

          // Ao reativar, não criamos meses
          // referentes ao período pausado.
          startsAt: Value(
            DateTime(
              now.year,
              now.month,
              1,
            ),
          ),
        ),
      );

      await generateDueTransactions();
    } else {
      await (database.update(
        database.recurringTransactions,
      )..where(
              (table) => table.id.equals(id),
            ))
          .write(
        const RecurringTransactionsCompanion(
          isActive: Value(false),
        ),
      );
    }
  }

  Future<void> deleteRule(
    int id,
  ) async {
    await (database.delete(
      database.recurringTransactions,
    )..where(
            (table) => table.id.equals(id),
          ))
        .go();
  }

  Future<void> generateDueTransactions({
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final rules = await (database.select(
      database.recurringTransactions,
    )..where(
            (table) => table.isActive.equals(true),
          ))
        .get();

    for (final rule in rules) {
      var month = DateTime(
        rule.startsAt.year,
        rule.startsAt.month,
        1,
      );

      final currentMonth = DateTime(
        today.year,
        today.month,
        1,
      );

      while (!month.isAfter(currentMonth)) {
        final dueDate = _occurrenceDate(
          month.year,
          month.month,
          rule.dayOfMonth,
        );

        if (!dueDate.isAfter(today)) {
          await _generateOccurrence(
            rule: rule,
            dueDate: dueDate,
          );
        }

        month = DateTime(
          month.year,
          month.month + 1,
          1,
        );
      }
    }
  }

  Future<void> _generateOccurrence({
    required RecurringTransactionRule rule,
    required DateTime dueDate,
  }) async {
    await database.transaction(
      () async {
        final existing = await (database.select(
          database.recurringOccurrences,
        )..where(
                (table) =>
                    table.recurringTransactionId.equals(
                      rule.id,
                    ) &
                    table.year.equals(
                      dueDate.year,
                    ) &
                    table.month.equals(
                      dueDate.month,
                    ),
              ))
            .getSingleOrNull();

        if (existing != null) {
          return;
        }

        final transactionId = await database.into(database.transactions).insert(
              TransactionsCompanion.insert(
                description: rule.description,
                amountInCents: rule.amountInCents,
                type: rule.type,
                date: dueDate,
                accountId: rule.accountId,
                categoryId: rule.categoryId,
                notes: rule.notes == null
                    ? const Value.absent()
                    : Value(
                        rule.notes,
                      ),
              ),
            );

        await database.into(database.recurringOccurrences).insert(
              RecurringOccurrencesCompanion.insert(
                recurringTransactionId: rule.id,
                year: dueDate.year,
                month: dueDate.month,
                transactionId: Value(
                  transactionId,
                ),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      },
    );
  }

  DateTime _occurrenceDate(
    int year,
    int month,
    int requestedDay,
  ) {
    final lastDay = DateTime(
      year,
      month + 1,
      0,
    ).day;

    return DateTime(
      year,
      month,
      math.min(
        requestedDay,
        lastDay,
      ),
    );
  }

  Value<String?> _notesValue(
    String? notes,
  ) {
    return Value(
      _cleanNotes(notes),
    );
  }

  String? _cleanNotes(
    String? notes,
  ) {
    final value = notes?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }
}
