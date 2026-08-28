import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_profile.dart';
import '../../models/performance_report.dart';
import '../../services/app_repository.dart';
import '../../services/report_pdf_service.dart';
import '../../services/reporting_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/trend_chart.dart';

class ReportsScreen extends StatefulWidget {
  final AppProfile profile;

  const ReportsScreen({super.key, required this.profile});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final reporting = ReportingService();
  final pdf = ReportPdfService();

  Set<String> selectedCompetitionIds = {};
  String team = '';
  String organisation = '';
  String lane = '';
  String period = 'All time';
  String _reportKey = '';
  Future<PerformanceReport>? _reportFuture;

  DateTime? get fromDate {
    final now = DateTime.now();
    if (period == 'Last 30 days') return now.subtract(const Duration(days: 30));
    if (period == 'Last 90 days') return now.subtract(const Duration(days: 90));
    if (period == 'This year') return DateTime(now.year, 1, 1);
    return null;
  }

  ReportFilter get filter => ReportFilter(
        competitionIds: selectedCompetitionIds,
        from: fromDate,
        teamName: team,
        organisation: organisation,
        lane: lane,
      );


  Future<PerformanceReport> _currentReport(String dataVersion) {
    final ids = selectedCompetitionIds.toList()..sort();
    final key = '$dataVersion::${ids.join('|')}::$period::$team::$organisation::$lane';
    if (_reportFuture == null || key != _reportKey) {
      _reportKey = key;
      _reportFuture = reporting.buildReport(
        clubId: widget.profile.clubId,
        filter: filter,
        title: '${widget.profile.clubName} performance',
      );
    }
    return _reportFuture!;
  }

