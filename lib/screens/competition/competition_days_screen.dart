import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';
import 'competition_day_detail_screen.dart';
import 'create_competition_day_screen.dart';
import 'deleted_competitions_screen.dart';
import 'edit_competition_day_screen.dart';
import 'history_screen.dart';

class CompetitionDaysScreen extends StatelessWidget {
  final AppProfile profile;

  const CompetitionDaysScreen({
    super.key,
    required this.profile,
  });

  bool get canManage => profile.role == 'owner' || profile.role == 'admin';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Competitions'),
          actions: [
            IconButton(
              tooltip: 'Deleted competitions',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeletedCompetitionsScreen(profile: profile),
                ),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
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
              builder: (_) => CreateCompetitionDayScreen(profile: profile),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('NEW COMPETITION'),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AppRepository().competitionDays(profile.clubId),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snap.data!.docs
                .where((d) => d.data()['status'] != 'deleted')
                .toList();

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 54),
                      const SizedBox(height: 12),
                      const Text('No competition days yet.',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a competition, then keep every race and leg from that day together.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateCompetitionDayScreen(profile: profile),
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
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final data = doc.data();
                final rawDate = data['date'];
                final date = rawDate is Timestamp ? rawDate.toDate().toLocal() : null;

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
                    title: Text((data['name'] ?? 'Competition').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Text([
                      if (date != null)
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                      if ((data['venue'] ?? '').toString().isNotEmpty) data['venue'].toString(),
                      if ((data['teamName'] ?? '').toString().isNotEmpty) data['teamName'].toString(),
                    ].join(' · ')),
                    trailing: canManage
                        ? PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'open') {
                                if (!context.mounted) return;
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => CompetitionDayDetailScreen(
                                    profile: profile,
                                    competitionId: doc.id,
                                    competitionData: data,
                                  ),
                                ));
                              }
                              if (v == 'edit') {
                                await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => EditCompetitionDayScreen(
                                    profile: profile,
                                    competitionId: doc.id,
                                    data: data,
                                  ),
                                ));
                              }
                              if (v == 'delete') {
                                final yes = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Move competition to bin?'),
                                    content: const Text('Nothing is permanently erased. You can restore it from Deleted Competitions.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('MOVE TO BIN')),
                                    ],
                                  ),
                                );
                                if (yes == true) {
                                  await AppRepository().moveCompetitionToBin(profile.clubId, doc.id);
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'open', child: Text('Open')),
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Move to bin')),
                            ],
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CompetitionDayDetailScreen(
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
