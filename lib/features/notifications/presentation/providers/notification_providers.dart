import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';

import '../../data/budget_notification_manager.dart';
import '../../data/goal_notification_manager.dart';
import '../../data/notification_service.dart';
import '../../data/recurring_notification_scheduler.dart';

import 'notification_inbox_providers.dart';
import 'notification_settings_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();

  ref.onDispose(
    service.dispose,
  );

  return service;
});

final budgetNotificationManagerProvider =
    Provider<BudgetNotificationManager>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  final notificationService = ref.watch(
    notificationServiceProvider,
  );

  final preferencesRepository = ref.watch(
    notificationPreferencesRepositoryProvider,
  );

  final inboxRepository = ref.watch(
    notificationInboxRepositoryProvider,
  );

  return BudgetNotificationManager(
    database: database,
    notificationService: notificationService,
    preferencesRepository: preferencesRepository,
    inboxRepository: inboxRepository,
  );
});

final recurringNotificationSchedulerProvider =
    Provider<RecurringNotificationScheduler>((ref) {
  final notificationService = ref.watch(
    notificationServiceProvider,
  );

  final preferencesRepository = ref.watch(
    notificationPreferencesRepositoryProvider,
  );

  final inboxRepository = ref.watch(
    notificationInboxRepositoryProvider,
  );

  return RecurringNotificationScheduler(
    notificationService: notificationService,
    preferencesRepository: preferencesRepository,
    inboxRepository: inboxRepository,
  );
});

final goalNotificationManagerProvider =
    Provider<GoalNotificationManager>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  final notificationService = ref.watch(
    notificationServiceProvider,
  );

  final preferencesRepository = ref.watch(
    notificationPreferencesRepositoryProvider,
  );

  final inboxRepository = ref.watch(
    notificationInboxRepositoryProvider,
  );

  return GoalNotificationManager(
    database: database,
    notificationService: notificationService,
    preferencesRepository: preferencesRepository,
    inboxRepository: inboxRepository,
  );
});
