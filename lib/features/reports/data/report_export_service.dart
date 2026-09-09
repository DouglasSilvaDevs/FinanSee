import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../domain/report_export_data.dart';

class ReportExportService {
  static final PdfColor _primary =
      PdfColor.fromHex('#6366F1');

  static final PdfColor _income =
      PdfColor.fromHex('#22C55E');

  static final PdfColor _expense =
      PdfColor.fromHex('#EF4444');

  static final PdfColor _surface =
      PdfColor.fromHex('#F6F7FB');

  static final PdfColor _textSecondary =
      PdfColor.fromHex('#6B7280');

  Future<File> generatePdf(
    MonthlyReportExportData report,
  ) async {
    final document = pw.Document(
      title: 'Relatório Financeiro FinanSee',
      author: 'FinanSee',
      creator: 'FinanSee',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          36,
          40,
          36,
          36,
        ),
        maxPages: 100,

        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(
              top: 16,
            ),
            padding: const pw.EdgeInsets.only(
              top: 8,
            ),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColors.grey300,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Gerado pelo FinanSee',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: _textSecondary,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          );
        },

        build: (context) {
          return [
            _buildHeader(
              report,
            ),

            pw.SizedBox(
              height: 24,
            ),

            _buildSummary(
              report,
            ),

            pw.SizedBox(
              height: 28,
            ),

            _buildSectionTitle(
              'Despesas por categoria',
            ),

            pw.SizedBox(
              height: 10,
            ),

            _buildCategories(
              report,
            ),

            pw.SizedBox(
              height: 28,
            ),

            _buildSectionTitle(
              'Transações',
            ),

            pw.SizedBox(
              height: 10,
            ),

            _buildTransactions(
              report,
            ),
          ];
        },
      ),
    );

    final directory =
        await getTemporaryDirectory();

    final file = File(
      '${directory.path}/${_fileName(report)}.pdf',
    );

    final bytes =
        await document.save();

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return file;
  }

  Future<File> generateCsv(
    MonthlyReportExportData report,
  ) async {
    final rows =
        <List<dynamic>>[
      [
        'Data',
        'Descrição',
        'Tipo',
        'Categoria',
        'Conta',
        'Valor',
        'Observações',
      ],
    ];

    for (final transaction
        in report.transactions) {
      rows.add([
        DateFormat(
          'dd/MM/yyyy',
        ).format(
          transaction.date,
        ),

        transaction.description,

        transaction.isIncome
            ? 'Receita'
            : 'Despesa',

        transaction.categoryName,

        transaction.accountName,

        _csvValue(
          transaction.signedAmountInCents,
        ),

        transaction.notes ?? '',
      ]);
    }

    //
    // No Brasil é melhor usar ";"
    // como separador para Excel/LibreOffice.
    //
    final csv = const ListToCsvConverter(
      fieldDelimiter: ';',
      eol: '\r\n',
    ).convert(
      rows,
    );

    final directory =
        await getTemporaryDirectory();

    final file = File(
      '${directory.path}/${_fileName(report)}.csv',
    );

    //
    // BOM UTF-8 ajuda o Excel a reconhecer
    // corretamente acentos como:
    //
    // Alimentação
    // Educação
    // Descrição
    //
    final content =
        '\uFEFF$csv';

    await file.writeAsBytes(
      utf8.encode(
        content,
      ),
      flush: true,
    );

    return file;
  }

  Future<void> exportPdfAndShare(
    MonthlyReportExportData report,
  ) async {
    final file =
        await generatePdf(
      report,
    );

    await Share.shareXFiles(
      [
        XFile(
          file.path,
        ),
      ],
      subject:
          'Relatório FinanSee - ${_monthName(report)}',
      text:
          'Relatório financeiro gerado pelo FinanSee.',
    );
  }

  Future<void> exportCsvAndShare(
    MonthlyReportExportData report,
  ) async {
    final file =
        await generateCsv(
      report,
    );

    await Share.shareXFiles(
      [
        XFile(
          file.path,
        ),
      ],
      subject:
          'Movimentações FinanSee - ${_monthName(report)}',
      text:
          'Movimentações financeiras exportadas pelo FinanSee.',
    );
  }

  pw.Widget _buildHeader(
    MonthlyReportExportData report,
  ) {
    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FINANSEE',
                  style: pw.TextStyle(
                    color: _primary,
                    fontSize: 22,
                    fontWeight:
                        pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                pw.SizedBox(
                  height: 4,
                ),

                pw.Text(
                  'Relatório Financeiro',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),
              ],
            ),

            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration:
                  pw.BoxDecoration(
                color: _surface,
                borderRadius:
                    pw.BorderRadius.circular(
                  6,
                ),
              ),
              child: pw.Text(
                _monthName(
                  report,
                ),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(
          height: 12,
        ),

        pw.Divider(
          color: PdfColors.grey300,
        ),
      ],
    );
  }

  pw.Widget _buildSummary(
    MonthlyReportExportData report,
  ) {
    return pw.Column(
      crossAxisAlignment:
          pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Resumo do período',
        ),

        pw.SizedBox(
          height: 12,
        ),

        pw.Row(
          children: [
            pw.Expanded(
              child: _summaryCard(
                label:
                    'Receitas',
                value:
                    _money(
                  report.incomeInCents,
                ),
                color:
                    _income,
              ),
            ),

            pw.SizedBox(
              width: 10,
            ),

            pw.Expanded(
              child: _summaryCard(
                label:
                    'Despesas',
                value:
                    _money(
                  report.expenseInCents,
                ),
                color:
                    _expense,
              ),
            ),

            pw.SizedBox(
              width: 10,
            ),

            pw.Expanded(
              child: _summaryCard(
                label:
                    'Resultado',
                value:
                    _signedMoney(
                  report.resultInCents,
                ),
                color:
                    report.resultInCents >= 0
                        ? _income
                        : _expense,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _summaryCard({
    required String label,
    required String value,
    required PdfColor color,
  }) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.all(
        12,
      ),
      decoration:
          pw.BoxDecoration(
        color: _surface,
        borderRadius:
            pw.BorderRadius.circular(
          6,
        ),
        border: pw.Border.all(
          color: PdfColors.grey200,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color:
                  _textSecondary,
              fontSize: 9,
            ),
          ),

          pw.SizedBox(
            height: 5,
          ),

          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight:
                  pw.FontWeight.bold,
              color:
                  color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategories(
    MonthlyReportExportData report,
  ) {
    if (report.expenseCategories.isEmpty) {
      return _emptyBox(
        'Nenhuma despesa registrada neste período.',
      );
    }

    final data =
        report.expenseCategories.map(
      (category) {
        return [
          category.categoryName,
          _money(
            category.amountInCents,
          ),
          _percentage(
            category.percentageOf(
              report.expenseInCents,
            ),
          ),
        ];
      },
    ).toList();

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Categoria',
        'Valor',
        '% das despesas',
      ],
      data: data,
      headerDecoration:
          pw.BoxDecoration(
        color: _primary,
      ),
      headerStyle:
          pw.TextStyle(
        color: PdfColors.white,
        fontWeight:
            pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle:
          const pw.TextStyle(
        fontSize: 9,
      ),
      cellPadding:
          const pw.EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      border:
          pw.TableBorder(
        horizontalInside:
            pw.BorderSide(
          color: PdfColors.grey200,
        ),
        bottom:
            pw.BorderSide(
          color: PdfColors.grey300,
        ),
      ),
      headerAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      columnWidths: const {
        0: pw.FlexColumnWidth(
          2,
        ),
        1: pw.FlexColumnWidth(
          1,
        ),
        2: pw.FlexColumnWidth(
          1,
        ),
      },
    );
  }

  pw.Widget _buildTransactions(
    MonthlyReportExportData report,
  ) {
    if (report.transactions.isEmpty) {
      return _emptyBox(
        'Nenhuma transação registrada neste período.',
      );
    }

    final data =
        report.transactions.map(
      (transaction) {
        return [
          DateFormat(
            'dd/MM',
          ).format(
            transaction.date,
          ),

          transaction.description,

          transaction.categoryName,

          transaction.accountName,

          transaction.isIncome
              ? 'Receita'
              : 'Despesa',

          _signedMoney(
            transaction.signedAmountInCents,
          ),
        ];
      },
    ).toList();

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Data',
        'Descrição',
        'Categoria',
        'Conta',
        'Tipo',
        'Valor',
      ],
      data: data,
      headerDecoration:
          pw.BoxDecoration(
        color:
            PdfColors.grey800,
      ),
      headerStyle:
          pw.TextStyle(
        color:
            PdfColors.white,
        fontWeight:
            pw.FontWeight.bold,
        fontSize: 8,
      ),
      cellStyle:
          const pw.TextStyle(
        fontSize: 7.5,
      ),
      cellPadding:
          const pw.EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 6,
      ),
      border:
          pw.TableBorder(
        horizontalInside:
            pw.BorderSide(
          color:
              PdfColors.grey200,
        ),
        bottom:
            pw.BorderSide(
          color:
              PdfColors.grey300,
        ),
      ),
      headerAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
      columnWidths: const {
        0: pw.FlexColumnWidth(
          0.7,
        ),
        1: pw.FlexColumnWidth(
          1.8,
        ),
        2: pw.FlexColumnWidth(
          1.2,
        ),
        3: pw.FlexColumnWidth(
          1.1,
        ),
        4: pw.FlexColumnWidth(
          0.8,
        ),
        5: pw.FlexColumnWidth(
          1.1,
        ),
      },
    );
  }

  pw.Widget _buildSectionTitle(
    String title,
  ) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight:
            pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _emptyBox(
    String message,
  ) {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.all(
        14,
      ),
      decoration:
          pw.BoxDecoration(
        color: _surface,
        borderRadius:
            pw.BorderRadius.circular(
          6,
        ),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(
          fontSize: 9,
          color:
              _textSecondary,
        ),
      ),
    );
  }

  String _fileName(
    MonthlyReportExportData report,
  ) {
    final month =
        report.month.toString().padLeft(
              2,
              '0',
            );

    return 'finansee_relatorio_${report.year}_$month';
  }

  String _monthName(
    MonthlyReportExportData report,
  ) {
    final date = DateTime(
      report.year,
      report.month,
      1,
    );

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

  String _money(
    int cents,
  ) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(
      cents.abs() / 100,
    );
  }

  String _signedMoney(
    int cents,
  ) {
    final value = _money(
      cents,
    );

    if (cents > 0) {
      return '+ $value';
    }

    if (cents < 0) {
      return '- $value';
    }

    return value;
  }

  String _percentage(
    double percentage,
  ) {
    return '${(percentage * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  String _csvValue(
    int cents,
  ) {
    return (cents / 100)
        .toStringAsFixed(2)
        .replaceAll(
          '.',
          ',',
        );
  }
}
