import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../data/accounts_repository.dart';
import '../../domain/account_models.dart';
import '../../domain/account_details.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  return AccountsRepository(
    database,
  );
});

final accountsWithBalanceProvider =
    StreamProvider<List<AccountWithBalance>>((ref) {
  final repository = ref.watch(
    accountsRepositoryProvider,
  );

  return repository.watchAccountsWithBalance();
});

final accountDetailsProvider = StreamProvider.family<AccountDetailsData?, int>(
  (ref, accountId) {
    final repository = ref.watch(
      accountsRepositoryProvider,
    );

    return repository.watchAccountDetails(
      accountId,
    );
  },
);
