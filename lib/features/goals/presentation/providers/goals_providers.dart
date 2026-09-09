import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/goals_repository.dart';
import '../../domain/goal_models.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return GoalsRepository(
    database,
  );
});

final goalsProvider = StreamProvider<List<GoalProgress>>((ref) {
  final repository = ref.watch(
    goalsRepositoryProvider,
  );

  return repository.watchGoals();
});

final goalContributionsProvider =
    StreamProvider.family<List<GoalContribution>, int>((ref, goalId) {
  final repository = ref.watch(
    goalsRepositoryProvider,
  );

  return repository.watchContributions(
    goalId,
  );
});
