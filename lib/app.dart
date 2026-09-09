import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'features/budgets/domain/budget_models.dart';
import 'features/budgets/presentation/providers/budgets_providers.dart';
import 'features/goals/presentation/providers/goals_providers.dart';
import 'features/notifications/presentation/providers/notification_inbox_providers.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/onboarding/presentation/providers/onboarding_providers.dart';
import 'features/recurring/presentation/providers/recurring_providers.dart';
import 'features/settings/presentation/providers/appearance_providers.dart';

class FinanSeeApp extends ConsumerStatefulWidget {
  const FinanSeeApp({
    super.key,
  });

  @override
  ConsumerState<FinanSeeApp> createState() {
    return _FinanSeeAppState();
  }
}

class _FinanSeeAppState extends ConsumerState<FinanSeeApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationTapSubscription;

  ProviderSubscription<AsyncValue<List<BudgetProgress>>>? _budgetSubscription;

  DateTime? _budgetListenerMonth;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    _setupNotificationNavigation();

    _setupProviderListeners();

    Future.microtask(
      _initializeServices,
    );
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();

    _budgetSubscription?.close();

    WidgetsBinding.instance.removeObserver(
      this,
    );

    super.dispose();
  }

  // =========================================================
  // PROVIDER LISTENERS
  // =========================================================

  void _setupProviderListeners() {
    _setupBudgetListener();

    // =======================================================
    // RECORRÊNCIAS
    // =======================================================

    ref.listenManual(
      recurringTransactionsProvider,
      (
        previous,
        next,
      ) {
        next.whenData(
          (
            items,
          ) async {
            debugPrint(
              'Sincronizando ${items.length} recorrências...',
            );

            await ref
                .read(
                  recurringNotificationSchedulerProvider,
                )
                .sync(
                  items,
                );
          },
        );
      },
      fireImmediately: true,
    );

    // =======================================================
    // METAS
    // =======================================================

    ref.listenManual(
      goalsProvider,
      (
        previous,
        next,
      ) {
        next.whenData(
          (
            goals,
          ) async {
            debugPrint(
              'Verificando ${goals.length} metas...',
            );

            await ref
                .read(
                  goalNotificationManagerProvider,
                )
                .checkGoals(
                  goals,
                );
          },
        );
      },
      fireImmediately: true,
    );
  }

  void _setupBudgetListener() {
    final now = DateTime.now();

    final month = DateTime(
      now.year,
      now.month,
      1,
    );

    if (_budgetListenerMonth != null &&
        _budgetListenerMonth!.year == month.year &&
        _budgetListenerMonth!.month == month.month) {
      return;
    }

    _budgetSubscription?.close();

    _budgetListenerMonth = month;

    _budgetSubscription = ref.listenManual<AsyncValue<List<BudgetProgress>>>(
      budgetsProvider(
        month,
      ),
      (
        previous,
        next,
      ) {
        next.whenData(
          (
            budgets,
          ) async {
            debugPrint(
              'Verificando ${budgets.length} orçamentos '
              'de ${month.month}/${month.year}...',
            );

            await ref
                .read(
                  budgetNotificationManagerProvider,
                )
                .checkBudgets(
                  budgets,
                );
          },
        );
      },
      fireImmediately: true,
    );
  }

  // =========================================================
  // NOTIFICATION NAVIGATION
  // =========================================================

  void _setupNotificationNavigation() {
    final service = ref.read(
      notificationServiceProvider,
    );

    _notificationTapSubscription = service.notificationTapStream.listen(
      _handleNotificationPayload,
    );
  }

  void _handleNotificationPayload(
    String payload,
  ) {
    debugPrint(
      'Abrindo notificação: $payload',
    );

    if (payload == 'budgets') {
      AppRouter.router.go(
        '/budgets',
      );

      return;
    }

    if (payload.startsWith(
      'recurring:',
    )) {
      AppRouter.router.go(
        '/recurring',
      );

      return;
    }

    if (payload.startsWith(
      'goal:',
    )) {
      final rawId = payload.substring(
        'goal:'.length,
      );

      final goalId = int.tryParse(
        rawId,
      );

      if (goalId != null) {
        AppRouter.router.go(
          '/goals/$goalId',
        );
      } else {
        AppRouter.router.go(
          '/goals',
        );
      }

      return;
    }
  }

  // =========================================================
  // INITIALIZATION
  // =========================================================

  Future<void> _initializeServices() async {
    await _initializeNotifications();

    await _syncRecurringTransactions();
  }

  Future<void> _initializeNotifications() async {
    try {
      final service = ref.read(
        notificationServiceProvider,
      );

      await service.initialize();

      //
      // Não solicita automaticamente.
      //
      // Apenas verifica se o Android já
      // concedeu a permissão.
      //
      final enabled = await service.notificationsEnabled();

      debugPrint(
        'Notificações habilitadas: $enabled',
      );

      // =====================================================
      // APP ABERTO POR NOTIFICAÇÃO
      // =====================================================

      final launchPayload = await service.getLaunchPayload();

      if (launchPayload != null) {
        debugPrint(
          'App iniciado por notificação: '
          '$launchPayload',
        );

        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            if (!mounted) {
              return;
            }

            _handleNotificationPayload(
              launchPayload,
            );
          },
        );
      }

      if (enabled) {
        final now = DateTime.now();

        final currentMonth = DateTime(
          now.year,
          now.month,
          1,
        );

        ref.invalidate(
          budgetsProvider(
            currentMonth,
          ),
        );

        ref.invalidate(
          recurringTransactionsProvider,
        );

        ref.invalidate(
          goalsProvider,
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao inicializar notificações: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // =========================================================
  // RECURRING
  // =========================================================

  Future<void> _syncRecurringTransactions() async {
    try {
      await ref
          .read(
            recurringTransactionsRepositoryProvider,
          )
          .generateDueTransactions();
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao processar recorrências: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // =========================================================
  // LIFECYCLE
  // =========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    //
    // Caso o mês tenha mudado enquanto
    // o aplicativo estava suspenso,
    // troca o listener de orçamento.
    //
    _setupBudgetListener();

    _syncRecurringTransactions();

    ref.invalidate(
      recurringTransactionsProvider,
    );

    ref.invalidate(
      goalsProvider,
    );

    final now = DateTime.now();

    final currentMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    ref.invalidate(
      budgetsProvider(
        currentMonth,
      ),
    );

    ref.invalidate(
      notificationInboxProvider,
    );

    ref.invalidate(
      notificationUnreadCountProvider,
    );
  }

  // =========================================================
  // SYSTEM UI
  // =========================================================

  Widget _systemUiBuilder(
    BuildContext context,
    Widget? child,
  ) {
    final brightness = Theme.of(context).brightness;

    final dark = brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            dark ? AppTheme.darkBackground : AppTheme.lightBackground,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final themeMode = ref.watch(
      themeModeProvider,
    );

    final onboarding = ref.watch(
      onboardingProvider,
    );

    // =======================================================
    // LOADING
    // =======================================================

    if (onboarding.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FinanSee',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: _systemUiBuilder,
        home: const _FinanSeeLoadingScreen(),
      );
    }

    // =======================================================
    // ONBOARDING ERROR
    // =======================================================

    if (onboarding.hasError) {
      debugPrint(
        'Erro ao verificar onboarding: '
        '${onboarding.error}',
      );
    }

    final onboardingCompleted = onboarding.valueOrNull ?? true;

    // =======================================================
    // ONBOARDING
    // =======================================================

    if (!onboardingCompleted) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FinanSee',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: _systemUiBuilder,
        home: const OnboardingPage(),
      );
    }

    // =======================================================
    // APP
    // =======================================================

    return MaterialApp.router(
      title: 'FinanSee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: _systemUiBuilder,
      routerConfig: AppRouter.router,
    );
  }
}

// ===========================================================
// STARTUP LOADING
// ===========================================================

class _FinanSeeLoadingScreen extends StatelessWidget {
  const _FinanSeeLoadingScreen();

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
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
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                'FinanSee',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
