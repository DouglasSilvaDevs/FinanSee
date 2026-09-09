import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../categories/domain/category_icons.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/transactions_providers.dart';

class NewTransactionPage extends ConsumerStatefulWidget {
  const NewTransactionPage({super.key});

  @override
  ConsumerState<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends ConsumerState<NewTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'expense';

  int? _accountId;
  int? _categoryId;

  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accounts = ref.watch(accountsProvider);

    final categories = ref.watch(
      categoriesByTypeProvider(_type),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _type == 'expense' ? 'Nova despesa' : 'Nova receita',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    icon: Icon(
                      Icons.arrow_downward_rounded,
                    ),
                    label: Text('Despesa'),
                  ),
                  ButtonSegment(
                    value: 'income',
                    icon: Icon(
                      Icons.arrow_upward_rounded,
                    ),
                    label: Text('Receita'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;

                    // A categoria precisa mudar porque
                    // receitas e despesas possuem
                    // categorias diferentes.
                    _categoryId = null;
                  });
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Valor',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
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

                  final cents = _parseAmountInCents(value);

                  if (cents == null || cents <= 0) {
                    return 'Informe um valor válido.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 16),
              accounts.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Text(
                      'Nenhuma conta cadastrada.',
                    );
                  }

                  return DropdownButtonFormField<int>(
                    value: _accountId,
                    decoration: const InputDecoration(
                      labelText: 'Conta',
                      prefixIcon: Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    hint: const Text(
                      'Selecione uma conta',
                    ),
                    items: items.map((account) {
                      return DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _accountId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma conta.';
                      }

                      return null;
                    },
                  );
                },
                loading: () {
                  return const LinearProgressIndicator();
                },
                error: (error, stackTrace) {
                  return Text(
                    'Erro ao carregar contas: $error',
                  );
                },
              ),
              const SizedBox(height: 16),
              categories.when(
                data: (items) {
                  return DropdownButtonFormField<int>(
                    value: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(
                        Icons.category_outlined,
                      ),
                    ),
                    hint: const Text(
                      'Selecione uma categoria',
                    ),
                    items: items.map((category) {
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
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma categoria.';
                      }

                      return null;
                    },
                  );
                },
                loading: () {
                  return const LinearProgressIndicator();
                },
                error: (error, stackTrace) {
                  return Text(
                    'Erro ao carregar categorias: $error',
                  );
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(16),
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
                    ).format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Opcional',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      bottom: 48,
                    ),
                    child: Icon(
                      Icons.notes_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveTransaction,
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
                    _isSaving ? 'Salvando...' : 'Salvar transação',
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

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountInCents = _parseAmountInCents(
      _amountController.text,
    );

    if (amountInCents == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(
        transactionsRepositoryProvider,
      );

      await repository.createTransaction(
        description: _descriptionController.text,
        amountInCents: amountInCents,
        type: _type,
        date: _selectedDate,
        accountId: _accountId!,
        categoryId: _categoryId!,
        notes: _notesController.text,
      );

      if (!mounted) {
        return;
      }

      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar: $error',
          ),
        ),
      );

      setState(() {
        _isSaving = false;
      });
    }
  }

  int? _parseAmountInCents(String rawValue) {
    var value = rawValue.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (value.isEmpty) {
      return null;
    }

    // Formato brasileiro:
    // 1.250,90
    if (value.contains(',') && value.contains('.')) {
      value = value.replaceAll('.', '');
      value = value.replaceAll(',', '.');
    } else if (value.contains(',')) {
      // 250,90
      value = value.replaceAll(',', '.');
    }

    final amount = double.tryParse(value);

    if (amount == null) {
      return null;
    }

    return (amount * 100).round();
  }
}
