import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../budgets/domain/budget_models.dart';
import 'notification_service.dart';
import 'notification_preferences_repository.dart';
import 'notification_inbox_repository.dart';

class BudgetNotificationManager {
  final AppDatabase database;
  final NotificationService notificationService;
  final NotificationPreferencesRepository preferencesRepository;
  final NotificationInboxRepository inboxRepository;

  bool _checking = false;

  BudgetNotificationManager({
    required this.database,
    required this.notificationService,
    required this.preferencesRepository,
    required this.inboxRepository,
  });

  Future<void> checkBudgets(
    List<BudgetProgress> budgets,
  ) async {
    if (_checking) {
      return;
    }

    _checking = true;

    try {
      final preferences = await preferencesRepository.load();

      if (!preferences.budgetAlertsEnabled) {
        return;
      }
      final enabled = await notificationService.notificationsEnabled();

      if (!enabled) {
        return;
      }

      for (final budget in budgets) {
        await _checkBudget(
          budget,
        );
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _checkBudget(
    BudgetProgress budget,
  ) async {
    final state = await _getState(
      budget.budgetId,
    );

    final notified80 = state?.notifiedAt80 ?? false;

    final notified100 = state?.notifiedAt100 ?? false;

    //
    // Se pulou direto de 70% para 110%,
    // mostramos apenas o alerta mais importante.
    //
    if (budget.progress >= 1.0 && !notified100) {
      final shown = await notificationService.showBudgetReached(
        notificationId: _notificationId(
          budget.budgetId,
          100,
        ),
        categoryName: budget.categoryName,
        message: _criticalMessage(
          budget,
        ),
      );

      if (shown) {
        await inboxRepository.upsertNotification(
          uniqueKey: 'budget:${budget.budgetId}:100',
          type: 'budget',
          title: 'Atenção ao orçamento',
          message: '${budget.categoryName}: ${_criticalMessage(budget)}',
          route: '/budgets',
        );
        await _saveState(
          budgetId: budget.budgetId,
          notifiedAt80: true,
          notifiedAt100: true,
        );
      }

      return;
    }

    if (budget.progress >= 0.8 && !notified80) {
      final percentage = (budget.progress * 100).round();

      final shown = await notificationService.showBudgetWarning(
        notificationId: _notificationId(
          budget.budgetId,
          80,
        ),
        categoryName: budget.categoryName,
        percentage: percentage,
        remaining: 'Restam ${_money(budget.remainingInCents)}',
      );

      if (shown) {
        await inboxRepository.upsertNotification(
          uniqueKey: 'budget:${budget.budgetId}:80',
          type: 'budget',
          title: 'Orçamento próximo do limite',
          message: '${budget.categoryName} já está em $percentage%. '
              'Restam ${_money(budget.remainingInCents)}.',
          route: '/budgets',
        );
        await _saveState(
          budgetId: budget.budgetId,
          notifiedAt80: true,
          notifiedAt100: notified100,
        );
      }
    }
  }

  String _criticalMessage(
    BudgetProgress budget,
  ) {
    if (budget.spentInCents > budget.limitInCents) {
      final exceeded = budget.spentInCents - budget.limitInCents;

      return 'você ultrapassou o limite em ${_money(exceeded)}.';
    }

    return 'você atingiu 100% do limite mensal.';
  }

  Future<BudgetNotificationState?> _getState(
    int budgetId,
  ) {
    return (database.select(
      database.budgetNotificationStates,
    )..where(
            (table) => table.budgetId.equals(
              budgetId,
            ),
          ))
        .getSingleOrNull();
  }

  Future<void> _saveState({
    required int budgetId,
    required bool notifiedAt80,
    required bool notifiedAt100,
  }) async {
    final existing = await _getState(
      budgetId,
    );

    if (existing == null) {
      await database
          .into(
            database.budgetNotificationStates,
          )
          .insert(
            BudgetNotificationStatesCompanion.insert(
              budgetId: Value(
                budgetId,
              ),
              notifiedAt80: Value(
                notifiedAt80,
              ),
              notifiedAt100: Value(
                notifiedAt100,
              ),
            ),
          );

      return;
    }

    await (database.update(
      database.budgetNotificationStates,
    )..where(
            (table) => table.budgetId.equals(
              budgetId,
            ),
          ))
        .write(
      BudgetNotificationStatesCompanion(
        notifiedAt80: Value(
          notifiedAt80,
        ),
        notifiedAt100: Value(
          notifiedAt100,
        ),
        updatedAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  int _notificationId(
    int budgetId,
    int threshold,
  ) {
    return budgetId * 10 + (threshold == 100 ? 2 : 1);
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
