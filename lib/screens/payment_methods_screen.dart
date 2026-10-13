import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import '../services/payment_insights.dart';
import '../services/payment_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/payment_type_style.dart';
import '../utils/format_utils.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/icon_badge.dart';
import '../widgets/primary_button.dart';
import '../widgets/round_back_button.dart';
import '../widgets/slim_progress_bar.dart';
import 'payment_method_detail_screen.dart';
import 'payment_method_form_screen.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  void _openAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodFormScreen()),
    );
  }

  void _openDetail(BuildContext context, PaymentMethod method) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodDetailScreen(methodId: method.id),
      ),
    );
  }

  /// Swipe-to-delete: remove now, and offer an Undo button for a few seconds.
  void _deleteWithUndo(BuildContext context, PaymentMethod method) {
    final repo = PaymentRepository.instance;
    final removed = repo.removeForUndo(method.id);
    if (removed == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${method.title} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => repo.restore(removed.method, removed.index),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final repo = PaymentRepository.instance;

    return Scaffold(
      body: SafeArea(
        // Rebuilds this part of the screen whenever the data changes.
        child: ListenableBuilder(
          listenable: repo,
          builder: (context, _) {
            final methods = repo.methods;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _Header(onAdd: () => _openAdd(context)),
                const SizedBox(height: 20),
                if (methods.isEmpty)
                  _EmptyState(onAdd: () => _openAdd(context))
                else ...[
                  _MethodsCard(
                    methods: methods,
                    onTap: (method) => _openDetail(context, method),
                    onDelete: (method) => _deleteWithUndo(context, method),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Spend share by method',
                    style: AppTheme.body(13, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _SpendShareCard(methods: methods),
                  const SizedBox(height: 16),
                  AiInsightCard(insights: PaymentInsights.generate(methods)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onAdd;

  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: RoundBackButton(),
          ),
          Text('Payment methods', style: AppTheme.heading(18)),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  '+ Add',
                  style: AppTheme.body(
                    13,
                    weight: FontWeight.w700,
                    color: AppColors.terracottaDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MethodsCard extends StatelessWidget {
  final List<PaymentMethod> methods;
  final void Function(PaymentMethod) onTap;
  final void Function(PaymentMethod) onDelete;

  const _MethodsCard({
    required this.methods,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < methods.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.border,
              ),
            Dismissible(
              key: ValueKey(methods[i].id),
              direction: DismissDirection.endToStart, // swipe left
              onDismissed: (_) => onDelete(methods[i]),
              background: Container(
                color: AppColors.coral,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 22),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _MethodRow(
                method: methods[i],
                onTap: () => onTap(methods[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback onTap;

  const _MethodRow({required this.method, required this.onTap});

  String get _subtitle {
    final n = method.transactionCount;
    if (n == 0) return 'No transactions yet';
    return '$n transaction${n == 1 ? '' : 's'} this month';
  }

  @override
  Widget build(BuildContext context) {
    final amount = FormatUtils.rm(method.totalAmount);

    // Material gives the row a solid background (needed while swiping).
    return Material(
      color: AppColors.paper,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: method.type.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  method.type.icon,
                  size: 20,
                  color: method.type.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          method.title,
                          style: AppTheme.body(14, weight: FontWeight.w700),
                        ),
                        if (method.isDefault)
                          const _Chip(
                            label: 'Default',
                            background: AppColors.terracottaTint,
                            color: AppColors.terracottaDark,
                          ),
                        if (method.isOverLimit)
                          const _Chip(
                            label: 'Over limit',
                            background: AppColors.coralTint,
                            color: AppColors.coral,
                          )
                        else if (method.isNearLimit)
                          const _Chip(
                            label: 'Near limit',
                            background: AppColors.coralTint,
                            color: AppColors.coral,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle,
                      style: AppTheme.body(11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                method.isIncome ? '+ $amount' : amount,
                style: AppTheme.body(
                  13,
                  weight: FontWeight.w800,
                  color: method.isIncome
                      ? AppColors.sage
                      : AppColors.terracottaDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded tag, like "Default" or "Over limit".
class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;

  const _Chip({
    required this.label,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTheme.body(10, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SpendShareCard extends StatelessWidget {
  final List<PaymentMethod> methods;

  const _SpendShareCard({required this.methods});

  @override
  Widget build(BuildContext context) {
    // Only spending counts (bank transfers are income), biggest first.
    final spending = methods
        .where((m) => !m.isIncome && m.totalAmount > 0)
        .toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final total = spending.fold<double>(0, (sum, m) => sum + m.totalAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: spending.isEmpty
          ? Text(
              'No spending recorded yet.',
              style: AppTheme.body(13, color: AppColors.textMuted),
            )
          : Column(
              children: [
                for (var i = 0; i < spending.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _ShareBar(
                    label: spending[i].title,
                    share: spending[i].totalAmount / total,
                  ),
                ],
              ],
            ),
    );
  }
}

class _ShareBar extends StatelessWidget {
  final String label;
  final double share; // 0.0 to 1.0

  const _ShareBar({required this.label, required this.share});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(13.5, weight: FontWeight.w600),
              ),
            ),
            Text(
              '${(share * 100).round()}%',
              style: AppTheme.body(12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SlimProgressBar(value: share),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          const IconBadge(icon: Icons.account_balance_wallet_outlined),
          const SizedBox(height: 16),
          Text('No payment methods yet', style: AppTheme.heading(20)),
          const SizedBox(height: 8),
          Text(
            'Add a card, e-wallet, bank or cash to start tracking.',
            textAlign: TextAlign.center,
            style: AppTheme.body(13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Add payment method', onPressed: onAdd),
        ],
      ),
    );
  }
}
