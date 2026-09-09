import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../budgets/domain/budget_models.dart';
import '../../../categories/domain/category_icons.dart';

class BudgetOverviewCard extends StatelessWidget {
  final List<BudgetProgress> budgets;

  const BudgetOverviewCard({
    super.key,
    required this.budgets,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    if (budgets.isEmpty) {
      return _EmptyBudgetCard(
        onCreate: () {
          context.push(
            '/budgets',
          );
        },
      );
    }

    final sorted = [...budgets]..sort(
        (
          a,
          b,
        ) =>
            b.progress.compareTo(
          a.progress,
        ),
      );

    final visible = sorted.take(3).toList();

    final exceededCount = budgets
        .where(
          (
            budget,
          ) =>
              budget.isExceeded,
        )
        .length;

    final nearLimitCount = budgets
        .where(
          (
            budget,
          ) =>
              budget.isNearLimit,
        )
        .length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    Icons.speed_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 21,
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
                        'Orçamentos',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Acompanhe seus limites deste mês',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.push(
                      '/budgets',
                    );
                  },
                  child: const Text(
                    'Ver todos',
                  ),
                ),
              ],
            ),
            if (exceededCount > 0) ...[
              const SizedBox(
                height: 16,
              ),
              _BudgetAlert(
                type: _BudgetAlertType.exceeded,
                message: exceededCount == 1
                    ? '1 categoria ultrapassou o orçamento'
                    : '$exceededCount categorias ultrapassaram o orçamento',
              ),
            ] else if (nearLimitCount > 0) ...[
              const SizedBox(
                height: 16,
              ),
              _BudgetAlert(
                type: _BudgetAlertType.warning,
                message: nearLimitCount == 1
                    ? '1 categoria está próxima do limite'
                    : '$nearLimitCount categorias estão próximas do limite',
              ),
            ],
            const SizedBox(
              height: 18,
            ),
            ...List.generate(
              visible.length,
              (
                index,
              ) {
                final budget = visible[index];

                return Column(
                  children: [
                    _BudgetItem(
                      budget: budget,
                      onTap: () {
                        context.push(
                          '/budgets',
                        );
                      },
                    ),
                    if (index != visible.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        child: Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (budgets.length > visible.length) ...[
              const SizedBox(
                height: 16,
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    context.push(
                      '/budgets',
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                  ),
                  label: Text(
                    'Ver mais ${budgets.length - visible.length} '
                    '${budgets.length - visible.length == 1 ? 'orçamento' : 'orçamentos'}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetItem extends StatelessWidget {
  final BudgetProgress budget;
  final VoidCallback onTap;

  const _BudgetItem({
    required this.budget,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final Color color;
    final String status;

    if (budget.isExceeded) {
      color = AppTheme.expense;
      status = 'Ultrapassado';
    } else if (budget.isNearLimit) {
      color = Colors.orange;
      status = 'Próximo do limite';
    } else {
      color = AppTheme.income;
      status = 'Dentro do limite';
    }

    final progress = budget.progress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    final percentage = budget.progress * 100;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          14,
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 2,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      categoryIconFromKey(
                        budget.categoryIcon,
                      ),
                      color: color,
                      size: 21,
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
                          budget.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          '${_money(budget.spentInCents)} de '
                          '${_money(budget.limitInCents)}',
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
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 11,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  20,
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: color,
                  backgroundColor: color.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
              if (budget.isExceeded) ...[
                const SizedBox(
                  height: 7,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_money(budget.remainingInCents.abs())} acima do limite',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.expense,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _BudgetAlertType {
  warning,
  exceeded,
}

class _BudgetAlert extends StatelessWidget {
  final _BudgetAlertType type;
  final String message;

  const _BudgetAlert({
    required this.type,
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isExceeded = type == _BudgetAlertType.exceeded;

    final color = isExceeded ? AppTheme.expense : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExceeded
                ? Icons.error_outline_rounded
                : Icons.warning_amber_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBudgetCard extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyBudgetCard({
    required this.onCreate,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCreate,
        child: Padding(
          padding: const EdgeInsets.all(
            22,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  Icons.speed_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
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
                      'Defina seus orçamentos',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Crie limites mensais para controlar seus gastos.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
