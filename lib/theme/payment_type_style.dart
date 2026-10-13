import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import 'app_colors.dart';

/// Name, icon and colors for each payment type.
extension PaymentTypeStyle on PaymentType {
  String get label => switch (this) {
        PaymentType.ewallet => 'E-wallet',
        PaymentType.card => 'Card',
        PaymentType.bank => 'Bank',
        PaymentType.cash => 'Cash',
      };

  IconData get icon => switch (this) {
        PaymentType.ewallet => Icons.account_balance_wallet_outlined,
        PaymentType.card => Icons.credit_card,
        PaymentType.bank => Icons.account_balance_outlined,
        PaymentType.cash => Icons.payments_outlined,
      };

  Color get tint => switch (this) {
        PaymentType.ewallet => const Color(0xFFE6E1F2),
        PaymentType.card => AppColors.goldTint,
        PaymentType.bank => AppColors.coralTint,
        PaymentType.cash => AppColors.sageTint,
      };

  Color get iconColor => switch (this) {
        PaymentType.ewallet => const Color(0xFF6B5FA8),
        PaymentType.card => AppColors.gold,
        PaymentType.bank => AppColors.coral,
        PaymentType.cash => AppColors.sage,
      };
}
