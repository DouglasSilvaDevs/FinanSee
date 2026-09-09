import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/backup_restore_service.dart';
import 'providers/backup_restore_providers.dart';

class BackupRestorePage extends ConsumerStatefulWidget {
  const BackupRestorePage({
    super.key,
  });

  @override
  ConsumerState<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends ConsumerState<BackupRestorePage> {
  bool _savingBackup = false;
  bool _sharingBackup = false;
  bool _restoringBackup = false;

  bool get _busy => _savingBackup || _sharingBackup || _restoringBackup;

  Future<void> _saveBackup() async {
    if (_busy) {
      return;
    }

    setState(() {
      _savingBackup = true;
    });

    try {
      final saved = await ref
          .read(
            backupRestoreServiceProvider,
          )
          .saveBackupToDevice();

      if (!mounted || !saved) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Backup salvo com sucesso!',
            ),
          ),
        );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao salvar backup: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showError(
        'Não foi possível salvar o backup.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingBackup = false;
        });
      }
    }
  }

  Future<void> _shareBackup() async {
    if (_busy) {
      return;
    }

    setState(() {
      _sharingBackup = true;
    });

    try {
      await ref
          .read(
            backupRestoreServiceProvider,
          )
          .createAndShareBackup();
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao compartilhar backup: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showError(
        'Não foi possível compartilhar o backup.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sharingBackup = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_busy) {
      return;
    }

    try {
      final service = ref.read(
        backupRestoreServiceProvider,
      );

      final backup = await service.pickBackupFile();

      if (backup == null || !mounted) {
        return;
      }

      final confirmed = await _confirmRestore(
        backup,
      );

      if (!confirmed || !mounted) {
        return;
      }

      setState(() {
        _restoringBackup = true;
      });

      await service.restoreBackup(
        backup,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Backup restaurado com sucesso!',
            ),
          ),
        );

      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao restaurar backup: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showError(
        'Não foi possível restaurar o backup.',
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _restoringBackup = false;
        });
      }
    }
  }

  Future<bool> _confirmRestore(
    BackupFileInfo backup,
  ) async {
    final theme = Theme.of(context);

    final createdAt = DateFormat(
      'dd/MM/yyyy • HH:mm',
    ).format(
      backup.createdAt,
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restore_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          title: const Text(
            'Restaurar backup?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Os dados atuais do FinanSee serão substituídos pelos dados deste backup.',
              ),
              const SizedBox(
                height: 18,
              ),
              Container(
                padding: const EdgeInsets.all(
                  14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Column(
                  children: [
                    _BackupDetail(
                      icon: Icons.description_outlined,
                      label: 'Arquivo',
                      value: backup.fileName,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _BackupDetail(
                      icon: Icons.schedule_rounded,
                      label: 'Criado em',
                      value: createdAt,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _BackupDetail(
                      icon: Icons.storage_rounded,
                      label: 'Registros',
                      value: '${backup.totalRecords}',
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 19,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita.',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                'Restaurar',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showError(
    String message,
    Object error,
  ) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$message\n$error',
          ),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backup e restauração',
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
            // INTRO
            //
            _Appear(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proteja seus dados',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Crie uma cópia das suas informações financeiras para guardar em segurança.',
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
                      Icons.shield_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _Appear(
              child: _BackupHero(
                busy: _busy,
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            const _SectionHeader(
              title: 'Seus dados',
              subtitle:
                  'Escolha o que deseja fazer com sua cópia de segurança.',
            ),

            const SizedBox(
              height: 12,
            ),

            _Appear(
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _BackupActionTile(
                      icon: Icons.save_alt_rounded,
                      title: 'Salvar no dispositivo',
                      subtitle:
                          'Escolha uma pasta para guardar o arquivo de backup.',
                      loading: _savingBackup,
                      enabled: !_busy,
                      onTap: _saveBackup,
                    ),
                    const _TileDivider(),
                    _BackupActionTile(
                      icon: Icons.share_outlined,
                      title: 'Compartilhar backup',
                      subtitle:
                          'Envie pelo Drive, WhatsApp, e-mail ou outro aplicativo.',
                      loading: _sharingBackup,
                      enabled: !_busy,
                      onTap: _shareBackup,
                    ),
                    const _TileDivider(),
                    _BackupActionTile(
                      icon: Icons.restore_rounded,
                      title: 'Restaurar backup',
                      subtitle:
                          'Substitua os dados atuais por uma cópia salva anteriormente.',
                      loading: _restoringBackup,
                      enabled: !_busy,
                      onTap: _restoreBackup,
                      destructive: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            const _SectionHeader(
              title: 'O que é salvo',
              subtitle: 'A cópia reúne os principais dados do FinanSee.',
            ),

            const SizedBox(
              height: 12,
            ),

            const _BackupContentsCard(),

            const SizedBox(
              height: 18,
            ),

            _SecurityNotice(
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// HERO
// ===========================================================

class _BackupHero extends StatelessWidget {
  final bool busy;

  const _BackupHero({
    required this.busy,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(
                      14,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.cloud_done_outlined,
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
                  busy ? 'Processando backup' : 'Mantenha uma cópia segura',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  busy
                      ? 'Aguarde a operação atual ser concluída antes de iniciar outra.'
                      : 'Salve em Downloads, Google Drive ou outro dispositivo para não depender apenas do armazenamento local.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(
                      alpha: 0.80,
                    ),
                    height: 1.4,
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
// HEADERS
// ===========================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
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
// ACTION
// ===========================================================

class _BackupActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  final bool destructive;

  const _BackupActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.enabled,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final color =
        destructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                color: color,
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
            const SizedBox(
              width: 10,
            ),
            if (loading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
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
// CONTENTS
// ===========================================================

class _BackupContentsCard extends StatelessWidget {
  const _BackupContentsCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _ContentChip(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Contas',
            ),
            _ContentChip(
              icon: Icons.category_outlined,
              label: 'Categorias',
            ),
            _ContentChip(
              icon: Icons.receipt_long_outlined,
              label: 'Transações',
            ),
            _ContentChip(
              icon: Icons.speed_outlined,
              label: 'Orçamentos',
            ),
            _ContentChip(
              icon: Icons.event_repeat_rounded,
              label: 'Recorrências',
            ),
            _ContentChip(
              icon: Icons.flag_outlined,
              label: 'Metas',
            ),
            _ContentChip(
              icon: Icons.savings_outlined,
              label: 'Aportes',
            ),
            _ContentChip(
              icon: Icons.notifications_outlined,
              label: 'Notificações',
            ),
            _ContentChip(
              icon: Icons.tune_rounded,
              label: 'Preferências',
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContentChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          30,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// SECURITY
// ===========================================================

class _SecurityNotice extends StatelessWidget {
  final ThemeData theme;

  const _SecurityNotice({
    required this.theme,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(
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
            Icons.lock_outline_rounded,
            size: 19,
            color: theme.colorScheme.error,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'O arquivo contém dados financeiros. Guarde-o em um local seguro e evite compartilhá-lo publicamente.',
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
// DETAILS
// ===========================================================

class _BackupDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BackupDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(
          width: 8,
        ),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
      indent: 71,
    );
  }
}

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
      tween: Tween(
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
