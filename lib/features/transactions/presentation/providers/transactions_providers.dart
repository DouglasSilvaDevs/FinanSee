import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction_models.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return TransactionsRepository(
    database,
  );
});

final transactionsProvider = StreamProvider<List<FinanceTransaction>>((ref) {
  final repository = ref.watch(
    transactionsRepositoryProvider,
  );

  return repository.watchTransactions();
});

final detailedTransactionsProvider = StreamProvider<List<TransactionDetails>>((ref) {
  final repository = ref.watch(
    transactionsRepositoryProvider,
  );

  return repository.watchDetailedTransactions();
});

final recentTransactionsProvider = StreamProvider<List<FinanceTransaction>>((ref) {
  final repository = ref.watch(
    transactionsRepositoryProvider,
  );

  return repository.watchRecentTransactions();
});

final accountsProvider = StreamProvider<List<FinanceAccount>>((ref) {
  final repository = ref.watch(
    transactionsRepositoryProvider,
  );

  return repository.watchAccounts();
});

final categoriesByTypeProvider = StreamProvider.family<List<FinanceCategory>, String>((ref, type) {
  final repository = ref.watch(
    transactionsRepositoryProvider,
  );

  return repository.watchCategoriesByType(
    type,
  );
});
