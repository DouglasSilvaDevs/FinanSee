import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPreferencesRepository {
  static const String _completedKey =
      'onboarding_completed';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<bool> isCompleted() async {
    return await _preferences.getBool(
          _completedKey,
        ) ??
        false;
  }

  Future<void> setCompleted() async {
    await _preferences.setBool(
      _completedKey,
      true,
    );
  }

  Future<void> reset() async {
    await _preferences.remove(
      _completedKey,
    );
  }
}
