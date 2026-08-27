import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/dog_record.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';
import 'edit_dog_screen.dart';

class DogDetailScreen extends StatelessWidget {
  final AppProfile profile;
  final DogRecord dog;

  const DogDetailScreen({
    super.key,
    required this.profile,
    required this.dog,
  });

  Future<void> _retire(BuildContext context) async {
    final repo = AppRepository();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retire ${dog.name}?'),
        content: const Text(
          'The dog will disappear from active line-ups, but all old '
          'competition records and times will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('RETIRE'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await repo.retireDog(profile.clubId, dog.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _restore(BuildContext context) async {
    await AppRepository().restoreDog(profile.clubId, dog.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${dog.name} permanently?'),
        content: const Text(
          'Use this only for test or accidental dog records. '
          'A dog with competition history cannot be permanently deleted; '
          'retire them instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await AppRepository().deleteDogPermanently(
        profile.clubId,
        dog.id,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text(dog.name),
        actions: [
          IconButton(
            tooltip: 'Edit dog',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditDogScreen(
                  profile: profile,
                  dog: dog,
                ),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'retire') _retire(context);
              if (value == 'restore') _restore(context);
              if (value == 'delete') _delete(context);
            },
            itemBuilder: (_) => [
              if (!dog.isRetired)
                const PopupMenuItem(
                  value: 'retire',
                  child: Text('Retire dog'),
                ),
              if (dog.isRetired)
                const PopupMenuItem(
                  value: 'restore',
                  child: Text('Return to active dogs'),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete test record permanently'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repo.dogRuns(profile.clubId, dog.id),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final runs = snap.data!.docs;
          final times = runs
              .map((d) => d.data()['dogTime'])
              .whereType<num>()
              .map((n) => n.toDouble())
              .toList();
          final starts = runs
              .map((d) => d.data()['startTime'])
              .whereType<num>()
              .map((n) => n.toDouble())
              .toList();

          final faults =
              runs.where((d) => d.data()['fault'] == true).length;
          final clean = runs.length - faults;

          final pb = times.isEmpty
              ? null
              : times.reduce((a, b) => a < b ? a : b);
          final avg = times.isEmpty
              ? null
              : times.reduce((a, b) => a + b) / times.length;
          final bestStart = starts.isEmpty
              ? null
              : starts.reduce(
                  (a, b) => a.abs() < b.abs() ? a : b,
                );

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (dog.isRetired)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.archive_outlined),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'RETIRED · Historical records are still kept.',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DOG DETAILS',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (dog.bfaNumber.isNotEmpty)
                        Text('BFA number: ${dog.bfaNumber}'),
                      if (dog.ukflNumber.isNotEmpty)
                        Text('UKFL number: ${dog.ukflNumber}'),
                      if (dog.breed.isNotEmpty)
                        Text('Breed: ${dog.breed}'),
                      if (dog.jumpHeight.isNotEmpty)
                        Text('Jump height: ${dog.jumpHeight}'),
                      if (dog.startDistance.isNotEmpty)
                        Text('Start mark: ${dog.startDistance}'),
                      if (dog.releaseCue.isNotEmpty)
                        Text('Release cue: ${dog.releaseCue}'),
                      if (dog.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(dog.notes),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Stat(label: 'RUNS', value: '${runs.length}'),
                  _Stat(
                    label: 'PB',
                    value: pb == null
                        ? '—'
                        : '${pb.toStringAsFixed(3)}s',
                  ),
                  _Stat(
                    label: 'AVERAGE',
                    value: avg == null
                        ? '—'
                        : '${avg.toStringAsFixed(3)}s',
                  ),
                  _Stat(
                    label: 'CLEAN',
                    value: runs.isEmpty
                        ? '—'
                        : '${((clean / runs.length) * 100).round()}%',
                  ),
                  _Stat(
                    label: 'BEST START',
                    value: bestStart == null
                        ? '—'
                        : _signed(bestStart),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'RECENT RECORDED RUNS',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (runs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No competition times recorded yet.',
                    ),
                  ),
                ),
              for (final doc in runs)
                _RunTile(data: doc.data()),
            ],
          );
        },
      ),
    );
  }

  static String _signed(double n) =>
      '${n >= 0 ? '+' : ''}${n.toStringAsFixed(3)}';
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
        width: 105,
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
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
}

class _RunTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RunTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final t = data['dogTime'];
    final start = data['startTime'];
    final isRerun = data['isRerun'] == true;
    final fault = data['fault'] == true;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${data['runPosition'] ?? '?'}'),
        ),
        title: Text(
          t is num
              ? '${t.toStringAsFixed(3)}s'
                  '${isRerun ? ' · RERUN' : ''}'
              : 'Time not entered',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            if (start is num)
              'Start ${start >= 0 ? '+' : ''}'
                  '${start.toStringAsFixed(3)}',
            if ((data['crossover'] ?? '')
                .toString()
                .isNotEmpty)
              data['crossover'].toString(),
            if (data['gapFeet'] is num)
              '${data['gapFeet']} ft',
            if (fault)
              'FAULT: ${data['faultReason'] ?? ''}',
          ].join(' · '),
        ),
      ),
    );
  }
}
