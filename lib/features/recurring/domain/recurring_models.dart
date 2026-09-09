import '../../../core/database/app_database.dart';

class RecurringTransactionDetails {
  final RecurringTransactionRule rule;
  final FinanceAccount account;
  final FinanceCategory category;

  const RecurringTransactionDetails({
    required this.rule,
    required this.account,
    required this.category,
  });
}
