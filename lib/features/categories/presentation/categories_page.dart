import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../data/categories_repository.dart';
import '../domain/category_icons.dart';
import 'providers/categories_providers.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final categories = ref.watch(
      allCategoriesProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categorias',
        ),
        actions: [
          IconButton(
            tooltip: 'Nova categoria',
            onPressed: () {
              context.push(
                '/categories/new',
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
            '/categories/new',
          );
        },
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Nova categoria',
        ),
      ),
      body: categories.when(
        data: (items) {
          final expenses = items
              .where(
                (category) => category.type == 'expense',
              )
              .toList();

          final incomes = items
              .where(
                (category) => category.type == 'income',
              )
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                allCategoriesProvider,
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
                _Appear(
                  child: _CategoriesSummary(
                    expenses: expenses.length,
                    incomes: incomes.length,
                  ),
                ),
                const SizedBox(
                  height: 28,
                ),
                _Appear(
                  child: _CategorySection(
                    title: 'Despesas',
                    subtitle: 'Onde seu dinheiro é gasto',
                    icon: Icons.north_east_rounded,
                    color: AppTheme.expense,
                    categories: expenses,
                    onEdit: (
                      category,
                    ) {
                      context.push(
                        '/categories/${category.id}/edit',
                      );
                    },
                    onDelete: (
                      category,
                    ) {
                      _confirmDelete(
                        context,
                        ref,
                        category,
                      );
                    },
                  ),
                ),
                const SizedBox(
                  height: 28,
                ),
                _Appear(
                  child: _CategorySection(
                    title: 'Receitas',
                    subtitle: 'De onde seu dinheiro vem',
                    icon: Icons.south_west_rounded,
                    color: AppTheme.income,
                    categories: incomes,
                    onEdit: (
                      category,
                    ) {
                      context.push(
                        '/categories/${category.id}/edit',
                      );
                    },
                    onDelete: (
                      category,
                    ) {
                      _confirmDelete(
                        context,
                        ref,
                        category,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () {
          return const _CategoriesLoading();
        },
        error: (
          error,
          stackTrace,
        ) {
          return _CategoriesError(
            error: error,
            onRetry: () {
              ref.invalidate(
                allCategoriesProvider,
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
    FinanceCategory category,
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
            'Excluir categoria?',
          ),
          content: Text(
            'Deseja excluir a categoria "${category.name}"?',
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

    try {
      final repository = ref.read(
        categoriesRepositoryProvider,
      );

      final result = await repository.deleteCategory(
        category.id,
      );

      if (!context.mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(
        context,
      );

      messenger.clearSnackBars();

      switch (result) {
        case DeleteCategoryResult.deleted:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Categoria excluída.',
              ),
            ),
          );

        case DeleteCategoryResult.hasTransactions:
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '"${category.name}" possui transações e não pode ser excluída.',
              ),
            ),
          );

        case DeleteCategoryResult.hasRecurringTransactions:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Essa categoria está sendo usada por uma transação recorrente.',
              ),
            ),
          );
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
              'Não foi possível excluir a categoria.',
            ),
          ),
        );
    }
  }
}

// ===========================================================
// INTRO
// ===========================================================

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organize suas movimentações',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Use categorias para entender melhor de onde seu dinheiro vem e para onde ele vai.',
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
            Icons.category_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// SUMMARY
// ===========================================================

class _CategoriesSummary extends StatelessWidget {
  final int expenses;
  final int incomes;

  const _CategoriesSummary({
    required this.expenses,
    required this.incomes,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final total = expenses + incomes;

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
                  'Categorias cadastradas',
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
                  Icons.label_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            '$total',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            total == 1 ? 'categoria disponível' : 'categorias disponíveis',
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.72,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.north_east_rounded,
                  label: 'Despesas',
                  value: '$expenses',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(
                  alpha: 0.16,
                ),
              ),
              const SizedBox(
                width: 18,
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.south_west_rounded,
                  label: 'Receitas',
                  value: '$incomes',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.13,
            ),
            borderRadius: BorderRadius.circular(
              11,
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: Colors.white,
          ),
        ),
        const SizedBox(
          width: 9,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.70,
                  ),
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// CATEGORY SECTION
// ===========================================================

class _CategorySection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  final List<FinanceCategory> categories;

  final void Function(
    FinanceCategory category,
  ) onEdit;

  final void Function(
    FinanceCategory category,
  ) onDelete;

  const _CategorySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.11,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
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
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 1,
                  ),
                  Text(
                    subtitle,
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
                color: color.withValues(
                  alpha: 0.09,
                ),
                borderRadius: BorderRadius.circular(
                  30,
                ),
              ),
              child: Text(
                '${categories.length}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 14,
        ),
        if (categories.isEmpty)
          _EmptyCategorySection(
            color: color,
          )
        else
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: List.generate(
                categories.length,
                (
                  index,
                ) {
                  final category = categories[index];

                  return Column(
                    children: [
                      _CategoryTile(
                        category: category,
                        color: color,
                        onEdit: () {
                          onEdit(
                            category,
                          );
                        },
                        onDelete: () {
                          onDelete(
                            category,
                          );
                        },
                      ),
                      if (index != categories.length - 1)
                        const Divider(
                          height: 1,
                          indent: 70,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final FinanceCategory category;
  final Color color;

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onEdit,
      child: Padding(
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
                color: color.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                categoryIconFromKey(
                  category.icon ?? '',
                ),
                color: color,
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
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    category.type == 'expense'
                        ? 'Categoria de despesa'
                        : 'Categoria de receita',
                    style: theme.textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}

class _EmptyCategorySection extends StatelessWidget {
  final Color color;

  const _EmptyCategorySection({
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 24,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.09,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.label_outline_rounded,
                color: color,
              ),
            ),
            const SizedBox(
              width: 13,
            ),
            Expanded(
              child: Text(
                'Nenhuma categoria cadastrada neste grupo.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// LOADING
// ===========================================================

class _CategoriesLoading extends StatelessWidget {
  const _CategoriesLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
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
          height: 190,
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

class _CategoriesError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _CategoriesError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
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
              'Não foi possível carregar as categorias',
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
