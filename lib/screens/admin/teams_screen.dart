import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/team_record.dart';
import '../../services/app_repository.dart';

class TeamsScreen extends StatelessWidget {
  final AppProfile profile;

  const TeamsScreen({super.key, required this.profile});

  bool get canEdit => profile.role == 'owner' || profile.role == 'admin';

  Future<void> _edit(BuildContext context, {TeamRecord? team}) async {
    final controller = TextEditingController(text: team?.name ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(team == null ? 'Add team' : 'Rename team'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Team name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    await AppRepository().saveTeam(
      profile.clubId,
      teamId: team?.id ?? '',
      name: value,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Teams')),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: const Text('ADD TEAM'),
              )
            : null,
        body: StreamBuilder<List<TeamRecord>>(
          stream: AppRepository().teams(profile.clubId, includeArchived: true),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final teams = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (canEdit)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final added = await AppRepository().importMenaiTeams(profile.clubId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$added Menai team(s) added.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.sailing_outlined),
                    label: const Text('IMPORT MENAI TEAMS'),
                  ),
                const SizedBox(height: 8),
                if (teams.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No saved teams yet. Competition days can still use a custom team name.'),
                  )),
                for (final team in teams)
                  Card(
                    child: ListTile(
                      leading: Icon(team.isArchived ? Icons.archive_outlined : Icons.flag_outlined),
                      title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(team.isArchived ? 'ARCHIVED' : 'ACTIVE'),
                      trailing: canEdit
                          ? PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') await _edit(context, team: team);
                                if (value == 'archive') {
                                  await AppRepository().archiveTeam(profile.clubId, team.id);
                                }
                                if (value == 'restore') {
                                  await AppRepository().restoreTeam(profile.clubId, team.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Rename')),
                                if (!team.isArchived)
                                  const PopupMenuItem(value: 'archive', child: Text('Archive')),
                                if (team.isArchived)
                                  const PopupMenuItem(value: 'restore', child: Text('Restore')),
                              ],
                            )
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      );
}
