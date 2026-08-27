import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';

class HistoryScreen extends StatelessWidget {
  final AppProfile profile;
  const HistoryScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Competition history')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppRepository().competitionSessions(profile.clubId),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Could not load history:\n${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No competition sessions saved yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final ts = d['updatedAt'];
            String date = 'Just now';
            if (ts is Timestamp) {
              final x = ts.toDate().toLocal();
              date = '${x.day.toString().padLeft(2, '0')}/'
                  '${x.month.toString().padLeft(2, '0')}/${x.year} '
                  '${x.hour.toString().padLeft(2, '0')}:'
                  '${x.minute.toString().padLeft(2, '0')}';
            }
            return Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text('${d['lane'] ?? ''} lane · ${d['legs'] ?? 0} leg(s)'),
                subtitle: Text('$date · ${d['status'] ?? 'active'}'),
              ),
            );
          },
        );
      },
    ),
  );
}
