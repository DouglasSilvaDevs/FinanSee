import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../categories/domain/category_icons.dart';
import '../../transactions/presentation/providers/transactions_providers.dart';
import 'providers/recurring_providers.dart';

class RecurringTransactionFormPage extends ConsumerStatefulWidget {
  final int? ruleId;

  const RecurringTransactionFormPage({
    super.key,
    this.ruleId,
  });

  bool get isEditing => ruleId != null;

  @override
  ConsumerState<RecurringTransactionFormPage> createState() =>
      _RecurringTransactionFormPageState();
}

class _RecurringTransactionFormPageState
    extends ConsumerState<RecurringTransactionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();

  final _amountController = TextEditingController();

  final _dayController = TextEditingController();

  final _notesController = TextEditingController();

  String _type = 'expense';

  int? _accountId;
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
          _loadRule();
        },
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _loadRule() async {
    final repository = ref.read(
      recurringTransactionsRepositoryProvider,
    );

    try {
      final rule = await repository.getRule(
        widget.ruleId!,
      );

      if (!mounted) {
        return;
      }

      if (rule == null) {
        context.pop();

        return;
      }

      _fillForm(
        rule,
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
              'Não foi possível carregar a recorrência.',
            ),
          ),
        );
    }
  }

  void _fillForm(
    RecurringTransactionRule rule,
  ) {
    _descriptionController.text = rule.description;

    _amountController.text = _formatInput(
      rule.amountInCents,
    );

    _dayController.text = rule.dayOfMonth.toString();

    _notesController.text = rule.notes ?? '';

    _type = rule.type;

    _accountId = rule.accountId;

    _categoryId = rule.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accounts = ref.watch(
      accountsProvider,
    );

    final categories = ref.watch(
      categoriesByTypeProvider(
        _type,
      ),
    );

    final amount = _parseMoney(
      _amountController.text,
    );

    final day = int.tryParse(
      _dayController.text,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar recorrência' : 'Nova recorrência',
        ),
      ),
      body: _loading
          ? const _RecurringFormLoading()
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
                            Icons.event_repeat_rounded,
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
                                widget.isEditing
                                    ? 'Ajuste sua recorrência'
                                    : 'Automatize um lançamento',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                'O lançamento será criado automaticamente todos os meses.',
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
                      height: 26,
                    ),

                    //
                    // =====================================
                    // TIPO
                    // =====================================
                    //
                    const _FieldTitle(
                      title: 'Tipo de movimentação',
                      subtitle:
                          'Escolha se esta recorrência representa uma entrada ou saída.',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'expense',
                            icon: Icon(
                              Icons.north_east_rounded,
                            ),
                            label: Text(
                              'Despesa',
                            ),
                          ),
                          ButtonSegment(
                            value: 'income',
                            icon: Icon(
                              Icons.south_west_rounded,
                            ),
                            label: Text(
                              'Receita',
                            ),
                          ),
                        ],
                        selected: {
                          _type,
                        },
                        onSelectionChanged: (
                          selection,
                        ) {
                          setState(() {
                            _type = selection.first;
                            _categoryId = null;
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    //
                    // =====================================
                    // DADOS
                    // =====================================
                    //
                    const _FieldTitle(
                      title: 'Dados da recorrência',
                      subtitle:
                          'Informe uma descrição, valor e o dia do lançamento.',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Ex.: Internet',
                        prefixIcon: Icon(
                          Icons.description_outlined,
                        ),
                      ),
                      validator: (
                        value,
                      ) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe uma descrição.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _type == 'expense'
                            ? AppTheme.expense
                            : AppTheme.income,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Valor',
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                        prefixIcon: Icon(
                          _type == 'expense'
                              ? Icons.north_east_rounded
                              : Icons.south_west_rounded,
                          color: _type == 'expense'
                              ? AppTheme.expense
                              : AppTheme.income,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      validator: (
                        value,
                      ) {
                        final parsed = _parseMoney(
                          value ?? '',
                        );

                        if (parsed == null || parsed <= 0) {
                          return 'Informe um valor válido.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    TextFormField(
                      controller: _dayController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          2,
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Dia do mês',
                        hintText: '10',
                        prefixIcon: Icon(
                          Icons.calendar_month_outlined,
                        ),
                        helperText:
                            'Em meses menores, será usado o último dia disponível.',
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      validator: (
                        value,
                      ) {
                        final parsed = int.tryParse(
                          value ?? '',
                        );

                        if (parsed == null || parsed < 1 || parsed > 31) {
                          return 'Informe um dia entre 1 e 31.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    //
                    // =====================================
                    // DESTINO
                    // =====================================
                    //
                    const _FieldTitle(
                      title: 'Classificação',
                      subtitle:
                          'Escolha a conta e a categoria usadas no lançamento.',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    accounts.when(
                      data: (
                        items,
                      ) {
                        final value = items.any(
                          (
                            item,
                          ) {
                            return item.id == _accountId;
                          },
                        )
                            ? _accountId
                            : null;

                        return DropdownButtonFormField<int>(
                          value: value,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Conta',
                            prefixIcon: Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                          hint: const Text(
                            'Selecione uma conta',
                          ),
                          items: items.map(
                            (
                              account,
                            ) {
                              return DropdownMenuItem<int>(
                                value: account.id,
                                child: Text(
                                  account.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (
                            value,
                          ) {
                            setState(() {
                              _accountId = value;
                            });
                          },
                          validator: (
                            value,
                          ) {
                            if (value == null) {
                              return 'Selecione uma conta.';
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
                        return _FieldError(
                          message: 'Não foi possível carregar as contas.',
                          onRetry: () {
                            ref.invalidate(
                              accountsProvider,
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    categories.when(
                      data: (
                        items,
                      ) {
                        final value = items.any(
                          (
                            item,
                          ) {
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

                        return DropdownButtonFormField<int>(
                          value: value,
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
                                        category.icon ?? '',
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
                        return _FieldError(
                          message: 'Não foi possível carregar as categorias.',
                          onRetry: () {
                            ref.invalidate(
                              categoriesByTypeProvider(
                                _type,
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    //
                    // =====================================
                    // OBSERVAÇÕES
                    // =====================================
                    //
                    const _FieldTitle(
                      title: 'Observações',
                      subtitle: 'Adicione informações extras, se desejar.',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextFormField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        hintText: 'Opcional',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(
                            bottom: 54,
                          ),
                          child: Icon(
                            Icons.notes_rounded,
                          ),
                        ),
                      ),
                    ),

                    if (amount != null &&
                        amount > 0 &&
                        day != null &&
                        day >= 1 &&
                        day <= 31) ...[
                      const SizedBox(
                        height: 24,
                      ),
                      _RecurringPreview(
                        type: _type,
                        amountInCents: amount,
                        day: day,
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
                                  : 'Criar recorrência',
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

    final amount = _parseMoney(
      _amountController.text,
    );

    final day = int.tryParse(
      _dayController.text,
    );

    if (amount == null ||
        day == null ||
        _accountId == null ||
        _categoryId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(
        recurringTransactionsRepositoryProvider,
      );

      if (widget.isEditing) {
        await repository.updateRule(
          id: widget.ruleId!,
          description: _descriptionController.text.trim(),
          amountInCents: amount,
          type: _type,
          dayOfMonth: day,
          accountId: _accountId!,
          categoryId: _categoryId!,
          notes: _notesController.text.trim(),
        );
      } else {
        await repository.createRule(
          description: _descriptionController.text.trim(),
          amountInCents: amount,
          type: _type,
          dayOfMonth: day,
          accountId: _accountId!,
          categoryId: _categoryId!,
          notes: _notesController.text.trim(),
        );
      }

      if (!mounted) {
        return;
      }

      context.pop(
        true,
      );
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
          SnackBar(
            content: Text(
              'Não foi possível salvar: $error',
            ),
          ),
        );
    }
  }
}

// ===========================================================
// FIELD TITLES
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

class _RecurringPreview extends StatelessWidget {
  final String type;
  final int amountInCents;
  final int day;

  const _RecurringPreview({
    required this.type,
    required this.amountInCents,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final income = type == 'income';

    final color = income ? AppTheme.income : AppTheme.expense;

    return Container(
      padding: const EdgeInsets.all(
        17,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: color.withValues(
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
              color: color.withValues(
                alpha: 0.11,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              Icons.event_repeat_rounded,
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
                  income ? 'Receita recorrente' : 'Despesa recorrente',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '${_money(amountInCents)} • Todo dia $day',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
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
// FIELD STATES
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

class _FieldError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FieldError({
    required this.message,
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
              message,
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

// ===========================================================
// LOADING
// ===========================================================

class _RecurringFormLoading extends StatelessWidget {
  const _RecurringFormLoading();

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
                    width: 180,
                    height: 18,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  _LoadingBox(
                    width: 225,
                    height: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 28,
        ),
        _LoadingBox(
          height: 50,
          radius: 14,
        ),
        SizedBox(
          height: 28,
        ),
        _LoadingBox(
          height: 58,
          radius: 14,
        ),
        SizedBox(
          height: 16,
        ),
        _LoadingBox(
          height: 58,
          radius: 14,
        ),
        SizedBox(
          height: 16,
        ),
        _LoadingBox(
          height: 76,
          radius: 14,
        ),
        SizedBox(
          height: 28,
        ),
        _LoadingBox(
          height: 58,
          radius: 14,
        ),
        SizedBox(
          height: 16,
        ),
        _LoadingBox(
          height: 58,
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

  return number == null ? null : (number * 100).round();
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
