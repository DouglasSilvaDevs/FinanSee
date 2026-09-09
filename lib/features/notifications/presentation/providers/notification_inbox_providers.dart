import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/notification_inbox_repository.dart';

final notificationInboxRepositoryProvider =
    Provider<NotificationInboxRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return NotificationInboxRepository(
    database,
  );
});

final notificationInboxProvider =
    StreamProvider<List<FinanSeeNotification>>((ref) {
  final repository = ref.watch(
    notificationInboxRepositoryProvider,
  );

  return repository.watchNotifications();
});

final notificationUnreadCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(
    notificationInboxRepositoryProvider,
  );

  return repository.watchUnreadCount();
});
