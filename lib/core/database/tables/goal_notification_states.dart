import 'package:drift/drift.dart';

import 'financial_goals.dart';

@DataClassName('GoalNotificationState')
class GoalNotificationStates extends Table {
  IntColumn get goalId => integer().references(
        FinancialGoals,
        #id,
        onDelete: KeyAction.cascade,
      )();

  BoolColumn get notifiedDeadline7Days => boolean().withDefault(
        const Constant(false),
      )();

  BoolColumn get notifiedDeadline1Day => boolean().withDefault(
        const Constant(false),
      )();

  BoolColumn get notifiedCompleted => boolean().withDefault(
        const Constant(false),
      )();

  DateTimeColumn get updatedAt => dateTime().withDefault(
        currentDateAndTime,
      )();

  @override
  Set<Column<Object>> get primaryKey => {
        goalId,
      };
}
