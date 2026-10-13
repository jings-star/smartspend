import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dashboard_data.dart';

// ---------------------------------------------------------------------------
// Income vs Expenses bar chart
// ---------------------------------------------------------------------------

class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({
    super.key,
    required this.labels,
    required this.data,
    this.height = 140,
    this.barWidth = 12,
  });

  final List<String> labels;
  final List<Totals> data;
  final double height;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarPainter(labels, data, barWidth),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.labels, this.data, this.barWidth);

  final List<String> labels;
  final List<Totals> data;
  final double barWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 22.0;
    final chartH = size.height - labelH;
    double maxV = 1;
    for (final t in data) {
      maxV = math.max(maxV, math.max(t.income, t.expense));
    }
    maxV *= 1.05;

    final base = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartH), Offset(size.width, chartH), base);

    final groupW = size.width / data.length;
    final incomePaint = Paint()..color = AppColors.sage;
    final expensePaint = Paint()..color = AppColors.terracotta;
    const gap = 3.0;

    for (var i = 0; i < data.length; i++) {
      final cx = groupW * (i + 0.5);
      _bar(canvas, cx - barWidth - gap / 2, chartH,
          data[i].income / maxV * chartH, incomePaint);
      _bar(canvas, cx + gap / 2, chartH,
          data[i].expense / maxV * chartH, expensePaint);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, chartH + 6));
    }
  }

  void _bar(Canvas c, double x, double bottom, double h, Paint p) {
    if (h <= 0) return;
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x, bottom - h, barWidth, h),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.data != data || old.labels != labels || old.barWidth != barWidth;
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(t,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]);
    return Row(children: [
      dot(AppColors.sage, 'Income'),
      const SizedBox(width: 14),
      dot(AppColors.terracotta, 'Expenses'),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Pie chart
// ---------------------------------------------------------------------------

class PieChartView extends StatelessWidget {
  const PieChartView({super.key, required this.groups, this.size = 100});

  final List<PieGroup> groups;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PiePainter(groups)),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.groups);
  final List<PieGroup> groups;

  @override
  void paint(Canvas canvas, Size size) {
    final total = groups.fold<double>(0, (s, g) => s + g.amount);
    final rect = Offset.zero & size;
    if (total <= 0) {
      canvas.drawCircle(rect.center, size.width / 2,
          Paint()..color = AppColors.border);
      return;
    }
    var start = -math.pi / 2;
    for (final g in groups) {
      final sweep = g.amount / total * 2 * math.pi;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = g.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.groups != groups;
}

// ---------------------------------------------------------------------------
// Financial health ring
// ---------------------------------------------------------------------------

class HealthRing extends StatelessWidget {
  const HealthRing({super.key, required this.score, this.size = 52});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(size: Size(size, size), painter: _RingPainter(score / 100)),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$score',
              style: const TextStyle(
                  fontSize: 15,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const Text('/100',
              style: TextStyle(fontSize: 7, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke,
        size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.border;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.sage;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}
