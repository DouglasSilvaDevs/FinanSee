import 'package:drift/drift.dart';

import 'categories.dart';

@DataClassName('MonthlyBudget')
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get categoryId => integer().references(
        Categories,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get year => integer()();

  IntColumn get month => integer()();

  IntColumn get limitInCents => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}
