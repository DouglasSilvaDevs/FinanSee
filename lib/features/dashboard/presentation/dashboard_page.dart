import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/dashboard_models.dart';
import 'providers/dashboard_providers.dart';
import '../../budgets/presentation/providers/budgets_providers.dart';

import 'widgets/budget_overview_card.dart';
import 'widgets/notification_bell_button.dart';
import 'widgets/expense_category_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);

    final now = DateTime.now();

    final currentMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    final summary = ref.watch(
      dashboardSummaryProvider,
    );

    final recentTransactions = ref.watch(
      dashboardRecentTransactionsProvider,
    );

    final budgets = ref.watch(
      budgetsProvider(
        currentMonth,
      ),
    );

    final expensesByCategory = ref.watch(
      dashboardExpensesByCategoryProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              dashboardSummaryProvider,
            );

            ref.invalidate(
              dashboardExpensesByCategoryProvider,
            );

            ref.invalidate(
              budgetsProvider(
                currentMonth,
              ),
            );

            ref.invalidate(
              dashboardRecentTransactionsProvider,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              100,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'FinanSee',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const NotificationBellButton(),
                ],
              ),
              const SizedBox(
                height: 28,
              ),
              summary.when(
                data: (data) {
                  return Column(
                    children: [
                      _BalanceCard(
                        balanceInCents: data.totalBalanceInCents,
                        onTap: () {
                          context.push(
                            '/accounts',
                          );
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Receitas',
                              valueInCents: data.incomeThisMonthInCents,
                              icon: Icons.arrow_upward_rounded,
                              color: AppTheme.income,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Despesas',
                              valueInCents: data.expenseThisMonthInCents,
                              icon: Icons.arrow_downward_rounded,
                              color: AppTheme.expense,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      _MonthResultCard(
                        valueInCents: data.monthBalanceInCents,
                      ),
                    ],
                  );
                },
                loading: () {
                  return const SizedBox(
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                error: (
                  error,
                  stackTrace,
                ) {
                  return _ErrorCard(
                    message: 'Não foi possível calcular o resumo financeiro.',
                    onRetry: () {
                      ref.invalidate(
                        dashboardSummaryProvider,
                      );
                    },
                  );
                },
              ),
              const SizedBox(
                height: 28,
              ),
              expensesByCategory.when(
                data: (items) {
                  return ExpenseCategoryChart(
                    items: items,
                  );
                },
                loading: () {
                  return const Card(
                    child: SizedBox(
                      height: 280,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                },
                error: (
                  error,
                  stackTrace,
                ) {
                  return _ErrorCard(
                    message:
                        'Não foi possível carregar os gastos por categoria.',
                    onRetry: () {
                      ref.invalidate(
                        dashboardExpensesByCategoryProvider,
                      );
                    },
                  );
                },
              ),
              const SizedBox(
                height: 20,
              ),
              budgets.when(
                data: (items) {
                  return BudgetOverviewCard(
                    budgets: items,
                  );
                },
                loading: () {
                  return const Card(
                    child: SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                },
                error: (
                  error,
                  stackTrace,
                ) {
                  return _ErrorCard(
                    message: 'Não foi possível carregar seus orçamentos.',
                    onRetry: () {
                      ref.invalidate(
                        budgetsProvider(
                          currentMonth,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(
                height: 34,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transações recentes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(
                        '/transactions',
                      );
                    },
                    child: const Text(
                      'Ver todas',
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              recentTransactions.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyRecentTransactions();
                  }

                  return Column(
                    children: items.map(
                      (item) {
                        return _TransactionItem(
                          item: item,
                        );
                      },
                    ).toList(),
                  );
                },
                loading: () {
                  return const Padding(
                    padding: EdgeInsets.all(
                      32,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                error: (
                  error,
                  stackTrace,
                ) {
                  return _ErrorCard(
                    message: 'Não foi possível carregar as transações.',
                    onRetry: () {
                      ref.invalidate(
                        dashboardRecentTransactionsProvider,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Bom dia 👋';
    }

    if (hour < 18) {
      return 'Boa tarde 👋';
    }

    return 'Boa noite 👋';
  }
}

class _BalanceCard extends StatelessWidget {
  final int balanceInCents;
  final VoidCallback onTap;

  const _BalanceCard({
    required this.balanceInCents,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        24,
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFF6366F1,
              ),
              Color(
                0xFF8B5CF6,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(
            24,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saldo total',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  _formatCurrency(
                    balanceInCents,
                  ),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(
                      30,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                      SizedBox(
                        width: 6,
                      ),
                      Text(
                        'Ver todas as contas',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int valueInCents;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.valueInCents,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _formatCurrency(
                  valueInCents,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthResultCard extends StatelessWidget {
  final int valueInCents;

  const _MonthResultCard({
    required this.valueInCents,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final positive = valueInCents >= 0;

    final color = positive ? AppTheme.income : AppTheme.expense;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(
              positive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: color,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resultado do mês',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    positive
                        ? 'Você está no positivo'
                        : 'Suas despesas superaram as receitas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatCurrency(
                valueInCents,
              ),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final DashboardTransaction item;

  const _TransactionItem({
    required this.item,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final transaction = item.transaction;

    final isIncome = transaction.type == 'income';

    final color = isIncome ? AppTheme.income : AppTheme.expense;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                15,
              ),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: color,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '${item.category.name} • '
                  '${_formatDate(transaction.date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Text(
            '${isIncome ? '+' : '-'} '
            '${_formatCurrency(transaction.amountInCents)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentTransactions extends StatelessWidget {
  const _EmptyRecentTransactions();

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          28,
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'Nenhuma transação ainda',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Adicione uma receita ou despesa usando o botão +.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 10,
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCurrency(
  int amountInCents,
) {
  final formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  return formatter.format(
    amountInCents / 100,
  );
}

String _formatDate(
  DateTime date,
) {
  final now = DateTime.now();

  if (DateUtils.isSameDay(
    now,
    date,
  )) {
    return 'Hoje';
  }

  final yesterday = DateTime(
    now.year,
    now.month,
    now.day - 1,
  );

  if (DateUtils.isSameDay(
    yesterday,
    date,
  )) {
    return 'Ontem';
  }

  return DateFormat(
    'dd/MM/yyyy',
  ).format(
    date,
  );
}
