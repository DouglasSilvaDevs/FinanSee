import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/onboarding_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  //
  // false = primeira abertura
  // true  = usuário abriu novamente
  //         pelas configurações
  //
  final bool isReplay;

  const OnboardingPage({
    super.key,
    this.isReplay = false,
  });

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  bool _finishing = false;

  static const _pages = [
    _OnboardingData(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Bem-vindo ao FinanSee',
      description: 'Sua vida financeira mais clara. '
          'Organize suas finanças de forma simples, '
          'visual e prática.',
    ),
    _OnboardingData(
      icon: Icons.receipt_long_rounded,
      title: 'Controle suas finanças',
      description: 'Registre receitas e despesas, acompanhe '
          'suas contas e saiba exatamente para onde '
          'seu dinheiro está indo.',
    ),
    _OnboardingData(
      icon: Icons.track_changes_rounded,
      title: 'Planeje seus objetivos',
      description: 'Crie orçamentos, acompanhe gastos, '
          'organize recorrências e construa suas '
          'metas financeiras.',
    ),
    _OnboardingData(
      icon: Icons.shield_outlined,
      title: 'Seus dados, seu controle',
      description: 'Receba alertas, exporte relatórios e '
          'mantenha seus dados protegidos através '
          'de backups do FinanSee.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  Future<void> _next() async {
    if (_currentPage < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeOutCubic,
      );

      return;
    }

    await _finish();
  }

  Future<void> _skip() async {
    await _finish();
  }

  Future<void> _finish() async {
    if (_finishing) {
      return;
    }

    setState(() {
      _finishing = true;
    });

    try {
      await ref
          .read(
            onboardingProvider.notifier,
          )
          .complete();

      if (!mounted) {
        return;
      }

      //
      // Se o onboarding foi aberto pelas
      // configurações, o MaterialApp.router
      // já está ativo.
      //
      if (widget.isReplay) {
        context.go(
          '/',
        );
      }

      //
      // Na primeira abertura não precisamos
      // navegar manualmente.
      //
      // O FinanSeeApp observa onboardingProvider.
      // Quando ele vira true, o app troca
      // automaticamente para MaterialApp.router.
      //
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao concluir onboarding: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível concluir a introdução.',
            ),
          ),
        );

      setState(() {
        _finishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            //
            // ==================================
            // TOPO
            // ==================================
            //
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                12,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'FinanSee',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finishing ? null : _skip,
                    child: Text(
                      widget.isReplay ? 'Fechar' : 'Pular',
                    ),
                  ),
                ],
              ),
            ),

            //
            // ==================================
            // PÁGINAS
            // ==================================
            //
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (
                  context,
                  index,
                ) {
                  return _OnboardingSlide(
                    data: _pages[index],
                    pageIndex: index,
                  );
                },
              ),
            ),

            //
            // ==================================
            // INDICADORES
            // ==================================
            //
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) {
                  final selected = index == _currentPage;

                  return AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 220,
                    ),
                    width: selected ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            //
            // ==================================
            // BOTÃO
            // ==================================
            //
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                24,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _finishing ? null : _next,
                  icon: _finishing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          lastPage
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    _finishing
                        ? 'Preparando...'
                        : lastPage
                            ? 'Começar a usar'
                            : 'Continuar',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  final int pageIndex;

  const _OnboardingSlide({
    required this.data,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //
          // Ilustração
          //
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(
                56,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 30,
                  right: 26,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 28,
                  left: 28,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(
                        alpha: 0.18,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(
                      30,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 24,
                        offset: const Offset(
                          0,
                          10,
                        ),
                      ),
                    ],
                  ),
                  child: Icon(
                    data.icon,
                    size: 46,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 44,
          ),

          Text(
            data.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
