import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/accounts_repository.dart';
import '../domain/account_models.dart';
import 'providers/accounts_providers.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final accounts = ref.watch(
      accountsWithBalanceProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contas',
        ),
        actions: [
          IconButton(
            tooltip: 'Nova conta',
            onPressed: () {
              context.push(
                '/accounts/new',
              );
            },
            icon: const Icon(
              Icons.add_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(
            '/accounts/new',
          );
        },
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Nova conta',
        ),
      ),
      body: accounts.when(
        data: (items) {
          final totalBalance = items.fold<int>(
            0,
            (
              sum,
              account,
            ) {
              return sum + account.currentBalanceInCents;
            },
          );

          final positiveAccounts = items.where(
            (account) {
              return account.currentBalanceInCents >= 0;
            },
          ).length;

          final negativeAccounts = items.length - positiveAccounts;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                accountsWithBalanceProvider,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                120,
              ),
              children: [
                if (items.isEmpty)
                  _EmptyAccounts(
                    onCreate: () {
                      context.push(
                        '/accounts/new',
                      );
                    },
                  )
                else ...[
                  _Appear(
                    child: _TotalBalanceCard(
                      balanceInCents: totalBalance,
                      accountCount: items.length,
                      positiveAccounts: positiveAccounts,
                      negativeAccounts: negativeAccounts,
                    ),
                  ),
                  const SizedBox(
                    height: 28,
                  ),
                  _SectionHeader(
                    title: 'Suas contas',
                    count: items.length,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  ...List.generate(
                    items.length,
                    (
                      index,
                    ) {
                      final account = items[index];

                      return _Appear(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 11,
                          ),
                          child: _AccountCard(
                            account: account,
                            onOpen: () {
                              context.push(
                                '/accounts/${account.id}',
                              );
                            },
                            onEdit: () {
                              context.push(
                                '/accounts/${account.id}/edit',
                              );
                            },
                            onDelete: () {
                              _confirmDelete(
                                context,
                                ref,
                                account,
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
          return const _AccountsLoading();
        },
        error: (
          error,
          stackTrace,
        ) {
          return _AccountsError(
            error: error,
            onRetry: () {
              ref.invalidate(
                accountsWithBalanceProvider,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AccountWithBalance account,
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
            'Excluir conta?',
          ),
          content: Text(
            'Deseja excluir a conta "${account.name}"?',
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    final repository = ref.read(
      accountsRepositoryProvider,
    );

    final result = await repository.deleteAccount(
      account.id,
    );

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(
      context,
    );

    messenger.clearSnackBars();

    switch (result) {
      case DeleteAccountResult.deleted:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Conta excluída.',
            ),
          ),
        );

      case DeleteAccountResult.hasTransactions:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'A conta "${account.name}" possui transações e não pode ser excluída.',
            ),
          ),
        );

      case DeleteAccountResult.lastAccount:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Você precisa manter pelo menos uma conta cadastrada.',
            ),
          ),
        );

      case DeleteAccountResult.hasRecurringTransactions:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Essa conta está sendo usada por uma transação recorrente.',
            ),
          ),
        );
    }
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final int balanceInCents;
  final int accountCount;
  final int positiveAccounts;
  final int negativeAccounts;

  const _TotalBalanceCard({
    required this.balanceInCents,
    required this.accountCount,
    required this.positiveAccounts,
    required this.negativeAccounts,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final negative = balanceInCents < 0;

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
                  'Saldo consolidado',
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
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(
                balanceInCents,
              ),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BalanceBadge(
                icon: Icons.wallet_outlined,
                label:
                    '$accountCount ${accountCount == 1 ? 'conta' : 'contas'}',
              ),
              if (negative)
                const _BalanceBadge(
                  icon: Icons.warning_amber_rounded,
                  label: 'Saldo negativo',
                )
              else
                const _BalanceBadge(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Saldo positivo',
                ),
            ],
          ),
          if (negativeAccounts > 0) ...[
            const SizedBox(
              height: 14,
            ),
            Text(
              negativeAccounts == 1
                  ? '1 conta está com saldo negativo.'
                  : '$negativeAccounts contas estão com saldo negativo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(
                  alpha: 0.82,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BalanceBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.14,
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
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
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

class _AccountCard extends StatelessWidget {
  final AccountWithBalance account;

  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isNegative = account.currentBalanceInCents < 0;

    final balanceColor =
        isNegative ? AppTheme.expense : theme.colorScheme.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            15,
            8,
            15,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
                child: Icon(
                  _accountIcon(
                    account.type,
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
                      account.name,
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
                        Flexible(
                          child: Text(
                            _accountTypeName(
                              account.type,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (isNegative) ...[
                          const SizedBox(
                            width: 7,
                          ),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppTheme.expense,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            'Negativo',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.expense,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 125,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatCurrency(
                          account.currentBalanceInCents,
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: balanceColor,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Saldo atual',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                onSelected: (
                  value,
                ) {
                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) {
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
        ),
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyAccounts({
    required this.onCreate,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
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
              Icons.account_balance_wallet_outlined,
              size: 38,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Nenhuma conta cadastrada',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            'Crie sua primeira conta para começar a organizar seu dinheiro.',
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
              'Criar conta',
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsLoading extends StatelessWidget {
  const _AccountsLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        120,
      ),
      children: const [
        _LoadingBox(
          height: 180,
          radius: 24,
        ),
        SizedBox(
          height: 28,
        ),
        _LoadingBox(
          width: 120,
          height: 18,
        ),
        SizedBox(
          height: 14,
        ),
        _LoadingBox(
          height: 82,
          radius: 20,
        ),
        SizedBox(
          height: 11,
        ),
        _LoadingBox(
          height: 82,
          radius: 20,
        ),
        SizedBox(
          height: 11,
        ),
        _LoadingBox(
          height: 82,
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
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          radius,
        ),
      ),
    );
  }
}

class _AccountsError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _AccountsError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
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
              'Não foi possível carregar as contas',
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
      ),
    );
  }
}

class _Appear extends StatelessWidget {
  final Widget child;

  const _Appear({
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
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

IconData _accountIcon(
  String type,
) {
  switch (type) {
    case 'cash':
      return Icons.account_balance_wallet_outlined;

    case 'checking':
      return Icons.account_balance_outlined;

    case 'savings':
      return Icons.savings_outlined;

    case 'investment':
      return Icons.trending_up_rounded;

    default:
      return Icons.wallet_outlined;
  }
}

String _accountTypeName(
  String type,
) {
  switch (type) {
    case 'cash':
      return 'Carteira';

    case 'checking':
      return 'Conta corrente';

    case 'savings':
      return 'Poupança';

    case 'investment':
      return 'Investimentos';

    default:
      return 'Outra';
  }
}

String _formatCurrency(
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
