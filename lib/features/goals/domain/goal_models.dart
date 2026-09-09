class GoalProgress {
  final int id;
  final String name;
  final String? icon;

  final int targetInCents;
  final int currentInCents;

  final DateTime? deadline;

  final bool isArchived;

  const GoalProgress({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetInCents,
    required this.currentInCents,
    required this.deadline,
    required this.isArchived,
  });

  int get remainingInCents => targetInCents - currentInCents;

  double get progress {
    if (targetInCents <= 0) {
      return 0;
    }

    return currentInCents / targetInCents;
  }

  bool get isCompleted => currentInCents >= targetInCents;
}
