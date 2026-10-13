import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'goal_assistant_sheet.dart';
import 'goal_form_sheet.dart';
import 'goal_remove_sheet.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  // TODO: replace with data from your service / database.
  final List<SavingsGoal> _goals = [...sampleGoals];

  List<SavingsGoal> get _inProgress =>
      _goals.where((g) => !g.isCompleted).toList();
  List<SavingsGoal> get _completed =>
      _goals.where((g) => g.isCompleted).toList();

  // ---------- actions ----------

  Future<void> _create() async {
    final g = await showGoalFormSheet(context);
    if (g != null) setState(() => _goals.add(g));
  }

  Future<void> _edit(SavingsGoal goal) async {
    final g = await showGoalFormSheet(context, initial: goal);
    if (g == null) return;
    setState(() {
      final i = _goals.indexWhere((x) => x.id == goal.id);
      if (i != -1) _goals[i] = _withCompletion(g);
    });
  }

  Future<void> _remove(SavingsGoal goal) async {
    final ok = await showGoalRemoveSheet(context, goal);
    if (ok) setState(() => _goals.removeWhere((x) => x.id == goal.id));
  }

  /// Tap a card to record money saved towards it.
  Future<void> _addSavings(SavingsGoal goal) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Add to ${goal.name}', style: AppTheme.heading(18)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Amount', prefixText: 'RM '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (amount == null) return;
    setState(() {
      final i = _goals.indexWhere((x) => x.id == goal.id);
      if (i != -1) {
        _goals[i] = _withCompletion(goal.copyWith(saved: goal.saved + amount));
      }
    });
  }

  /// Stamps completedDate when a goal is reached.
  SavingsGoal _withCompletion(SavingsGoal g) =>
      g.isCompleted && g.completedDate == null
          ? g.copyWith(completedDate: DateTime.now())
          : g;

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final inProgress = _inProgress;
    final completed = _completed;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text('Savings Goals', style: AppTheme.heading(26)),
            const SizedBox(height: 4),
            Text('Set a target, and watch your progress grow.',
                style: AppTheme.body(12, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text('New Savings Goal',
                        style: AppTheme.body(14,
                            weight: FontWeight.w800, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.terracotta.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => showGoalAssistantSheet(context, _goals),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE4F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD9CFEE)),
                  ),
                  child: const Icon(Icons.smart_toy_outlined,
                      color: Color(0xFF7B5EA7)),
                ),
              ),
            ]),
            if (_goals.isEmpty) ...[
              const SizedBox(height: 60),
              Center(
                child: Text('No goals yet. Tap "New Savings Goal" to start.',
                    textAlign: TextAlign.center,
                    style: AppTheme.body(13, color: AppColors.textMuted)),
              ),
            ],
            if (inProgress.isNotEmpty) ...[
              const SizedBox(height: 22),
              _section('IN PROGRESS'),
              for (final g in inProgress) _inProgressCard(g),
            ],
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section('COMPLETED'),
              for (final g in completed) _completedCard(g),
            ],
          ],
        ),
      ),
      // If your app shell already owns the bottom nav, remove this and

    );
  }

  Widget _section(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(s,
            style: AppTheme.body(11,
                weight: FontWeight.w800, color: AppColors.textMuted)),
      );

  Widget _iconBox(SavingsGoal g) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: g.category.tint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(g.category.emoji, style: const TextStyle(fontSize: 20)),
      );

  Widget _bar(double value, Color color) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 7,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );

  Widget _cardShell({required Widget child, VoidCallback? onTap}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: child,
            ),
          ),
        ),
      );

  Widget _inProgressCard(SavingsGoal g) {
    final color = g.progress >= 0.5 ? AppColors.sage : AppColors.gold;
    final pct = (g.progress * 100).round();
    return _cardShell(
      onTap: () => _addSavings(g),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(g),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(g.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(14, weight: FontWeight.w800)),
                  ),
                  GestureDetector(
                    onTap: () => _edit(g),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.edit,
                          size: 16, color: AppColors.textFaint),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _remove(g),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.delete,
                          size: 16, color: AppColors.textFaint),
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(
                    'Target: ${fmtRm(g.target)} · by ${fmtMonthYear(g.targetDate)}',
                    style: AppTheme.body(11, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                _bar(g.progress, color),
                const SizedBox(height: 6),
                Row(children: [
                  Text('$pct% complete',
                      style: AppTheme.body(11,
                          weight: FontWeight.w800, color: color)),
                  const Spacer(),
                  Text('${fmtRm(g.remaining)} to go',
                      style: AppTheme.body(11,
                          weight: FontWeight.w600,
                          color: AppColors.textMuted)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedCard(SavingsGoal g) {
    final done = g.completedDate ?? g.targetDate;
    return _cardShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(g),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(g.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(14, weight: FontWeight.w800)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sage.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.sage.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check, size: 12, color: AppColors.sage),
                      const SizedBox(width: 4),
                      Text('Goal reached',
                          style: AppTheme.body(10,
                              weight: FontWeight.w700,
                              color: AppColors.sage)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(
                    'Saved ${fmtRm(g.saved)} · completed ${fmtMonthYear(done)}',
                    style: AppTheme.body(11, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                _bar(1, AppColors.sage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
