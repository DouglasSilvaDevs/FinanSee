import 'package:drift/drift.dart';

@DataClassName('FinanceCategory')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(
        min: 1,
        max: 50,
      )();

  TextColumn get type => text()();

  TextColumn get icon => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}
