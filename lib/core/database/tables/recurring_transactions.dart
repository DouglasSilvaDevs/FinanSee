import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';

@DataClassName('RecurringTransactionRule')
class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().withLength(
        min: 1,
        max: 120,
      )();

  IntColumn get amountInCents => integer()();

  TextColumn get type => text()();

  IntColumn get dayOfMonth => integer().check(
        dayOfMonth.isBetweenValues(
          1,
          31,
        ),
      )();

  IntColumn get accountId => integer().references(
        Accounts,
        #id,
      )();

  IntColumn get categoryId => integer().references(
        Categories,
        #id,
      )();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get startsAt => dateTime()();

  BoolColumn get isActive => boolean().withDefault(
        const Constant(true),
      )();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}
