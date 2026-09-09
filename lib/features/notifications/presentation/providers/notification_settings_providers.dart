import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/notification_preferences_repository.dart';
import '../../domain/notification_preferences.dart';

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
  return NotificationPreferencesRepository();
});

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsController, AsyncValue<NotificationPreferences>>(
  (ref) {
    final repository = ref.watch(
      notificationPreferencesRepositoryProvider,
    );

    return NotificationSettingsController(
      repository,
    );
  },
);

class NotificationSettingsController
    extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final NotificationPreferencesRepository _repository;

  NotificationSettingsController(
    this._repository,
  ) : super(
          const AsyncValue.loading(),
        ) {
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _repository.load();

      state = AsyncValue.data(
        settings,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }

  Future<void> setBudgetAlerts(
    bool enabled,
  ) async {
    final current = state.asData?.value ?? const NotificationPreferences();

    final updated = current.copyWith(
      budgetAlertsEnabled: enabled,
    );

    state = AsyncValue.data(
      updated,
    );

    try {
      await _repository.setBudgetAlertsEnabled(
        enabled,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }

  Future<void> setRecurringReminders(
    bool enabled,
  ) async {
    final current = state.asData?.value ?? const NotificationPreferences();

    final updated = current.copyWith(
      recurringRemindersEnabled: enabled,
    );

    state = AsyncValue.data(
      updated,
    );

    try {
      await _repository.setRecurringRemindersEnabled(
        enabled,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }

  Future<void> setGoalAlerts(
    bool enabled,
  ) async {
    final current = state.asData?.value ?? const NotificationPreferences();

    final updated = current.copyWith(
      goalAlertsEnabled: enabled,
    );

    state = AsyncValue.data(
      updated,
    );

    try {
      await _repository.setGoalAlertsEnabled(
        enabled,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }
}
