import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../categories/domain/category_icons.dart';
import 'providers/transactions_providers.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  final int? transactionId;

  const TransactionFormPage({
    super.key,
    this.transactionId,
  });

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();

  final _amountController = TextEditingController();

  final _notesController = TextEditingController();

  String _type = 'expense';

  int? _accountId;
  int? _categoryId;

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _isLoading = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadTransaction(),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _loadTransaction() async {
    final repository = ref.read(
      transactionsRepositoryProvider,
    );

    final transaction = await repository.getTransaction(
      widget.transactionId!,
    );

    if (!mounted) {
      return;
    }

    if (transaction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transação não encontrada.',
          ),
        ),
      );

      context.pop();

      return;
    }

    _fillForm(
      transaction,
    );

    setState(() {
      _isLoading = false;
    });
  }

  void _fillForm(
    FinanceTransaction transaction,
  ) {
    _descriptionController.text = transaction.description;

    _amountController.text = _formatInputValue(
      transaction.amountInCents,
    );

    _notesController.text = transaction.notes ?? '';

    _type = transaction.type;

    _accountId = transaction.accountId;

    _categoryId = transaction.categoryId;

    _selectedDate = transaction.date;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Editar transação'
              : _type == 'expense'
                  ? 'Nova despesa'
                  : 'Nova receita',
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(
                    20,
                  ),
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'expense',
                          icon: Icon(
                            Icons.arrow_downward_rounded,
                          ),
                          label: Text(
                            'Despesa',
                          ),
                        ),
                        ButtonSegment(
                          value: 'income',
                          icon: Icon(
                            Icons.arrow_upward_rounded,
                          ),
                          label: Text(
                            'Receita',
                          ),
                        ),
                      ],
                      selected: {
                        _type,
                      },
                      onSelectionChanged: (selection) {
                        setState(() {
                          _type = selection.first;

                          _categoryId = null;
                        });
                      },
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    Text(
                      'Valor',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _type == 'expense' ? AppTheme.expense : AppTheme.income,
                      ),
                      decoration: const InputDecoration(
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o valor.';
                        }

                        final cents = _parseMoney(
                          value,
                        );

                        if (cents == null || cents <= 0) {
                          return 'Informe um valor válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Ex.: Supermercado',
                        prefixIcon: Icon(
                          Icons.description_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe uma descrição.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    accounts.when(
                      data: (items) {
                        final currentValue = items.any(
                          (item) => item.id == _accountId,
                        )
                            ? _accountId
                            : null;

                        return DropdownButtonFormField<int>(
                          value: currentValue,
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
                              return DropdownMenuItem(
                                value: account.id,
                                child: Text(
                                  account.name,
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            setState(
                              () {
                                _accountId = value;
                              },
                            );
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione uma conta.';
                            }

                            return null;
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (
                        error,
                        stackTrace,
                      ) =>
                          Text(
                        'Erro ao carregar contas: $error',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    categories.when(
                      data: (items) {
                        final currentValue = items.any(
                          (item) => item.id == _categoryId,
                        )
                            ? _categoryId
                            : null;

                        return DropdownButtonFormField<int>(
                          value: currentValue,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            prefixIcon: Icon(
                              Icons.category_outlined,
                            ),
                          ),
                          hint: const Text(
                            'Selecione uma categoria',
                          ),
                          items: items.map(
                            (
                              category,
                            ) {
                              return DropdownMenuItem(
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
                                    Text(
                                      category.name,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            setState(
                              () {
                                _categoryId = value;
                              },
                            );
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione uma categoria.';
                            }

                            return null;
                          },
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (
                        error,
                        stackTrace,
                      ) =>
                          Text(
                        'Erro ao carregar categorias: $error',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          prefixIcon: Icon(
                            Icons.calendar_today_outlined,
                          ),
                        ),
                        child: Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(
                            _selectedDate,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      controller: _notesController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        hintText: 'Opcional',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.check_rounded,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Salvando...'
                              : widget.isEditing
                                  ? 'Salvar alterações'
                                  : 'Salvar transação',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date == null) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = _parseMoney(
      _amountController.text,
    );

    if (amount == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(
        transactionsRepositoryProvider,
      );

      if (widget.isEditing) {
        await repository.updateTransaction(
          transactionId: widget.transactionId!,
          description: _descriptionController.text,
          amountInCents: amount,
          type: _type,
          date: _selectedDate,
          accountId: _accountId!,
          categoryId: _categoryId!,
          notes: _notesController.text,
        );
      } else {
        await repository.createTransaction(
          description: _descriptionController.text,
          amountInCents: amount,
          type: _type,
          date: _selectedDate,
          accountId: _accountId!,
          categoryId: _categoryId!,
          notes: _notesController.text,
        );
      }

      if (!mounted) {
        return;
      }

      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar: $error',
          ),
        ),
      );
    }
  }
}

int? _parseMoney(
  String raw,
) {
  var value = raw.trim().replaceAll('R\$', '').replaceAll(' ', '');

  if (value.isEmpty) {
    return null;
  }

  if (value.contains(',') && value.contains('.')) {
    value = value.replaceAll('.', '');

    value = value.replaceAll(',', '.');
  } else if (value.contains(',')) {
    value = value.replaceAll(',', '.');
  }

  final number = double.tryParse(value);

  if (number == null) {
    return null;
  }

  return (number * 100).round();
}

String _formatInputValue(
  int cents,
) {
  return (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
}
