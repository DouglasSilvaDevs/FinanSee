import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/recurring_transactions_repository.dart';
import '../../domain/recurring_models.dart';

final recurringTransactionsRepositoryProvider =
    Provider<RecurringTransactionsRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return RecurringTransactionsRepository(
    database,
  );
});

final recurringTransactionsProvider =
    StreamProvider<List<RecurringTransactionDetails>>((ref) {
  final repository = ref.watch(
    recurringTransactionsRepositoryProvider,
  );

  return repository.watchRecurringTransactions();
});
