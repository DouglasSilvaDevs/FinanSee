import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class NotificationInboxRepository {
  final AppDatabase database;

  NotificationInboxRepository(
    this.database,
  );

  Stream<List<FinanSeeNotification>> watchNotifications() {
    final now = DateTime.now();

    final query = database.select(database.appNotifications)
      ..where(
        (table) =>
            table.scheduledFor.isNull() |
            table.scheduledFor.isSmallerOrEqualValue(
              now,
            ),
      )
      ..orderBy([
        (table) => OrderingTerm.desc(
              table.createdAt,
            ),
      ]);

    return query.watch();
  }

  Stream<int> watchUnreadCount() {
    final now = DateTime.now();

    final countExpression = database.appNotifications.id.count();

    final query = database.selectOnly(
      database.appNotifications,
    )
      ..addColumns([
        countExpression,
      ])
      ..where(
        database.appNotifications.isRead.equals(
              false,
            ) &
            (database.appNotifications.scheduledFor.isNull() |
                database.appNotifications.scheduledFor.isSmallerOrEqualValue(
                  now,
                )),
      );

    return query.watch().map(
      (row) {
        if (row.isEmpty) {
          return 0;
        }

        return row.first.read(
              countExpression,
            ) ??
            0;
      },
    );
  }

  Future<void> upsertNotification({
    required String uniqueKey,
    required String type,
    required String title,
    required String message,
    String? route,
    DateTime? scheduledFor,
  }) async {
    final existing = await (database.select(
      database.appNotifications,
    )..where(
            (table) => table.uniqueKey.equals(
              uniqueKey,
            ),
          ))
        .getSingleOrNull();

    if (existing == null) {
      await database.into(database.appNotifications).insert(
            AppNotificationsCompanion.insert(
              type: type,
              title: title,
              message: message,
              uniqueKey: uniqueKey,
              route: Value(route),
              scheduledFor: Value(
                scheduledFor,
              ),
            ),
          );

      return;
    }

    await (database.update(
      database.appNotifications,
    )..where(
            (table) => table.id.equals(
              existing.id,
            ),
          ))
        .write(
      AppNotificationsCompanion(
        type: Value(type),
        title: Value(title),
        message: Value(message),
        route: Value(route),
        scheduledFor: Value(
          scheduledFor,
        ),
      ),
    );
  }

  Future<void> markAsRead(
    int id,
  ) async {
    await (database.update(
      database.appNotifications,
    )..where(
            (table) => table.id.equals(id),
          ))
        .write(
      const AppNotificationsCompanion(
        isRead: Value(true),
      ),
    );
  }

  Future<void> markAllAsRead() async {
    final now = DateTime.now();

    await (database.update(
      database.appNotifications,
    )..where(
            (table) =>
                table.isRead.equals(false) &
                (table.scheduledFor.isNull() |
                    table.scheduledFor.isSmallerOrEqualValue(
                      now,
                    )),
          ))
        .write(
      const AppNotificationsCompanion(
        isRead: Value(true),
      ),
    );
  }

  Future<void> deleteFutureRecurringNotifications() async {
    final now = DateTime.now();

    await (database.delete(
      database.appNotifications,
    )..where(
            (table) =>
                table.type.equals(
                  'recurring',
                ) &
                table.scheduledFor.isNotNull() &
                table.scheduledFor.isBiggerThanValue(
                  now,
                ),
          ))
        .go();
  }

  Future<void> deleteNotification(
    int id,
  ) async {
    await (database.delete(
      database.appNotifications,
    )..where(
            (table) => table.id.equals(id),
          ))
        .go();
  }

  Future<void> deleteAllVisibleNotifications() async {
    final now = DateTime.now();

    await (database.delete(
      database.appNotifications,
    )..where(
            (table) =>
                table.scheduledFor.isNull() |
                table.scheduledFor.isSmallerOrEqualValue(
                  now,
                ),
          ))
        .go();
  }
}
