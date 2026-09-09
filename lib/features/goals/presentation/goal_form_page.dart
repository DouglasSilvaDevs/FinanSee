import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/goal_icons.dart';
import 'providers/goals_providers.dart';

class GoalFormPage extends ConsumerStatefulWidget {
  final int? goalId;

  const GoalFormPage({
    super.key,
    this.goalId,
  });

  bool get isEditing => goalId != null;

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _targetController = TextEditingController();

  final _initialAmountController = TextEditingController();

  String _icon = 'target';

  DateTime? _deadline;

  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loading = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          _loadGoal();
        },
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _initialAmountController.dispose();

    super.dispose();
  }

  Future<void> _loadGoal() async {
    try {
      final goal = await ref
          .read(
            goalsRepositoryProvider,
          )
          .getGoal(
            widget.goalId!,
          );

      if (!mounted) {
        return;
      }

      if (goal == null) {
        context.pop();

        return;
      }

      _nameController.text = goal.name;

      _targetController.text = _formatInput(
        goal.targetInCents,
      );

      _icon = goal.icon ?? 'target';

      _deadline = goal.deadline;

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
              'Não foi possível carregar a meta.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final target = _parseMoney(
      _targetController.text,
    );

    final initialAmount = _parseMoney(
          _initialAmountController.text,
        ) ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar meta' : 'Nova meta',
        ),
      ),
      body: _loading
          ? const _GoalFormLoading()
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
                            goalIconFromKey(
                              _icon,
                            ),
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
                                    ? 'Ajuste seu objetivo'
                                    : 'Crie um novo objetivo',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Defina o valor que deseja alcançar e acompanhe sua evolução.',
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
                    const _FieldTitle(
                      title: 'Objetivo',
                      subtitle: 'Dê um nome e defina o valor da sua meta.',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome da meta',
                        hintText: 'Ex.: PC novo',
                        prefixIcon: Icon(
                          Icons.flag_outlined,
                        ),
                      ),
                      validator: (
                        value,
                      ) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome da meta.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor da meta',
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                        prefixIcon: Icon(
                          Icons.savings_outlined,
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                      validator: (
                        value,
                      ) {
                        final amount = _parseMoney(
                          value ?? '',
                        );

                        if (amount == null || amount <= 0) {
                          return 'Informe um valor válido.';
                        }

                        return null;
                      },
                    ),
                    if (!widget.isEditing) ...[
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        controller: _initialAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor já acumulado',
                          prefixText: 'R\$ ',
                          hintText: '0,00',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ],
                    const SizedBox(
                      height: 26,
                    ),
                    const _FieldTitle(
                      title: 'Prazo',
                      subtitle:
                          'Você pode definir uma data ou deixar a meta sem prazo.',
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                      onTap: _selectDeadline,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Prazo',
                          prefixIcon: Icon(
                            Icons.event_outlined,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _deadline == null
                                    ? 'Sem prazo definido'
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(
                                        _deadline!,
                                      ),
                              ),
                            ),
                            if (_deadline != null)
                              IconButton(
                                tooltip: 'Remover prazo',
                                onPressed: () {
                                  setState(() {
                                    _deadline = null;
                                  });
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                ),
                              )
                            else
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 19,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    const _FieldTitle(
                      title: 'Ícone',
                      subtitle:
                          'Escolha um símbolo para identificar rapidamente sua meta.',
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    LayoutBuilder(
                      builder: (
                        context,
                        constraints,
                      ) {
                        final columns = constraints.maxWidth < 340 ? 4 : 5;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: goalIconOptions.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (
                            context,
                            index,
                          ) {
                            final option = goalIconOptions[index];

                            final selected = option.key == _icon;

                            return Tooltip(
                              message: option.label,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  16,
                                ),
                                onTap: () {
                                  setState(() {
                                    _icon = option.key;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 160,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? theme.colorScheme.primaryContainer
                                        : theme.colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      16,
                                    ),
                                    border: Border.all(
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (target != null && target > 0) ...[
                      const SizedBox(
                        height: 28,
                      ),
                      _GoalPreview(
                        targetInCents: target,
                        initialInCents: widget.isEditing ? 0 : initialAmount,
                        deadline: _deadline,
                        icon: _icon,
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
                                  : 'Criar meta',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ??
          DateTime(
            now.year,
            now.month + 1,
            now.day,
          ),
      firstDate: today,
      lastDate: DateTime(
        now.year + 20,
      ),
    );

    if (date == null) {
      return;
    }

    setState(() {
      _deadline = date;
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final target = _parseMoney(
      _targetController.text,
    );

    if (target == null) {
      return;
    }

    final initialAmount = _parseMoney(
          _initialAmountController.text,
        ) ??
        0;

    if (initialAmount > target) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'O valor acumulado inicial não pode ser maior que a meta.',
            ),
          ),
        );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(
        goalsRepositoryProvider,
      );

      if (widget.isEditing) {
        await repository.updateGoal(
          goalId: widget.goalId!,
          name: _nameController.text.trim(),
          targetInCents: target,
          icon: _icon,
          deadline: _deadline,
        );
      } else {
        await repository.createGoal(
          name: _nameController.text.trim(),
          targetInCents: target,
          icon: _icon,
          deadline: _deadline,
          initialAmountInCents: initialAmount,
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
// FIELD TITLE
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

class _GoalPreview extends StatelessWidget {
  final int targetInCents;
  final int initialInCents;
  final DateTime? deadline;
  final String icon;

  const _GoalPreview({
    required this.targetInCents,
    required this.initialInCents,
    required this.deadline,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progress = targetInCents <= 0 ? 0.0 : initialInCents / targetInCents;

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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              goalIconFromKey(
                icon,
              ),
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
                  'Objetivo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  _money(
                    targetInCents,
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (deadline != null) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Prazo: ${DateFormat('dd/MM/yyyy').format(deadline!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (initialInCents > 0) ...[
                  const SizedBox(
                    height: 8,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                    child: LinearProgressIndicator(
                      value: progress.clamp(
                        0.0,
                        1.0,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
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
// LOADING
// ===========================================================

class _GoalFormLoading extends StatelessWidget {
  const _GoalFormLoading();

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
          height: 26,
        ),
        _LoadingBox(
          height: 58,
          radius: 14,
        ),
        SizedBox(
          height: 28,
        ),
        _LoadingBox(
          height: 160,
          radius: 18,
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
// HELPERS
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
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(
    cents / 100,
  );
}
