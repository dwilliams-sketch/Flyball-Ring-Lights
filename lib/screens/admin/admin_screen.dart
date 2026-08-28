import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import 'fault_types_screen.dart';
import 'members_screen.dart';
import 'teams_screen.dart';
import '../competition/deleted_competitions_screen.dart';

class AdminScreen extends StatelessWidget {
  final AppProfile profile;

  const AdminScreen({super.key, required this.profile});

  bool get canAdmin => profile.role == 'owner' || profile.role == 'admin';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Club Admin')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'CONTROL CABIN',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text('Signed in as ${profile.role.toUpperCase()}'),
            const SizedBox(height: 18),
            _AdminTile(
              icon: Icons.people_alt_outlined,
              title: 'Members & roles',
              subtitle: 'Owner, Admin, Trainer and Member access',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MembersScreen(profile: profile)),
              ),
            ),
            _AdminTile(
              icon: Icons.flag_outlined,
              title: 'Teams',
              subtitle: 'Create, rename, archive and restore club teams',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TeamsScreen(profile: profile)),
              ),
            ),
            _AdminTile(
              icon: Icons.warning_amber_rounded,
              title: 'Fault types',
              subtitle: 'Add, rename, order or disable competition faults',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FaultTypesScreen(profile: profile)),
              ),
            ),
            _AdminTile(
              icon: Icons.delete_outline,
              title: 'Deleted competitions',
              subtitle: 'Restore a competition or permanently remove test data',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeletedCompetitionsScreen(profile: profile),
                ),
              ),
            ),
            if (!canAdmin) ...[
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Some controls are read-only for your role. An Owner or Admin can change club-wide settings.',
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
