import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/savings_goal.dart';
import '../models/transaction_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_data.dart';
import 'dashboard_sheets.dart';
import '../widgets/report_pdf.dart';

enum _Range { thisMonth, lastMonth, custom }

/// Export report flow (Images 4.1.16 - 4.1.19):
/// options -> "Report exported" -> Open (preview) / Share.
Future<void> showExportReportSheet(
  BuildContext context, {
  required List<TransactionItem> all,
  required List<DateTime> months,
  required DateTime month,
  required List<SavingsGoal> goals,
}) {
  return showDashSheet<void>(
    context,
    (_) => _ExportSheet(all: all, months: months, month: month, goals: goals),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({
    required this.all,
    required this.months,
    required this.month,
    required this.goals,
  });

  final List<TransactionItem> all;
  final List<DateTime> months;
  final DateTime month;
  final List<SavingsGoal> goals;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  _Range _range = _Range.thisMonth;
  DateTimeRange? _custom;

  bool _summary = true;
  bool _goals = true;
  bool _category = true;
  bool _trend = false;

  bool _busy = false;
  ReportResult? _result;
  String _fileName = '';

  // ---------- range helpers ----------

  DateTime get _lastMonth =>
      DateTime(widget.month.year, widget.month.month - 1);

  /// (start, end, label for title, file name) of the selected range.
  (DateTime, DateTime, String, String) get _period {
    switch (_range) {
      case _Range.thisMonth:
        final m = widget.month;
        return (
          DateTime(m.year, m.month, 1),
          DateTime(m.year, m.month + 1, 0),
          monthYear(m),
          'SmartSpend_${monthLong(m)}_${m.year}_Report.pdf',
        );
      case _Range.lastMonth:
        final m = _lastMonth;
        return (
          DateTime(m.year, m.month, 1),
          DateTime(m.year, m.month + 1, 0),
          monthYear(m),
          'SmartSpend_${monthLong(m)}_${m.year}_Report.pdf',
        );
      case _Range.custom:
        final r = _custom!;
        String d(DateTime x) =>
            '${x.year}${x.month.toString().padLeft(2, '0')}${x.day.toString().padLeft(2, '0')}';
        String nice(DateTime x) => '${x.day} ${monthShort(x)} ${x.year}';
        return (
          r.start,
          r.end,
          '${nice(r.start)} - ${nice(r.end)}',
          'SmartSpend_${d(r.start)}_${d(r.end)}_Report.pdf',
        );
    }
  }

  Future<void> _selectRange(_Range r) async {
    if (r == _Range.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(now.year + 1),
        initialDateRange: _custom,
      );
      if (picked == null) return;
      setState(() {
        _custom = picked;
        _range = r;
      });
    } else {
      setState(() => _range = r);
    }
  }

  // ---------- export ----------

  Future<void> _export() async {
    if (!(_summary || _goals || _category || _trend)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select at least one item to include')));
      return;
    }
    setState(() => _busy = true);
    try {
      final (start, end, label, name) = _period;
      final stats = _range == _Range.custom
          ? PeriodStats.range(widget.all, start, end)
          : PeriodStats.month(widget.all, DateTime(start.year, start.month));

      final result = await buildReportPdf(
        periodLabel: label,
        stats: stats,
        all: widget.all,
        goals: widget.goals,
        trendMonths: widget.months,
        weekMonth:
            _range == _Range.custom ? null : DateTime(start.year, start.month),
        includeSummary: _summary,
        includeGoals: _goals,
        includeCategories: _category,
        includeTrend: _trend,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _fileName = name;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not create report: $e')));
    }
  }

  Future<void> _share() => Printing.sharePdf(
      bytes: _result!.bytes, filename: _fileName);

  Future<void> _open() {
    final r = _result!;
    return showDashSheet<void>(
      context,
      tall: true,
      (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: SheetShell(
          title: _fileName,
          scrollBody: false,
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PdfPreview(
                  build: (_) async => r.bytes,
                  useActions: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: _fileName,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _outlined('Close preview', () => Navigator.pop(ctx)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _filled('Download again', Icons.download, _share),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) =>
      _result == null ? _form() : _done(_result!);

  Widget _form() {
    return SheetShell(
      title: 'Export report',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DATE RANGE'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _rangeChip('This month', _Range.thisMonth)),
            const SizedBox(width: 8),
            Expanded(child: _rangeChip('Last month', _Range.lastMonth)),
            const SizedBox(width: 8),
            Expanded(child: _rangeChip('Custom', _Range.custom)),
          ]),
          if (_range == _Range.custom && _custom != null) ...[
            const SizedBox(height: 8),
            Text(_period.$3,
                style: AppTheme.body(11, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 18),
          _label('INCLUDE IN REPORT'),
          const SizedBox(height: 4),
          _check('Income and expense summary', _summary,
              (v) => setState(() => _summary = v)),
          _check('Savings goal progress', _goals,
              (v) => setState(() => _goals = v)),
          _check('Category breakdown chart', _category,
              (v) => setState(() => _category = v)),
          _check('Spending trend chart', _trend,
              (v) => setState(() => _trend = v)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _export,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf, size: 18),
              label: Text(_busy ? 'Creating...' : 'Export PDF',
                  style: AppTheme.body(14,
                      weight: FontWeight.w800, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _done(ReportResult r) {
    final kb = (r.bytes.length / 1024).round();
    return SheetShell(
      title: '',
      titleWidget: const SizedBox.shrink(),
      child: Column(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.sage.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: AppColors.sage),
        ),
        const SizedBox(height: 12),
        Text('Report exported', style: AppTheme.heading(22)),
        const SizedBox(height: 4),
        Text('Your PDF is ready to view or share.',
            style: AppTheme.body(12, color: AppColors.textMuted)),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            const Icon(Icons.picture_as_pdf,
                color: AppColors.terracotta, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_fileName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(12, weight: FontWeight.w800)),
                  Text('$kb KB · ${r.pages} page${r.pages == 1 ? '' : 's'}',
                      style: AppTheme.body(10, color: AppColors.textMuted)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _outlined('Share', _share, icon: Icons.share_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _filled('Open', Icons.visibility, _open)),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _outlined('Done', () => Navigator.pop(context)),
        ),
      ]),
    );
  }

  // ---------- small widgets ----------

  Widget _label(String s) => Text(s,
      style: AppTheme.body(11,
          weight: FontWeight.w800, color: AppColors.textMuted));

  Widget _rangeChip(String label, _Range r) {
    final on = _range == r;
    return GestureDetector(
      onTap: () => _selectRange(r),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.terracotta : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: on ? AppColors.terracotta : AppColors.border),
        ),
        child: Text(label,
            style: AppTheme.body(12,
                weight: FontWeight.w800,
                color: on ? Colors.white : AppColors.text)),
      ),
    );
  }

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.terracotta : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: value ? AppColors.terracotta : AppColors.border),
            ),
            child: value
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.body(13, weight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _outlined(String label, VoidCallback onTap, {IconData? icon}) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.text),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: AppTheme.body(13,
                  weight: FontWeight.w700, color: AppColors.text)),
        ]),
      ),
    );
  }

  Widget _filled(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: AppTheme.body(13,
                weight: FontWeight.w800, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
