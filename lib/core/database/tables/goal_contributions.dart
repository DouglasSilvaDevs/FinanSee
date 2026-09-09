import 'package:drift/drift.dart';

import 'financial_goals.dart';

@DataClassName('GoalContribution')
class GoalContributions extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get goalId => integer().references(
        FinancialGoals,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get amountInCents => integer()();

  DateTimeColumn get date => dateTime()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}
