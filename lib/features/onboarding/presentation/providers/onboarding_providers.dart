import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/onboarding_preferences_repository.dart';

final onboardingPreferencesRepositoryProvider =
    Provider<OnboardingPreferencesRepository>((ref) {
  return OnboardingPreferencesRepository();
});

final onboardingProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<bool>>(
  (ref) {
    final repository = ref.watch(
      onboardingPreferencesRepositoryProvider,
    );

    return OnboardingController(
      repository,
    );
  },
);

class OnboardingController extends StateNotifier<AsyncValue<bool>> {
  final OnboardingPreferencesRepository _repository;

  OnboardingController(
    this._repository,
  ) : super(
          const AsyncValue.loading(),
        ) {
    _load();
  }

  Future<void> _load() async {
    try {
      final completed = await _repository.isCompleted();

      state = AsyncValue.data(
        completed,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }

  Future<void> complete() async {
    await _repository.setCompleted();

    state = const AsyncValue.data(
      true,
    );
  }

  //
  // Útil durante o desenvolvimento.
  //
  Future<void> reset() async {
    await _repository.reset();

    state = const AsyncValue.data(
      false,
    );
  }
}
