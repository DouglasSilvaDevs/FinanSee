import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../notifications/presentation/providers/notification_inbox_providers.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final unread = ref.watch(
      notificationUnreadCountProvider,
    );

    final count = unread.valueOrNull ?? 0;

    final label = count > 99 ? '99+' : count.toString();

    return IconButton(
      tooltip: 'Notificações',
      onPressed: () {
        context.push(
          '/notifications',
        );
      },
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(
          label,
        ),
        child: const Icon(
          Icons.notifications_outlined,
        ),
      ),
    );
  }
}
