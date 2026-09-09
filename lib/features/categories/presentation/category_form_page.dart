import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../data/categories_repository.dart';
import '../domain/category_icons.dart';
import 'providers/categories_providers.dart';

class CategoryFormPage extends ConsumerStatefulWidget {
  final int? categoryId;

  const CategoryFormPage({
    super.key,
    this.categoryId,
  });

  bool get isEditing => categoryId != null;

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  String _type = 'expense';

  String _selectedIconKey = 'shopping_bag';

  bool _isLoading = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _isLoading = true;

      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          _loadCategory();
        },
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  Future<void> _loadCategory() async {
    try {
      final repository = ref.read(
        categoriesRepositoryProvider,
      );

      final category = await repository.getCategory(
        widget.categoryId!,
      );

      if (!mounted) {
        return;
      }

      if (category == null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Categoria não encontrada.',
              ),
            ),
          );

        context.pop();

        return;
      }

      _fillForm(
        category,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível carregar a categoria.',
            ),
          ),
        );
    }
  }

  void _fillForm(
    FinanceCategory category,
  ) {
    _nameController.text = category.name;

    _type = category.type;

    _selectedIconKey = category.icon ?? 'more_horiz';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isExpense = _type == 'expense';

    final typeColor = isExpense ? AppTheme.expense : AppTheme.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar categoria' : 'Nova categoria',
        ),
      ),
      body: _isLoading
          ? const _CategoryFormLoading()
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
                    // ===========================
                    // INTRO
                    // ===========================
                    //
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: typeColor.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(
                              15,
                            ),
                          ),
                          child: Icon(
                            categoryIconFromKey(
                              _selectedIconKey,
                            ),
                            color: typeColor,
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
                                    ? 'Personalize sua categoria'
                                    : 'Crie uma nova categoria',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Organize suas movimentações com nomes e ícones fáceis de identificar.',
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
                    // ===========================
                    // TIPO
                    // ===========================
                    //
                    const _FieldTitle(
                      title: 'Tipo',
                      subtitle:
                          'Defina se a categoria será usada para saídas ou entradas.',
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
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    //
                    // ===========================
                    // NOME
                    // ===========================
                    //
                    const _FieldTitle(
                      title: 'Identificação',
                      subtitle:
                          'Escolha um nome fácil de reconhecer nas movimentações.',
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nome da categoria',
                        hintText: 'Ex.: Restaurante',
                        prefixIcon: Icon(
                          Icons.label_outline_rounded,
                        ),
                      ),
                      validator: (
                        value,
                      ) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome da categoria.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    //
                    // ===========================
                    // ÍCONE
                    // ===========================
                    //
                    const _FieldTitle(
                      title: 'Ícone',
                      subtitle:
                          'Escolha um símbolo para identificar rapidamente esta categoria.',
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
                          itemCount: categoryIconOptions.length,
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
                            final option = categoryIconOptions[index];

                            final selected = option.key == _selectedIconKey;

                            return Tooltip(
                              message: option.label,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  16,
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedIconKey = option.key;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 160,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? typeColor.withValues(
                                            alpha: 0.11,
                                          )
                                        : theme.colorScheme
                                            .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      16,
                                    ),
                                    border: Border.all(
                                      color: selected
                                          ? typeColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    color: selected
                                        ? typeColor
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    if (widget.isEditing) ...[
                      const SizedBox(
                        height: 22,
                      ),
                      Container(
                        padding: const EdgeInsets.all(
                          14,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(
                            alpha: 0.50,
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
                                'Se esta categoria já possuir movimentações, o tipo Receita/Despesa não poderá ser alterado.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 26,
                    ),

                    //
                    // ===========================
                    // PREVIEW
                    // ===========================
                    //
                    _CategoryPreview(
                      iconKey: _selectedIconKey,
                      name: _nameController.text.trim().isEmpty
                          ? 'Sua categoria'
                          : _nameController.text.trim(),
                      type: _type,
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
                            : Icon(
                                widget.isEditing
                                    ? Icons.save_outlined
                                    : Icons.check_rounded,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Salvando...'
                              : widget.isEditing
                                  ? 'Salvar alterações'
                                  : 'Criar categoria',
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
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(
        categoriesRepositoryProvider,
      );

      late CategorySaveResult result;

      if (widget.isEditing) {
        result = await repository.updateCategory(
          categoryId: widget.categoryId!,
          name: _nameController.text.trim(),
          type: _type,
          icon: _selectedIconKey,
        );
      } else {
        result = await repository.createCategory(
          name: _nameController.text.trim(),
          type: _type,
          icon: _selectedIconKey,
        );
      }

      if (!mounted) {
        return;
      }

      switch (result) {
        case CategorySaveResult.saved:
          context.pop(
            true,
          );

        case CategorySaveResult.duplicateName:
          setState(() {
            _isSaving = false;
          });

          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Já existe uma categoria com esse nome.',
                ),
              ),
            );

        case CategorySaveResult.typeChangeBlocked:
          setState(() {
            _isSaving = false;
          });

          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Não é possível alterar o tipo de uma categoria que já possui transações.',
                ),
              ),
            );

        case CategorySaveResult.notFound:
          setState(() {
            _isSaving = false;
          });

          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Categoria não encontrada.',
                ),
              ),
            );
      }
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
          const SnackBar(
            content: Text(
              'Não foi possível salvar a categoria.',
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
  Widget build(
    BuildContext context,
  ) {
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

class _CategoryPreview extends StatelessWidget {
  final String iconKey;
  final String name;
  final String type;

  const _CategoryPreview({
    required this.iconKey,
    required this.name,
    required this.type,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isExpense = type == 'expense';

    final color = isExpense ? AppTheme.expense : AppTheme.income;

    return Container(
      padding: const EdgeInsets.all(
        16,
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.11,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              categoryIconFromKey(
                iconKey,
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
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  isExpense ? 'Categoria de despesa' : 'Categoria de receita',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
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
// LOADING
// ===========================================================

class _CategoryFormLoading extends StatelessWidget {
  const _CategoryFormLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
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
          height: 28,
        ),
        _LoadingBox(
          height: 50,
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
          height: 190,
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
