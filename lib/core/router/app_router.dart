import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/transactions/presentation/transactions_page.dart';
import '../../features/transactions/presentation/transaction_form_page.dart';
import '../../features/accounts/presentation/account_form_page.dart';
import '../../features/accounts/presentation/accounts_page.dart';
import '../../features/categories/presentation/categories_page.dart';
import '../../features/categories/presentation/category_form_page.dart';
import '../../features/budgets/presentation/budget_form_page.dart';
import '../../features/budgets/presentation/budgets_page.dart';
import '../../features/recurring/presentation/recurring_transactions_form_page.dart';
import '../../features/recurring/presentation/recurring_transactions_page.dart';
import '../../features/goals/presentation/goal_details_page.dart';
import '../../features/goals/presentation/goal_form_page.dart';
import '../../features/goals/presentation/goals_page.dart';
import '../../features/notifications/presentation/notification_settings_page.dart';
import '../../features/notifications/presentation/notifications_page.dart';
import '../../features/settings/presentation/backup_restore_page.dart';
import '../../features/accounts/presentation/account_details_page.dart';
import '../../features/settings/presentation/appearance_settings_page.dart';
import '../../features/settings/presentation/about_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (
          context,
          state,
          navigationShell,
        ) {
          return MainShell(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) {
                  return const DashboardPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) {
                  return const TransactionsPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) {
                  return const ReportsPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) {
                  return const SettingsPage();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (context, state) {
          return const TransactionFormPage();
        },
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (id == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Transação inválida.',
                ),
              ),
            );
          }

          return TransactionFormPage(
            transactionId: id,
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (
          context,
          state,
        ) {
          return const OnboardingPage(
            isReplay: true,
          );
        },
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) {
          return const AccountsPage();
        },
      ),
      GoRoute(
        path: '/accounts/new',
        builder: (context, state) {
          return const AccountFormPage();
        },
      ),
      GoRoute(
        path: '/accounts/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (id == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Conta inválida.',
                ),
              ),
            );
          }

          return AccountFormPage(
            accountId: id,
          );
        },
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (
          context,
          state,
        ) {
          final id = int.parse(
            state.pathParameters['id']!,
          );

          return AccountDetailsPage(
            accountId: id,
          );
        },
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (
          context,
          state,
        ) {
          return const NotificationSettingsPage();
        },
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) {
          return const CategoriesPage();
        },
      ),
      GoRoute(
        path: '/categories/new',
        builder: (context, state) {
          return const CategoryFormPage();
        },
      ),
      GoRoute(
        path: '/categories/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (id == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Categoria inválida.',
                ),
              ),
            );
          }

          return CategoryFormPage(
            categoryId: id,
          );
        },
      ),
      GoRoute(
        path: '/backup',
        builder: (
          context,
          state,
        ) {
          return const BackupRestorePage();
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (
          context,
          state,
        ) {
          return const NotificationsPage();
        },
      ),
      GoRoute(
        path: '/about',
        builder: (
          context,
          state,
        ) {
          return const AboutPage();
        },
      ),
      GoRoute(
        path: '/recurring',
        builder: (
          context,
          state,
        ) {
          return const RecurringTransactionsPage();
        },
      ),
      GoRoute(
        path: '/recurring/new',
        builder: (
          context,
          state,
        ) {
          return const RecurringTransactionFormPage();
        },
      ),
      GoRoute(
        path: '/recurring/:id/edit',
        builder: (
          context,
          state,
        ) {
          final id = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (id == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Recorrência inválida.',
                ),
              ),
            );
          }

          return RecurringTransactionFormPage(
            ruleId: id,
          );
        },
      ),
      GoRoute(
        path: '/appearance',
        builder: (
          context,
          state,
        ) {
          return const AppearanceSettingsPage();
        },
      ),
      GoRoute(
        path: '/goals',
        builder: (
          context,
          state,
        ) {
          return const GoalsPage();
        },
      ),
      GoRoute(
        path: '/goals/new',
        builder: (
          context,
          state,
        ) {
          return const GoalFormPage();
        },
      ),
      GoRoute(
        path: '/goals/:id',
        builder: (
          context,
          state,
        ) {
          final id = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (id == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Meta inválida.',
                ),
              ),
            );
          }

          return GoalDetailsPage(
            goalId: id,
          );
        },
      ),
      GoRoute(
        path: '/goals/:id/edit',
        builder: (
          context,
          state,
        ) {
          final id = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (id == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Meta inválida.',
                ),
              ),
            );
          }

          return GoalFormPage(
            goalId: id,
          );
        },
      ),
      GoRoute(
        path: '/budgets',
        builder: (
          context,
          state,
        ) {
          return const BudgetsPage();
        },
      ),
      GoRoute(
        path: '/budgets/new',
        builder: (
          context,
          state,
        ) {
          final now = DateTime.now();

          final year = int.tryParse(
                state.uri.queryParameters['year'] ?? '',
              ) ??
              now.year;

          final month = int.tryParse(
                state.uri.queryParameters['month'] ?? '',
              ) ??
              now.month;

          return BudgetFormPage(
            year: year,
            month: month,
          );
        },
      ),
      GoRoute(
        path: '/budgets/:id/edit',
        builder: (
          context,
          state,
        ) {
          final id = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          final now = DateTime.now();

          final year = int.tryParse(
                state.uri.queryParameters['year'] ?? '',
              ) ??
              now.year;

          final month = int.tryParse(
                state.uri.queryParameters['month'] ?? '',
              ) ??
              now.month;

          if (id == null) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Orçamento inválido.',
                ),
              ),
            );
          }

          return BudgetFormPage(
            budgetId: id,
            year: year,
            month: month,
          );
        },
      ),
    ],
  );
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>(
            '/transactions/new',
          );

          if (created == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Transação adicionada com sucesso!',
                ),
              ),
            );
          }
        },
        child: const Icon(
          Icons.add_rounded,
          size: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert_rounded),
            selectedIcon: Icon(Icons.swap_vert_circle_rounded),
            label: 'Transações',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Relatórios',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}
