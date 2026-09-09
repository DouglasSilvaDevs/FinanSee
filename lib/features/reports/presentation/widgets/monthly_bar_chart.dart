import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/report_models.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlyFinancialData> months;

  const MonthlyBarChart({
    super.key,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (months.isEmpty) {
      return const _EmptyHistory();
    }

    final highestValue = months.fold<double>(
      0,
      (
        current,
        month,
      ) {
        final income = month.incomeInCents / 100;

        final expense = month.expenseInCents / 100;

        return math.max(
          current,
          math.max(
            income,
            expense,
          ),
        );
      },
    );

    final maxY = highestValue <= 0 ? 100.0 : highestValue * 1.25;

    final interval = maxY / 4;

    final totalIncome = months.fold<int>(
      0,
      (
        sum,
        month,
      ) =>
          sum + month.incomeInCents,
    );

    final totalExpense = months.fold<int>(
      0,
      (
        sum,
        month,
      ) =>
          sum + month.expenseInCents,
    );

    final result = totalIncome - totalExpense;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          18,
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receitas × Despesas',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Comparativo dos últimos 6 meses',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 18,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const _Legend(
                  color: AppTheme.income,
                  label: 'Receitas',
                ),
                const _Legend(
                  color: AppTheme.expense,
                  label: 'Despesas',
                ),
                _ResultBadge(
                  positive: result >= 0,
                  valueInCents: result,
                ),
              ],
            ),
            const SizedBox(
              height: 26,
            ),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (
                      value,
                    ) {
                      return FlLine(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.55,
                        ),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: interval,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: 7,
                            ),
                            child: Text(
                              _compactValue(
                                value,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          final index = value.toInt();

                          if (index < 0 || index >= months.length) {
                            return const SizedBox();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 9,
                            ),
                            child: Text(
                              _monthAbbreviation(
                                months[index].month,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    months.length,
                    (
                      index,
                    ) {
                      final data = months[index];

                      return BarChartGroupData(
                        x: index,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: data.incomeInCents / 100,
                            width: 11,
                            color: AppTheme.income,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(
                                5,
                              ),
                            ),
                          ),
                          BarChartRodData(
                            toY: data.expenseInCents / 100,
                            width: 11,
                            color: AppTheme.expense,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(
                                5,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                duration: const Duration(
                  milliseconds: 400,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Divider(
              color: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.6,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                Expanded(
                  child: _HistoryTotal(
                    label: 'Receitas no período',
                    valueInCents: totalIncome,
                    color: AppTheme.income,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: _HistoryTotal(
                    label: 'Despesas no período',
                    valueInCents: totalExpense,
                    color: AppTheme.expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 7,
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final bool positive;
  final int valueInCents;

  const _ResultBadge({
    required this.positive,
    required this.valueInCents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = positive ? AppTheme.income : AppTheme.expense;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            _money(
              valueInCents,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTotal extends StatelessWidget {
  final String label;
  final int valueInCents;
  final Color color;

  const _HistoryTotal({
    required this.label,
    required this.valueInCents,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
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
              valueInCents,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          28,
        ),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 32,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Histórico ainda vazio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'O comparativo mensal aparecerá conforme você registrar movimentações.',
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

String _monthAbbreviation(
  DateTime date,
) {
  const months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  return months[date.month - 1];
}

String _compactValue(
  double value,
) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }

  if (value >= 1000) {
    final result = value / 1000;

    if (result == result.roundToDouble()) {
      return '${result.toInt()}k';
    }

    return '${result.toStringAsFixed(1)}k';
  }

  return value.toInt().toString();
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
