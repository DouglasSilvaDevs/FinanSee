import 'package:drift/drift.dart';

import 'budgets.dart';

@DataClassName('BudgetNotificationState')
class BudgetNotificationStates extends Table {
  IntColumn get budgetId => integer().references(
        Budgets,
        #id,
        onDelete: KeyAction.cascade,
      )();

  BoolColumn get notifiedAt80 => boolean().withDefault(
        const Constant(false),
      )();

  BoolColumn get notifiedAt100 => boolean().withDefault(
        const Constant(false),
      )();

  DateTimeColumn get updatedAt => dateTime().withDefault(
        currentDateAndTime,
      )();

  @override
  Set<Column<Object>> get primaryKey => {
        budgetId,
      };
}
