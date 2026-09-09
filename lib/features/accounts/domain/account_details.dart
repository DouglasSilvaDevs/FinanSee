import '../../../core/database/app_database.dart';

class AccountDetailsData {
  final FinanceAccount account;

  final int incomeInCents;
  final int expenseInCents;
  final int currentBalanceInCents;

  final List<AccountTransactionItem> transactions;

  const AccountDetailsData({
    required this.account,
    required this.incomeInCents,
    required this.expenseInCents,
    required this.currentBalanceInCents,
    required this.transactions,
  });
}

class AccountTransactionItem {
  final FinanceTransaction transaction;

  final String categoryName;
  final String? categoryIcon;

  const AccountTransactionItem({
    required this.transaction,
    required this.categoryName,
    required this.categoryIcon,
  });

  bool get isIncome => transaction.type == 'income';

  bool get isExpense => transaction.type == 'expense';
}
