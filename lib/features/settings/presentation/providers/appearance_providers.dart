import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/appearance_preferences_repository.dart';

final appearancePreferencesRepositoryProvider =
    Provider<AppearancePreferencesRepository>((ref) {
  return AppearancePreferencesRepository();
});

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    final repository = ref.watch(
      appearancePreferencesRepositoryProvider,
    );

    return ThemeModeController(
      repository,
    );
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  final AppearancePreferencesRepository _repository;

  ThemeModeController(
    this._repository,
  ) : super(
          ThemeMode.system,
        ) {
    _load();
  }

  Future<void> _load() async {
    try {
      state = await _repository.loadThemeMode();
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(
    ThemeMode mode,
  ) async {
    state = mode;

    await _repository.saveThemeMode(
      mode,
    );
  }
}
