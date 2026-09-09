import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import 'providers/notification_inbox_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final notifications = ref.watch(
      notificationInboxProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificações',
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opções',
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
            onSelected: (
              value,
            ) async {
              switch (value) {
                case 'read_all':
                  await ref
                      .read(
                        notificationInboxRepositoryProvider,
                      )
                      .markAllAsRead();

                case 'clear_all':
                  final confirmed = await _confirmClearAll(
                    context,
                  );

                  if (!confirmed) {
                    return;
                  }

                  await ref
                      .read(
                        notificationInboxRepositoryProvider,
                      )
                      .deleteAllVisibleNotifications();

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notificações removidas.',
                        ),
                      ),
                    );
              }
            },
            itemBuilder: (
              context,
            ) {
              return const [
                PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Text(
                        'Marcar todas como lidas',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_sweep_outlined,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Text(
                        'Limpar todas',
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: notifications.when(
        data: (
          items,
        ) {
          final unread = items.where(
            (
              item,
            ) {
              return !item.isRead;
            },
          ).length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                notificationInboxProvider,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                40,
              ),
              children: [
                const _PageIntro(),
                const SizedBox(
                  height: 18,
                ),
                if (items.isNotEmpty) ...[
                  _NotificationSummary(
                    total: items.length,
                    unread: unread,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  _SectionHeader(
                    unread: unread,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  ...items.map(
                    (
                      notification,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 9,
                        ),
                        child: Dismissible(
                          key: ValueKey(
                            notification.id,
                          ),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(
                                18,
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                          onDismissed: (
                            direction,
                          ) async {
                            await ref
                                .read(
                                  notificationInboxRepositoryProvider,
                                )
                                .deleteNotification(
                                  notification.id,
                                );

                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              context,
                            )
                              ..clearSnackBars()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notificação excluída.',
                                  ),
                                ),
                              );
                          },
                          child: _NotificationCard(
                            notification: notification,
                            onTap: () async {
                              await ref
                                  .read(
                                    notificationInboxRepositoryProvider,
                                  )
                                  .markAsRead(
                                    notification.id,
                                  );

                              if (!context.mounted) {
                                return;
                              }

                              final route = notification.route;

                              if (route != null && route.isNotEmpty) {
                                context.push(
                                  route,
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ] else
                  const _EmptyNotifications(),
              ],
            ),
          );
        },
        loading: () {
          return const _NotificationsLoading();
        },
        error: (
          error,
          stackTrace,
        ) {
          return _NotificationsError(
            error: error,
            onRetry: () {
              ref.invalidate(
                notificationInboxProvider,
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
                'Central de alertas',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Acompanhe avisos importantes sobre sua vida financeira.',
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
            Icons.notifications_none_rounded,
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

class _NotificationSummary extends StatelessWidget {
  final int total;
  final int unread;

  const _NotificationSummary({
    required this.total,
    required this.unread,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final read = total - unread;

    return Container(
      padding: const EdgeInsets.all(
        20,
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
              alpha: 0.18,
            ),
            blurRadius: 22,
            offset: const Offset(
              0,
              9,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 25,
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
                  unread == 0
                      ? 'Tudo em dia'
                      : '$unread ${unread == 1 ? 'aviso não lido' : 'avisos não lidos'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '$total ${total == 1 ? 'notificação' : 'notificações'} • $read ${read == 1 ? 'lida' : 'lidas'}',
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
// HEADER
// ===========================================================

class _SectionHeader extends StatelessWidget {
  final int unread;

  const _SectionHeader({
    required this.unread,
  });

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
                'Recentes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                unread == 0
                    ? 'Você já visualizou todos os avisos'
                    : 'Os avisos não lidos aparecem em destaque',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (unread > 0)
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
              '$unread',
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
// CARD
// ===========================================================

class _NotificationCard extends StatelessWidget {
  final FinanSeeNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final color = _notificationColor(
      notification.type,
      theme,
    );

    final hasRoute =
        notification.route != null && notification.route!.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      elevation: notification.isRead ? 0 : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      _notificationIcon(
                        notification.type,
                      ),
                      color: color,
                    ),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
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
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(
                            width: 8,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              'Novo',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(
                      height: 9,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          _dateLabel(
                            notification.scheduledFor ?? notification.createdAt,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (hasRoute) ...[
                const SizedBox(
                  width: 6,
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
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

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

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
              Icons.notifications_none_rounded,
              size: 38,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            'Nenhuma notificação',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'Seus alertas de orçamento, recorrências e metas aparecerão aqui.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'Quando houver algo importante, o FinanSee avisa você.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// LOADING / ERROR
// ===========================================================

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        40,
      ),
      children: const [
        _PageIntro(),
        SizedBox(
          height: 18,
        ),
        _LoadingBox(
          height: 90,
          radius: 24,
        ),
        SizedBox(
          height: 24,
        ),
        _LoadingBox(
          width: 120,
          height: 18,
        ),
        SizedBox(
          height: 12,
        ),
        _LoadingBox(
          height: 115,
          radius: 18,
        ),
        SizedBox(
          height: 9,
        ),
        _LoadingBox(
          height: 115,
          radius: 18,
        ),
        SizedBox(
          height: 9,
        ),
        _LoadingBox(
          height: 115,
          radius: 18,
        ),
      ],
    );
  }
}

class _NotificationsError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _NotificationsError({
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
              'Não foi possível carregar as notificações',
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

// ===========================================================
// DIALOG
// ===========================================================

Future<bool> _confirmClearAll(
  BuildContext context,
) async {
  final theme = Theme.of(context);

  final result = await showDialog<bool>(
    context: context,
    builder: (
      dialogContext,
    ) {
      return AlertDialog(
        icon: Icon(
          Icons.delete_sweep_outlined,
          color: theme.colorScheme.error,
        ),
        title: const Text(
          'Limpar notificações?',
        ),
        content: const Text(
          'Todas as notificações exibidas na Central serão removidas. '
          'Os próximos lembretes agendados continuarão funcionando normalmente.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(
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
              Navigator.of(
                dialogContext,
              ).pop(
                true,
              );
            },
            child: const Text(
              'Limpar',
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

// ===========================================================
// HELPERS
// ===========================================================

IconData _notificationIcon(
  String type,
) {
  switch (type) {
    case 'budget':
      return Icons.speed_outlined;

    case 'recurring':
      return Icons.event_repeat_rounded;

    case 'goal':
      return Icons.flag_outlined;

    default:
      return Icons.notifications_outlined;
  }
}

Color _notificationColor(
  String type,
  ThemeData theme,
) {
  switch (type) {
    case 'budget':
      return Colors.orange;

    case 'recurring':
      return theme.colorScheme.primary;

    case 'goal':
      return const Color(
        0xFF22C55E,
      );

    default:
      return theme.colorScheme.primary;
  }
}

String _dateLabel(
  DateTime date,
) {
  final now = DateTime.now();

  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final target = DateTime(
    date.year,
    date.month,
    date.day,
  );

  if (target == today) {
    return 'Hoje • '
        '${DateFormat('HH:mm').format(date)}';
  }

  if (target ==
      today.subtract(
        const Duration(
          days: 1,
        ),
      )) {
    return 'Ontem • '
        '${DateFormat('HH:mm').format(date)}';
  }

  return DateFormat(
    'dd/MM/yyyy • HH:mm',
  ).format(
    date,
  );
}
