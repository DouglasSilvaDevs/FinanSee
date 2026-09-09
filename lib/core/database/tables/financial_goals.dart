import 'package:drift/drift.dart';

@DataClassName('FinancialGoal')
class FinancialGoals extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(
        min: 1,
        max: 100,
      )();

  IntColumn get targetInCents => integer()();

  TextColumn get icon => text().nullable()();

  DateTimeColumn get deadline => dateTime().nullable()();

  BoolColumn get isArchived => boolean().withDefault(
        const Constant(false),
      )();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}
