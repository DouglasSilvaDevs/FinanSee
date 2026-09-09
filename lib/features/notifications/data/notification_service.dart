import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _notificationTapController =
      StreamController<String>.broadcast();

  Stream<String> get notificationTapStream => _notificationTapController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Inicializa banco de fusos horários.
    tz.initializeTimeZones();

    try {
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();

      final location = tz.getLocation(
        currentTimeZone,
      );

      tz.setLocalLocation(
        location,
      );

      debugPrint(
        'Timezone configurado: $currentTimeZone',
      );
    } catch (error) {
      debugPrint(
        'Não foi possível configurar timezone: $error',
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(
    NotificationResponse response,
  ) {
    final payload = response.payload;

    debugPrint(
      'Notificação tocada: $payload',
    );

    if (payload == null || payload.isEmpty) {
      return;
    }

    _notificationTapController.add(
      payload,
    );
  }

  Future<String?> getLaunchPayload() async {
    await initialize();

    final details = await _plugin.getNotificationAppLaunchDetails();

    if (details?.didNotificationLaunchApp != true) {
      return null;
    }

    return details?.notificationResponse?.payload;
  }

  void dispose() {
    _notificationTapController.close();
  }

  Future<bool> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      return notificationsEnabled();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      return granted ?? false;
    }

    return true;
  }

  Future<bool> notificationsEnabled() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }

    return true;
  }

  //
  // ORÇAMENTO - 80%
  //
  Future<bool> showBudgetWarning({
    required int notificationId,
    required String categoryName,
    required int percentage,
    required String remaining,
  }) async {
    if (!await notificationsEnabled()) {
      return false;
    }

    const android = AndroidNotificationDetails(
      'budget_alerts',
      'Alertas de orçamento',
      channelDescription:
          'Avisos quando seus orçamentos estão próximos do limite.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: android,
    );

    await _plugin.show(
      notificationId,
      'Orçamento próximo do limite',
      '$categoryName já está em $percentage%. $remaining.',
      details,
      payload: 'budgets',
    );

    return true;
  }

  //
  // ORÇAMENTO - 100%
  //
  Future<bool> showBudgetReached({
    required int notificationId,
    required String categoryName,
    required String message,
  }) async {
    if (!await notificationsEnabled()) {
      return false;
    }

    const android = AndroidNotificationDetails(
      'budget_critical_alerts',
      'Limites de orçamento',
      channelDescription:
          'Avisos quando um orçamento chega ou ultrapassa o limite.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: android,
    );

    await _plugin.show(
      notificationId,
      'Atenção ao orçamento',
      '$categoryName: $message',
      details,
      payload: 'budgets',
    );

    return true;
  }

  //
  // RECORRÊNCIA
  //
  Future<void> scheduleRecurringReminder({
    required int notificationId,
    required DateTime scheduledAt,
    required int ruleId,
    required String description,
    required String amount,
    required String accountName,
  }) async {
    await initialize();

    if (!await notificationsEnabled()) {
      return;
    }

    final scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
      scheduledAt.hour,
      scheduledAt.minute,
    );

    final now = tz.TZDateTime.now(
      tz.local,
    );

    if (!scheduledDate.isAfter(now)) {
      return;
    }

    const android = AndroidNotificationDetails(
      'recurring_reminders',
      'Lembretes de recorrências',
      channelDescription:
          'Avisos sobre receitas e despesas recorrentes próximas do vencimento.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: android,
      iOS: ios,
    );

    await _plugin.zonedSchedule(
      notificationId,
      'Vence amanhã',
      '$description • $amount • $accountName',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'recurring:$ruleId',
    );

    debugPrint(
      'Lembrete agendado: '
      '$description -> $scheduledDate',
    );
  }

  //
  // Remove somente notificações agendadas
  // das recorrências.
  //
  Future<void> cancelRecurringReminders() async {
    await initialize();

    final pending = await _plugin.pendingNotificationRequests();

    for (final notification in pending) {
      final payload = notification.payload;

      if (payload != null &&
          payload.startsWith(
            'recurring:',
          )) {
        await _plugin.cancel(
          notification.id,
        );
      }
    }
  }

  Future<int> pendingRecurringReminderCount() async {
    await initialize();

    final pending = await _plugin.pendingNotificationRequests();

    return pending.where(
      (notification) {
        return notification.payload?.startsWith(
              'recurring:',
            ) ??
            false;
      },
    ).length;
  }

  Future<bool> showGoalDeadline({
    required int notificationId,
    required int goalId,
    required String goalName,
    required int daysRemaining,
    required String remainingAmount,
  }) async {
    if (!await notificationsEnabled()) {
      return false;
    }

    final String title;

    if (daysRemaining <= 0) {
      title = 'Sua meta vence hoje';
    } else if (daysRemaining == 1) {
      title = 'Sua meta vence amanhã';
    } else {
      title = 'Prazo da meta se aproximando';
    }

    final String body;

    if (daysRemaining <= 0) {
      body =
          '$goalName vence hoje. Faltam $remainingAmount para alcançar o objetivo.';
    } else if (daysRemaining == 1) {
      body =
          '$goalName vence amanhã. Faltam $remainingAmount para alcançar o objetivo.';
    } else {
      body =
          '$goalName vence em $daysRemaining dias. Faltam $remainingAmount para alcançar o objetivo.';
    }

    const android = AndroidNotificationDetails(
      'goal_deadline_alerts',
      'Prazos de metas',
      channelDescription:
          'Avisos quando o prazo de uma meta financeira está próximo.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: android,
      iOS: ios,
    );

    await _plugin.show(
      notificationId,
      title,
      body,
      details,
      payload: 'goal:$goalId',
    );

    return true;
  }

  Future<bool> showGoalCompleted({
    required int notificationId,
    required int goalId,
    required String goalName,
  }) async {
    if (!await notificationsEnabled()) {
      return false;
    }

    const android = AndroidNotificationDetails(
      'goal_completed_alerts',
      'Metas alcançadas',
      channelDescription: 'Avisos quando uma meta financeira é alcançada.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: android,
      iOS: ios,
    );

    await _plugin.show(
      notificationId,
      'Meta alcançada! 🎉',
      'Você alcançou seu objetivo: $goalName.',
      details,
      payload: 'goal:$goalId',
    );

    return true;
  }
}
