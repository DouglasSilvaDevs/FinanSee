class BudgetProgress {
  final int budgetId;

  final int categoryId;
  final String categoryName;
  final String? categoryIcon;

  final int limitInCents;
  final int spentInCents;

  const BudgetProgress({
    required this.budgetId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.limitInCents,
    required this.spentInCents,
  });

  int get remainingInCents => limitInCents - spentInCents;

  double get progress {
    if (limitInCents <= 0) {
      return 0;
    }

    return spentInCents / limitInCents;
  }

  bool get isExceeded => spentInCents > limitInCents;

  bool get isNearLimit => progress >= 0.8 && !isExceeded;
}
