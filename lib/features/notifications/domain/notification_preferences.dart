class NotificationPreferences {
  final bool budgetAlertsEnabled;
  final bool recurringRemindersEnabled;
  final bool goalAlertsEnabled;

  const NotificationPreferences({
    this.budgetAlertsEnabled = true,
    this.recurringRemindersEnabled = true,
    this.goalAlertsEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? budgetAlertsEnabled,
    bool? recurringRemindersEnabled,
    bool? goalAlertsEnabled,
  }) {
    return NotificationPreferences(
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      recurringRemindersEnabled:
          recurringRemindersEnabled ?? this.recurringRemindersEnabled,
      goalAlertsEnabled: goalAlertsEnabled ?? this.goalAlertsEnabled,
    );
  }
}
