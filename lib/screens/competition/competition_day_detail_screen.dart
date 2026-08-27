import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';
import 'competition_setup_screen.dart';
import 'race_history_detail_screen.dart';

class CompetitionDayDetailScreen extends StatelessWidget {
  final AppProfile profile;
  final String competitionId;
  final Map<String, dynamic> competitionData;

  const CompetitionDayDetailScreen({
    super.key,
    required this.profile,
    required this.competitionId,
    required this.competitionData,
  });

  DateTime? _date() {
    final raw = competitionData['date'];
    if (raw is Timestamp) return raw.toDate().toLocal();
    if (raw is DateTime) return raw;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository();
    final name =
        (competitionData['name'] ?? 'Competition').toString();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: repo.competitionRaces(
          profile.clubId,
          competitionId,
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final races = snap.data!.docs.toList()
            ..sort((a, b) {
              final av = (a.data()['raceNumber'] ?? 0) as num;
              final bv = (b.data()['raceNumber'] ?? 0) as num;
              return av.compareTo(bv);
            });

          final finished = races
              .where((r) => r.data()['status'] == 'finished')
              .toList();

          final raceWins = finished
              .where((r) => r.data()['raceResult'] == 'Win')
              .length;
          final raceLosses = finished
              .where((r) => r.data()['raceResult'] == 'Loss')
              .length;
          final raceDraws = finished
              .where((r) => r.data()['raceResult'] == 'Draw')
              .length;

          final legWins = finished.fold<int>(
            0,
            (sum, r) =>
                sum + ((r.data()['legWins'] ?? 0) as num).toInt(),
          );
          final legLosses = finished.fold<int>(
            0,
            (sum, r) =>
                sum + ((r.data()['legLosses'] ?? 0) as num).toInt(),
          );
          final cleanLegs = finished.fold<int>(
            0,
            (sum, r) =>
                sum + ((r.data()['cleanLegs'] ?? 0) as num).toInt(),
          );
          final faults = finished.fold<int>(
            0,
            (sum, r) =>
                sum + ((r.data()['faults'] ?? 0) as num).toInt(),
          );
          final reruns = finished.fold<int>(
            0,
            (sum, r) =>
                sum + ((r.data()['reruns'] ?? 0) as num).toInt(),
          );

          final times = finished
              .map((r) => r.data()['fastestTeamTime'])
              .whereType<num>()
              .map((n) => n.toDouble())
              .toList();
          final fastest = times.isEmpty
              ? null
              : times.reduce((a, b) => a < b ? a : b);

          final date = _date();
          final nextRace = races.length + 1;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (date != null)
                            '${date.day.toString().padLeft(2, '0')}/'
                                '${date.month.toString().padLeft(2, '0')}/'
                                '${date.year}',
                          if ((competitionData['venue'] ?? '')
                              .toString()
                              .isNotEmpty)
                            competitionData['venue'].toString(),
                          if ((competitionData['organisation'] ?? '')
                              .toString()
                              .isNotEmpty)
                            competitionData['organisation'].toString(),
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if ((competitionData['teamName'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Team: ${competitionData['teamName']}',
                        ),
                      ],
                      if ((competitionData['division'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text(
                          'Division: ${competitionData['division']}',
                        ),
                      if (competitionData['seedTime'] is num)
                        Text(
                          'Seed / declared: '
                          '${(competitionData['seedTime'] as num).toStringAsFixed(3)}s',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Stat(
                    label: 'RACES',
                    value: '${finished.length}',
                  ),
                  _Stat(
                    label: 'W-L-D',
                    value:
                        '$raceWins-$raceLosses-$raceDraws',
                  ),
                  _Stat(
                    label: 'LEGS W-L',
                    value: '$legWins-$legLosses',
                  ),
                  _Stat(
                    label: 'FASTEST',
                    value: fastest == null
                        ? '—'
                        : '${fastest.toStringAsFixed(3)}s',
                  ),
                  _Stat(
                    label: 'CLEAN LEGS',
                    value: '$cleanLegs',
                  ),
                  _Stat(
                    label: 'FAULTS',
                    value: '$faults',
                  ),
                  _Stat(
                    label: 'RERUNS',
                    value: '$reruns',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompetitionSetupScreen(
                        profile: profile,
                        competitionId: competitionId,
                        competitionName: name,
                        raceNumber: nextRace,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    races.isEmpty
                        ? 'START RACE 1'
                        : 'START RACE $nextRace',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'RACES',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (races.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No races recorded yet.',
                    ),
                  ),
                ),
              for (final doc in races)
                _RaceTile(
                  profile: profile,
                  raceId: doc.id,
                  data: doc.data(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RaceTile extends StatelessWidget {
  final AppProfile profile;
  final String raceId;
  final Map<String, dynamic> data;

  const _RaceTile({
    required this.profile,
    required this.raceId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final raceNumber = data['raceNumber'] ?? '?';
    final opponent = (data['opponent'] ?? '').toString();
    final result = (data['raceResult'] ??
            (data['status'] == 'finished'
                ? 'Finished'
                : 'In progress'))
        .toString();

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('$raceNumber')),
        title: Text(
          opponent.isEmpty
              ? 'Race $raceNumber'
              : 'Race $raceNumber · v $opponent',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            result,
            '${data['legs'] ?? 0} leg(s)',
            if (data['fastestTeamTime'] is num)
              'Best ${(data['fastestTeamTime'] as num).toStringAsFixed(3)}s',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RaceHistoryDetailScreen(
              profile: profile,
              sessionId: raceId,
              sessionData: data,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
}
