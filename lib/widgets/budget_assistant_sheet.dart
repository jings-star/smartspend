import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../services/budget_assistant_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Opens the Budget Assistant chat.
///
///   showBudgetAssistantSheet(context, budgets: store.items);
Future<void> showBudgetAssistantSheet(
  BuildContext context, {
  required List<Budget> budgets,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _AssistantSheet(budgets: budgets),
  );
}

const _suggestions = [
  'Give me a budget recommendation',
  'Where can I cut back?',
  'Am I overspending anywhere?',
  'How should I reallocate next month?',
];

class _AssistantSheet extends StatefulWidget {
  final List<Budget> budgets;
  const _AssistantSheet({required this.budgets});

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _service = BudgetAssistantService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<ChatTurn> _turns = const [
    ChatTurn(
      fromUser: false,
      text: "Hi! I'm your budget assistant. I can look at your current "
          'budgets, spending pattern, and category limits, and suggest how '
          'to reallocate them. What would you like to know?',
    ),
  ].toList();

  bool _loading = false;

  bool get _showChips => _turns.length == 1;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _loading) return;

    setState(() {
      _turns.add(ChatTurn(fromUser: true, text: question));
      _loading = true;
      _input.clear();
    });
    _scrollToEnd();

    ChatTurn reply;
    try {
      final answer = await _service.ask(List.of(_turns), widget.budgets);
      reply = ChatTurn(fromUser: false, text: answer);
    } catch (_) {
      reply = const ChatTurn(
        fromUser: false,
        isError: true,
        text: "Sorry, I couldn't reach the assistant. Please try again.",
      );
    }

    if (!mounted) return;
    setState(() {
      _turns.add(reply);
      _loading = false;
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.78;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            _header(context),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                children: [
                  for (final t in _turns) _Bubble(turn: t),
                  if (_loading) const _TypingBubble(),
                  if (_showChips) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 34),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in _suggestions)
                            _SuggestionChip(
                                label: s, onTap: () => _send(s)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.terracottaTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 18, color: AppColors.terracottaDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget Assistant', style: AppTheme.heading(16)),
                    const SizedBox(height: 2),
                    Text(
                      _service.isConfigured
                          ? 'AI · POWERED BY CLAUDE'
                          : 'SMART TIPS · OFFLINE MODE',
                      style: AppTheme.body(9.5,
                          weight: FontWeight.w700,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.close,
                      size: 16, color: AppColors.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_loading,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  cursorColor: AppColors.terracotta,
                  style: AppTheme.body(13),
                  decoration: InputDecoration(
                    hintText: 'Ask about your budget...',
                    hintStyle:
                        AppTheme.body(13, color: AppColors.textFaint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _send(_input.text),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _loading
                        ? AppColors.terracotta.withValues(alpha: 0.5)
                        : AppColors.terracotta,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      size: 17, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.terracottaTint,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome,
          size: 12, color: AppColors.terracottaDark),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatTurn turn;
  const _Bubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    if (turn.fromUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.terracotta,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(turn.text,
                style: AppTheme.body(12.5, color: Colors.white)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                turn.text,
                style: AppTheme.body(
                  12.5,
                  color: turn.isError ? AppColors.coral : AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.terracotta,
                  ),
                ),
                const SizedBox(width: 10),
                Text('Thinking...',
                    style: AppTheme.body(12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTheme.body(11.5,
              weight: FontWeight.w600, color: AppColors.terracottaDark),
        ),
      ),
    );
  }
}
