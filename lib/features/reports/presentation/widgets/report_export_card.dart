import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/report_export_providers.dart';

class ReportExportCard extends ConsumerStatefulWidget {
  final DateTime selectedMonth;

  const ReportExportCard({
    super.key,
    required this.selectedMonth,
  });

  @override
  ConsumerState<ReportExportCard> createState() => _ReportExportCardState();
}

class _ReportExportCardState extends ConsumerState<ReportExportCard> {
  bool _exportingPdf = false;
  bool _exportingCsv = false;

  bool get _isExporting => _exportingPdf || _exportingCsv;

  Future<void> _exportPdf() async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _exportingPdf = true;
    });

    try {
      final report = await ref.read(
        monthlyReportExportProvider(
          widget.selectedMonth,
        ).future,
      );

      final service = ref.read(
        reportExportServiceProvider,
      );

      await service.exportPdfAndShare(
        report,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao exportar PDF: $error',
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
          SnackBar(
            content: Text(
              'Não foi possível gerar o PDF.\n$error',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _exportingPdf = false;
        });
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_isExporting) {
      return;
    }

    setState(() {
      _exportingCsv = true;
    });

    try {
      final report = await ref.read(
        monthlyReportExportProvider(
          widget.selectedMonth,
        ).future,
      );

      final service = ref.read(
        reportExportServiceProvider,
      );

      await service.exportCsvAndShare(
        report,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao exportar CSV: $error',
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
          SnackBar(
            content: Text(
              'Não foi possível gerar o CSV.\n$error',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _exportingCsv = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    Icons.file_download_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
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
                        'Exportar relatório',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Compartilhe os dados de ${_monthLabel(widget.selectedMonth)}.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 18,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : _exportPdf,
                    icon: _exportingPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.picture_as_pdf_outlined,
                          ),
                    label: Text(
                      _exportingPdf ? 'Gerando...' : 'PDF',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isExporting ? null : _exportCsv,
                    icon: _exportingCsv
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.table_view_outlined,
                          ),
                    label: Text(
                      _exportingCsv ? 'Gerando...' : 'CSV',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child: Text(
                    'O PDF contém o resumo financeiro, categorias e movimentações. '
                    'O CSV é ideal para Excel e planilhas.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _monthLabel(
  DateTime date,
) {
  final value = DateFormat(
    "MMMM 'de' yyyy",
    'pt_BR',
  ).format(
    date,
  );

  if (value.isEmpty) {
    return value;
  }

  return '${value[0].toUpperCase()}${value.substring(1)}';
}
