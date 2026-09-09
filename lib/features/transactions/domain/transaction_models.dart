import '../../../core/database/app_database.dart';

class TransactionDetails {
  final FinanceTransaction transaction;
  final FinanceCategory category;
  final FinanceAccount account;

  const TransactionDetails({
    required this.transaction,
    required this.category,
    required this.account,
  });
}
