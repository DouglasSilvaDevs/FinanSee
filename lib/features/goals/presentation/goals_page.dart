import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/goal_icons.dart';
import '../domain/goal_models.dart';
import 'providers/goals_providers.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final goals = ref.watch(
      goalsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Metas',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(
            '/goals/new',
          );
        },
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Nova meta',
        ),
      ),
      body: goals.when(
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                goalsProvider,
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
                const _PageIntro(),
                const SizedBox(
                  height: 20,
                ),
                if (items.isEmpty)
                  _EmptyGoals(
                    onCreate: () {
                      context.push(
                        '/goals/new',
                      );
                    },
                  )
                else ...[
                  _Appear(
                    child: _GoalsSummary(
                      items: items,
                    ),
                  ),
                  const SizedBox(
                    height: 28,
                  ),
                  _SectionHeader(
                    count: items.length,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  ...items.map(
                    (goal) {
                      return _Appear(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _GoalCard(
                            goal: goal,
                            onTap: () {
                              context.push(
                                '/goals/${goal.id}',
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
        loading: () {
          return const _GoalsLoading();
        },
        error: (
          error,
          stackTrace,
        ) {
          return _GoalsError(
            error: error,
            onRetry: () {
              ref.invalidate(
                goalsProvider,
              );
            },
          );
        },
      ),
    );
  }
}

// ===========================================================
// INTRO
// ===========================================================

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transforme planos em objetivos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Defina metas, acompanhe o progresso e registre seus aportes.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 14,
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
            Icons.flag_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// RESUMO
// ===========================================================

class _GoalsSummary extends StatelessWidget {
  final List<GoalProgress> items;

  const _GoalsSummary({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalTarget = items.fold<int>(
      0,
      (
        sum,
        item,
      ) {
        return sum + item.targetInCents;
      },
    );

    final accumulated = items.fold<int>(
      0,
      (
        sum,
        item,
      ) {
        return sum + item.currentInCents;
      },
    );

    final completed = items.where(
      (item) {
        return item.isCompleted;
      },
    ).length;

    final inProgress = items.length - completed;

    final progress = totalTarget <= 0 ? 0.0 : accumulated / totalTarget;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Progresso das suas metas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(
                      alpha: 0.82,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 9,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(
                accumulated,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            'de ${_money(totalTarget)} planejados',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.72,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              30,
            ),
            child: LinearProgressIndicator(
              value: progress.clamp(
                0.0,
                1.0,
              ),
              minHeight: 9,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% acumulado',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.78,
                  ),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (inProgress > 0)
                _SummaryBadge(
                  icon: Icons.timelapse_rounded,
                  label:
                      '$inProgress ${inProgress == 1 ? 'em andamento' : 'em andamento'}',
                ),
              if (completed > 0)
                _SummaryBadge(
                  icon: Icons.check_circle_outline_rounded,
                  label:
                      '$completed ${completed == 1 ? 'concluída' : 'concluídas'}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.13,
        ),
        borderRadius: BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: Colors.white,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// HEADER
// ===========================================================

class _SectionHeader extends StatelessWidget {
  final int count;

  const _SectionHeader({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seus objetivos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                'Toque em uma meta para ver os detalhes',
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
// GOAL CARD
// ===========================================================

class _GoalCard extends StatelessWidget {
  final GoalProgress goal;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final completed = goal.isCompleted;

    final color = completed ? AppTheme.income : theme.colorScheme.primary;

    final progress = goal.progress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    final deadlineStatus = _deadlineStatus(
      goal.deadline,
      completed,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            18,
          ),
          child: Column(
            children: [
              Row(
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
                      goalIconFromKey(
                        goal.icon,
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
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Row(
                          children: [
                            Icon(
                              deadlineStatus.icon,
                              size: 14,
                              color: deadlineStatus.color ??
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Flexible(
                              child: Text(
                                deadlineStatus.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: deadlineStatus.color ??
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(goal.progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        completed ? 'Concluída' : 'Progresso',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 17,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  20,
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  color: color,
                  backgroundColor: color.withValues(
                    alpha: 0.09,
                  ),
                ),
              ),
              const SizedBox(
                height: 11,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_money(goal.currentInCents)} de ${_money(goal.targetInCents)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    completed
                        ? 'Meta alcançada!'
                        : 'Faltam ${_money(goal.remainingInCents)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// EMPTY
// ===========================================================

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyGoals({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 60,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flag_outlined,
              size: 38,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Nenhuma meta financeira',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'Crie uma meta para acompanhar seus objetivos e registrar seus aportes.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Criar meta',
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

class _GoalsLoading extends StatelessWidget {
  const _GoalsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        120,
      ),
      children: const [
        _PageIntro(),
        SizedBox(
          height: 20,
        ),
        _LoadingBox(
          height: 230,
          radius: 24,
        ),
        SizedBox(
          height: 28,
        ),
        _LoadingBox(
          width: 150,
          height: 18,
        ),
        SizedBox(
          height: 14,
        ),
        _LoadingBox(
          height: 150,
          radius: 20,
        ),
        SizedBox(
          height: 12,
        ),
        _LoadingBox(
          height: 150,
          radius: 20,
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
// ERROR
// ===========================================================

class _GoalsError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _GoalsError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        120,
      ),
      children: [
        const _PageIntro(),
        const SizedBox(
          height: 70,
        ),
        Column(
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
              'Não foi possível carregar as metas',
              textAlign: TextAlign.center,
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
      ],
    );
  }
}

// ===========================================================
// ANIMATION
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
        milliseconds: 380,
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
// DEADLINE
// ===========================================================

class _DeadlineStatus {
  final String text;
  final IconData icon;
  final Color? color;

  const _DeadlineStatus({
    required this.text,
    required this.icon,
    this.color,
  });
}

_DeadlineStatus _deadlineStatus(
  DateTime? deadline,
  bool completed,
) {
  if (completed) {
    return const _DeadlineStatus(
      text: 'Objetivo concluído',
      icon: Icons.check_circle_outline_rounded,
      color: AppTheme.income,
    );
  }

  if (deadline == null) {
    return const _DeadlineStatus(
      text: 'Sem prazo definido',
      icon: Icons.event_outlined,
    );
  }

  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final target = DateTime(
    deadline.year,
    deadline.month,
    deadline.day,
  );

  final difference = target.difference(today).inDays;

  if (difference < 0) {
    return _DeadlineStatus(
      text: 'Prazo encerrado em ${DateFormat('dd/MM/yyyy').format(deadline)}',
      icon: Icons.warning_amber_rounded,
      color: AppTheme.expense,
    );
  }

  if (difference == 0) {
    return const _DeadlineStatus(
      text: 'Prazo termina hoje',
      icon: Icons.schedule_rounded,
      color: Colors.orange,
    );
  }

  if (difference <= 30) {
    return _DeadlineStatus(
      text:
          '$difference ${difference == 1 ? 'dia restante' : 'dias restantes'}',
      icon: Icons.schedule_rounded,
      color: Colors.orange,
    );
  }

  return _DeadlineStatus(
    text: 'Meta: ${DateFormat('dd/MM/yyyy').format(deadline)}',
    icon: Icons.event_outlined,
  );
}

// ===========================================================
// MONEY
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
