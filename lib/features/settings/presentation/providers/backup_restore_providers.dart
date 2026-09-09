import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../notifications/presentation/providers/notification_settings_providers.dart';
import '../../data/backup_restore_service.dart';

final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  final database = ref.watch(
    databaseProvider,
  );

  final preferencesRepository = ref.watch(
    notificationPreferencesRepositoryProvider,
  );

  return BackupRestoreService(
    database: database,
    notificationPreferencesRepository: preferencesRepository,
  );
});
