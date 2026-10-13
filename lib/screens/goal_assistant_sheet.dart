import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const _lavender = Color(0xFFEAE4F5);
const _purple = Color(0xFF7B5EA7);

/// Smart Finance Assistant (Image 4.1.2). Answers are rule-based from the
/// user's goals; swap [_answer] for a real AI call later.
Future<void> showGoalAssistantSheet(
    BuildContext context, List<SavingsGoal> goals) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _AssistantSheet(goals: goals),
  );
}

/// A message is a list of (boldLabel?, text) parts.
class _Msg {
  _Msg.user(String text)
      : isUser = true,
        parts = [(null, text)];
  _Msg.bot(this.parts) : isUser = false;
  final bool isUser;
  final List<(String?, String)> parts;
}

const _questions = [
  'How much should I save monthly?',
  'Can I reach this goal earlier?',
  'Which goal should I prioritize?',
  'Can I afford another goal?',
];

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet({required this.goals});
  final List<SavingsGoal> goals;

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    _Msg.bot([(null, 'Hi! Ask me anything about your savings goals.')]),
  ];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<SavingsGoal> get _active =>
      widget.goals.where((g) => !g.isCompleted).toList();

  List<(String?, String)> _answer(int q) {
    final goals = _active;
    if (goals.isEmpty) {
      return [(null, 'You have no goals in progress. Create one to get started!')];
    }
    switch (q) {
      case 0:
        return [
          for (final g in goals)
            ('${g.name}: ',
                'save about ${fmtRm(g.monthlyNeeded.ceilToDouble())}/month to hit '
                '${fmtRm(g.target)} by ${fmtMonthYear(g.targetDate)}.\n'),
        ];
      case 1:
        return [
          for (final g in goals)
            ('${g.name}: ', _earlier(g)),
        ];
      case 2:
        final sorted = [...goals]
          ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
        final g = sorted.first;
        return [
          ('${g.name}: ',
              'it has the nearest deadline (${fmtMonthYear(g.targetDate)}), so '
              'put it first. Then move to the next goal.'),
        ];
      default:
        final total = goals.fold<double>(0, (s, g) => s + g.monthlyNeeded);
        return [
          (null,
              'Your current goals need about ${fmtRm(total.ceilToDouble())}/month in total. '
              'If your monthly surplus is clearly above that, you can add another goal — '
              'otherwise consider a later target date.'),
        ];
    }
  }

  String _earlier(SavingsGoal g) {
    const extra = 100.0;
    final m = g.monthlyNeeded;
    final before = g.remaining / m;
    final after = g.remaining / (m + extra);
    final saved = (before - after).floor();
    return saved >= 1
        ? 'adding ${fmtRm(extra)} extra each month could finish about $saved '
            'month${saved > 1 ? 's' : ''} sooner.\n'
        : 'you are already on a tight timeline; adding ${fmtRm(extra)} a month '
            'helps but won\'t move the date much.\n';
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
                    Text('Answers based on your savings goals',
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
                  if (p.$1 != null)
                    TextSpan(
                        text: p.$1,
                        style: AppTheme.body(12,
                            weight: FontWeight.w800, color: _purple)),
                  TextSpan(
                      text: p.$2,
                      style: AppTheme.body(12, color: AppColors.text)),
                ],
              ])),
      ),
    );
  }
}
