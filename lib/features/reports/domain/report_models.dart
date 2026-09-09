class MonthlyFinancialData {
  final DateTime month;
  final int incomeInCents;
  final int expenseInCents;

  const MonthlyFinancialData({
    required this.month,
    required this.incomeInCents,
    required this.expenseInCents,
  });

  int get resultInCents => incomeInCents - expenseInCents;
}

class ReportMonthSummary {
  final int incomeInCents;
  final int expenseInCents;

  const ReportMonthSummary({
    required this.incomeInCents,
    required this.expenseInCents,
  });

  int get resultInCents => incomeInCents - expenseInCents;
}

class ReportCategoryTotal {
  final int categoryId;
  final String categoryName;
  final int totalInCents;

  const ReportCategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.totalInCents,
  });
}
