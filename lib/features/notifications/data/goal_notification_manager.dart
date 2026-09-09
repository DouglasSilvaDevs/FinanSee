import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../goals/domain/goal_models.dart';
import 'notification_preferences_repository.dart';
import 'notification_service.dart';
import 'notification_inbox_repository.dart';

class GoalNotificationManager {
  final AppDatabase database;

  final NotificationService notificationService;

  final NotificationPreferencesRepository preferencesRepository;

  final NotificationInboxRepository inboxRepository;

  bool _checking = false;

  GoalNotificationManager({
    required this.database,
    required this.notificationService,
    required this.preferencesRepository,
    required this.inboxRepository,
  });

  Future<void> checkGoals(
    List<GoalProgress> goals,
  ) async {
    if (_checking) {
      return;
    }

    _checking = true;

    try {
      final preferences = await preferencesRepository.load();

      if (!preferences.goalAlertsEnabled) {
        return;
      }

      final enabled = await notificationService.notificationsEnabled();

      if (!enabled) {
        return;
      }

      for (final goal in goals) {
        if (goal.isArchived) {
          continue;
        }

        await _checkGoal(
          goal,
        );
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _checkGoal(
    GoalProgress goal,
  ) async {
    final state = await _getState(
      goal.id,
    );

    final notified7Days = state?.notifiedDeadline7Days ?? false;

    final notified1Day = state?.notifiedDeadline1Day ?? false;

    final notifiedCompleted = state?.notifiedCompleted ?? false;

    //
    // ==========================================
    // META CONCLUÍDA
    // ==========================================
    //
    if (goal.isCompleted) {
      if (!notifiedCompleted) {
        final shown = await notificationService.showGoalCompleted(
          notificationId: _notificationId(
            goal.id,
            3,
          ),
          goalId: goal.id,
          goalName: goal.name,
        );

        if (shown) {
          await inboxRepository.upsertNotification(
            uniqueKey: 'goal:${goal.id}:completed',
            type: 'goal',
            title: 'Meta alcançada! 🎉',
            message: 'Você alcançou seu objetivo: ${goal.name}.',
            route: '/goals/${goal.id}',
          );
          await _saveState(
            goalId: goal.id,
            notifiedDeadline7Days: notified7Days,
            notifiedDeadline1Day: notified1Day,
            notifiedCompleted: true,
          );
        }
      }

      //
      // Meta alcançada não precisa
      // de alerta de prazo.
      //
      return;
    }

    //
    // Sem prazo.
    //
    if (goal.deadline == null) {
      return;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final deadline = DateTime(
      goal.deadline!.year,
      goal.deadline!.month,
      goal.deadline!.day,
    );

    final daysRemaining = deadline.difference(today).inDays;

    //
    // Prazo já passou.
    //
    if (daysRemaining < 0) {
      return;
    }

    //
    // ==========================================
    // 1 DIA / HOJE
    // ==========================================
    //
    if (daysRemaining <= 1 && !notified1Day) {
      final shown = await notificationService.showGoalDeadline(
        notificationId: _notificationId(
          goal.id,
          2,
        ),
        goalId: goal.id,
        goalName: goal.name,
        daysRemaining: daysRemaining,
        remainingAmount: _money(
          goal.remainingInCents,
        ),
      );

      if (shown) {
        await inboxRepository.upsertNotification(
          uniqueKey: 'goal:${goal.id}:deadline1',
          type: 'goal',
          title: daysRemaining == 0
              ? 'Sua meta vence hoje'
              : 'Sua meta vence amanhã',
          message: '${goal.name} está próxima do prazo. '
              'Faltam ${_money(goal.remainingInCents)}.',
          route: '/goals/${goal.id}',
        );
        await _saveState(
          goalId: goal.id,
          notifiedDeadline7Days: true,
          notifiedDeadline1Day: true,
          notifiedCompleted: notifiedCompleted,
        );
      }

      return;
    }

    //
    // ==========================================
    // 7 DIAS
    // ==========================================
    //
    if (daysRemaining <= 7 && !notified7Days) {
      final shown = await notificationService.showGoalDeadline(
        notificationId: _notificationId(
          goal.id,
          1,
        ),
        goalId: goal.id,
        goalName: goal.name,
        daysRemaining: daysRemaining,
        remainingAmount: _money(
          goal.remainingInCents,
        ),
      );

      if (shown) {
        await inboxRepository.upsertNotification(
          uniqueKey: 'goal:${goal.id}:deadline7',
          type: 'goal',
          title: 'Prazo da meta se aproximando',
          message: '${goal.name} vence em $daysRemaining dias. '
              'Faltam ${_money(goal.remainingInCents)}.',
          route: '/goals/${goal.id}',
        );
        await _saveState(
          goalId: goal.id,
          notifiedDeadline7Days: true,
          notifiedDeadline1Day: notified1Day,
          notifiedCompleted: notifiedCompleted,
        );
      }
    }
  }

  Future<GoalNotificationState?> _getState(
    int goalId,
  ) {
    return (database.select(
      database.goalNotificationStates,
    )..where(
            (table) => table.goalId.equals(
              goalId,
            ),
          ))
        .getSingleOrNull();
  }

  Future<void> _saveState({
    required int goalId,
    required bool notifiedDeadline7Days,
    required bool notifiedDeadline1Day,
    required bool notifiedCompleted,
  }) async {
    final existing = await _getState(
      goalId,
    );

    if (existing == null) {
      await database
          .into(
            database.goalNotificationStates,
          )
          .insert(
            GoalNotificationStatesCompanion.insert(
              //
              // Assim como aconteceu no
              // BudgetNotificationState,
              // o Drift espera Value<int>.
              //
              goalId: Value(
                goalId,
              ),

              notifiedDeadline7Days: Value(
                notifiedDeadline7Days,
              ),

              notifiedDeadline1Day: Value(
                notifiedDeadline1Day,
              ),

              notifiedCompleted: Value(
                notifiedCompleted,
              ),
            ),
          );

      return;
    }

    await (database.update(
      database.goalNotificationStates,
    )..where(
            (table) => table.goalId.equals(
              goalId,
            ),
          ))
        .write(
      GoalNotificationStatesCompanion(
        notifiedDeadline7Days: Value(
          notifiedDeadline7Days,
        ),
        notifiedDeadline1Day: Value(
          notifiedDeadline1Day,
        ),
        notifiedCompleted: Value(
          notifiedCompleted,
        ),
        updatedAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  int _notificationId(
    int goalId,
    int type,
  ) {
    //
    // Faixa separada das notificações
    // de orçamento e recorrências.
    //
    return 400000000 + ((goalId % 100000) * 10) + type;
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
