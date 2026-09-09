import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../categories/domain/category_icons.dart';
import '../domain/account_details.dart';
import 'providers/accounts_providers.dart';

class AccountDetailsPage extends ConsumerWidget {
  final int accountId;

  const AccountDetailsPage({
    super.key,
    required this.accountId,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final details = ref.watch(
      accountDetailsProvider(
        accountId,
      ),
    );

    return details.when(
      loading: () {
        return const _AccountDetailsLoading();
      },
      error: (
        error,
        stackTrace,
      ) {
        return Scaffold(
          appBar: AppBar(),
          body: _DetailsError(
            error: error,
            onRetry: () {
              ref.invalidate(
                accountDetailsProvider(
                  accountId,
                ),
              );
            },
          ),
        );
      },
      data: (data) {
        if (data == null) {
          return const _AccountNotFound();
        }

        return _AccountDetailsContent(
          data: data,
        );
      },
    );
  }
}

class _AccountDetailsContent extends StatelessWidget {
  final AccountDetailsData data;

  const _AccountDetailsContent({
    required this.data,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final movementResult = data.incomeInCents - data.expenseInCents;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data.account.name,
        ),
        actions: [
          IconButton(
            tooltip: 'Editar conta',
            onPressed: () {
              context.push(
                '/accounts/${data.account.id}/edit',
              );
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          40,
        ),
        children: [
          //
          // =====================================
          // SALDO
          // =====================================
          //
          _Appear(
            child: _BalanceCard(
              balance: data.currentBalanceInCents,
              initialBalance: data.account.initialBalanceInCents,
              accountName: data.account.name,
              accountType: data.account.type,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          //
          // =====================================
          // RECEITAS / DESPESAS
          // =====================================
          //
          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              if (constraints.maxWidth < 340) {
                return Column(
                  children: [
                    _SummaryCard(
                      icon: Icons.south_west_rounded,
                      title: 'Receitas',
                      amount: data.incomeInCents,
                      color: AppTheme.income,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    _SummaryCard(
                      icon: Icons.north_east_rounded,
                      title: 'Despesas',
                      amount: data.expenseInCents,
                      color: AppTheme.expense,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.south_west_rounded,
                      title: 'Receitas',
                      amount: data.incomeInCents,
                      color: AppTheme.income,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.north_east_rounded,
                      title: 'Despesas',
                      amount: data.expenseInCents,
                      color: AppTheme.expense,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(
            height: 12,
          ),

          _MovementResultCard(
            valueInCents: movementResult,
          ),

          const SizedBox(
            height: 30,
          ),

          //
          // =====================================
          // MOVIMENTAÇÕES
          // =====================================
          //
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Movimentações',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Histórico desta conta',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    30,
                  ),
                ),
                child: Text(
                  '${data.transactions.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          if (data.transactions.isEmpty)
            const _EmptyTransactions()
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(
                  data.transactions.length,
                  (
                    index,
                  ) {
                    final item = data.transactions[index];

                    return Column(
                      children: [
                        _TransactionTile(
                          item: item,
                        ),
                        if (index != data.transactions.length - 1)
                          const Divider(
                            height: 1,
                            indent: 72,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================
// SALDO
// ===========================================================

class _BalanceCard extends StatelessWidget {
  final int balance;
  final int initialBalance;

  final String accountName;
  final String accountType;

  const _BalanceCard({
    required this.balance,
    required this.initialBalance,
    required this.accountName,
    required this.accountType,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final negative = balance < 0;

    return Container(
      padding: const EdgeInsets.all(
        22,
      ),
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
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF6366F1,
            ).withValues(
              alpha: 0.18,
            ),
            blurRadius: 22,
            offset: const Offset(
              0,
              9,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  _accountIcon(
                    accountType,
                  ),
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      _accountTypeName(
                        accountType,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            'Saldo atual',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(
                alpha: 0.78,
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(
                balance,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoBadge(
                icon: Icons.history_rounded,
                label: 'Inicial: ${_money(initialBalance)}',
              ),
              _InfoBadge(
                icon: negative
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                label: negative ? 'Saldo negativo' : 'Saldo positivo',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.14,
        ),
        borderRadius: BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// RESUMO
// ===========================================================

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int amount;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.11,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
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
                _money(
                  amount,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementResultCard extends StatelessWidget {
  final int valueInCents;

  const _MovementResultCard({
    required this.valueInCents,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final positive = valueInCents >= 0;

    final color = positive ? AppTheme.income : AppTheme.expense;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Movimentação líquida',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  positive
                      ? 'Entradas acima das saídas'
                      : 'Saídas acima das entradas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _money(
              valueInCents,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// TRANSAÇÕES
// ===========================================================

class _TransactionTile extends StatelessWidget {
  final AccountTransactionItem item;

  const _TransactionTile({
    required this.item,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final transaction = item.transaction;

    final income = item.isIncome;

    final color = income ? AppTheme.income : AppTheme.expense;

    return InkWell(
      onTap: () {
        context.push(
          '/transactions/${transaction.id}/edit',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                categoryIconFromKey(
                  item.categoryIcon ?? '',
                ),
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(
              width: 13,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    '${item.categoryName} • '
                    '${_formatDate(transaction.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${income ? '+' : '-'} '
                  '${_money(transaction.amountInCents.abs())}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 34,
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Nenhuma movimentação',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'As receitas e despesas desta conta aparecerão aqui.',
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

// ===========================================================
// LOADING / ERRO
// ===========================================================

class _AccountDetailsLoading extends StatelessWidget {
  const _AccountDetailsLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          40,
        ),
        children: const [
          _LoadingBox(
            height: 220,
            radius: 24,
          ),
          SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child: _LoadingBox(
                  height: 120,
                  radius: 20,
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: _LoadingBox(
                  height: 120,
                  radius: 20,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 28,
          ),
          _LoadingBox(
            width: 160,
            height: 18,
          ),
          SizedBox(
            height: 14,
          ),
          _LoadingBox(
            height: 75,
            radius: 18,
          ),
          SizedBox(
            height: 8,
          ),
          _LoadingBox(
            height: 75,
            radius: 18,
          ),
        ],
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _LoadingBox({
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          radius,
        ),
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _DetailsError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Não foi possível carregar a conta',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountNotFound extends StatelessWidget {
  const _AccountNotFound();

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(
            32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(
                height: 14,
              ),
              Text(
                'Conta não encontrada',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// ANIMAÇÃO / HELPERS
// ===========================================================

class _Appear extends StatelessWidget {
  final Widget child;

  const _Appear({
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: 1,
      ),
      duration: const Duration(
        milliseconds: 380,
      ),
      curve: Curves.easeOutCubic,
      builder: (
        context,
        value,
        child,
      ) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              0,
              8 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

IconData _accountIcon(
  String type,
) {
  switch (type) {
    case 'cash':
      return Icons.account_balance_wallet_outlined;

    case 'checking':
      return Icons.account_balance_outlined;

    case 'savings':
      return Icons.savings_outlined;

    case 'investment':
      return Icons.trending_up_rounded;

    default:
      return Icons.wallet_outlined;
  }
}

String _accountTypeName(
  String type,
) {
  switch (type) {
    case 'cash':
      return 'Carteira';

    case 'checking':
      return 'Conta corrente';

    case 'savings':
      return 'Poupança';

    case 'investment':
      return 'Investimentos';

    default:
      return 'Outra';
  }
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

String _money(
  int cents,
) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(
    cents / 100,
  );
}
