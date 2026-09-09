import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/appearance_providers.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);

    final selectedMode = ref.watch(
      themeModeProvider,
    );

    void changeTheme(
      ThemeMode mode,
    ) {
      ref
          .read(
            themeModeProvider.notifier,
          )
          .setThemeMode(
            mode,
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aparência',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            40,
          ),
          children: [
            //
            // =====================================
            // INTRO
            // =====================================
            //
            _Appear(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Do seu jeito',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Escolha como o FinanSee deve aparecer no seu dispositivo.',
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
                      Icons.palette_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 26,
            ),

            Text(
              'Tema do aplicativo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              'A alteração é aplicada imediatamente.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            _Appear(
              child: _ThemeOption(
                title: 'Seguir o sistema',
                description:
                    'Acompanha automaticamente o tema claro ou escuro definido no celular.',
                icon: Icons.brightness_auto_outlined,
                value: ThemeMode.system,
                groupValue: selectedMode,
                onChanged: changeTheme,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            _Appear(
              child: _ThemeOption(
                title: 'Claro',
                description: 'Mantém o FinanSee sempre com a aparência clara.',
                icon: Icons.light_mode_outlined,
                value: ThemeMode.light,
                groupValue: selectedMode,
                onChanged: changeTheme,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            _Appear(
              child: _ThemeOption(
                title: 'Escuro',
                description: 'Mantém o FinanSee sempre com a aparência escura.',
                icon: Icons.dark_mode_outlined,
                value: ThemeMode.dark,
                groupValue: selectedMode,
                onChanged: changeTheme,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            Text(
              'Pré-visualização',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              'Uma amostra da aparência selecionada.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            _ThemePreview(
              mode: selectedMode,
            ),

            const SizedBox(
              height: 18,
            ),

            _CurrentThemeCard(
              mode: selectedMode,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// THEME OPTION
// ===========================================================

class _ThemeOption extends StatelessWidget {
  final String title;
  final String description;

  final IconData icon;

  final ThemeMode value;
  final ThemeMode groupValue;

  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final selected = value == groupValue;

    return Card(
      margin: EdgeInsets.zero,
      elevation: selected ? 1 : 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary.withValues(
                  alpha: 0.55,
                )
              : Colors.transparent,
          width: 1.3,
        ),
      ),
      child: InkWell(
        onTap: () {
          onChanged(
            value,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (selected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              'Ativo',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 6,
              ),
              Radio<ThemeMode>(
                value: value,
                groupValue: groupValue,
                onChanged: (
                  mode,
                ) {
                  if (mode != null) {
                    onChanged(
                      mode,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// THEME PREVIEW
// ===========================================================

class _ThemePreview extends StatelessWidget {
  final ThemeMode mode;

  const _ThemePreview({
    required this.mode,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => MediaQuery.platformBrightnessOf(
            context,
          ) ==
          Brightness.dark,
    };

    final background = isDark
        ? const Color(
            0xFF0F1115,
          )
        : const Color(
            0xFFF6F7FB,
          );

    final surface = isDark
        ? const Color(
            0xFF1A1D23,
          )
        : Colors.white;

    final primaryText = isDark
        ? Colors.white
        : const Color(
            0xFF202124,
          );

    final secondaryText = isDark
        ? Colors.white70
        : const Color(
            0xFF6B7280,
          );

    return Container(
      height: 245,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(
                alpha: 0.5,
              ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF6366F1,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                'FinanSee',
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.notifications_none_rounded,
                color: secondaryText,
                size: 20,
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              15,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
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
                17,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo atual',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  'R\$ 4.850,00',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 11,
          ),
          Row(
            children: [
              Expanded(
                child: _PreviewCard(
                  surface: surface,
                  title: 'Receitas',
                  value: 'R\$ 5.200',
                  valueColor: const Color(
                    0xFF22C55E,
                  ),
                  primaryText: primaryText,
                ),
              ),
              const SizedBox(
                width: 9,
              ),
              Expanded(
                child: _PreviewCard(
                  surface: surface,
                  title: 'Despesas',
                  value: 'R\$ 2.150',
                  valueColor: const Color(
                    0xFFEF4444,
                  ),
                  primaryText: primaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Color surface;
  final String title;
  final String value;
  final Color valueColor;
  final Color primaryText;

  const _PreviewCard({
    required this.surface,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.primaryText,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(
          15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryText.withValues(
                alpha: 0.65,
              ),
              fontSize: 10,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// CURRENT THEME
// ===========================================================

class _CurrentThemeCard extends StatelessWidget {
  final ThemeMode mode;

  const _CurrentThemeCard({
    required this.mode,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final label = switch (mode) {
      ThemeMode.system => 'Seguindo o sistema',
      ThemeMode.light => 'Tema claro',
      ThemeMode.dark => 'Tema escuro',
    };

    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(
          17,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aparência atual',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
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
        milliseconds: 360,
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
