import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../notifications/data/notification_preferences_repository.dart';

class BackupRestoreService {
  static const String backupFormat = 'finansee-backup';

  static const int backupVersion = 1;

  final AppDatabase database;

  final NotificationPreferencesRepository notificationPreferencesRepository;

  BackupRestoreService({
    required this.database,
    required this.notificationPreferencesRepository,
  });

  static const List<String> _tables = [
    'accounts',
    'categories',
    'transactions',
    'budgets',
    'recurring_transactions',
    'recurring_occurrences',
    'financial_goals',
    'goal_contributions',
    'budget_notification_states',
    'goal_notification_states',
    'app_notifications',
  ];

  //
  // Filhos primeiro.
  //
  static const List<String> _deleteOrder = [
    'app_notifications',
    'budget_notification_states',
    'goal_notification_states',
    'goal_contributions',
    'recurring_occurrences',
    'transactions',
    'budgets',
    'recurring_transactions',
    'financial_goals',
    'categories',
    'accounts',
  ];

  //
  // Pais primeiro.
  //
  static const List<String> _insertOrder = [
    'accounts',
    'categories',
    'financial_goals',
    'budgets',
    'recurring_transactions',
    'transactions',
    'goal_contributions',
    'recurring_occurrences',
    'budget_notification_states',
    'goal_notification_states',
    'app_notifications',
  ];

  Future<File> createBackup() async {
    final now = DateTime.now();

    final tables = <String, List<Map<String, dynamic>>>{};

    for (final table in _tables) {
      tables[table] = await _readTable(table);
    }

    final notificationPreferences =
        await notificationPreferencesRepository.load();

    final backup = <String, dynamic>{
      'format': backupFormat,
      'backupVersion': backupVersion,
      'schemaVersion': database.schemaVersion,
      'createdAt': now.toIso8601String(),
      'preferences': {
        'budgetAlertsEnabled': notificationPreferences.budgetAlertsEnabled,
        'recurringRemindersEnabled':
            notificationPreferences.recurringRemindersEnabled,
        'goalAlertsEnabled': notificationPreferences.goalAlertsEnabled,
      },
      'tables': tables,
    };

    final directory = await getTemporaryDirectory();

    final timestamp = DateFormat(
      'yyyy-MM-dd_HHmm',
    ).format(now);

    final file = File(
      '${directory.path}/'
      'finansee_backup_$timestamp.finansee',
    );

    //
    // pretty JSON para facilitar
    // inspeção/debug durante o desenvolvimento.
    //
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(
      backup,
    );

    await file.writeAsString(
      json,
      encoding: utf8,
      flush: true,
    );

    return file;
  }

  Future<void> createAndShareBackup() async {
    final file = await createBackup();

    await Share.shareXFiles(
      [
        XFile(
          file.path,
        ),
      ],
      subject: 'Backup do FinanSee',
      text: 'Backup dos dados do FinanSee.',
    );
  }

