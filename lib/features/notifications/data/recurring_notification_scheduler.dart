import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../recurring/domain/recurring_models.dart';
import 'notification_preferences_repository.dart';
import 'notification_service.dart';
import 'notification_inbox_repository.dart';

class RecurringNotificationScheduler {
  final NotificationService notificationService;
  final NotificationPreferencesRepository preferencesRepository;
  final NotificationInboxRepository inboxRepository;

  bool _syncing = false;

  RecurringNotificationScheduler({
    required this.notificationService,
    required this.preferencesRepository,
    required this.inboxRepository,
  });

  Future<void> sync(
    List<RecurringTransactionDetails> items,
  ) async {
    if (_syncing) {
      return;
    }

    _syncing = true;

    try {
      //
      // Sempre removemos os agendamentos anteriores.
      //
      await notificationService.cancelRecurringReminders();
      await inboxRepository.deleteFutureRecurringNotifications();

      final preferences = await preferencesRepository.load();

      //
      // Se o usuário desativou,
      // paramos aqui.
      //
      if (!preferences.recurringRemindersEnabled) {
        print(
          'Lembretes de recorrências desativados.',
        );

        return;
      }

      final enabled = await notificationService.notificationsEnabled();

      if (!enabled) {
        return;
      }

      final now = DateTime.now();

      var scheduledCount = 0;

      // restante do método continua igual...

      for (final item in items) {
        final rule = item.rule;

        if (!rule.isActive) {
          continue;
        }

        //
        // Agenda os próximos 6 meses.
        //
        for (var offset = 0; offset < 6; offset++) {
          final month = DateTime(
            now.year,
            now.month + offset,
            1,
          );

          final startMonth = DateTime(
            rule.startsAt.year,
            rule.startsAt.month,
            1,
          );

          if (month.isBefore(
            startMonth,
          )) {
            continue;
          }

          final dueDate = _occurrenceDate(
            month.year,
            month.month,
            rule.dayOfMonth,
          );

          final today = DateTime(
            now.year,
            now.month,
            now.day,
          );

          //
          // Vencimento já passou.
          //
          if (dueDate.isBefore(
            today,
          )) {
            continue;
          }

          //
          // Lembrete:
          // um dia antes às 09:00.
          //
          var reminderDate = DateTime(
            dueDate.year,
            dueDate.month,
            dueDate.day,
            9,
          ).subtract(
            const Duration(
              days: 1,
            ),
          );

          //
          // Caso o vencimento seja amanhã,
          // mas já tenha passado das 09:00 hoje,
          // ainda mostramos o lembrete hoje.
          //
          final tomorrow = today.add(
            const Duration(
              days: 1,
            ),
          );

          if (!reminderDate.isAfter(now) &&
              _sameDay(
                dueDate,
                tomorrow,
              )) {
            reminderDate = now.add(
              const Duration(
                seconds: 10,
              ),
            );
          }

          if (!reminderDate.isAfter(now)) {
            continue;
          }

          final notificationId = _notificationId(
            rule.id,
            offset,
          );

          await notificationService.scheduleRecurringReminder(
            notificationId: notificationId,
            scheduledAt: reminderDate,
            ruleId: rule.id,
            description: rule.description,
            amount: _money(
              rule.amountInCents,
            ),
            accountName: item.account.name,
          );
          await inboxRepository.upsertNotification(
            uniqueKey: 'recurring:${rule.id}:${dueDate.year}-${dueDate.month}',
            type: 'recurring',
            title: 'Vence amanhã',
            message: '${rule.description} • '
                '${_money(rule.amountInCents)} • '
                '${item.account.name}',
            route: '/recurring',
            scheduledFor: reminderDate,
          );

          scheduledCount++;
        }
      }

      final pending = await notificationService.pendingRecurringReminderCount();

      print(
        'Recorrências: '
        '$scheduledCount lembretes agendados. '
        'Pendentes: $pending',
      );
    } finally {
      _syncing = false;
    }
  }

  DateTime _occurrenceDate(
    int year,
    int month,
    int requestedDay,
  ) {
    final lastDay = DateTime(
      year,
      month + 1,
      0,
    ).day;

    return DateTime(
      year,
      month,
      math.min(
        requestedDay,
        lastDay,
      ),
    );
  }

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _notificationId(
    int ruleId,
    int monthOffset,
  ) {
    //
    // Reservamos uma faixa diferente
    // para notificações recorrentes.
    //
    return 300000000 + ((ruleId % 10000) * 100) + monthOffset;
  }
}

String _money(
  int cents,
) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(
    cents / 100,
  );
}
