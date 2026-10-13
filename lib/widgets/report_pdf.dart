import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/savings_goal.dart';
import '../models/transaction_item.dart';
import 'dashboard_data.dart';

class ReportResult {
  const ReportResult(this.bytes, this.pages);
  final Uint8List bytes;
  final int pages;
}

const _brand = PdfColor.fromInt(0xFFB97A57);
const _green = PdfColor.fromInt(0xFF5B8F67);
const _muted = PdfColor.fromInt(0xFF7A6F63);
const _track = PdfColor.fromInt(0xFFE6DCCB);

/// Builds the "SmartSpend Financial Report" PDF.
///
/// Uses only ASCII text because the default PDF font has no emoji / arrows.
/// [weekMonth] is the month used for the "this week" column (null = skip it).
Future<ReportResult> buildReportPdf({
  required String periodLabel,
  required PeriodStats stats,
  required List<TransactionItem> all,
  required List<SavingsGoal> goals,
  required List<DateTime> trendMonths,
  DateTime? weekMonth,
  bool includeSummary = true,
  bool includeGoals = true,
  bool includeCategories = true,
  bool includeTrend = false,
}) async {
  final doc = pw.Document(title: 'SmartSpend Financial Report');

  pw.Widget section(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget line(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  final change = stats.expenseChangePct;
  final groups = pieGroups(stats);

  final widgets = <pw.Widget>[
    pw.Text('SmartSpend Financial Report',
        style: pw.TextStyle(
            fontSize: 22, fontWeight: pw.FontWeight.bold, color: _brand)),
    pw.SizedBox(height: 4),
    pw.Text('Period: $periodLabel',
        style: const pw.TextStyle(fontSize: 11, color: _muted)),
    pw.Divider(color: _track),

    if (includeSummary) ...[
      section('Income & Expense Summary'),
      line('Total income', fmtMoney(stats.income)),
      line('Total expenses', fmtMoney(stats.expense)),
      line('Remaining balance', fmtMoney(stats.balance)),
      line('Projected end-of-month balance',
          fmtMoney(stats.projectedBalance.roundToDouble())),
      line('Financial health score',
          '${stats.healthScore}/100 (${stats.healthLabel})'),
      if (change != null)
        line('Expense change vs last month',
            '${change >= 0 ? '+' : ''}${change.round()}%'),
    ],

    if (includeCategories) ...[
      section('Category Breakdown'),
      if (groups.isEmpty)
        pw.Text('No expenses in this period.',
            style: const pw.TextStyle(fontSize: 11, color: _muted))
      else ...[
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.SizedBox(
            width: 110,
            height: 110,
            child: pw.Chart(
              grid: pw.PieGrid(),
              datasets: [
                for (final g in groups)
                  pw.PieDataSet(
                    legend: '',
                    value: g.amount,
                    color: PdfColor.fromInt(catColorInt(g.label)),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            for (final g in groups)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(children: [
                  pw.Container(
                      width: 8,
                      height: 8,
                      decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(catColorInt(g.label)),
                          shape: pw.BoxShape.circle)),
                  pw.SizedBox(width: 6),
                  pw.Text(
                      '${g.label} - ${(g.amount / stats.totalExpenseForPct * 100).round()}%',
                      style: const pw.TextStyle(fontSize: 10)),
                ]),
              ),
          ]),
        ]),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headerStyle:
              pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: _track),
          cellAlignments: {
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          headers: [
            'Category',
            'Amount',
            '% of spend',
            if (weekMonth != null) 'This week',
          ],
          data: [
            for (final g in groups)
              [
                g.label,
                fmtMoney(g.amount),
                '${(g.amount / stats.totalExpenseForPct * 100).round()}%',
                if (weekMonth != null)
                  '${(lastWeekShare(all, weekMonth, g.names) * 100).round()}%',
              ],
          ],
        ),
      ],
    ],

    if (includeGoals) ...[
      section('Savings Goal Progress'),
      if (goals.isEmpty)
        pw.Text('No savings goals yet.',
            style: const pw.TextStyle(fontSize: 11, color: _muted))
      else
        for (final g in goals)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(g.name,
                          style: pw.TextStyle(
                              fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          '${fmtRm(g.saved)} / ${fmtRm(g.target)}  (${(g.progress * 100).round()}% complete)',
                          style: const pw.TextStyle(
                              fontSize: 10, color: _muted)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: 480,
                    height: 6,
                    color: _track,
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Container(
                        width: 480 * g.progress,
                        height: 6,
                        color: g.progress >= 0.5 ? _green : _brand,
                      ),
                    ),
                  ),
                ]),
          ),
    ],

    if (includeTrend) ...[
      section('Spending Trend'),
      _trendChart(all, trendMonths),
    ],
  ];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    build: (_) => widgets,
  ));

  final bytes = await doc.save();
  var pages = 1;
  try {
    pages = doc.document.pdfPageList.pages.length;
  } catch (_) {}
  return ReportResult(bytes, pages);
}

pw.Widget _trendChart(List<TransactionItem> all, List<DateTime> months) {
  final totals = monthlyTotals(all, months);
  double maxV = 1;
  for (final t in totals) {
    if (t.income > maxV) maxV = t.income;
    if (t.expense > maxV) maxV = t.expense;
  }
  const h = 90.0;
  return pw.Column(children: [
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < months.length; i++)
          pw.Column(children: [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Container(
                  width: 16, height: totals[i].income / maxV * h, color: _green),
              pw.SizedBox(width: 3),
              pw.Container(
                  width: 16,
                  height: totals[i].expense / maxV * h,
                  color: _brand),
            ]),
            pw.SizedBox(height: 4),
            pw.Text(monthShortYear(months[i]),
                style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ]),
      ],
    ),
    pw.SizedBox(height: 8),
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
      pw.Container(width: 8, height: 8, color: _green),
      pw.SizedBox(width: 4),
      pw.Text('Income', style: const pw.TextStyle(fontSize: 9)),
      pw.SizedBox(width: 14),
      pw.Container(width: 8, height: 8, color: _brand),
      pw.SizedBox(width: 4),
      pw.Text('Expenses', style: const pw.TextStyle(fontSize: 9)),
    ]),
  ]);
}
