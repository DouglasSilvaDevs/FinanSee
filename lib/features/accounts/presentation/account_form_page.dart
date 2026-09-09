import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import 'providers/accounts_providers.dart';

class AccountFormPage extends ConsumerStatefulWidget {
  final int? accountId;

  const AccountFormPage({
    super.key,
    this.accountId,
  });

  bool get isEditing => accountId != null;

  @override
  ConsumerState<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends ConsumerState<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _initialBalanceController = TextEditingController();

  String _type = 'checking';

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _isLoading = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          _loadAccount();
        },
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();

    super.dispose();
  }

  Future<void> _loadAccount() async {
    final repository = ref.read(
      accountsRepositoryProvider,
    );

    final account = await repository.getAccount(
      widget.accountId!,
    );

    if (!mounted) {
      return;
    }

    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Conta não encontrada.',
          ),
        ),
      );

      context.pop();
      return;
    }

    _fillForm(account);

    setState(() {
      _isLoading = false;
    });
  }

  void _fillForm(
    FinanceAccount account,
  ) {
    _nameController.text = account.name;

    _type = account.type;

    _initialBalanceController.text = _formatInputValue(
      account.initialBalanceInCents,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar conta' : 'Nova conta',
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
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      widget.isEditing
                          ? 'Atualize as informações da sua conta.'
                          : 'Cadastre uma conta para organizar melhor seu dinheiro.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome da conta',
                        hintText: 'Ex.: Nubank',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome da conta.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo da conta',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'cash',
                          child: Text(
                            'Carteira / Dinheiro',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'checking',
                          child: Text(
                            'Conta corrente',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'savings',
                          child: Text(
                            'Poupança',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'investment',
                          child: Text(
                            'Investimentos',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(
                            'Outra',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _type = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _initialBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Saldo inicial',
                        hintText: '0,00',
                        prefixText: 'R\$ ',
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o saldo inicial.';
                        }

                        final cents = _parseMoney(
                          value,
                        );

                        if (cents == null) {
                          return 'Informe um valor válido.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isEditing
                          ? 'Alterar o saldo inicial recalcula o saldo atual da conta. As transações não serão alteradas.'
                          : 'Use o valor que já existe na conta antes de começar a registrar movimentações no FinanSee.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
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
                                  : 'Criar conta',
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final balance = _parseMoney(
      _initialBalanceController.text,
    );

    if (balance == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(
        accountsRepositoryProvider,
      );

      if (widget.isEditing) {
        await repository.updateAccount(
          accountId: widget.accountId!,
          name: _nameController.text,
          type: _type,
          initialBalanceInCents: balance,
        );
      } else {
        await repository.createAccount(
          name: _nameController.text,
          type: _type,
          initialBalanceInCents: balance,
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar a conta: $error',
          ),
        ),
      );

      setState(() {
        _isSaving = false;
      });
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
