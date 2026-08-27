import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';

class ClubScreen extends StatelessWidget {
  final AppProfile profile;
  const ClubScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Club')),
    body: FutureBuilder<Map<String, dynamic>?>(
      future: AppRepository().clubInfo(profile.clubId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final data = snap.data ?? {};
        final code = (data['inviteCode'] ?? '').toString();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(profile.clubName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Your role: ${profile.role}',
              style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text('CREW INVITE CODE',
                      style: TextStyle(fontSize: 12, color: Colors.white54)),
                    const SizedBox(height: 8),
                    SelectableText(code,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: code.isEmpty ? null : () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite code copied.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('COPY CODE'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Members can choose Join Club when creating their account and enter this code.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        );
      },
    ),
  );
}
