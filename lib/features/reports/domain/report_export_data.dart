class MonthlyReportExportData {
  final int year;
  final int month;

  final int incomeInCents;
  final int expenseInCents;

  final List<ReportExportTransaction> transactions;
  final List<ReportExportCategoryTotal> expenseCategories;

  const MonthlyReportExportData({
    required this.year,
    required this.month,
    required this.incomeInCents,
    required this.expenseInCents,
    required this.transactions,
    required this.expenseCategories,
  });

  int get resultInCents => incomeInCents - expenseInCents;

  bool get hasTransactions => transactions.isNotEmpty;
}

class ReportExportTransaction {
  final int id;

  final String description;
  final int amountInCents;
  final String type;

  final DateTime date;

  final String accountName;
  final String categoryName;

  final String? notes;

  const ReportExportTransaction({
    required this.id,
    required this.description,
    required this.amountInCents,
    required this.type,
    required this.date,
    required this.accountName,
    required this.categoryName,
    required this.notes,
  });

  bool get isIncome => type == 'income';

  bool get isExpense => type == 'expense';

  int get signedAmountInCents {
    if (isExpense) {
      return -amountInCents.abs();
    }

    return amountInCents.abs();
  }
}

class ReportExportCategoryTotal {
  final int categoryId;
  final String categoryName;
  final int amountInCents;

  const ReportExportCategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.amountInCents,
  });

  double percentageOf(
    int totalExpenseInCents,
  ) {
    if (totalExpenseInCents <= 0) {
      return 0;
    }

    return amountInCents / totalExpenseInCents;
  }
}
