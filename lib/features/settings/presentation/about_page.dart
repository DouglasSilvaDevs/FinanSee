import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({
    super.key,
  });

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '...';

  String _buildNumber = '...';

  @override
  void initState() {
    super.initState();

    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (!mounted) {
        return;
      }

      setState(() {
        _version = packageInfo.version;

        _buildNumber = packageInfo.buildNumber;
      });
    } catch (error) {
      debugPrint(
        'Erro ao carregar informações do app: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _version = '-';

        _buildNumber = '-';
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sobre o FinanSee',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            40,
          ),
          children: [
            //
            // =====================================
            // HERO
            // =====================================
            //
            _Appear(
              child: Container(
                padding: const EdgeInsets.all(
                  24,
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
                    26,
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
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(
                          25,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 39,
                      ),
                    ),
                    const SizedBox(
                      height: 17,
                    ),
                    Text(
                      'FinanSee',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Sua vida financeira mais clara.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(
                          alpha: 0.80,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.13,
                        ),
                        borderRadius: BorderRadius.circular(
                          30,
                        ),
                      ),
                      child: Text(
                        'Versão $_version  •  Build $_buildNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            //
            // =====================================
            // SOBRE
            // =====================================
            //
            const _SectionHeader(
              icon: Icons.info_outline_rounded,
              title: 'Sobre o aplicativo',
              subtitle: 'Finanças pessoais de forma simples e organizada.',
            ),

            const SizedBox(
              height: 12,
            ),

            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(
                  18,
                ),
                child: Text(
                  'O FinanSee é um gerenciador de finanças pessoais '
                  'desenvolvido para facilitar o acompanhamento de receitas, '
                  'despesas, contas, orçamentos, recorrências e metas financeiras. '
                  'O objetivo é reunir as principais informações financeiras '
                  'em uma experiência simples, moderna e organizada.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.55,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            //
            // =====================================
            // RECURSOS
            // =====================================
            //
            const _SectionHeader(
              icon: Icons.auto_awesome_rounded,
              title: 'Principais recursos',
              subtitle: 'Tudo que já faz parte do FinanSee.',
            ),

            const SizedBox(
              height: 12,
            ),

            const Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _FeatureTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Receitas e despesas',
                    description: 'Controle completo das suas movimentações.',
                  ),
                  _TileDivider(),
                  _FeatureTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Contas',
                    description: 'Saldo individual e consolidado.',
                  ),
                  _TileDivider(),
                  _FeatureTile(
                    icon: Icons.speed_outlined,
                    title: 'Orçamentos',
                    description: 'Limites mensais e alertas de gastos.',
                  ),
                  _TileDivider(),
                  _FeatureTile(
                    icon: Icons.event_repeat_rounded,
                    title: 'Recorrências',
                    description: 'Lançamentos automáticos e lembretes.',
                  ),
                  _TileDivider(),
                  _FeatureTile(
                    icon: Icons.flag_outlined,
                    title: 'Metas financeiras',
                    description: 'Acompanhe objetivos e seus aportes.',
                  ),
                  _TileDivider(),
                  _FeatureTile(
                    icon: Icons.picture_as_pdf_outlined,
                    title: 'Relatórios',
                    description: 'Exportação dos seus dados em PDF e CSV.',
                  ),
                  _TileDivider(),
                  _FeatureTile(
                    icon: Icons.backup_outlined,
                    title: 'Backup',
                    description: 'Salve, compartilhe e restaure seus dados.',
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            //
            // =====================================
            // TECNOLOGIAS
            // =====================================
            //
            const _SectionHeader(
              icon: Icons.code_rounded,
              title: 'Tecnologias',
              subtitle: 'Principais ferramentas usadas no desenvolvimento.',
            ),

            const SizedBox(
              height: 12,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _TechnologyChip(
                  label: 'Flutter',
                ),
                _TechnologyChip(
                  label: 'Dart',
                ),
                _TechnologyChip(
                  label: 'Riverpod',
                ),
                _TechnologyChip(
                  label: 'Drift',
                ),
                _TechnologyChip(
                  label: 'SQLite',
                ),
                _TechnologyChip(
                  label: 'GoRouter',
                ),
                _TechnologyChip(
                  label: 'fl_chart',
                ),
                _TechnologyChip(
                  label: 'Material 3',
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),

            //
            // =====================================
            // INFORMAÇÕES
            // =====================================
            //
            const _SectionHeader(
              icon: Icons.settings_outlined,
              title: 'Informações',
              subtitle: 'Versão, introdução e componentes utilizados.',
            ),

            const SizedBox(
              height: 12,
            ),

            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Versão',
                    trailing: _version,
                  ),
                  const _TileDivider(),
                  _InfoTile(
                    icon: Icons.construction_outlined,
                    title: 'Build',
                    trailing: _buildNumber,
                  ),
                  const _TileDivider(),
                  _ActionTile(
                    icon: Icons.slideshow_outlined,
                    title: 'Ver introdução novamente',
                    subtitle: 'Conheça os principais recursos do FinanSee',
                    onTap: () {
                      context.push(
                        '/onboarding',
                      );
                    },
                  ),
                  const _TileDivider(),
                  _ActionTile(
                    icon: Icons.description_outlined,
                    title: 'Licenças de software',
                    subtitle: 'Bibliotecas utilizadas pelo aplicativo',
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'FinanSee',
                        applicationVersion: _version,
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(
                            12,
                          ),
                          child: Container(
                            width: 56,
                            height: 56,
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
                                16,
                              ),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 34,
            ),

            //
            // =====================================
            // FOOTER
            // =====================================
            //
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(
                      alpha: 0.75,
                    ),
                  ),
                  const SizedBox(
                    height: 7,
                  ),
                  Text(
                    'Desenvolvido com Flutter',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    '© 2026 FinanSee',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
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
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            size: 19,
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
      ],
    );
  }
}

// ===========================================================
// FEATURES
// ===========================================================

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.70,
              ),
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
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
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// INFO / ACTION
// ===========================================================

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            child: Text(
              trailing,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
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
// TECHNOLOGY
// ===========================================================

class _TechnologyChip extends StatelessWidget {
  final String label;

  const _TechnologyChip({
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Chip(
      side: BorderSide.none,
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.55,
      ),
      avatar: Icon(
        Icons.code_rounded,
        size: 17,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ===========================================================
// DIVIDER
// ===========================================================

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Divider(
      height: 1,
      indent: 68,
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
