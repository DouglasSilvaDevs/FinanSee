import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/report_models.dart';
import 'providers/reports_providers.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/report_export_card.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({
    super.key,
  });

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
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
    final theme = Theme.of(context);

    final summary = ref.watch(
      reportMonthSummaryProvider(
        _selectedMonth,
      ),
    );

    final categories = ref.watch(
      reportCategoriesProvider(
        _selectedMonth,
      ),
    );

    final history = ref.watch(
      reportSixMonthsProvider(
        _selectedMonth,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              reportMonthSummaryProvider(
                _selectedMonth,
              ),
            );

            ref.invalidate(
              reportCategoriesProvider(
                _selectedMonth,
              ),
            );

            ref.invalidate(
              reportSixMonthsProvider(
                _selectedMonth,
              ),
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              110,
            ),
            children: [
              //
              // =====================================
              // CABEÇALHO
              // =====================================
              //
              _Appear(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Relatórios',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Entenda como seu dinheiro está se comportando.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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
                        Icons.insights_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              //
              // =====================================
              // MÊS
              // =====================================
              //
              _Appear(
                child: _MonthSelector(
                  selectedMonth: _selectedMonth,
                  onPrevious: _previousMonth,
                  onNext: _isCurrentMonth ? null : _nextMonth,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              //
              // =====================================
              // RESUMO
              // =====================================
              //
              summary.when(
                data: (data) {
                  return _Appear(
                    child: _SummarySection(
                      summary: data,
                    ),
                  );
                },
                loading: () {
                  return const _SummaryLoading();
                },
                error: (
                  error,
                  stackTrace,
                ) {
                  return _ErrorCard(
                    message: 'Não foi possível calcular o resumo do mês.',
                    onRetry: () {
                      ref.invalidate(
                        reportMonthSummaryProvider(
                          _selectedMonth,
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              //
              // =====================================
              // HISTÓRICO
              // =====================================
              //
              history.when(
                data: (months) {
                  return _Appear(
                    child: MonthlyBarChart(
                      months: months,
                    ),
                  );
                },
                loading: () {
                  return const _LoadingCard(
                    height: 390,
                  );
                },
                error: (
                  error,
                  stackTrace,
                ) {
                  return _ErrorCard(
                    message:
                        'Não foi possível carregar o histórico financeiro.',
                    onRetry: () {
                      ref.invalidate(
                        reportSixMonthsProvider(
                          _selectedMonth,
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              //
              // =====================================
              // CATEGORIAS
              // =====================================
              //
              categories.when(
                data: (items) {
                  return _Appear(
                    child: _CategoriesRanking(
                      items: items,
                    ),
                  );
                },
                loading: () {
                  return const _LoadingCard(
                    height: 280,
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
                        reportCategoriesProvider(
                          _selectedMonth,
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              //
              // =====================================
              // EXPORTAÇÃO
              // =====================================
              //
              _Appear(
                child: ReportExportCard(
                  selectedMonth: _selectedMonth,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
// SELETOR DE MÊS
// ===========================================================

class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;

  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
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
                    selectedMonth.month,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  '${selectedMonth.year}',
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
// RESUMO
// ===========================================================

class _SummarySection extends StatelessWidget {
  final ReportMonthSummary summary;

  const _SummarySection({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final result = summary.resultInCents;

    final positive = result >= 0;

    final resultColor = positive ? AppTheme.income : AppTheme.expense;

    return Column(
      children: [
        LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            if (constraints.maxWidth < 340) {
              return Column(
                children: [
                  _ReportCard(
                    title: 'Receitas',
                    value: _money(
                      summary.incomeInCents,
                    ),
                    icon: Icons.south_west_rounded,
                    color: AppTheme.income,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  _ReportCard(
                    title: 'Despesas',
                    value: _money(
                      summary.expenseInCents,
                    ),
                    icon: Icons.north_east_rounded,
                    color: AppTheme.expense,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _ReportCard(
                    title: 'Receitas',
                    value: _money(
                      summary.incomeInCents,
                    ),
                    icon: Icons.south_west_rounded,
                    color: AppTheme.income,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: _ReportCard(
                    title: 'Despesas',
                    value: _money(
                      summary.expenseInCents,
                    ),
                    icon: Icons.north_east_rounded,
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
        Container(
          padding: const EdgeInsets.all(
            17,
          ),
          decoration: BoxDecoration(
            color: resultColor.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: resultColor.withValues(
                alpha: 0.12,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: resultColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: resultColor,
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
                          ? 'Seu mês está positivo'
                          : 'Suas despesas superaram as receitas',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _money(
                    result,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: resultColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
                  width: 38,
                  height: 38,
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
                    color: color,
                    size: 19,
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
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// RANKING
// ===========================================================

class _CategoriesRanking extends StatelessWidget {
  final List<ReportCategoryTotal> items;

  const _CategoriesRanking({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return const _EmptyCategories();
    }

    final total = items.fold<int>(
      0,
      (
        sum,
        item,
      ) =>
          sum + item.totalInCents,
    );

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
                    Icons.leaderboard_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
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
                        'Maiores gastos',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Categorias que mais consumiram seu orçamento',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 22,
            ),
            ...List.generate(
              items.length,
              (
                index,
              ) {
                final item = items[index];

                final percentage = total == 0 ? 0.0 : item.totalInCents / total;

                return _RankingItem(
                  position: index + 1,
                  name: item.categoryName,
                  valueInCents: item.totalInCents,
                  percentage: percentage,
                  isLast: index == items.length - 1,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  final int position;
  final String name;
  final int valueInCents;
  final double percentage;
  final bool isLast;

  const _RankingItem({
    required this.position,
    required this.name,
    required this.valueInCents,
    required this.percentage,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primary = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 18,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: position <= 3
                      ? primary.withValues(
                          alpha: 0.11,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: Text(
                  '$position',
                  style: TextStyle(
                    color: position <= 3
                        ? primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
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
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}% das despesas',
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
                _money(
                  valueInCents,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
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
              value: percentage.clamp(
                0.0,
                1.0,
              ),
              minHeight: 7,
              backgroundColor: primary.withValues(
                alpha: 0.08,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

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
                Icons.category_outlined,
                size: 30,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Sem despesas neste mês',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Quando houver gastos, as categorias com maior impacto aparecerão aqui.',
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
// LOADING
// ===========================================================

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LoadingBox(
                height: 120,
              ),
            ),
            SizedBox(
              width: 12,
            ),
            Expanded(
              child: _LoadingBox(
                height: 120,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 12,
        ),
        _LoadingBox(
          height: 78,
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Padding(
          padding: EdgeInsets.all(
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LoadingLine(
                width: 170,
                height: 16,
              ),
              SizedBox(
                height: 10,
              ),
              _LoadingLine(
                width: 210,
                height: 10,
              ),
              Spacer(),
              Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  final double height;

  const _LoadingBox({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  final double? width;
  final double height;

  const _LoadingLine({
    this.width,
    required this.height,
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
          8,
        ),
      ),
    );
  }
}

// ===========================================================
// ERRO
// ===========================================================

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 10,
            ),
            TextButton.icon(
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
        milliseconds: 400,
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
