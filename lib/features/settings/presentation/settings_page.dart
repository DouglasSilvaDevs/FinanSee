import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            110,
          ),
          children: [
            //
            // =====================================
            // CABEÇALHO
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
                          'Mais',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Organize suas finanças e personalize o FinanSee.',
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
                      Icons.tune_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            //
            // =====================================
            // FINANÇAS
            // =====================================
            //
            const _SectionHeader(
              title: 'Finanças',
              subtitle: 'Gerencie os principais recursos do seu planejamento.',
              icon: Icons.account_balance_wallet_outlined,
            ),

            const SizedBox(
              height: 10,
            ),

            _Appear(
              child: _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Contas',
                    subtitle: 'Carteiras, bancos e saldos',
                    onTap: () {
                      context.push(
                        '/accounts',
                      );
                    },
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.category_outlined,
                    title: 'Categorias',
                    subtitle: 'Receitas e despesas',
                    onTap: () {
                      context.push(
                        '/categories',
                      );
                    },
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.speed_outlined,
                    title: 'Orçamentos',
                    subtitle: 'Limites mensais por categoria',
                    onTap: () {
                      context.push(
                        '/budgets',
                      );
                    },
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.event_repeat_rounded,
                    title: 'Recorrências',
                    subtitle: 'Receitas e despesas fixas',
                    onTap: () {
                      context.push(
                        '/recurring',
                      );
                    },
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.flag_outlined,
                    title: 'Metas',
                    subtitle: 'Objetivos e aportes',
                    onTap: () {
                      context.push(
                        '/goals',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            //
            // =====================================
            // DADOS
            // =====================================
            //
            const _SectionHeader(
              title: 'Dados',
              subtitle: 'Proteja as informações armazenadas no aplicativo.',
              icon: Icons.storage_rounded,
            ),

            const SizedBox(
              height: 10,
            ),

            _Appear(
              child: _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.backup_outlined,
                    title: 'Backup e restauração',
                    subtitle: 'Proteja e recupere seus dados',
                    onTap: () {
                      context.push(
                        '/backup',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            //
            // =====================================
            // APLICATIVO
            // =====================================
            //
            const _SectionHeader(
              title: 'Aplicativo',
              subtitle: 'Personalize o comportamento e a aparência.',
              icon: Icons.phone_android_rounded,
            ),

            const SizedBox(
              height: 10,
            ),

            _Appear(
              child: _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notificações',
                    subtitle: 'Alertas e lembretes',
                    onTap: () {
                      context.push(
                        '/notification-settings',
                      );
                    },
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Aparência',
                    subtitle: 'Claro, escuro ou sistema',
                    onTap: () {
                      context.push(
                        '/appearance',
                      );
                    },
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Sobre',
                    subtitle: 'Informações sobre o FinanSee',
                    onTap: () {
                      context.push(
                        '/about',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            //
            // =====================================
            // FOOTER
            // =====================================
            //
            Center(
              child: Text(
                'FinanSee',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
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
// SECTION HEADER
// ===========================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.65,
            ),
            borderRadius: BorderRadius.circular(
              11,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(
          width: 11,
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
                height: 2,
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
      ],
    );
  }
}

// ===========================================================
// CARD
// ===========================================================

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

// ===========================================================
// TILE
// ===========================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.65,
                ),
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
              child: Icon(
                icon,
                size: 21,
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
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
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
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// DIVIDER
// ===========================================================

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 69,
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
