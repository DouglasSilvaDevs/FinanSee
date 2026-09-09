import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/goal_icons.dart';
import '../domain/goal_models.dart';
import 'providers/goals_providers.dart';

class GoalDetailsPage extends ConsumerWidget {
  final int goalId;

  const GoalDetailsPage({
    super.key,
    required this.goalId,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final goals = ref.watch(
      goalsProvider,
    );

    final contributions = ref.watch(
      goalContributionsProvider(
        goalId,
      ),
    );

    return goals.when(
      data: (
        items,
      ) {
        final matching = items.where(
          (
            item,
          ) {
            return item.id == goalId;
          },
        );

        if (matching.isEmpty) {
          return const _GoalNotFound();
        }

        final goal = matching.first;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              goal.name,
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (
                  value,
                ) {
                  if (value == 'edit') {
                    context.push(
                      '/goals/$goalId/edit',
                    );
                  }

                  if (value == 'delete') {
                    _deleteGoal(
                      context,
                      ref,
                    );
                  }
                },
                itemBuilder: (
                  context,
                ) {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Editar',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Excluir',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          floatingActionButton: goal.isCompleted
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    _showContributionSheet(
                      context,
                      ref,
                    );
                  },
                  icon: const Icon(
                    Icons.add_rounded,
                  ),
                  label: const Text(
                    'Adicionar aporte',
                  ),
                ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                goalsProvider,
              );

              ref.invalidate(
                goalContributionsProvider(
                  goalId,
                ),
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                120,
              ),
              children: [
                _GoalHeader(
                  goal: goal,
                ),
                const SizedBox(
                  height: 28,
                ),
                _ContributionsHeader(
                  contributions: contributions,
                ),
                const SizedBox(
                  height: 12,
                ),
                contributions.when(
                  data: (
                    items,
                  ) {
                    if (items.isEmpty) {
                      return const _EmptyContributions();
                    }

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: List.generate(
                          items.length,
                          (
                            index,
                          ) {
                            final contribution = items[index];

                            return Column(
                              children: [
                                _ContributionTile(
                                  amountInCents: contribution.amountInCents,
                                  date: contribution.date,
                                  notes: contribution.notes,
                                  onDelete: () {
                                    _deleteContribution(
                                      context,
                                      ref,
                                      contribution.id,
                                    );
                                  },
                                ),
                                if (index != items.length - 1)
                                  const Divider(
                                    height: 1,
                                    indent: 70,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                  loading: () {
                    return const _ContributionsLoading();
                  },
                  error: (
                    error,
                    stackTrace,
                  ) {
                    return _ContributionsError(
                      onRetry: () {
                        ref.invalidate(
                          goalContributionsProvider(
                            goalId,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        return const _GoalDetailsLoading();
      },
      error: (
        error,
        stackTrace,
      ) {
        return Scaffold(
          appBar: AppBar(),
          body: _GoalDetailsError(
            error: error,
            onRetry: () {
              ref.invalidate(
                goalsProvider,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showContributionSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (
        context,
      ) {
        return _ContributionSheet(
          goalId: goalId,
        );
      },
    );

    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Aporte adicionado com sucesso!',
            ),
          ),
        );
    }
  }

  Future<void> _deleteContribution(
    BuildContext context,
    WidgetRef ref,
    int contributionId,
  ) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: theme.colorScheme.error,
          ),
          title: const Text(
            'Excluir aporte?',
          ),
          content: const Text(
            'O valor será removido do progresso desta meta.',
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
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
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

    try {
      await ref
          .read(
            goalsRepositoryProvider,
          )
          .deleteContribution(
            contributionId,
          );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Aporte excluído.',
            ),
          ),
        );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível excluir o aporte.',
            ),
          ),
        );
    }
  }

  Future<void> _deleteGoal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: theme.colorScheme.error,
          ),
          title: const Text(
            'Excluir meta?',
          ),
          content: const Text(
            'A meta e todo o histórico de aportes serão excluídos.',
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
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
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

    try {
      await ref
          .read(
            goalsRepositoryProvider,
          )
          .deleteGoal(
            goalId,
          );

      if (context.mounted) {
        context.pop();
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível excluir a meta.',
            ),
          ),
        );
    }
  }
}

// ===========================================================
// GOAL HEADER
// ===========================================================

class _GoalHeader extends StatelessWidget {
  final GoalProgress goal;

  const _GoalHeader({
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progress = goal.progress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    final completed = goal.isCompleted;

    final color = completed ? AppTheme.income : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(
              0xFF6366F1,
            ),
            Color(
              0xFF8B5CF6,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF6366F1,
            ).withValues(
              alpha: 0.20,
            ),
            blurRadius: 24,
            offset: const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(
                    17,
                  ),
                ),
                child: Icon(
                  goalIconFromKey(
                    goal.icon,
                  ),
                  color: Colors.white,
                  size: 27,
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
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      _deadlineText(
                        goal.deadline,
                        completed,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(
                          alpha: 0.72,
                        ),
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
          Text(
            'Valor acumulado',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.70,
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _money(
                goal.currentInCents,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'de ${_money(goal.targetInCents)}',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.72,
              ),
            ),
          ),
          const SizedBox(
            height: 22,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              30,
            ),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          const SizedBox(
            height: 9,
          ),
          Row(
            children: [
              Text(
                '${(goal.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                completed
                    ? 'Meta alcançada!'
                    : 'Faltam ${_money(goal.remainingInCents)}',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.88,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (completed) ...[
            const SizedBox(
              height: 18,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.13,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 9,
                  ),
                  Expanded(
                    child: Text(
                      'Parabéns! Você alcançou este objetivo.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================
// CONTRIBUTIONS HEADER
// ===========================================================

class _ContributionsHeader extends StatelessWidget {
  final AsyncValue contributions;

  const _ContributionsHeader({
    required this.contributions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final count = contributions.maybeWhen<int>(
      data: (
        items,
      ) {
        return (items as List).length;
      },
      orElse: () {
        return 0;
      },
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Histórico de aportes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                'Valores adicionados ao longo do tempo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              30,
            ),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// CONTRIBUTION TILE
// ===========================================================

class _ContributionTile extends StatelessWidget {
  final int amountInCents;
  final DateTime date;
  final String? notes;
  final VoidCallback onDelete;

  const _ContributionTile({
    required this.amountInCents,
    required this.date,
    required this.notes,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final note = notes?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        6,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.income.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppTheme.income,
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
                  _money(
                    amountInCents,
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.income,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  DateFormat(
                    'dd/MM/yyyy',
                  ).format(
                    date,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Excluir aporte',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// EMPTY CONTRIBUTIONS
// ===========================================================

class _EmptyContributions extends StatelessWidget {
  const _EmptyContributions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 34,
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                size: 30,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              'Nenhum aporte registrado',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'Adicione valores à meta para começar a acompanhar sua evolução.',
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
// CONTRIBUTION SHEET
// ===========================================================

class _ContributionSheet extends ConsumerStatefulWidget {
  final int goalId;

  const _ContributionSheet({
    required this.goalId,
  });

  @override
  ConsumerState<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends ConsumerState<_ContributionSheet> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      Icons.add_card_rounded,
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
                          'Adicionar aporte',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Registre um novo valor para esta meta.',
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
                height: 24,
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Valor do aporte',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                  prefixIcon: Icon(
                    Icons.add_card_rounded,
                  ),
                ),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(
                            _selectedDate,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  hintText: 'Opcional',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      bottom: 35,
                    ),
                    child: Icon(
                      Icons.notes_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 26,
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveContribution,
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
                    _isSaving ? 'Adicionando...' : 'Adicionar aporte',
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

  Future<void> _saveContribution() async {
    if (_isSaving) {
      return;
    }

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
      await ref
          .read(
            goalsRepositoryProvider,
          )
          .addContribution(
            goalId: widget.goalId,
            amountInCents: amount,
            date: _selectedDate,
            notes: _notesController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Não foi possível adicionar o aporte: $error',
            ),
          ),
        );
    }
  }
}

// ===========================================================
// STATES
// ===========================================================

class _ContributionsLoading extends StatelessWidget {
  const _ContributionsLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _LoadingBox(
          height: 72,
          radius: 18,
        ),
        SizedBox(
          height: 8,
        ),
        _LoadingBox(
          height: 72,
          radius: 18,
        ),
        SizedBox(
          height: 8,
        ),
        _LoadingBox(
          height: 72,
          radius: 18,
        ),
      ],
    );
  }
}

class _ContributionsError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ContributionsError({
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
            Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 30,
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Não foi possível carregar os aportes.',
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

class _GoalDetailsLoading extends StatelessWidget {
  const _GoalDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          110,
        ),
        children: const [
          _LoadingBox(
            height: 310,
            radius: 24,
          ),
          SizedBox(
            height: 28,
          ),
          _LoadingBox(
            width: 180,
            height: 18,
          ),
          SizedBox(
            height: 14,
          ),
          _LoadingBox(
            height: 72,
            radius: 18,
          ),
          SizedBox(
            height: 8,
          ),
          _LoadingBox(
            height: 72,
            radius: 18,
          ),
        ],
      ),
    );
  }
}

class _GoalDetailsError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _GoalDetailsError({
    required this.error,
    required this.onRetry,
  });

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
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Não foi possível carregar a meta',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton.tonalIcon(
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

class _GoalNotFound extends StatelessWidget {
  const _GoalNotFound();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              'Meta não encontrada',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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

String _deadlineText(
  DateTime? deadline,
  bool completed,
) {
  if (completed) {
    return 'Objetivo concluído';
  }

  if (deadline == null) {
    return 'Sem prazo definido';
  }

  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final date = DateTime(
    deadline.year,
    deadline.month,
    deadline.day,
  );

  final days = date.difference(today).inDays;

  if (days < 0) {
    return 'Prazo encerrado em '
        '${DateFormat('dd/MM/yyyy').format(deadline)}';
  }

  if (days == 0) {
    return 'Prazo termina hoje';
  }

  if (days == 1) {
    return '1 dia restante';
  }

  if (days <= 30) {
    return '$days dias restantes';
  }

  return 'Prazo: '
      '${DateFormat('dd/MM/yyyy').format(deadline)}';
}

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
