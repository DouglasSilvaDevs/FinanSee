import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/transactions.dart';
import 'tables/budgets.dart';
import 'tables/recurring_occurrences.dart';
import 'tables/recurring_transactions.dart';
import 'tables/financial_goals.dart';
import 'tables/goal_contributions.dart';
import 'tables/budget_notification_states.dart';
import 'tables/goal_notification_states.dart';
import 'tables/app_notifications.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Budgets,
    RecurringTransactions,
    RecurringOccurrences,
    FinancialGoals,
    GoalContributions,
    BudgetNotificationStates,
    GoalNotificationStates,
    AppNotifications,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(
          executor ?? _openConnection(),
        );

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        await _seedInitialData();
      },
      onUpgrade: (
        Migrator m,
        int from,
        int to,
      ) async {
        if (from < 2) {
          await m.createTable(
            budgets,
          );
        }

        if (from < 3) {
          await m.createTable(
            recurringTransactions,
          );

          await m.createTable(
            recurringOccurrences,
          );
        }

        if (from < 4) {
          await m.createTable(
            financialGoals,
          );

          await m.createTable(
            goalContributions,
          );
        }
        if (from < 5) {
          await m.createTable(
            budgetNotificationStates,
          );
        }
        if (from < 6) {
          await m.createTable(
            goalNotificationStates,
          );
        }
        if (from < 7) {
          await m.createTable(
            appNotifications,
          );
        }
      },
      beforeOpen: (details) async {
        await customStatement(
          'PRAGMA foreign_keys = ON',
        );
      },
    );
  }

  Future<void> _seedInitialData() async {
    await batch((batch) {
      //
      // CONTA PADRÃO
      //
      batch.insert(
        accounts,
        AccountsCompanion.insert(
          name: 'Carteira',
          type: 'cash',
        ),
      );

      //
      // CATEGORIAS DE DESPESA
      //
      batch.insertAll(
        categories,
        [
          CategoriesCompanion.insert(
            name: 'Alimentação',
            type: 'expense',
            icon: const Value('restaurant'),
          ),
          CategoriesCompanion.insert(
            name: 'Transporte',
            type: 'expense',
            icon: const Value('directions_car'),
          ),
          CategoriesCompanion.insert(
            name: 'Moradia',
            type: 'expense',
            icon: const Value('home'),
          ),
          CategoriesCompanion.insert(
            name: 'Saúde',
            type: 'expense',
            icon: const Value('health'),
          ),
          CategoriesCompanion.insert(
            name: 'Lazer',
            type: 'expense',
            icon: const Value('sports_esports'),
          ),
          CategoriesCompanion.insert(
            name: 'Educação',
            type: 'expense',
            icon: const Value('school'),
          ),
          CategoriesCompanion.insert(
            name: 'Compras',
            type: 'expense',
            icon: const Value('shopping_bag'),
          ),
          CategoriesCompanion.insert(
            name: 'Contas',
            type: 'expense',
            icon: const Value('receipt'),
          ),

          //
          // CATEGORIAS DE RECEITA
          //
          CategoriesCompanion.insert(
            name: 'Salário',
            type: 'income',
            icon: const Value('payments'),
          ),
          CategoriesCompanion.insert(
            name: 'Freelance',
            type: 'income',
            icon: const Value('work'),
          ),
          CategoriesCompanion.insert(
            name: 'Investimentos',
            type: 'income',
            icon: const Value('trending_up'),
          ),
          CategoriesCompanion.insert(
            name: 'Outras receitas',
            type: 'income',
            icon: const Value('attach_money'),
          ),
        ],
      );
    });
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'finansee',
  );
}