  Future<void> _chooseCompetitions(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    var selected = Set<String>.from(selectedCompetitionIds);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Choose competitions'),
          content: SizedBox(
            width: 520,
            child: ListView(
              shrinkWrap: true,
              children: [
                CheckboxListTile(
                  value: selected.isEmpty,
                  title: const Text('All competitions'),
                  subtitle: const Text('Leave individual boxes clear to include everything'),
                  onChanged: (_) => setLocal(() => selected.clear()),
                ),
                const Divider(),
                for (final doc in docs)
                  CheckboxListTile(
                    value: selected.contains(doc.id),
                    title: Text((doc.data()['name'] ?? 'Competition').toString()),
                    subtitle: Text((doc.data()['teamName'] ?? '').toString()),
                    onChanged: (on) => setLocal(() {
                      if (selected.isEmpty && on == true) selected = {doc.id};
                      else if (on == true) selected.add(doc.id);
                      else selected.remove(doc.id);
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('APPLY')),
          ],
        ),
      ),
    );
    if (result != null) setState(() => selectedCompetitionIds = result);
  }

  String _filterSummary() {
    final parts = <String>[];
    parts.add(period);
    if (selectedCompetitionIds.isNotEmpty) parts.add('${selectedCompetitionIds.length} selected competition(s)');
    if (team.isNotEmpty) parts.add('Team: $team');
    if (organisation.isNotEmpty) parts.add(organisation);
    if (lane.isNotEmpty) parts.add('$lane lane');
    return parts.join(' · ');
  }

  String _sponsorSummary(PerformanceReport r) {
    final lines = <String>[
      '${widget.profile.clubName} — Flyball performance',
      _filterSummary(),
      '',
      '${r.competitionCount} competitions · ${r.raceCount} races · ${r.legCount} competitive legs',
      'Race record ${r.raceWins}-${r.raceLosses}-${r.raceDraws} · win rate ${r.raceWinPercent.toStringAsFixed(1)}%',
      'Clean leg rate ${r.cleanLegPercent.toStringAsFixed(1)}% · ${r.faults} recorded faults · ${r.reruns} reruns',
      '${r.dogRuns} recorded dog runs',
      if (r.fastestTeamTime != null) 'Fastest team time ${r.fastestTeamTime!.toStringAsFixed(3)}s',
      if (r.averageTeamTime != null) 'Average team time ${r.averageTeamTime!.toStringAsFixed(3)}s',
    ];
    return lines.join('\n');
  }

  String _csv(PerformanceReport r) {
    String q(Object? v) {
      final raw = (v ?? '').toString().replaceAll('\"', '\"\"');
      return '"$raw"';
    }
    final rows = <List<Object?>>[
      ['Metric', 'Value'],
      ['Competitions', r.competitionCount],
      ['Races', r.raceCount],
      ['Race wins', r.raceWins],
      ['Race losses', r.raceLosses],
      ['Race draws', r.raceDraws],
      ['Legs', r.legCount],
      ['Clean leg %', r.cleanLegPercent.toStringAsFixed(2)],
      ['Faults', r.faults],
      ['Reruns', r.reruns],
      ['Dog runs', r.dogRuns],
      ['Average team time', r.averageTeamTime?.toStringAsFixed(3) ?? ''],
      ['Fastest team time', r.fastestTeamTime?.toStringAsFixed(3) ?? ''],
      [],
      ['Dog', 'Runs', 'Faults', 'Fault %', 'Average time', 'Fastest time', 'Average start'],
      ...r.dogs.map((d) => [
            d.dogName,
            d.runs,
            d.faults,
            d.faultRate.toStringAsFixed(2),
            d.averageTime?.toStringAsFixed(3) ?? '',
            d.fastestTime?.toStringAsFixed(3) ?? '',
            d.averageStart?.toStringAsFixed(3) ?? '',
          ]),
    ];
    return rows.map((row) => row.map(q).join(',')).join('\n');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reports & Performance')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AppRepository().competitionDays(widget.profile.clubId),
          builder: (context, daySnap) {
            if (!daySnap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = daySnap.data!.docs.where((d) => d.data()['status'] != 'deleted').toList();
            final teams = docs.map((d) => (d.data()['teamName'] ?? '').toString()).where((v) => v.isNotEmpty).toSet().toList()..sort();
            final organisations = docs.map((d) => (d.data()['organisation'] ?? '').toString()).where((v) => v.isNotEmpty).toSet().toList()..sort();
            final dataVersion = docs.map((d) {
              final updated = d.data()['updatedAt'];
              final stamp = updated is Timestamp ? updated.toDate().millisecondsSinceEpoch : 0;
              return '${d.id}:$stamp';
            }).join('|');

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('PERFORMANCE REPORT', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text('Filter the same real competition data for coaching, committee reports, grants or sponsors.', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(width: 180, child: DropdownButtonFormField<String>(value: period, decoration: const InputDecoration(labelText: 'Period'), items: const ['All time','Last 30 days','Last 90 days','This year'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(), onChanged:(v)=>setState(()=>period=v??'All time'))),
                        SizedBox(width: 210, child: DropdownButtonFormField<String>(value: team, decoration: const InputDecoration(labelText:'Team'), items: [const DropdownMenuItem(value:'',child:Text('All teams')),...teams.map((v)=>DropdownMenuItem(value:v,child:Text(v)))], onChanged:(v)=>setState(()=>team=v??''))),
                        SizedBox(width: 160, child: DropdownButtonFormField<String>(value: organisation, decoration: const InputDecoration(labelText:'Organisation'), items: [const DropdownMenuItem(value:'',child:Text('All')),...organisations.map((v)=>DropdownMenuItem(value:v,child:Text(v)))], onChanged:(v)=>setState(()=>organisation=v??''))),
                        SizedBox(width: 160, child: DropdownButtonFormField<String>(value: lane, decoration: const InputDecoration(labelText:'Lane'), items: const [DropdownMenuItem(value:'',child:Text('Both lanes')),DropdownMenuItem(value:'Blue',child:Text('Blue')),DropdownMenuItem(value:'Red',child:Text('Red'))], onChanged:(v)=>setState(()=>lane=v??''))),
                        OutlinedButton.icon(onPressed:()=>_chooseCompetitions(docs), icon:const Icon(Icons.checklist), label:Text(selectedCompetitionIds.isEmpty?'ALL COMPETITIONS':'${selectedCompetitionIds.length} SELECTED')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<PerformanceReport>(
                  future: _currentReport(dataVersion),
                  builder: (context, reportSnap) {
                    if (!reportSnap.hasData) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
                    final r = reportSnap.data!;
                    return _report(context, r);
                  },
                ),
              ],
            );
          },
        ),
      );

  Widget _report(BuildContext context, PerformanceReport r) {
    if (r.competitionCount == 0) {
      return const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No competition data matches these filters.')));
    }
    final faults = r.faultBreakdown.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Kpi('COMPETITIONS', '${r.competitionCount}'),
            _Kpi('RACES W-L-D', '${r.raceWins}-${r.raceLosses}-${r.raceDraws}'),
            _Kpi('WIN RATE', '${r.raceWinPercent.toStringAsFixed(1)}%'),
            _Kpi('LEGS', '${r.legCount}'),
            _Kpi('CLEAN LEGS', '${r.cleanLegPercent.toStringAsFixed(1)}%'),
            _Kpi('FAULTS', '${r.faults}'),
            _Kpi('RERUNS', '${r.reruns}'),
            _Kpi('DOG RUNS', '${r.dogRuns}'),
            _Kpi('FASTEST', r.fastestTeamTime == null ? '—' : '${r.fastestTeamTime!.toStringAsFixed(3)}s'),
            _Kpi('AVERAGE', r.averageTeamTime == null ? '—' : '${r.averageTeamTime!.toStringAsFixed(3)}s'),
            _Kpi('MEDIAN', r.medianTeamTime == null ? '—' : '${r.medianTeamTime!.toStringAsFixed(3)}s'),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () async {
                await pdf.shareSponsorPdf(
                  clubName: widget.profile.clubName,
                  report: r,
                  filterSummary: _filterSummary(),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('SHARE / SAVE PDF'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: _sponsorSummary(r)),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sponsor summary copied.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('COPY SPONSOR SUMMARY'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _csv(r)));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CSV data copied — paste into Excel or Sheets.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('COPY CSV'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text('TEAM TIME TREND', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Card(child:Padding(padding:const EdgeInsets.all(12), child:TrendChart(points:r.trend))),
        const SizedBox(height: 18),
        const Text('LANE COMPARISON', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Row(children:[
          Expanded(child:_LaneCard(kpi:r.lanes['Blue'], lane:'Blue')),
          const SizedBox(width:8),
          Expanded(child:_LaneCard(kpi:r.lanes['Red'], lane:'Red')),
        ]),
        const SizedBox(height: 18),
        const Text('FAULT ANALYSIS', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        if (faults.isEmpty)
          const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('No faults recorded in this selection.')))
        else
          Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
            for (final e in faults.take(12)) ...[
              Row(children:[Expanded(child:Text(e.key)),Text('${e.value}',style:const TextStyle(fontWeight:FontWeight.w900))]),
              const SizedBox(height:4),
              LinearProgressIndicator(value:r.faults==0?0:e.value/r.faults),
              const SizedBox(height:10),
            ],
          ]))),
        const SizedBox(height: 18),
        const Text('DOG PERFORMANCE', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Card(child:SingleChildScrollView(scrollDirection:Axis.horizontal, child:DataTable(
          columns:const [
            DataColumn(label:Text('Dog')),DataColumn(label:Text('Runs')),DataColumn(label:Text('Faults')),DataColumn(label:Text('Fault %')),DataColumn(label:Text('Average')),DataColumn(label:Text('PB')),DataColumn(label:Text('Avg start')),
          ],
          rows:r.dogs.map((d)=>DataRow(cells:[
            DataCell(Text(d.dogName)),DataCell(Text('${d.runs}')),DataCell(Text('${d.faults}')),DataCell(Text('${d.faultRate.toStringAsFixed(1)}%')),DataCell(Text(d.averageTime==null?'—':'${d.averageTime!.toStringAsFixed(3)}s')),DataCell(Text(d.fastestTime==null?'—':'${d.fastestTime!.toStringAsFixed(3)}s')),DataCell(Text(d.averageStart==null?'—':d.averageStart!.toStringAsFixed(3))),
          ])).toList(),
        ))),
        const SizedBox(height: 18),
        const Text('CROSSOVER QUALITY', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Wrap(spacing:8,runSpacing:8,children:r.crossoverBreakdown.entries.map((e)=>Chip(label:Text('${e.key}: ${e.value}'))).toList()),
        const SizedBox(height: 32),
        const Text('Data quality: blank/unrecorded times are excluded from speed averages — they are never treated as zero.', style:TextStyle(color:AppTheme.textMuted,fontSize:12)),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  const _Kpi(this.label,this.value);
  @override
  Widget build(BuildContext context)=>Container(width:128,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppTheme.surface,border:Border.all(color:AppTheme.border),borderRadius:BorderRadius.circular(16)),child:Column(children:[Text(value,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:3),Text(label,textAlign:TextAlign.center,style:const TextStyle(fontSize:9,color:AppTheme.textMuted))]));
}

class _LaneCard extends StatelessWidget {
  final LaneKpi? kpi;
  final String lane;

  const _LaneCard({required this.kpi, required this.lane});

  @override
  Widget build(BuildContext context) {
    final k = kpi;
    final record = k == null ? '0-0-0' : '${k.wins}-${k.losses}-${k.draws}';
    final clean = k == null ? '0.0' : k.cleanPercent.toStringAsFixed(1);
    final average = k?.averageTime == null ? '—' : '${k!.averageTime!.toStringAsFixed(3)}s';
    final fastest = k?.fastestTime == null ? '—' : '${k!.fastestTime!.toStringAsFixed(3)}s';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$lane LANE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: lane == 'Blue' ? AppTheme.blueLane : AppTheme.redLane,
              ),
            ),
            const SizedBox(height: 7),
            Text('Legs ${k?.legs ?? 0}'),
            Text('W-L-D $record'),
            Text('Clean $clean%'),
            Text('Faults ${k?.faults ?? 0}'),
            Text('Average $average'),
            Text('Fastest $fastest'),
          ],
        ),
      ),
    );
  }
}
