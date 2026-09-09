import 'package:drift/drift.dart';

@DataClassName('FinanSeeNotification')
class AppNotifications extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get type => text()();

  TextColumn get title => text()();

  TextColumn get message => text()();

  TextColumn get route => text().nullable()();

  //
  // Evita criar a mesma notificação duas vezes.
  //
  TextColumn get uniqueKey => text().unique()();

  //
  // Para recorrências podemos registrar uma
  // notificação que só ficará visível no futuro.
  //
  DateTimeColumn get scheduledFor => dateTime().nullable()();

  BoolColumn get isRead => boolean().withDefault(
        const Constant(false),
      )();

  DateTimeColumn get createdAt => dateTime().withDefault(
        currentDateAndTime,
      )();
}
