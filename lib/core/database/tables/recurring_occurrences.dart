import 'package:drift/drift.dart';

import 'recurring_transactions.dart';
import 'transactions.dart';

@DataClassName('RecurringOccurrence')
class RecurringOccurrences extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get recurringTransactionId => integer().references(
        RecurringTransactions,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get year => integer()();

  IntColumn get month => integer()();

  IntColumn get transactionId => integer().nullable().references(
        Transactions,
        #id,
        onDelete: KeyAction.setNull,
      )();

  DateTimeColumn get generatedAt => dateTime().withDefault(
        currentDateAndTime,
      )();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {
          recurringTransactionId,
          year,
          month,
        },
      ];
}
