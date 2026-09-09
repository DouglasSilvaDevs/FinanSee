import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../categories/domain/category_icons.dart';
import '../domain/recurring_models.dart';
import 'providers/recurring_providers.dart';

class RecurringTransactionsPage extends ConsumerWidget {
  const RecurringTransactionsPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final rules = ref.watch(
      recurringTransactionsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recorrências',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(
            '/recurring/new',
          );
        },
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Nova recorrência',
        ),
      ),
      body: rules.when(
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                recurringTransactionsProvider,
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
                const _PageIntro(),
                const SizedBox(
                  height: 20,
                ),
                if (items.isEmpty)
                  _EmptyState(
                    onCreate: () {
                      context.push(
                        '/recurring/new',
                      );
                    },
                  )
                else ...[
                  _Appear(
                    child: _RecurringSummary(
                      items: items,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const _InformationCard(),
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
                    (item) {
                      return _Appear(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _RecurringCard(
                            item: item,
                            onEdit: () {
                              context.push(
                                '/recurring/${item.rule.id}/edit',
                              );
                            },
                            onToggle: (
                              active,
                            ) async {
                              try {
                                await ref
                                    .read(
                                      recurringTransactionsRepositoryProvider,
                                    )
                                    .setActive(
                                      id: item.rule.id,
                                      active: active,
                                    );
                              } catch (error) {
                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não foi possível alterar o status da recorrência.',
                                      ),
                                    ),
                                  );
                              }
                            },
                            onDelete: () {
                              _delete(
                                context,
                                ref,
                                item,
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
          return const _RecurringLoading();
        },
        error: (
          error,
          stackTrace,
        ) {
          return _RecurringError(
            error: error,
            onRetry: () {
              ref.invalidate(
                recurringTransactionsProvider,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RecurringTransactionDetails item,
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
            'Excluir recorrência?',
          ),
          content: Text(
            'A regra "${item.rule.description}" será removida. '
            'As transações já geradas continuarão no histórico.',
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
            recurringTransactionsRepositoryProvider,
          )
          .deleteRule(
            item.rule.id,
          );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Recorrência excluída.',
            ),
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível excluir a recorrência.',
            ),
          ),
        );
    }
  }
}

// ===========================================================
// INTRO
// ===========================================================

class _PageIntro extends StatelessWidget {
  const _PageIntro();

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
                'Automatize seus lançamentos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Organize despesas e receitas que se repetem todos os meses.',
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
            Icons.event_repeat_rounded,
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

class _RecurringSummary extends StatelessWidget {
  final List<RecurringTransactionDetails> items;

  const _RecurringSummary({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeItems = items.where(
      (item) {
        return item.rule.isActive;
      },
    ).toList();

    final activeCount = activeItems.length;

    final pausedCount = items.length - activeCount;

    final monthlyIncome = activeItems.fold<int>(
      0,
      (
        sum,
        item,
      ) {
        if (item.rule.type != 'income') {
          return sum;
        }

        return sum + item.rule.amountInCents;
      },
    );

    final monthlyExpense = activeItems.fold<int>(
      0,
      (
        sum,
        item,
      ) {
        if (item.rule.type != 'expense') {
          return sum;
        }

        return sum + item.rule.amountInCents;
      },
    );

    final result = monthlyIncome - monthlyExpense;

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
                  'Previsão mensal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(
                      alpha: 0.82,
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
                  Icons.autorenew_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Receitas',
                  value: _money(
                    monthlyIncome,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(
                  alpha: 0.16,
                ),
              ),
              const SizedBox(
                width: 18,
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'Despesas',
                  value: _money(
                    monthlyExpense,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Text(
                    'Resultado previsto',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.82,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _money(
                    result,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryBadge(
                icon: Icons.check_circle_outline_rounded,
                label: '$activeCount ${activeCount == 1 ? 'ativa' : 'ativas'}',
              ),
              if (pausedCount > 0)
                _SummaryBadge(
                  icon: Icons.pause_circle_outline_rounded,
                  label:
                      '$pausedCount ${pausedCount == 1 ? 'pausada' : 'pausadas'}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryValue({
    required this.label,
    required this.value,
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
              alpha: 0.70,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryBadge({
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
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// INFORMAÇÃO
// ===========================================================

class _InformationCard extends StatelessWidget {
  const _InformationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.primary,
            size: 19,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'Movimentações vencidas são adicionadas automaticamente quando o FinanSee é aberto.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// SECTION HEADER
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
                'Suas recorrências',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                'Toque em uma recorrência para editar',
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
// CARD
// ===========================================================

class _RecurringCard extends StatelessWidget {
  final RecurringTransactionDetails item;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _RecurringCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rule = item.rule;

    final isIncome = rule.type == 'income';

    final color = isIncome ? AppTheme.income : AppTheme.expense;

    final displayColor =
        rule.isActive ? color : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            8,
            14,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: displayColor.withValues(
                        alpha: rule.isActive ? 0.10 : 0.07,
                      ),
                      borderRadius: BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: Icon(
                      categoryIconFromKey(
                        item.category.icon ?? '',
                      ),
                      color: displayColor,
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
                          rule.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: rule.isActive
                                ? null
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          '${item.category.name} • ${item.account.name}',
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
                    width: 8,
                  ),
                  Text(
                    '${isIncome ? '+' : '-'} '
                    '${_money(rule.amountInCents.abs())}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: displayColor,
                      fontWeight: FontWeight.w800,
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
                height: 15,
              ),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      size: 17,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todo dia ${rule.dayOfMonth}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          rule.isActive
                              ? 'Próxima ocorrência em ${_nextDue(rule.dayOfMonth)}'
                              : 'Geração automática pausada',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: rule.isActive,
                    onChanged: onToggle,
                  ),
                ],
              ),
              const SizedBox(
                height: 9,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: rule.isActive
                        ? AppTheme.income.withValues(
                            alpha: 0.09,
                          )
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      30,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rule.isActive
                            ? Icons.check_circle_outline_rounded
                            : Icons.pause_circle_outline_rounded,
                        size: 14,
                        color: rule.isActive
                            ? AppTheme.income
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        rule.isActive ? 'Ativa' : 'Pausada',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: rule.isActive
                              ? AppTheme.income
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
// EMPTY
// ===========================================================

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 60,
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
              Icons.event_repeat_rounded,
              size: 38,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Nenhuma recorrência cadastrada',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'Crie receitas ou despesas recorrentes e deixe o FinanSee fazer os lançamentos mensais por você.',
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
              'Criar recorrência',
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

class _RecurringLoading extends StatelessWidget {
  const _RecurringLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        120,
      ),
      children: const [
        _PageIntro(),
        SizedBox(
          height: 20,
        ),
        _LoadingBox(
          height: 220,
          radius: 24,
        ),
        SizedBox(
          height: 16,
        ),
        _LoadingBox(
          height: 70,
          radius: 16,
        ),
        SizedBox(
          height: 28,
        ),
        _LoadingBox(
          width: 170,
          height: 18,
        ),
        SizedBox(
          height: 14,
        ),
        _LoadingBox(
          height: 175,
          radius: 20,
        ),
        SizedBox(
          height: 12,
        ),
        _LoadingBox(
          height: 175,
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

// ===========================================================
// ERROR
// ===========================================================

class _RecurringError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _RecurringError({
    required this.error,
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
        const _PageIntro(),
        const SizedBox(
          height: 70,
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
              'Não foi possível carregar as recorrências',
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
// ANIMAÇÃO
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

String _nextDue(
  int day,
) {
  final now = DateTime.now();

  DateTime due = _dateForDay(
    now.year,
    now.month,
    day,
  );

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  if (due.isBefore(
    today,
  )) {
    due = _dateForDay(
      now.year,
      now.month + 1,
      day,
    );
  }

  if (DateUtils.isSameDay(
    due,
    today,
  )) {
    return 'hoje';
  }

  return DateFormat(
    'dd/MM',
  ).format(
    due,
  );
}

DateTime _dateForDay(
  int year,
  int month,
  int day,
) {
  final lastDay = DateTime(
    year,
    month + 1,
    0,
  ).day;

  return DateTime(
    year,
    month,
    math.min(
      day,
      lastDay,
    ),
  );
}
