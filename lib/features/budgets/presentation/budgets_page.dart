import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../categories/domain/category_icons.dart';
import '../domain/budget_models.dart';
import 'providers/budgets_providers.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({
    super.key,
  });

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(
      now.year,
      now.month,
      1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(
      budgetsProvider(
        _selectedMonth,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Orçamentos',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBudget,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Novo orçamento',
        ),
      ),
      body: budgets.when(
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                budgetsProvider(
                  _selectedMonth,
                ),
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                120,
              ),
              children: [
                _PageIntro(
                  month: _selectedMonth,
                ),
                const SizedBox(
                  height: 20,
                ),
                _MonthSelector(
                  month: _selectedMonth,
                  onPrevious: _previousMonth,
                  onNext: _isCurrentMonth ? null : _nextMonth,
                ),
                const SizedBox(
                  height: 20,
                ),
                if (items.isEmpty)
                  _EmptyBudgets(
                    month: _selectedMonth,
                    onCreate: _createBudget,
                  )
                else ...[
                  _Appear(
                    child: _BudgetSummary(
                      items: items,
                    ),
                  ),
                  const SizedBox(
                    height: 28,
                  ),
                  _SectionHeader(
                    count: items.length,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  ...items.map(
                    (budget) {
                      return _Appear(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _BudgetCard(
                            budget: budget,
                            onEdit: () {
                              context.push(
                                '/budgets/${budget.budgetId}/edit'
                                '?year=${_selectedMonth.year}'
                                '&month=${_selectedMonth.month}',
                              );
                            },
                            onDelete: () {
                              _deleteBudget(
                                budget,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
        loading: () {
          return _BudgetsLoading(
            month: _selectedMonth,
            onPrevious: _previousMonth,
            onNext: _isCurrentMonth ? null : _nextMonth,
          );
        },
        error: (
          error,
          stackTrace,
        ) {
          return _BudgetsError(
            month: _selectedMonth,
            error: error,
            onPrevious: _previousMonth,
            onNext: _isCurrentMonth ? null : _nextMonth,
            onRetry: () {
              ref.invalidate(
                budgetsProvider(
                  _selectedMonth,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createBudget() async {
    await context.push(
      '/budgets/new'
      '?year=${_selectedMonth.year}'
      '&month=${_selectedMonth.month}',
    );
  }

  Future<void> _deleteBudget(
    BudgetProgress budget,
  ) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: theme.colorScheme.error,
          ),
          title: const Text(
            'Excluir orçamento?',
          ),
          content: Text(
            'Deseja excluir o orçamento de "${budget.categoryName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Excluir',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(
            budgetsRepositoryProvider,
          )
          .deleteBudget(
            budget.budgetId,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Orçamento excluído.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível excluir o orçamento.',
            ),
          ),
        );
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();

    return now.year == _selectedMonth.year && now.month == _selectedMonth.month;
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
  }
}

// ===========================================================
// INTRO
// ===========================================================

class _PageIntro extends StatelessWidget {
  final DateTime month;

  const _PageIntro({
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planeje seus gastos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Defina limites por categoria e acompanhe o consumo durante o mês.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 14,
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              15,
            ),
          ),
          child: Icon(
            Icons.speed_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// RESUMO
// ===========================================================

class _BudgetSummary extends StatelessWidget {
  final List<BudgetProgress> items;

  const _BudgetSummary({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalLimit = items.fold<int>(
      0,
      (
        sum,
        item,
      ) {
        return sum + item.limitInCents;
      },
    );

    final totalSpent = items.fold<int>(
      0,
      (
        sum,
        item,
      ) {
        return sum + item.spentInCents;
      },
    );

    final remaining = totalLimit - totalSpent;

    final progress = totalLimit <= 0 ? 0.0 : totalSpent / totalLimit;

    final exceededCount = items.where(
      (item) {
        return item.isExceeded;
      },
    ).length;

    final nearCount = items.where(
      (item) {
        return !item.isExceeded && item.isNearLimit;
      },
    ).length;

    final healthyCount = items.length - exceededCount - nearCount;

    final statusColor = remaining < 0
        ? AppTheme.expense
        : progress >= 0.8
            ? Colors.orange
            : AppTheme.income;

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
              alpha: 0.20,
            ),
            blurRadius: 24,
            offset: const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Orçamento mensal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(
                      alpha: 0.80,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.pie_chart_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 7,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(
                totalLimit,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              30,
            ),
            child: LinearProgressIndicator(
              value: progress.clamp(
                0.0,
                1.0,
              ),
              minHeight: 9,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% utilizado',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.82,
                  ),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 22,
          ),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Gasto',
                  value: _money(
                    totalSpent,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(
                  alpha: 0.16,
                ),
              ),
              const SizedBox(
                width: 18,
              ),
              Expanded(
                child: _SummaryItem(
                  label: remaining >= 0 ? 'Disponível' : 'Excedido',
                  value: _money(
                    remaining.abs(),
                  ),
                  valueColor: remaining >= 0
                      ? null
                      : const Color(
                          0xFFFFD4D4,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (healthyCount > 0)
                _StatusBadge(
                  icon: Icons.check_circle_outline_rounded,
                  label: '$healthyCount dentro do limite',
                ),
              if (nearCount > 0)
                _StatusBadge(
                  icon: Icons.warning_amber_rounded,
                  label:
                      '$nearCount próximo${nearCount == 1 ? '' : 's'} do limite',
                ),
              if (exceededCount > 0)
                _StatusBadge(
                  icon: Icons.error_outline_rounded,
                  label:
                      '$exceededCount ultrapassado${exceededCount == 1 ? '' : 's'}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.72,
            ),
            fontSize: 12,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.13,
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// CABEÇALHO DA LISTA
// ===========================================================

class _SectionHeader extends StatelessWidget {
  final int count;

  const _SectionHeader({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Por categoria',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                'Acompanhe cada limite individualmente',
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
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// CARD DO ORÇAMENTO
// ===========================================================

class _BudgetCard extends StatelessWidget {
  final BudgetProgress budget;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final percentage = budget.progress * 100;

    final Color color;
    final String status;
    final IconData statusIcon;

    if (budget.isExceeded) {
      color = AppTheme.expense;
      status = 'Ultrapassado';
      statusIcon = Icons.error_outline_rounded;
    } else if (budget.isNearLimit) {
      color = Colors.orange;
      status = 'Próximo do limite';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      color = AppTheme.income;
      status = 'Dentro do limite';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    final progress = budget.progress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(
            18,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: 0.11,
                      ),
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Icon(
                      categoryIconFromKey(
                        budget.categoryIcon,
                      ),
                      color: color,
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
                          budget.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          '${_money(budget.spentInCents)} de '
                          '${_money(budget.limitInCents)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opções',
                    onSelected: (
                      value,
                    ) {
                      if (value == 'edit') {
                        onEdit();
                      }

                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (
                      context,
                    ) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Editar',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Excluir',
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(
                        30,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  20,
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  color: color,
                  backgroundColor: color.withValues(
                    alpha: 0.09,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Text(
                    'Gasto',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Text(
                    _money(
                      budget.spentInCents,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      budget.isExceeded
                          ? '${_money(budget.remainingInCents.abs())} acima do limite'
                          : '${_money(budget.remainingInCents)} disponíveis',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: budget.isExceeded
                            ? AppTheme.expense
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: budget.isExceeded ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// MÊS
// ===========================================================

class _MonthSelector extends StatelessWidget {
  final DateTime month;

  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: onPrevious,
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _monthName(
                    month.month,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  '${month.year}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: onNext,
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// EMPTY
// ===========================================================

class _EmptyBudgets extends StatelessWidget {
  final DateTime month;
  final VoidCallback onCreate;

  const _EmptyBudgets({
    required this.month,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 55,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.speed_outlined,
              size: 38,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Nenhum orçamento definido',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            'Você ainda não definiu limites para ${_monthLabel(month)}.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'Crie um orçamento para controlar melhor seus gastos por categoria.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Criar orçamento',
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// LOADING
// ===========================================================

class _BudgetsLoading extends StatelessWidget {
  final DateTime month;

  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _BudgetsLoading({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        120,
      ),
      children: [
        _PageIntro(
          month: month,
        ),
        const SizedBox(
          height: 20,
        ),
        _MonthSelector(
          month: month,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        const SizedBox(
          height: 20,
        ),
        const _LoadingBox(
          height: 235,
          radius: 24,
        ),
        const SizedBox(
          height: 28,
        ),
        const _LoadingBox(
          width: 150,
          height: 18,
        ),
        const SizedBox(
          height: 14,
        ),
        const _LoadingBox(
          height: 170,
          radius: 20,
        ),
        const SizedBox(
          height: 12,
        ),
        const _LoadingBox(
          height: 170,
          radius: 20,
        ),
      ],
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          radius,
        ),
      ),
    );
  }
}

// ===========================================================
// ERROR
// ===========================================================

class _BudgetsError extends StatelessWidget {
  final DateTime month;
  final Object error;

  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onRetry;

  const _BudgetsError({
    required this.month,
    required this.error,
    required this.onPrevious,
    required this.onNext,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        120,
      ),
      children: [
        _PageIntro(
          month: month,
        ),
        const SizedBox(
          height: 20,
        ),
        _MonthSelector(
          month: month,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        const SizedBox(
          height: 50,
        ),
        Column(
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
              'Não foi possível carregar os orçamentos',
              textAlign: TextAlign.center,
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
      ],
    );
  }
}

// ===========================================================
// APPEAR
// ===========================================================

class _Appear extends StatelessWidget {
  final Widget child;

  const _Appear({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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

// ===========================================================
// HELPERS
// ===========================================================

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

String _monthName(
  int month,
) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  return months[month - 1];
}

String _monthLabel(
  DateTime date,
) {
  return '${_monthName(date.month)} de ${date.year}';
}
