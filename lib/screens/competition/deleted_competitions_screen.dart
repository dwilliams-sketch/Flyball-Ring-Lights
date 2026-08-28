import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';

class DeletedCompetitionsScreen extends StatelessWidget {
  final AppProfile profile;

  const DeletedCompetitionsScreen({super.key, required this.profile});

  bool get canPermanentlyDelete => profile.role == 'owner' || profile.role == 'admin';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Deleted Competitions')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AppRepository().competitionDays(profile.clubId),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs.where((d) => d.data()['status'] == 'deleted').toList();
            if (docs.isEmpty) {
              return const Center(child: Text('The competition bin is empty.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Restore keeps every race, leg and dog result. Permanent delete removes the competition and its linked race history, so use it for test data only.',
                    ),
                  ),
                ),
                for (final doc in docs)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text((doc.data()['name'] ?? 'Competition').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text((doc.data()['venue'] ?? '').toString()),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'restore') {
                            await AppRepository().restoreCompetitionDay(profile.clubId, doc.id);
                          }
                          if (value == 'delete') {
                            final typed = TextEditingController();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Permanently delete?'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('This permanently removes the competition, linked races, legs and linked dog-run records. Type DELETE to confirm.'),
                                    const SizedBox(height: 12),
                                    TextField(controller: typed, decoration: const InputDecoration(labelText: 'Type DELETE')),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                  FilledButton(onPressed: () => Navigator.pop(context, typed.text.trim().toUpperCase() == 'DELETE'), child: const Text('DELETE FOREVER')),
                                ],
                              ),
                            );
                            typed.dispose();
                            if (confirmed == true) {
                              try {
                                await AppRepository().permanentlyDeleteCompetitionDay(profile.clubId, doc.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Competition permanently deleted.')));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
                                }
                              }
                            }
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'restore', child: Text('Restore')),
                          if (canPermanentlyDelete)
                            const PopupMenuItem(value: 'delete', child: Text('Permanently delete')),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}
