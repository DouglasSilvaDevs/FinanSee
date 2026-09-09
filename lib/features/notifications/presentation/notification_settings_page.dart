import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budgets/presentation/providers/budgets_providers.dart';
import '../../goals/presentation/providers/goals_providers.dart';
import '../../recurring/presentation/providers/recurring_providers.dart';
import 'providers/notification_providers.dart';
import 'providers/notification_settings_providers.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({
    super.key,
  });

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool? _systemNotificationsEnabled;

  bool _checkingPermission = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _refreshSystemPermission();
      },
    );
  }

  Future<void> _refreshSystemPermission() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _checkingPermission = true;
    });

    try {
      final enabled = await ref
          .read(
            notificationServiceProvider,
          )
          .notificationsEnabled();

      if (!mounted) {
        return;
      }

      setState(() {
        _systemNotificationsEnabled = enabled;

        _checkingPermission = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _systemNotificationsEnabled = false;

        _checkingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      final enabled = await ref
          .read(
            notificationServiceProvider,
          )
          .requestPermission();

      if (!mounted) {
        return;
      }

      setState(() {
        _systemNotificationsEnabled = enabled;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _systemNotificationsEnabled = false;
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final settings = ref.watch(
      notificationSettingsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificações',
        ),
      ),
      body: settings.when(
        data: (
          preferences,
        ) {
          final activeCount = [
            preferences.budgetAlertsEnabled,
            preferences.recurringRemindersEnabled,
            preferences.goalAlertsEnabled,
          ].where(
            (
              value,
            ) {
              return value;
            },
          ).length;

          return RefreshIndicator(
            onRefresh: () async {
              await _refreshSystemPermission();

              ref.invalidate(
                notificationSettingsProvider,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                40,
              ),
              children: [
                const _PageIntro(),
                const SizedBox(
                  height: 22,
                ),
                _SystemStatusCard(
                  enabled: _systemNotificationsEnabled,
                  loading: _checkingPermission,
                  onRequestPermission: _requestPermission,
                  onRefresh: _refreshSystemPermission,
                ),
                const SizedBox(
                  height: 18,
                ),
                _AlertsSummary(
                  active: activeCount,
                  systemEnabled: _systemNotificationsEnabled == true,
                ),
                const SizedBox(
                  height: 28,
                ),
                const _SectionTitle(
                  title: 'Alertas financeiros',
                  subtitle: 'Escolha quais eventos devem gerar avisos.',
                ),
                const SizedBox(
                  height: 12,
                ),
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _NotificationSwitchTile(
                        icon: Icons.speed_outlined,
                        title: 'Alertas de orçamento',
                        subtitle:
                            'Avise quando uma categoria atingir 80% e 100% do limite.',
                        value: preferences.budgetAlertsEnabled,
                        onChanged: (
                          enabled,
                        ) async {
                          await ref
                              .read(
                                notificationSettingsProvider.notifier,
                              )
                              .setBudgetAlerts(
                                enabled,
                              );

                          if (enabled) {
                            final now = DateTime.now();

                            ref.invalidate(
                              budgetsProvider(
                                DateTime(
                                  now.year,
                                  now.month,
                                  1,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const _TileDivider(),
                      _NotificationSwitchTile(
                        icon: Icons.event_repeat_rounded,
                        title: 'Lembretes de recorrências',
                        subtitle:
                            'Avise um dia antes das receitas e despesas recorrentes.',
                        value: preferences.recurringRemindersEnabled,
                        onChanged: (
                          enabled,
                        ) async {
                          await ref
                              .read(
                                notificationSettingsProvider.notifier,
                              )
                              .setRecurringReminders(
                                enabled,
                              );

                          ref.invalidate(
                            recurringTransactionsProvider,
                          );
                        },
                      ),
                      const _TileDivider(),
                      _NotificationSwitchTile(
                        icon: Icons.flag_outlined,
                        title: 'Avisos de metas',
                        subtitle:
                            'Receba alertas sobre prazos próximos e objetivos alcançados.',
                        value: preferences.goalAlertsEnabled,
                        onChanged: (
                          enabled,
                        ) async {
                          await ref
                              .read(
                                notificationSettingsProvider.notifier,
                              )
                              .setGoalAlerts(
                                enabled,
                              );

                          ref.invalidate(
                            goalsProvider,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                const _NotificationInfo(),
              ],
            ),
          );
        },
        loading: () {
          return const _NotificationSettingsLoading();
        },
        error: (
          error,
          stackTrace,
        ) {
          return _SettingsError(
            error: error,
            onRetry: () {
              ref.invalidate(
                notificationSettingsProvider,
              );

              _refreshSystemPermission();
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
                'Fique por dentro',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Escolha quais acontecimentos financeiros merecem sua atenção.',
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
            Icons.notifications_active_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// SYSTEM STATUS
// ===========================================================

class _SystemStatusCard extends StatelessWidget {
  final bool? enabled;
  final bool loading;

  final VoidCallback onRequestPermission;

  final VoidCallback onRefresh;

  const _SystemStatusCard({
    required this.enabled,
    required this.loading,
    required this.onRequestPermission,
    required this.onRefresh,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final isEnabled = enabled == true;

    final color = isEnabled
        ? const Color(
            0xFF22C55E,
          )
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                15,
              ),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(
                      13,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    isEnabled
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: color,
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
                  'Permissão do sistema',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  loading
                      ? 'Verificando permissão...'
                      : isEnabled
                          ? 'O Android permite que o FinanSee envie notificações.'
                          : 'As notificações estão desativadas no Android.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          if (!loading)
            isEnabled
                ? IconButton(
                    tooltip: 'Atualizar',
                    onPressed: onRefresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                  )
                : FilledButton.tonal(
                    onPressed: onRequestPermission,
                    child: const Text(
                      'Permitir',
                    ),
                  ),
        ],
      ),
    );
  }
}

// ===========================================================
// SUMMARY
// ===========================================================

class _AlertsSummary extends StatelessWidget {
  final int active;
  final bool systemEnabled;

  const _AlertsSummary({
    required this.active,
    required this.systemEnabled,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(
        16,
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
          20,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 21,
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
                  '$active de 3 tipos de alerta ativos',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  systemEnabled
                      ? 'Pronto para enviar avisos no dispositivo.'
                      : 'Ative a permissão do sistema para receber os avisos.',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.75,
                    ),
                    fontSize: 12,
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
// SWITCH TILE
// ===========================================================

class _NotificationSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;

  final ValueChanged<bool> onChanged;

  const _NotificationSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        8,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: value
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              icon,
              size: 21,
              color: value
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
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
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// INFO
// ===========================================================

class _NotificationInfo extends StatelessWidget {
  const _NotificationInfo();

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'As preferências controlam quais alertas o FinanSee gera. A permissão do Android também precisa estar ativa para que eles apareçam fora do aplicativo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// SECTION
// ===========================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(
          height: 3,
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
// LOADING / ERROR
// ===========================================================

class _NotificationSettingsLoading extends StatelessWidget {
  const _NotificationSettingsLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        40,
      ),
      children: const [
        _PageIntro(),
        SizedBox(
          height: 22,
        ),
        _LoadingBox(
          height: 86,
          radius: 20,
        ),
        SizedBox(
          height: 18,
        ),
        _LoadingBox(
          height: 82,
          radius: 20,
        ),
        SizedBox(
          height: 28,
        ),
        _LoadingBox(
          width: 170,
          height: 18,
        ),
        SizedBox(
          height: 12,
        ),
        _LoadingBox(
          height: 230,
          radius: 20,
        ),
      ],
    );
  }
}

class _SettingsError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _SettingsError({
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
              'Não foi possível carregar as configurações',
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

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Divider(
      height: 1,
      indent: 69,
    );
  }
}
