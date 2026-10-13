/// One payment made with (or received into) a payment method.
class PaymentTransaction {
  final String id;
  final String methodId; // which PaymentMethod it belongs to
  final String title;
  final double amount; // always positive
  final DateTime date;
  final bool isIncome;

  const PaymentTransaction({
    required this.id,
    required this.methodId,
    required this.title,
    required this.amount,
    required this.date,
    this.isIncome = false,
  });
}
