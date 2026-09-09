import 'package:drift/drift.dart';

@DataClassName('FinanceAccount')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(
        min: 1,
        max: 60,
      )();

  TextColumn get type => text()();

  IntColumn get initialBalanceInCents => integer().withDefault(
        const Constant(0),
      )();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}
