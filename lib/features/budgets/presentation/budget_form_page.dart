import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../categories/domain/category_icons.dart';
import '../data/budgets_repository.dart';
import 'providers/budgets_providers.dart';

class BudgetFormPage extends ConsumerStatefulWidget {
  final int? budgetId;

  final int year;
  final int month;

  const BudgetFormPage({
    super.key,
    this.budgetId,
    required this.year,
    required this.month,
  });

  bool get isEditing => budgetId != null;

  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _limitController = TextEditingController();

  int? _categoryId;

  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loading = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          _loadBudget();
        },
      );
    }
  }

  @override
  void dispose() {
    _limitController.dispose();

    super.dispose();
  }

  Future<void> _loadBudget() async {
    final repository = ref.read(
      budgetsRepositoryProvider,
    );

    try {
      final budget = await repository.getBudget(
        widget.budgetId!,
      );

      if (!mounted) {
        return;
      }

      if (budget == null) {
        context.pop();

        return;
      }

      _categoryId = budget.categoryId;

      _limitController.text = _formatInput(
        budget.limitInCents,
      );

      setState(() {
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível carregar o orçamento.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(
      budgetExpenseCategoriesProvider,
    );

    final theme = Theme.of(context);

    final parsedLimit = _parseMoney(
      _limitController.text,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar orçamento' : 'Novo orçamento',
        ),
      ),
      body: _loading
          ? const _BudgetFormLoading()
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    32,
                  ),
                  children: [
                    //
                    // =====================================
                    // INTRO
                    // =====================================
                    //
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
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
                        const SizedBox(
                          width: 14,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _monthLabel(
                                  widget.month,
                                  widget.year,
                                ),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                widget.isEditing
                                    ? 'Ajuste o limite definido para esta categoria.'
                                    : 'Defina quanto deseja gastar em uma categoria neste mês.',
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
                      height: 28,
                    ),

                    //
                    // =====================================
                    // CATEGORIA
                    // =====================================
                    //
                    _FieldTitle(
                      title: 'Categoria',
                      subtitle:
                          'Escolha qual tipo de despesa deseja controlar.',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    categories.when(
                      data: (items) {
                        final current = items.any(
                          (item) {
                            return item.id == _categoryId;
                          },
                        )
                            ? _categoryId
                            : null;

                        String selectedIcon = '';

                        for (final item in items) {
                          if (item.id == _categoryId) {
                            selectedIcon = item.icon ?? '';
                            break;
                          }
                        }

                        if (items.isEmpty) {
                          return const _NoCategoriesCard();
                        }

                        return DropdownButtonFormField<int>(
                          value: current,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Categoria',
                            prefixIcon: Icon(
                              categoryIconFromKey(
                                selectedIcon,
                              ),
                            ),
                          ),
                          hint: const Text(
                            'Selecione uma categoria',
                          ),
                          items: items.map(
                            (
                              category,
                            ) {
                              return DropdownMenuItem<int>(
                                value: category.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      categoryIconFromKey(
                                        category.icon,
                                      ),
                                      size: 20,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (
                            value,
                          ) {
                            setState(() {
                              _categoryId = value;
                            });
                          },
                          validator: (
                            value,
                          ) {
                            if (value == null) {
                              return 'Selecione uma categoria.';
                            }

                            return null;
                          },
                        );
                      },
                      loading: () {
                        return const _FieldLoading();
                      },
                      error: (
                        error,
                        stackTrace,
                      ) {
                        return _CategoryError(
                          onRetry: () {
                            ref.invalidate(
                              budgetExpenseCategoriesProvider,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    //
                    // =====================================
                    // LIMITE
                    // =====================================
                    //
                    const _FieldTitle(
                      title: 'Limite mensal',
                      subtitle: 'Informe o valor máximo que deseja gastar.',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextFormField(
                      controller: _limitController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Limite mensal',
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      onFieldSubmitted: (_) {
                        if (!_saving) {
                          _save();
                        }
                      },
                      validator: (
                        value,
                      ) {
                        final amount = _parseMoney(
                          value ?? '',
                        );

                        if (amount == null || amount <= 0) {
                          return 'Informe um limite válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Container(
                      padding: const EdgeInsets.all(
                        13,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Expanded(
                            child: Text(
                              'O FinanSee irá comparar esse limite com todas as despesas dessa categoria durante o mês.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (parsedLimit != null && parsedLimit > 0) ...[
                      const SizedBox(
                        height: 24,
                      ),
                      _BudgetPreview(
                        limitInCents: parsedLimit,
                      ),
                    ],

                    const SizedBox(
                      height: 32,
                    ),

                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                widget.isEditing
                                    ? Icons.save_outlined
                                    : Icons.check_rounded,
                              ),
                        label: Text(
                          _saving
                              ? 'Salvando...'
                              : widget.isEditing
                                  ? 'Salvar alterações'
                                  : 'Criar orçamento',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final limit = _parseMoney(
      _limitController.text,
    );

    if (limit == null || _categoryId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final repository = ref.read(
      budgetsRepositoryProvider,
    );

    try {
      late BudgetSaveResult result;

      if (widget.isEditing) {
        result = await repository.updateBudget(
          budgetId: widget.budgetId!,
          categoryId: _categoryId!,
          year: widget.year,
          month: widget.month,
          limitInCents: limit,
        );
      } else {
        result = await repository.createBudget(
          categoryId: _categoryId!,
          year: widget.year,
          month: widget.month,
          limitInCents: limit,
        );
      }

      if (!mounted) {
        return;
      }

      switch (result) {
        case BudgetSaveResult.saved:
          context.pop(
            true,
          );

        case BudgetSaveResult.duplicate:
          setState(() {
            _saving = false;
          });

          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Já existe um orçamento para essa categoria neste mês.',
                ),
              ),
            );

        case BudgetSaveResult.notFound:
          setState(() {
            _saving = false;
          });

          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Orçamento não encontrado.',
                ),
              ),
            );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível salvar o orçamento.',
            ),
          ),
        );
    }
  }
}

// ===========================================================
// TÍTULO DOS CAMPOS
// ===========================================================

class _FieldTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FieldTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// PREVIEW
// ===========================================================

class _BudgetPreview extends StatelessWidget {
  final int limitInCents;

  const _BudgetPreview({
    required this.limitInCents,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(
        17,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
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
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              Icons.flag_outlined,
              color: theme.colorScheme.onPrimaryContainer,
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
                  'Limite definido',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  _money(
                    limitInCents,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: AppTheme.income,
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// CATEGORY STATES
// ===========================================================

class _FieldLoading extends StatelessWidget {
  const _FieldLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
    );
  }
}

class _CategoryError extends StatelessWidget {
  final VoidCallback onRetry;

  const _CategoryError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'Não foi possível carregar as categorias.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Tentar',
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCategoriesCard extends StatelessWidget {
  const _NoCategoriesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Text(
              'Nenhuma categoria de despesa disponível.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// FORM LOADING
// ===========================================================

class _BudgetFormLoading extends StatelessWidget {
  const _BudgetFormLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        32,
      ),
      children: const [
        Row(
          children: [
            _LoadingBox(
              width: 48,
              height: 48,
              radius: 15,
            ),
            SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LoadingBox(
                    width: 160,
                    height: 18,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  _LoadingBox(
                    width: 220,
                    height: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 30,
        ),
        _LoadingBox(
          width: 120,
          height: 16,
        ),
        SizedBox(
          height: 12,
        ),
        _LoadingBox(
          height: 58,
          radius: 14,
        ),
        SizedBox(
          height: 26,
        ),
        _LoadingBox(
          width: 130,
          height: 16,
        ),
        SizedBox(
          height: 12,
        ),
        _LoadingBox(
          height: 58,
          radius: 14,
        ),
        SizedBox(
          height: 32,
        ),
        _LoadingBox(
          height: 54,
          radius: 14,
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
// MONEY
// ===========================================================

int? _parseMoney(
  String raw,
) {
  var value = raw
      .trim()
      .replaceAll(
        'R\$',
        '',
      )
      .replaceAll(
        ' ',
        '',
      );

  if (value.isEmpty) {
    return null;
  }

  if (value.contains(',') && value.contains('.')) {
    value = value.replaceAll(
      '.',
      '',
    );

    value = value.replaceAll(
      ',',
      '.',
    );
  } else if (value.contains(',')) {
    value = value.replaceAll(
      ',',
      '.',
    );
  }

  final number = double.tryParse(
    value,
  );

  if (number == null) {
    return null;
  }

  return (number * 100).round();
}

String _formatInput(
  int cents,
) {
  return (cents / 100)
      .toStringAsFixed(
        2,
      )
      .replaceAll(
        '.',
        ',',
      );
}

String _money(
  int cents,
) {
  return 'R\$ '
      '${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
}

String _monthLabel(
  int month,
  int year,
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

  return '${months[month - 1]} $year';
}
