import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';

@DataClassName('FinanceTransaction')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get description => text().withLength(
        min: 1,
        max: 120,
      )();

  IntColumn get amountInCents => integer()();

  TextColumn get type => text()();

  DateTimeColumn get date => dateTime()();

  IntColumn get accountId => integer().references(
        Accounts,
        #id,
      )();

  IntColumn get categoryId => integer().references(
        Categories,
        #id,
      )();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}
