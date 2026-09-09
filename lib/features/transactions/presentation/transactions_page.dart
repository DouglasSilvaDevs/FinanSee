import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../categories/domain/category_icons.dart';
import '../../categories/presentation/providers/categories_providers.dart';
import '../domain/transaction_models.dart';
import 'providers/transactions_providers.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({
    super.key,
  });

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchController = TextEditingController();

  late DateTime _selectedMonth;

  String _typeFilter = 'all';

  int? _accountFilter;
  int? _categoryFilter;

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
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final transactions = ref.watch(
      detailedTransactionsProvider,
    );

    final accounts = ref.watch(
      accountsProvider,
    );

    final categories = ref.watch(
      allCategoriesProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transações',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Filtros',
                        onPressed: () {
                          final accountItems = accounts.value ?? [];

                          final categoryItems = categories.value ?? [];

                          _openFilters(
                            accountItems,
                            categoryItems,
                          );
                        },
                        icon: Badge(
                          isLabelVisible:
                              _accountFilter != null || _categoryFilter != null,
                          child: const Icon(
                            Icons.tune_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Acompanhe suas receitas e despesas.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar transação...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                      ),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();

                                setState(
                                  () {},
                                );
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  _MonthSelector(
                    month: _selectedMonth,
                    onPrevious: _previousMonth,
                    onNext: _isCurrentMonth ? null : _nextMonth,
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'all',
                          label: Text(
                            'Todas',
                          ),
                        ),
                        ButtonSegment(
                          value: 'expense',
                          label: Text(
                            'Despesas',
                          ),
                        ),
                        ButtonSegment(
                          value: 'income',
                          label: Text(
                            'Receitas',
                          ),
                        ),
                      ],
                      selected: {
                        _typeFilter,
                      },
                      onSelectionChanged: (selection) {
                        setState(() {
                          _typeFilter = selection.first;
                        });
                      },
                    ),
                  ),
                  if (_accountFilter != null || _categoryFilter != null) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_accountFilter != null)
                          InputChip(
                            avatar: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _accountName(
                                accounts.value ?? [],
                                _accountFilter!,
                              ),
                            ),
                            onDeleted: () {
                              setState(
                                () {
                                  _accountFilter = null;
                                },
                              );
                            },
                          ),
                        if (_categoryFilter != null)
                          InputChip(
                            avatar: const Icon(
                              Icons.category_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _categoryName(
                                categories.value ?? [],
                                _categoryFilter!,
                              ),
                            ),
                            onDeleted: () {
                              setState(
                                () {
                                  _categoryFilter = null;
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(
                    height: 14,
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactions.when(
                data: (items) {
                  final filtered = _applyFilters(
                    items,
                  );

                  if (filtered.isEmpty) {
                    return const _EmptyTransactions();
                  }

                  final grouped = _groupTransactions(
                    filtered,
                  );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      120,
                    ),
                    children: [
                      _PeriodSummary(
                        transactions: filtered,
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      for (final entry in grouped.entries) ...[
                        _DayHeader(
                          date: entry.key,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        ...entry.value.map(
                          (
                            item,
                          ) =>
                              Padding(
                            padding: const EdgeInsets.only(
                              bottom: 9,
                            ),
                            child: _TransactionCard(
                              item: item,
                              onEdit: () {
                                _editTransaction(
                                  item.transaction.id,
                                );
                              },
                              onDelete: () {
                                _deleteTransaction(
                                  item,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    ],
                  );
                },
                loading: () {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                error: (
                  error,
                  stackTrace,
                ) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        32,
                      ),
                      child: Text(
                        'Não foi possível carregar as transações.\n\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionDetails> _applyFilters(
    List<TransactionDetails> items,
  ) {
    final search = _searchController.text.trim().toLowerCase();

    return items.where(
      (item) {
        final transaction = item.transaction;

        if (transaction.date.year != _selectedMonth.year ||
            transaction.date.month != _selectedMonth.month) {
          return false;
        }

        if (_typeFilter != 'all' && transaction.type != _typeFilter) {
          return false;
        }

        if (_accountFilter != null && transaction.accountId != _accountFilter) {
          return false;
        }

        if (_categoryFilter != null &&
            transaction.categoryId != _categoryFilter) {
          return false;
        }

        if (search.isNotEmpty) {
          final description = transaction.description.toLowerCase();

          final category = item.category.name.toLowerCase();

          final account = item.account.name.toLowerCase();

          final notes = (transaction.notes ?? '').toLowerCase();

          if (!description.contains(search) &&
              !category.contains(search) &&
              !account.contains(search) &&
              !notes.contains(search)) {
            return false;
          }
        }

        return true;
      },
    ).toList();
  }

  Map<DateTime, List<TransactionDetails>> _groupTransactions(
    List<TransactionDetails> items,
  ) {
    final result = <DateTime, List<TransactionDetails>>{};

    for (final item in items) {
      final date = item.transaction.date;

      final day = DateTime(
        date.year,
        date.month,
        date.day,
      );

      result.putIfAbsent(
        day,
        () => [],
      );

      result[day]!.add(
        item,
      );
    }

    return result;
  }

  Future<void> _editTransaction(
    int id,
  ) async {
    final changed = await context.push<bool>(
      '/transactions/$id/edit',
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transação atualizada.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteTransaction(
    TransactionDetails item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Excluir transação?',
          ),
          content: Text(
            'Deseja excluir "${item.transaction.description}"?',
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

    final repository = ref.read(
      transactionsRepositoryProvider,
    );

    await repository.deleteTransaction(
      item.transaction.id,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Transação excluída.',
        ),
      ),
    );
  }

  Future<void> _openFilters(
    List<FinanceAccount> accounts,
    List<FinanceCategory> categories,
  ) async {
    var account = _accountFilter;

    var category = _categoryFilter;

    final result = await showModalBottomSheet<(int?, int?)>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filtros',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(
                              () {
                                account = null;
                                category = null;
                              },
                            );
                          },
                          child: const Text(
                            'Limpar',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    DropdownButtonFormField<int?>(
                      value: account,
                      decoration: const InputDecoration(
                        labelText: 'Conta',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'Todas as contas',
                          ),
                        ),
                        ...accounts.map(
                          (
                            accountItem,
                          ) =>
                              DropdownMenuItem<int?>(
                            value: accountItem.id,
                            child: Text(
                              accountItem.name,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(
                          () {
                            account = value;
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    DropdownButtonFormField<int?>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'Todas as categorias',
                          ),
                        ),
                        ...categories.map(
                          (
                            item,
                          ) =>
                              DropdownMenuItem<int?>(
                            value: item.id,
                            child: Text(
                              item.name,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(
                          () {
                            category = value;
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            (
                              account,
                              category,
                            ),
                          );
                        },
                        child: const Text(
                          'Aplicar filtros',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _accountFilter = result.$1;

      _categoryFilter = result.$2;
    });
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

class _PeriodSummary extends StatelessWidget {
  final List<TransactionDetails> transactions;

  const _PeriodSummary({
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    var income = 0;
    var expense = 0;

    for (final item in transactions) {
      if (item.transaction.type == 'income') {
        income += item.transaction.amountInCents;
      } else {
        expense += item.transaction.amountInCents;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _MiniSummary(
            label: 'Entradas',
            value: income,
            color: AppTheme.income,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: _MiniSummary(
            label: 'Saídas',
            value: expense,
            color: AppTheme.expense,
          ),
        ),
      ],
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniSummary({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
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
                  value,
                ),
                style: TextStyle(
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

class _TransactionCard extends StatelessWidget {
  final TransactionDetails item;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = item.transaction;

    final isIncome = transaction.type == 'income';

    final color = isIncome ? AppTheme.income : AppTheme.expense;

    return Dismissible(
      key: ValueKey(
        transaction.id,
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text(
                'Excluir transação?',
              ),
              content: Text(
                'Deseja excluir "${transaction.description}"?',
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

        if (result == true) {
          onDelete();
        }

        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(
          right: 22,
        ),
        decoration: BoxDecoration(
          color: AppTheme.expense,
          borderRadius: BorderRadius.circular(
            20,
          ),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(
            20,
          ),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
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
                    categoryIconFromKey(
                      item.category.icon,
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
                        transaction.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '${item.category.name} • ${item.account.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'} ${_money(transaction.amountInCents)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        }

                        if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            'Editar',
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Excluir',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(
            Icons.chevron_left_rounded,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${_monthName(month.month)} ${month.year}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(
            Icons.chevron_right_rounded,
          ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime date;

  const _DayHeader({
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _dayLabel(date),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 50,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Nenhuma transação encontrada',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Tente alterar os filtros ou adicione uma nova movimentação.',
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

String _dayLabel(
  DateTime date,
) {
  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final target = DateTime(
    date.year,
    date.month,
    date.day,
  );

  if (target == today) {
    return 'Hoje';
  }

  final yesterday = today.subtract(
    const Duration(
      days: 1,
    ),
  );

  if (target == yesterday) {
    return 'Ontem';
  }

  return DateFormat(
    "dd 'de' MMMM",
    'pt_BR',
  ).format(
    target,
  );
}

String _accountName(
  List<FinanceAccount> accounts,
  int id,
) {
  for (final account in accounts) {
    if (account.id == id) {
      return account.name;
    }
  }

  return 'Conta';
}

String _categoryName(
  List<FinanceCategory> categories,
  int id,
) {
  for (final category in categories) {
    if (category.id == id) {
      return category.name;
    }
  }

  return 'Categoria';
}
