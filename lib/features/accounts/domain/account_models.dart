class AccountWithBalance {
  final int id;
  final String name;
  final String type;
  final int initialBalanceInCents;
  final int currentBalanceInCents;

  const AccountWithBalance({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalanceInCents,
    required this.currentBalanceInCents,
  });
}
