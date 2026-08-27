import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';
import 'competition_day_detail_screen.dart';
import 'create_competition_day_screen.dart';
import 'history_screen.dart';

class CompetitionDaysScreen extends StatelessWidget {
  final AppProfile profile;

  const CompetitionDaysScreen({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Competitions'),
          actions: [
            IconButton(
              tooltip: 'All race history',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(profile: profile),
                ),
              ),
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CreateCompetitionDayScreen(profile: profile),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('NEW COMPETITION'),
        ),
        body: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: AppRepository().competitionDays(profile.clubId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_outlined,
                        size: 54,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No competition days yet.',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a competition such as '
                        '"Pooches at Polo Ground", then keep every race and '
                        'leg from that day together.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateCompetitionDayScreen(
                              profile: profile,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('CREATE COMPETITION'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();

                final rawDate = data['date'];
                DateTime? date;
                if (rawDate is Timestamp) {
                  date = rawDate.toDate().toLocal();
                }

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.emoji_events_outlined),
                    ),
                    title: Text(
                      (data['name'] ?? 'Competition').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (date != null)
                          '${date.day.toString().padLeft(2, '0')}/'
                              '${date.month.toString().padLeft(2, '0')}/'
                              '${date.year}',
                        if ((data['venue'] ?? '')
                            .toString()
                            .isNotEmpty)
                          data['venue'].toString(),
                        if ((data['teamName'] ?? '')
                            .toString()
                            .isNotEmpty)
                          data['teamName'].toString(),
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CompetitionDayDetailScreen(
                          profile: profile,
                          competitionId: doc.id,
                          competitionData: data,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
