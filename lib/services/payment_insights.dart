import '../models/payment_method.dart';
import '../utils/format_utils.dart';

/// Makes short tips from the payment data.
///
/// This uses simple rules for now (no internet needed). Later you can
/// replace [generate] with a real AI call (for example the Claude API),
/// and the card on the screen will not need to change.
class PaymentInsights {
  static List<String> generate(List<PaymentMethod> methods) {
    final spending = methods
        .where((m) => !m.isIncome && m.totalAmount > 0)
        .toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    if (spending.isEmpty) {
      return ['Add some spending and your tips will show up here.'];
    }

    final insights = <String>[];

    // 1) Limit warnings come first (most important).
    for (final m in spending) {
      if (m.isOverLimit) {
        final over = m.totalAmount - m.monthlyLimit!;
        insights.add(
          '${m.title} is ${FormatUtils.rm(over)} over its monthly limit. '
          'Try using another method for a while.',
        );
      } else if (m.isNearLimit) {
        final left = m.monthlyLimit! - m.totalAmount;
        insights.add(
          '${m.title} has only ${FormatUtils.rm(left)} left before its limit.',
        );
      }
    }

    // 2) Biggest spender.
    final total = spending.fold<double>(0, (sum, m) => sum + m.totalAmount);
    final top = spending.first;
    final share = (top.totalAmount / total * 100).round();
    insights.add('${top.title} is your biggest spend, at $share% of the total.');

    return insights.take(2).toList();
  }
}
