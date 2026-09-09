import 'package:shared_preferences/shared_preferences.dart';

import '../domain/notification_preferences.dart';

class NotificationPreferencesRepository {
  static const _budgetAlertsKey = 'notification_budget_alerts';

  static const _recurringRemindersKey = 'notification_recurring_reminders';

  static const _goalAlertsKey = 'notification_goal_alerts';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<NotificationPreferences> load() async {
    final budgetAlerts = await _preferences.getBool(
      _budgetAlertsKey,
    );

    final recurringReminders = await _preferences.getBool(
      _recurringRemindersKey,
    );

    final goalAlerts = await _preferences.getBool(
      _goalAlertsKey,
    );

    return NotificationPreferences(
      budgetAlertsEnabled: budgetAlerts ?? true,
      recurringRemindersEnabled: recurringReminders ?? true,
      goalAlertsEnabled: goalAlerts ?? true,
    );
  }

  Future<void> setBudgetAlertsEnabled(
    bool enabled,
  ) async {
    await _preferences.setBool(
      _budgetAlertsKey,
      enabled,
    );
  }

  Future<void> setRecurringRemindersEnabled(
    bool enabled,
  ) async {
    await _preferences.setBool(
      _recurringRemindersKey,
      enabled,
    );
  }

  Future<void> setGoalAlertsEnabled(
    bool enabled,
  ) async {
    await _preferences.setBool(
      _goalAlertsKey,
      enabled,
    );
  }
}
