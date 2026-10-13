import 'transaction_item.dart';

class TxFilter {
  final TxType? type; // null = All
  final Set<String> categories;
  final DateTime? from;
  final DateTime? to;
  final double? minAmount;
  final double? maxAmount;
  final Set<String> paymentMethods;
  final SortOption sort;

  const TxFilter({
    this.type,
    this.categories = const {},
    this.from,
    this.to,
    this.minAmount,
    this.maxAmount,
    this.paymentMethods = const {},
    this.sort = SortOption.dateNewest,
  });

  TxFilter copyWith({
    TxType? type,
    bool clearType = false,
    Set<String>? categories,
    DateTime? from,
    DateTime? to,
    Set<String>? paymentMethods,
    SortOption? sort,
    double? minAmount,
    double? maxAmount,
    bool clearMin = false,
    bool clearMax = false,
  }) =>
      TxFilter(
        type: clearType ? null : (type ?? this.type),
        categories: categories ?? this.categories,
        from: from ?? this.from,
        to: to ?? this.to,
        minAmount: clearMin ? null : (minAmount ?? this.minAmount),
        maxAmount: clearMax ? null : (maxAmount ?? this.maxAmount),
        paymentMethods: paymentMethods ?? this.paymentMethods,
        sort: sort ?? this.sort,
      );

  bool get hasDateRange => from != null || to != null;

  bool get isActive =>
      type != null ||
      categories.isNotEmpty ||
      hasDateRange ||
      minAmount != null ||
      maxAmount != null ||
      paymentMethods.isNotEmpty;

  bool matches(TransactionItem t) {
    if (type != null && t.type != type) return false;
    if (categories.isNotEmpty && !categories.contains(t.category)) return false;
    if (paymentMethods.isNotEmpty && !paymentMethods.contains(t.paymentMethod)) {
      return false;
    }
    final d = DateTime(t.date.year, t.date.month, t.date.day);
    if (from != null && d.isBefore(from!)) return false;
    if (to != null && d.isAfter(to!)) return false;
    if (minAmount != null && t.amount < minAmount!) return false;
    if (maxAmount != null && t.amount > maxAmount!) return false;
    return true;
  }

  List<TransactionItem> apply(List<TransactionItem> all) {
    final list = all.where(matches).toList();
    switch (sort) {
      case SortOption.dateNewest:
        list.sort((a, b) => b.date.compareTo(a.date));
      case SortOption.dateOldest:
        list.sort((a, b) => a.date.compareTo(b.date));
      case SortOption.amountHigh:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case SortOption.amountLow:
        list.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return list;
  }
}
