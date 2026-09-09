import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/goal_models.dart';

class GoalsRepository {
  final AppDatabase database;

  GoalsRepository(
    this.database,
  );

  Stream<List<GoalProgress>> watchGoals({
    bool includeArchived = false,
  }) {
    final query = database.customSelect(
      '''
      SELECT
        g.id,
        g.name,
        g.icon,
        g.target_in_cents,
        g.deadline,
        g.is_archived,

        COALESCE(
          SUM(c.amount_in_cents),
          0
        ) AS current_in_cents

      FROM financial_goals g

      LEFT JOIN goal_contributions c
        ON c.goal_id = g.id

      WHERE (? = 1 OR g.is_archived = 0)

      GROUP BY
        g.id,
        g.name,
        g.icon,
        g.target_in_cents,
        g.deadline,
        g.is_archived

      ORDER BY
        g.is_archived ASC,
        g.created_at DESC
      ''',
      variables: [
        Variable.withInt(
          includeArchived ? 1 : 0,
        ),
      ],
      readsFrom: {
        database.financialGoals,
        database.goalContributions,
      },
    );

    return query.watch().map(
      (rows) {
        return rows.map(
          (row) {
            return GoalProgress(
              id: row.read<int>(
                'id',
              ),
              name: row.read<String>(
                'name',
              ),
              icon: row.readNullable<String>(
                'icon',
              ),
              targetInCents: row.read<int>(
                'target_in_cents',
              ),
              currentInCents: row.read<int>(
                'current_in_cents',
              ),
              deadline: row.readNullable<DateTime>(
                'deadline',
              ),
              isArchived: row.read<bool>(
                'is_archived',
              ),
            );
          },
        ).toList();
      },
    );
  }

  Future<FinancialGoal?> getGoal(
    int goalId,
  ) {
    return (database.select(
      database.financialGoals,
    )..where(
            (table) => table.id.equals(
              goalId,
            ),
          ))
        .getSingleOrNull();
  }

  Stream<List<GoalContribution>> watchContributions(
    int goalId,
  ) {
    final query = database.select(database.goalContributions)
      ..where(
        (table) => table.goalId.equals(
          goalId,
        ),
      )
      ..orderBy([
        (table) => OrderingTerm.desc(
              table.date,
            ),
        (table) => OrderingTerm.desc(
              table.id,
            ),
      ]);

    return query.watch();
  }

  Future<int> createGoal({
    required String name,
    required int targetInCents,
    required String icon,
    DateTime? deadline,
    int initialAmountInCents = 0,
  }) async {
    return database.transaction(
      () async {
        final goalId = await database.into(database.financialGoals).insert(
              FinancialGoalsCompanion.insert(
                name: name.trim(),
                targetInCents: targetInCents,
                icon: Value(icon),
                deadline: Value(deadline),
              ),
            );

        if (initialAmountInCents > 0) {
          await database.into(database.goalContributions).insert(
                GoalContributionsCompanion.insert(
                  goalId: goalId,
                  amountInCents: initialAmountInCents,
                  date: DateTime.now(),
                  notes: const Value(
                    'Valor inicial',
                  ),
                ),
              );
        }

        return goalId;
      },
    );
  }

  Future<void> updateGoal({
    required int goalId,
    required String name,
    required int targetInCents,
    required String icon,
    DateTime? deadline,
  }) async {
    await (database.update(
      database.financialGoals,
    )..where(
            (table) => table.id.equals(
              goalId,
            ),
          ))
        .write(
      FinancialGoalsCompanion(
        name: Value(
          name.trim(),
        ),
        targetInCents: Value(
          targetInCents,
        ),
        icon: Value(
          icon,
        ),
        deadline: Value(
          deadline,
        ),
      ),
    );
  }

  Future<void> addContribution({
    required int goalId,
    required int amountInCents,
    required DateTime date,
    String? notes,
  }) async {
    final cleanNotes = notes?.trim();

    await database.into(database.goalContributions).insert(
          GoalContributionsCompanion.insert(
            goalId: goalId,
            amountInCents: amountInCents,
            date: date,
            notes: Value(
              cleanNotes == null || cleanNotes.isEmpty ? null : cleanNotes,
            ),
          ),
        );
  }

  Future<void> deleteContribution(
    int contributionId,
  ) async {
    await (database.delete(
      database.goalContributions,
    )..where(
            (table) => table.id.equals(
              contributionId,
            ),
          ))
        .go();
  }

  Future<void> setArchived({
    required int goalId,
    required bool archived,
  }) async {
    await (database.update(
      database.financialGoals,
    )..where(
            (table) => table.id.equals(
              goalId,
            ),
          ))
        .write(
      FinancialGoalsCompanion(
        isArchived: Value(
          archived,
        ),
      ),
    );
  }

  Future<void> deleteGoal(
    int goalId,
  ) async {
    await (database.delete(
      database.financialGoals,
    )..where(
            (table) => table.id.equals(
              goalId,
            ),
          ))
        .go();
  }
}