  Future<bool> saveBackupToDevice() async {
    final file = await createBackup();

    final bytes = await file.readAsBytes();

    final fileName = file.uri.pathSegments.last;

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar backup do FinanSee',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [
        'finansee',
      ],
      bytes: bytes,
    );

    //
    // null significa que o usuário
    // cancelou o seletor.
    //
    return result != null;
  }

  Future<BackupFileInfo?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Selecionar backup do FinanSee',

      //
      // IMPORTANTE:
      // FileType.custom pode fazer o Android
      // desabilitar arquivos .finansee.
      //
      type: FileType.any,

      allowMultiple: false,

      //
      // Traz os dados do arquivo para a memória.
      //
      withData: true,
    );

    //
    // Usuário cancelou.
    //
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.single;

    //
    // Fazemos uma primeira validação pelo nome,
    // mas não dependemos apenas da extensão.
    //
    final fileName = picked.name.toLowerCase();

    if (!fileName.endsWith(
          '.finansee',
        ) &&
        !fileName.endsWith(
          '.json',
        )) {
      throw const BackupException(
        'Selecione um arquivo de backup do FinanSee (.finansee).',
      );
    }

    Uint8List? bytes = picked.bytes;

    //
    // Em alguns dispositivos o file_picker
    // fornece apenas o caminho.
    //
    if (bytes == null && picked.path != null) {
      bytes = await File(
        picked.path!,
      ).readAsBytes();
    }

    if (bytes == null) {
      throw const BackupException(
        'Não foi possível ler o arquivo selecionado.',
      );
    }

    String text;

    try {
      text = utf8.decode(
        bytes,
      );
    } catch (_) {
      throw const BackupException(
        'O arquivo selecionado não é um backup válido do FinanSee.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(
        text,
      );
    } catch (_) {
      throw const BackupException(
        'O arquivo selecionado não contém um backup válido do FinanSee.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupException(
        'Arquivo de backup inválido.',
      );
    }

    //
    // Esta é a validação realmente importante.
    // Ela verifica:
    //
    // format
    // backupVersion
    // schemaVersion
    // tabelas obrigatórias
    //
    _validateBackup(
      decoded,
    );

    return BackupFileInfo.fromJson(
      decoded,
      fileName: picked.name,
    );
  }

  Future<void> restoreBackup(
    BackupFileInfo backup,
  ) async {
    //
    // Validamos novamente imediatamente
    // antes de modificar qualquer dado.
    //
    _validateBackup(
      backup.rawData,
    );

    final tablesRaw = backup.rawData['tables'];

    if (tablesRaw is! Map<String, dynamic>) {
      throw const BackupException(
        'Estrutura de tabelas inválida.',
      );
    }

    //
    // Todo o banco é restaurado dentro
    // de UMA transaction.
    //
    // Se qualquer insert falhar,
    // Drift/SQLite faz rollback.
    //
    await database.transaction(
      () async {
        //
        // 1. Apaga filhos antes dos pais.
        //
        for (final table in _deleteOrder) {
          await database.customStatement(
            'DELETE FROM "$table"',
          );
        }

        //
        // 2. Insere pais antes dos filhos.
        //
        for (final table in _insertOrder) {
          final rawRows = tablesRaw[table];

          if (rawRows == null) {
            continue;
          }

          if (rawRows is! List) {
            throw BackupException(
              'Dados inválidos na tabela "$table".',
            );
          }

          for (final rawRow in rawRows) {
            if (rawRow is! Map) {
              throw BackupException(
                'Registro inválido na tabela "$table".',
              );
            }

            final row = Map<String, dynamic>.from(
              rawRow,
            );

            await _insertRawRow(
              table,
              row,
            );
          }
        }
      },
    );

    //
    // Preferências ficam fora do SQLite.
    //
    await _restorePreferences(
      backup.rawData,
    );
  }

  Future<List<Map<String, dynamic>>> _readTable(
    String table,
  ) async {
    final rows = await database
        .customSelect(
          'SELECT * FROM "$table"',
        )
        .get();

    return rows
        .map(
          (row) => Map<String, dynamic>.from(
            row.data,
          ),
        )
        .toList();
  }

  Future<void> _insertRawRow(
    String table,
    Map<String, dynamic> row,
  ) async {
    if (row.isEmpty) {
      return;
    }

    final columns = row.keys.toList();

    final columnSql = columns
        .map(
          (column) => '"$column"',
        )
        .join(', ');

    final placeholders = List.filled(
      columns.length,
      '?',
    ).join(', ');

    final values = columns
        .map(
          (column) => row[column],
        )
        .toList();

    await database.customStatement(
      'INSERT INTO "$table" '
      '($columnSql) '
      'VALUES ($placeholders)',
      values,
    );
  }

  void _validateBackup(
    Map<String, dynamic> backup,
  ) {
    if (backup['format'] != backupFormat) {
      throw const BackupException(
        'Este arquivo não é um backup válido do FinanSee.',
      );
    }

    final fileBackupVersion = backup['backupVersion'];

    if (fileBackupVersion != backupVersion) {
      throw BackupException(
        'Versão do arquivo de backup não suportada: '
        '$fileBackupVersion.',
      );
    }

    final schemaVersion = backup['schemaVersion'];

    if (schemaVersion != database.schemaVersion) {
      throw BackupException(
        'Este backup pertence à versão de banco '
        '$schemaVersion, mas o FinanSee atual usa '
        '${database.schemaVersion}.',
      );
    }

    final tables = backup['tables'];

    if (tables is! Map<String, dynamic>) {
      throw const BackupException(
        'O backup não contém tabelas válidas.',
      );
    }

    //
    // As tabelas principais precisam
    // necessariamente existir.
    //
    const requiredTables = [
      'accounts',
      'categories',
      'transactions',
    ];

    for (final table in requiredTables) {
      if (!tables.containsKey(
        table,
      )) {
        throw BackupException(
          'O backup está incompleto. '
          'Tabela ausente: $table.',
        );
      }

      if (tables[table] is! List) {
        throw BackupException(
          'A tabela "$table" possui formato inválido.',
        );
      }
    }
  }

  Future<void> _restorePreferences(
    Map<String, dynamic> backup,
  ) async {
    final raw = backup['preferences'];

    if (raw is! Map<String, dynamic>) {
      return;
    }

    final budget = raw['budgetAlertsEnabled'];

    final recurring = raw['recurringRemindersEnabled'];

    final goals = raw['goalAlertsEnabled'];

    if (budget is bool) {
      await notificationPreferencesRepository.setBudgetAlertsEnabled(
        budget,
      );
    }

    if (recurring is bool) {
      await notificationPreferencesRepository.setRecurringRemindersEnabled(
        recurring,
      );
    }

    if (goals is bool) {
      await notificationPreferencesRepository.setGoalAlertsEnabled(
        goals,
      );
    }
  }
}

class BackupFileInfo {
  final String fileName;

  final int backupVersion;
  final int schemaVersion;

  final DateTime createdAt;

  final int totalRecords;

  final Map<String, dynamic> rawData;

  const BackupFileInfo({
    required this.fileName,
    required this.backupVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.totalRecords,
    required this.rawData,
  });

  factory BackupFileInfo.fromJson(
    Map<String, dynamic> json, {
    required String fileName,
  }) {
    var totalRecords = 0;

    final tables = json['tables'];

    if (tables is Map<String, dynamic>) {
      for (final value in tables.values) {
        if (value is List) {
          totalRecords += value.length;
        }
      }
    }

    return BackupFileInfo(
      fileName: fileName,
      backupVersion: json['backupVersion'] as int,
      schemaVersion: json['schemaVersion'] as int,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      totalRecords: totalRecords,
      rawData: json,
    );
  }
}

class BackupException implements Exception {
  final String message;

  const BackupException(
    this.message,
  );

  @override
  String toString() => message;
}
