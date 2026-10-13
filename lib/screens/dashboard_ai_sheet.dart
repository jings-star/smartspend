import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_data.dart';

const _lavender = Color(0xFFEAE4F5);
const _purple = Color(0xFF7B5EA7);

const _questions = [
  'How am I doing this month?',
  'Why did I overspend?',
  'Give me saving tips.',
  'Which goal should I prioritize?',
];

/// Smart Finance Assistant for the dashboard. Answers are rule-based from the
/// selected month's data; replace [_answer] with a real AI call when ready.
Future<void> showDashboardAssistantSheet(
  BuildContext context, {
  required PeriodStats stats,
  required DateTime month,
  required List<SavingsGoal> goals,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _AssistantSheet(stats: stats, month: month, goals: goals),
  );
}

class _Msg {
  _Msg.user(String text)
      : isUser = true,
        parts = [(null, text)];
  _Msg.bot(this.parts) : isUser = false;
  final bool isUser;
  final List<(String?, String)> parts;
}

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet(
      {required this.stats, required this.month, required this.goals});
  final PeriodStats stats;
  final DateTime month;
  final List<SavingsGoal> goals;

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    _Msg.bot([(null, 'Hi! Ask me anything about this month\'s finances.')]),
  ];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<(String?, String)> _answer(int q) {
    final s = widget.stats;
    final top = s.categories.isEmpty ? null : s.categories.first;
    switch (q) {
      case 0:
        return [
          (
            null,
            'In ${monthYear(widget.month)} you earned ${fmtMoney(s.income)} and spent '
                '${fmtMoney(s.expense)}, leaving ${fmtMoney(s.balance)} '
                '(${(s.savedPct * 100).round()}% saved). Your Financial Health Score is '
          ),
          ('${s.healthScore}/100 (${s.healthLabel}).', ''),
        ];
      case 1:
        final change = s.expenseChangePct;
        final changeText = change == null
            ? ''
            : ', ${change >= 0 ? 'up' : 'down'} ${change.abs().round()}% from last month\'s ${fmtMoney(s.prevExpense!)}';
        return [
          (
            null,
            'Total expenses are ${fmtMoney(s.expense)}$changeText.'
          ),
          if (top != null) ...[
            (null, ' The main driver is '),
            (top.key, ' at ${fmtMoney(top.value)} '
                '(${(top.value / s.totalExpenseForPct * 100).round()}% of all spending).'),
          ],
        ];
      case 2:
        if (top == null) {
          return [(null, 'Add some expenses first and I can suggest where to save.')];
        }
        final cut = (top.value * 0.15).round();
        return [
          (null, 'Try trimming '),
          (top.key, ' by 15% - that saves about RM$cut a month. '),
          (null,
              'Set a weekly cap for it, and move part of your income to savings '
              'on payday before you spend.'),
        ];
      default:
        final active = widget.goals.where((g) => !g.isCompleted).toList()
          ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
        if (active.isEmpty) {
          return [(null, 'You have no goals in progress. Create one in the Goals tab.')];
        }
        final g = active.first;
        return [
          ('${g.name}: ', ''),
          (
            null,
            'it has the nearest deadline (${fmtMonthYear(g.targetDate)}) and needs about '
                '${fmtRm(g.monthlyNeeded.ceilToDouble())}/month. Prioritise it first.'
          ),
        ];
    }
  }

  void _ask(int q) {
    setState(() => _msgs.add(_Msg.user(_questions[q])));
    _scrollDown();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _msgs.add(_Msg.bot(_answer(q))));
      _scrollDown();
    });
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.82;
    return SizedBox(
      height: h,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: _purple, shape: BoxShape.circle),
                child: const Icon(Icons.smart_toy_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Finance Assistant',
                        style: AppTheme.body(13, weight: FontWeight.w800)),
                    Text("Answers based on this month's data",
                        style: AppTheme.body(11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    size: 20, color: AppColors.textMuted),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                itemCount: _msgs.length,
                itemBuilder: (_, i) => _bubble(_msgs[i]),
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _questions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _ask(i),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: _purple, shape: BoxShape.circle),
                        child: const Text('?',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 10),
                      Text(_questions[i],
                          style: AppTheme.body(12, weight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: m.isUser ? AppColors.terracotta : _lavender,
          borderRadius: BorderRadius.circular(14),
        ),
        child: m.isUser
            ? Text(m.parts.first.$2,
                style: AppTheme.body(12,
                    weight: FontWeight.w600, color: Colors.white))
            : Text.rich(TextSpan(children: [
                for (final p in m.parts) ...[
                  // (bold label, text) - label is highlighted in purple
                  if (p.$1 != null && p.$2.isEmpty)
                    TextSpan(
                        text: p.$1,
                        style: AppTheme.body(12,
                            weight: FontWeight.w800, color: _purple))
                  else ...[
                    if (p.$1 != null)
                      TextSpan(
                          text: p.$1,
                          style: AppTheme.body(12,
                              weight: FontWeight.w800, color: _purple)),
                    TextSpan(
                        text: p.$2,
                        style: AppTheme.body(12, color: AppColors.text)),
                  ],
                ],
              ])),
      ),
    );
  }
}
