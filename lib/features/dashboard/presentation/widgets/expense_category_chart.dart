import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/dashboard_models.dart';

class ExpenseCategoryChart extends StatefulWidget {
  final List<ExpenseCategoryTotal> items;

  const ExpenseCategoryChart({
    super.key,
    required this.items,
  });

  @override
  State<ExpenseCategoryChart> createState() => _ExpenseCategoryChartState();
}

class _ExpenseCategoryChartState extends State<ExpenseCategoryChart> {
  int _touchedIndex = -1;

  static const List<Color> _colors = [
    Color(0xFF6366F1),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF14B8A6),
  ];

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    if (widget.items.isEmpty) {
      return const _EmptyChart();
    }

    final totalInCents = widget.items.fold<int>(
      0,
      (
        sum,
        item,
      ) =>
          sum + item.totalInCents,
    );

    final selectedItem =
        _touchedIndex >= 0 && _touchedIndex < widget.items.length
            ? widget.items[_touchedIndex]
            : null;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gastos por categoria',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Distribuição das despesas deste mês',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    Icons.donut_large_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 28,
            ),
            Center(
              child: SizedBox(
                width: 215,
                height: 215,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 61,
                        sectionsSpace: 3,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback: (
                            FlTouchEvent event,
                            PieTouchResponse? response,
                          ) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }

                              _touchedIndex =
                                  response.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: List.generate(
                          widget.items.length,
                          (
                            index,
                          ) {
                            final item = widget.items[index];

                            final percentage = totalInCents == 0
                                ? 0.0
                                : item.totalInCents / totalInCents * 100;

                            final touched = index == _touchedIndex;

                            return PieChartSectionData(
                              value: item.totalInCents.toDouble(),
                              color: _colors[index % _colors.length],
                              radius: touched ? 36 : 29,
                              showTitle: percentage >= 7,
                              title: '${percentage.toStringAsFixed(0)}%',
                              titleStyle: TextStyle(
                                color: Colors.white,
                                fontSize: touched ? 13 : 11,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                      ),
                      duration: const Duration(
                        milliseconds: 350,
                      ),
                    ),
                    IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child: selectedItem == null
                            ? _ChartCenter(
                                key: const ValueKey(
                                  'total',
                                ),
                                label: 'Total',
                                value: _formatCurrency(
                                  totalInCents,
                                ),
                              )
                            : _ChartCenter(
                                key: ValueKey(
                                  _touchedIndex,
                                ),
                                label: selectedItem.categoryName,
                                value: _formatCurrency(
                                  selectedItem.totalInCents,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            ...List.generate(
              widget.items.length,
              (
                index,
              ) {
                final item = widget.items[index];

                final percentage = totalInCents == 0
                    ? 0.0
                    : item.totalInCents / totalInCents * 100;

                return _LegendItem(
                  color: _colors[index % _colors.length],
                  name: item.categoryName,
                  valueInCents: item.totalInCents,
                  percentage: percentage,
                  selected: index == _touchedIndex,
                  onTap: () {
                    setState(() {
                      _touchedIndex = _touchedIndex == index ? -1 : index;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCenter extends StatelessWidget {
  final String label;
  final String value;

  const _ChartCenter({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 108,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String name;
  final int valueInCents;
  final double percentage;
  final bool selected;
  final VoidCallback onTap;

  const _LegendItem({
    required this.color,
    required this.name,
    required this.valueInCents,
    required this.percentage,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 6,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          13,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            13,
          ),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(
                      alpha: 0.08,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  width: selected ? 12 : 10,
                  height: selected ? 12 : 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        selected ? color : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : null,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Flexible(
                  child: Text(
                    _formatCurrency(
                      valueInCents,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

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
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.donut_large_outlined,
                size: 32,
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
              'Quando você registrar despesas, a distribuição por categoria aparecerá aqui.',
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

String _formatCurrency(
  int amountInCents,
) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(
    amountInCents / 100,
  );
}
