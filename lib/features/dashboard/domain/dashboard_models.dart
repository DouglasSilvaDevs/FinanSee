import '../../../core/database/app_database.dart';

class DashboardSummary {
  final int totalBalanceInCents;
  final int incomeThisMonthInCents;
  final int expenseThisMonthInCents;

  const DashboardSummary({
    required this.totalBalanceInCents,
    required this.incomeThisMonthInCents,
    required this.expenseThisMonthInCents,
  });

  int get monthBalanceInCents => incomeThisMonthInCents - expenseThisMonthInCents;
}

class DashboardTransaction {
  final FinanceTransaction transaction;
  final FinanceCategory category;

  const DashboardTransaction({
    required this.transaction,
    required this.category,
  });
}

class ExpenseCategoryTotal {
  final int categoryId;
  final String categoryName;
  final String? icon;
  final int totalInCents;

  const ExpenseCategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.totalInCents,
  });
}
