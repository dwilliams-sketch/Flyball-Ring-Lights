import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/performance_report.dart';

class ReportPdfService {
  Future<Uint8List> buildSponsorPdf({
    required String clubName,
    required PerformanceReport report,
    required String filterSummary,
  }) async {
    final pdf = pw.Document();
    final topFaults = report.faultBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        build: (_) => [
          pw.Text(
            clubName,
            style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Flyball performance & club KPI report',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(filterSummary),
          pw.SizedBox(height: 18),
          _metricGrid(report),
          pw.SizedBox(height: 18),
          pw.Text('Performance overview',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 7),
          pw.Bullet(text: 'Race record: ${report.raceWins}-${report.raceLosses}-${report.raceDraws}'),
          pw.Bullet(text: 'Leg record: ${report.legWins}-${report.legLosses}-${report.legDraws}'),
          pw.Bullet(text: 'Clean leg rate: ${report.cleanLegPercent.toStringAsFixed(1)}%'),
          pw.Bullet(text: 'Faults per leg: ${report.faultsPerLeg.toStringAsFixed(2)}'),
          if (report.fastestTeamTime != null)
            pw.Bullet(text: 'Fastest recorded team time: ${report.fastestTeamTime!.toStringAsFixed(3)}s'),
          if (report.averageTeamTime != null)
            pw.Bullet(text: 'Average recorded team time: ${report.averageTeamTime!.toStringAsFixed(3)}s'),
          pw.SizedBox(height: 16),
          pw.Text('Lane comparison',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 7),
          pw.TableHelper.fromTextArray(
            headers: const ['Lane', 'Legs', 'W-L-D', 'Clean %', 'Faults', 'Avg time', 'Fastest'],
            data: ['Blue', 'Red'].map((lane) {
              final k = report.lanes[lane];
              if (k == null) return [lane, '0', '0-0-0', '0.0%', '0', '—', '—'];
              return [
                lane,
                '${k.legs}',
                '${k.wins}-${k.losses}-${k.draws}',
                '${k.cleanPercent.toStringAsFixed(1)}%',
                '${k.faults}',
                k.averageTime == null ? '—' : '${k.averageTime!.toStringAsFixed(3)}s',
                k.fastestTime == null ? '—' : '${k.fastestTime!.toStringAsFixed(3)}s',
              ];
            }).toList(),
          ),
          if (topFaults.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Most common recorded faults',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 7),
            pw.TableHelper.fromTextArray(
              headers: const ['Fault', 'Count', '% of faults'],
              data: topFaults.take(10).map((e) => [
                e.key,
                '${e.value}',
                report.faults == 0 ? '0.0%' : '${(e.value * 100 / report.faults).toStringAsFixed(1)}%',
              ]).toList(),
            ),
          ],
          if (report.dogs.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Dog performance',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 7),
            pw.TableHelper.fromTextArray(
              headers: const ['Dog', 'Runs', 'Faults', 'Fault %', 'Average', 'Fastest'],
              data: report.dogs.map((d) => [
                d.dogName,
                '${d.runs}',
                '${d.faults}',
                '${d.faultRate.toStringAsFixed(1)}%',
                d.averageTime == null ? '—' : '${d.averageTime!.toStringAsFixed(3)}s',
                d.fastestTime == null ? '—' : '${d.fastestTime!.toStringAsFixed(3)}s',
              ]).toList(),
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'Generated from recorded competition data in Flyball Ring Lights by Menai Muttineers. '
            'Missing or unrecorded values are excluded from averages rather than treated as zero.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> shareSponsorPdf({
    required String clubName,
    required PerformanceReport report,
    required String filterSummary,
  }) async {
    final bytes = await buildSponsorPdf(
      clubName: clubName,
      report: report,
      filterSummary: filterSummary,
    );
    final safe = clubName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${safe.isEmpty ? 'flyball' : safe}-performance-report.pdf',
    );
  }

  pw.Widget _metricGrid(PerformanceReport report) {
    final values = [
      ['Competitions', '${report.competitionCount}'],
      ['Races', '${report.raceCount}'],
      ['Race win rate', '${report.raceWinPercent.toStringAsFixed(1)}%'],
      ['Competitive legs', '${report.legCount}'],
      ['Clean legs', '${report.cleanLegPercent.toStringAsFixed(1)}%'],
      ['Recorded dog runs', '${report.dogRuns}'],
      ['Faults', '${report.faults}'],
      ['Reruns', '${report.reruns}'],
    ];

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) => pw.Container(
        width: 118,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(v[1], style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(v[0], style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      )).toList(),
    );
  }
}
