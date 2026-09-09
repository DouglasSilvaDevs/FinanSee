import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/account_models.dart';
import '../domain/account_details.dart';

enum DeleteAccountResult {
  deleted,
  hasTransactions,
  hasRecurringTransactions,
  lastAccount,
}

class AccountsRepository {
  final AppDatabase database;

  AccountsRepository(
    this.database,
  );

  Stream<List<AccountWithBalance>> watchAccountsWithBalance() {
    final query = database.customSelect(
      '''
      SELECT
        a.id,
        a.name,
        a.type,
        a.initial_balance_in_cents,

        a.initial_balance_in_cents
        +
        COALESCE(
          SUM(
            CASE
              WHEN t.type = 'income'
                THEN t.amount_in_cents

              WHEN t.type = 'expense'
                THEN -t.amount_in_cents

              ELSE 0
            END
          ),
          0
        ) AS current_balance_in_cents

      FROM accounts a

      LEFT JOIN transactions t
        ON t.account_id = a.id

      GROUP BY
        a.id,
        a.name,
        a.type,
        a.initial_balance_in_cents

      ORDER BY a.name ASC
      ''',
      readsFrom: {
        database.accounts,
        database.transactions,
      },
    );

    return query.watch().map(
      (rows) {
        return rows.map(
          (row) {
            return AccountWithBalance(
              id: row.read<int>(
                'id',
              ),
              name: row.read<String>(
                'name',
              ),
              type: row.read<String>(
                'type',
              ),
              initialBalanceInCents: row.read<int>(
                'initial_balance_in_cents',
              ),
              currentBalanceInCents: row.read<int>(
                'current_balance_in_cents',
              ),
            );
          },
        ).toList();
      },
    );
  }

  Future<FinanceAccount?> getAccount(
    int accountId,
  ) {
    return (database.select(database.accounts)
          ..where(
            (table) => table.id.equals(
              accountId,
            ),
          ))
        .getSingleOrNull();
  }

  Future<int> createAccount({
    required String name,
    required String type,
    required int initialBalanceInCents,
  }) {
    return database.into(database.accounts).insert(
          AccountsCompanion.insert(
            name: name.trim(),
            type: type,
            initialBalanceInCents: Value(
              initialBalanceInCents,
            ),
          ),
        );
  }

  Future<void> updateAccount({
    required int accountId,
    required String name,
    required String type,
    required int initialBalanceInCents,
  }) async {
    await (database.update(database.accounts)
          ..where(
            (table) => table.id.equals(
              accountId,
            ),
          ))
        .write(
      AccountsCompanion(
        name: Value(
          name.trim(),
        ),
        type: Value(
          type,
        ),
        initialBalanceInCents: Value(
          initialBalanceInCents,
        ),
      ),
    );
  }

  Future<DeleteAccountResult> deleteAccount(
    int accountId,
  ) async {
    //
    // Não permitimos excluir a última conta.
    //
    final accountCount = await _countAccounts();

    if (accountCount <= 1) {
      return DeleteAccountResult.lastAccount;
    }

    //
    // Verifica transações normais.
    //
    final transactionCount = await _countTransactions(
      accountId,
    );

    if (transactionCount > 0) {
      return DeleteAccountResult.hasTransactions;
    }

    //
    // Verifica regras recorrentes.
    //
    final recurringCount = await _countRecurringTransactions(
      accountId,
    );

    if (recurringCount > 0) {
      return DeleteAccountResult.hasRecurringTransactions;
    }

    //
    // Conta sem dependências:
    // pode excluir.
    //
    await (database.delete(database.accounts)
          ..where(
            (table) => table.id.equals(
              accountId,
            ),
          ))
        .go();

    return DeleteAccountResult.deleted;
  }

  Future<int> _countAccounts() async {
    final countExpression = database.accounts.id.count();

    final query = database.selectOnly(
      database.accounts,
    )..addColumns([
        countExpression,
      ]);

    final row = await query.getSingle();

    return row.read(
          countExpression,
        ) ??
        0;
  }

  Future<int> _countTransactions(
    int accountId,
  ) async {
    final countExpression = database.transactions.id.count();

    final query = database.selectOnly(
      database.transactions,
    )
      ..addColumns([
        countExpression,
      ])
      ..where(
        database.transactions.accountId.equals(
          accountId,
        ),
      );

    final row = await query.getSingle();

    return row.read(
          countExpression,
        ) ??
        0;
  }

  Future<int> _countRecurringTransactions(
    int accountId,
  ) async {
    final countExpression = database.recurringTransactions.id.count();

    final query = database.selectOnly(
      database.recurringTransactions,
    )
      ..addColumns([
        countExpression,
      ])
      ..where(
        database.recurringTransactions.accountId.equals(
          accountId,
        ),
      );

    final row = await query.getSingle();

    return row.read(
          countExpression,
        ) ??
        0;
  }

  Stream<AccountDetailsData?> watchAccountDetails(
    int accountId,
  ) async* {
    final query = database.select(database.transactions).join([
      innerJoin(
        database.accounts,
        database.accounts.id.equalsExp(
          database.transactions.accountId,
        ),
      ),
      innerJoin(
        database.categories,
        database.categories.id.equalsExp(
          database.transactions.categoryId,
        ),
      ),
    ])
      ..where(
        database.transactions.accountId.equals(
          accountId,
        ),
      )
      ..orderBy([
        OrderingTerm.desc(
          database.transactions.date,
        ),
        OrderingTerm.desc(
          database.transactions.id,
        ),
      ]);

    await for (final rows in query.watch()) {
      final account = await (database.select(database.accounts)
            ..where(
              (table) => table.id.equals(
                accountId,
              ),
            ))
          .getSingleOrNull();

      if (account == null) {
        yield null;
        continue;
      }

      var incomeInCents = 0;
      var expenseInCents = 0;

      final transactions = <AccountTransactionItem>[];

      for (final row in rows) {
        final transaction = row.readTable(
          database.transactions,
        );

        final category = row.readTable(
          database.categories,
        );

        final amount = transaction.amountInCents.abs();

        if (transaction.type == 'income') {
          incomeInCents += amount;
        }

        if (transaction.type == 'expense') {
          expenseInCents += amount;
        }

        transactions.add(
          AccountTransactionItem(
            transaction: transaction,
            categoryName: category.name,
            categoryIcon: category.icon,
          ),
        );
      }

      final currentBalanceInCents =
          account.initialBalanceInCents + incomeInCents - expenseInCents;

      yield AccountDetailsData(
        account: account,
        incomeInCents: incomeInCents,
        expenseInCents: expenseInCents,
        currentBalanceInCents: currentBalanceInCents,
        transactions: transactions,
      );
    }
  }
}
