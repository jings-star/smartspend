import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/budget.dart';
import '../models/recurring_transaction.dart' show currencySymbol, formatMoney;

class ChatTurn {
  final bool fromUser;
  final String text;

  /// Error messages are shown in the chat but never sent back to the API.
  final bool isError;

  const ChatTurn({
    required this.fromUser,
    required this.text,
    this.isError = false,
  });
}

/// Talks to Claude about the user's budgets.
///
/// SETUP (development): run the app with
///   flutter run --dart-define=ANTHROPIC_API_KEY=your_key
///
/// IMPORTANT: a key inside a mobile app can be extracted by anyone. For a real
/// release, send the request to your own backend and let the backend call
/// Claude. Point the app at it with
///   --dart-define=ASSISTANT_URL=https://your-server/assistant
/// (the backend should accept the same JSON body as the Anthropic Messages
/// API and return the same JSON shape).
///
/// With neither set, the assistant falls back to simple built-in tips.
class BudgetAssistantService {
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const _defaultUrl = 'https://api.anthropic.com/v1/messages';
  static const _endpoint =
      String.fromEnvironment('ASSISTANT_URL', defaultValue: _defaultUrl);
  static const _model = 'claude-sonnet-5-5';

  bool get isConfigured => _apiKey.isNotEmpty || _endpoint != _defaultUrl;

  Future<String> ask(List<ChatTurn> history, List<Budget> budgets) async {
    final question = history.last.text;
    if (!isConfigured) return _offlineReply(question, budgets);

    // The API wants the conversation to start with a user message, so the
    // local greeting (an assistant turn) is skipped.
    final messages = <Map<String, String>>[];
    for (final t in history) {
      if (t.isError) continue;
      final role = t.fromUser ? 'user' : 'assistant';
      if (messages.isEmpty && role != 'user') continue;
      messages.add({'role': role, 'content': t.text});
    }

    final res = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'content-type': 'application/json',
            'anthropic-version': '2023-06-01',
            if (_apiKey.isNotEmpty) 'x-api-key': _apiKey,
          },
          body: jsonEncode({
            'model': _model,
            'max_tokens': 600,
            'system': _systemPrompt(budgets),
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 40));

    if (res.statusCode != 200) {
      throw Exception('Assistant error ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final blocks = (data['content'] as List?) ?? const [];
    final text = blocks
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join('\n')
        .trim();
    return text.isEmpty ? "Sorry, I couldn't come up with an answer." : text;
  }

  String _systemPrompt(List<Budget> budgets) {
    final s = currencySymbol();
    final lines = budgets.map((b) {
      return '- ${b.category}: limit $s ${formatMoney(b.amount)} '
          '${b.period.label.toLowerCase()}, spent $s ${formatMoney(b.spent)} '
          '(${b.percent}%)';
    }).join('\n');

    return 'You are the Budget Assistant inside SmartSpend, a personal '
        'finance app for students and young adults in Malaysia. '
        'Answer using only the budget data below and say so if something '
        'is not in the data. Be friendly and concise (under 120 words). '
        'Use plain text with short lines and no markdown. Give concrete '
        'suggestions with amounts in $s when reallocating. You are not a '
        'licensed financial advisor and should not claim to be. If the '
        'question is unrelated to budgeting or personal finance, politely '
        'steer back to the budget.\n\n'
        "The user's budgets:\n${lines.isEmpty ? '(none yet)' : lines}";
  }

  // ---------- offline fallback ----------

  String _offlineReply(String question, List<Budget> budgets) {
    if (budgets.isEmpty) {
      return 'You have no budgets yet. Tap + on the Budgets page to add one, '
          'and I can start giving suggestions.';
    }

    final s = currencySymbol();
    String money(double v) => '$s ${formatMoney(v)}';

    final over = budgets.where((b) => b.status == BudgetStatus.over).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final near = budgets.where((b) => b.status == BudgetStatus.warning).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final safe = budgets.where((b) => b.status == BudgetStatus.safe).toList()
      ..sort((a, b) =>
          (b.amount - b.spent).compareTo(a.amount - a.spent));

    final q = question.toLowerCase();

    if (q.contains('overspend')) {
      if (over.isEmpty && near.isEmpty) {
        return 'Good news: every budget is still under 90% of its limit.';
      }
      final lines = <String>[
        for (final b in over)
          '${b.category} is over its limit at ${b.percent}% '
              '(${money(b.spent)} of ${money(b.amount)}).',
        for (final b in near)
          '${b.category} is close to its limit at ${b.percent}%.',
      ];
      return lines.join('\n');
    }

    if (q.contains('cut')) {
      final targets = [...over, ...near];
      if (targets.isEmpty) {
        final top = [...budgets]..sort((a, b) => b.spent.compareTo(a.spent));
        return 'Nothing is close to its limit right now. If you want to save '
            'more, ${top.first.category} is where you spend the most '
            '(${money(top.first.spent)}), so start there.';
      }
      return 'Start by easing off here:\n'
          '${targets.map((b) => '- ${b.category} (${b.percent}% used)').join('\n')}\n'
          'Even a small cut in these will keep you inside your limits.';
    }

    // Recommendation / reallocation (the default answer).
    if (over.isEmpty) {
      if (near.isNotEmpty) {
        return '${near.first.category} is at ${near.first.percent}%, so keep '
            'an eye on it. Everything else looks healthy. '
            "Nothing needs to move yet.";
      }
      return "You're within every limit. Nice! If you want to save more, "
          'move a little from your least-used budget to savings next month.';
    }

    final worst = over.first;
    final overshoot = worst.spent - worst.amount;
    if (safe.isEmpty) {
      return '${worst.category} is ${money(overshoot)} over its limit and no '
          'other budget has much room. Consider raising the total budget or '
          'trimming spending there.';
    }
    final donor = safe.first;
    final room = donor.amount - donor.spent;
    final move = (room * 0.5 < overshoot ? room * 0.5 : overshoot);
    return '${worst.category} is ${money(overshoot)} over its limit.\n'
        '${donor.category} has ${money(room)} unused '
        '(only ${donor.percent}% spent).\n'
        'Next month, try moving about ${money(move)} from ${donor.category} '
        'to ${worst.category}.';
  }
}
