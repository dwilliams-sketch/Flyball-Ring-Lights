import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';

class RaceHistoryDetailScreen extends StatelessWidget {
  final AppProfile profile;
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const RaceHistoryDetailScreen({
    super.key,
    required this.profile,
    required this.sessionId,
    required this.sessionData,
  });

  @override
  Widget build(BuildContext context) {
    final lane = (sessionData['lane'] ?? '').toString();
    final status = (sessionData['status'] ?? '').toString();
    final laneColor = lane.toLowerCase() == 'blue'
        ? AppTheme.blueLane
        : lane.toLowerCase() == 'red'
            ? AppTheme.redLane
            : AppTheme.gold;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Race history'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AppRepository().competitionLegs(
          profile.clubId,
          sessionId,
        ),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load the saved legs:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final legs = snap.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 34,
                        color: laneColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$lane LANE',
                              style: TextStyle(
                                color: laneColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                '${legs.length} saved leg${legs.length == 1 ? '' : 's'}',
                                if ((sessionData['opponent'] ?? '').toString().isNotEmpty)
                                  'v ${sessionData['opponent']}',
                                if (status.isNotEmpty) status,
                              ].join(' · '),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (legs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('This race has no saved legs yet.'),
                  ),
                ),
              for (final doc in legs)
                _LegCard(data: doc.data()),
            ],
          );
        },
      ),
    );
  }
}

class _LegCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _LegCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final legNumber = data['legNumber'] ?? '?';
    final result = (data['result'] ?? 'Not recorded').toString();
    final comments = (data['comments'] ?? '').toString();
    final teamTime = data['teamTime'];
    final entriesRaw = data['entries'];
    final entries = entriesRaw is List
        ? entriesRaw.whereType<Map>().map((e) {
            return Map<String, dynamic>.from(e);
          }).toList()
        : <Map<String, dynamic>>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          'LEG $legNumber',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          [
            result,
            if (teamTime is num) '${teamTime.toStringAsFixed(3)}s',
          ].join(' · '),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        children: [
          for (final entry in entries)
            _EntryRow(entry: entry),
          if (comments.trim().isNotEmpty) ...[
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'LEG COMMENTS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                comments,
                style: const TextStyle(height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _EntryRow({
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final position = entry['runPosition'] ?? '?';
    final dogName = (entry['dogName'] ?? 'Unknown dog').toString();
    final isRerun = entry['isRerun'] == true;
    final dogTime = entry['dogTime'];
    final startTime = entry['startTime'];
    final crossover = (entry['crossover'] ?? '').toString();
    final gap = entry['gapFeet'];
    final fault = entry['fault'] == true;
    final faultReason = (entry['faultReason'] ?? '').toString();

    final details = <String>[
      if (dogTime is num) 'Dog ${dogTime.toStringAsFixed(3)}s',
      if (startTime is num) 'Start ${_signed(startTime.toDouble())}',
      if (crossover.isNotEmpty) crossover,
      if (gap is num) '${_prettyNumber(gap)} ft',
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: .35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fault
              ? Colors.redAccent.withValues(alpha: .75)
              : Colors.white10,
          width: fault ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            child: Text(
              '$position',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dogName${isRerun ? ' · RE-RUN' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details.join(' · '),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
                if (fault) ...[
                  const SizedBox(height: 4),
                  Text(
                    faultReason.isEmpty
                        ? 'FAULT'
                        : 'FAULT · $faultReason',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _signed(double n) {
    return '${n >= 0 ? '+' : ''}${n.toStringAsFixed(3)}s';
  }

  static String _prettyNumber(num n) {
    final d = n.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(1);
  }
}
