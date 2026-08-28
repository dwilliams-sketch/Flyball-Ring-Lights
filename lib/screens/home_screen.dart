import 'package:flutter/material.dart';

import '../models/app_profile.dart';
import '../services/app_repository.dart';
import '../theme/app_theme.dart';
import 'club/club_screen.dart';
import 'competition/competition_setup_screen.dart';
import 'competition/competition_days_screen.dart';
import 'competition/history_screen.dart';
import 'dogs/dogs_screen.dart';
import 'ring/ring_screen.dart';
import 'live/live_ring_lobby_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppProfile profile;
  const HomeScreen({super.key, required this.profile});

  Future<void> _signOut(BuildContext context) async {
    await AppRepository().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(profile.clubName),
      actions: [
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'signout') _signOut(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'signout', child: Text('Sign out')),
          ],
        ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Ahoy ${profile.displayName}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'What are we doing today?',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 17),
          ),
          const SizedBox(height: 24),
          _BigAction(
            icon: Icons.wifi_tethering_rounded,
            title: 'START LIVE RING',
            subtitle: 'Blue, Red, Display and Viewers on multiple devices',
            color: AppTheme.gold,
            darkText: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LiveRingLobbyScreen(profile: profile),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RingScreen()),
            ),
            icon: const Icon(Icons.phone_android),
            label: const Text('LOCAL / OFFLINE TRAINING RING'),
          ),
          const SizedBox(height: 12),
          _BigAction(
            icon: Icons.emoji_events_outlined,
            title: 'COMPETITION DAY',
            subtitle: 'Group races and legs into one event',
            color: AppTheme.green,
            darkText: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CompetitionDaysScreen(profile: profile),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CompetitionSetupScreen(profile: profile),
              ),
            ),
            icon: const Icon(Icons.flash_on_outlined),
            label: const Text('QUICK STANDALONE RACE'),
          ),
          const SizedBox(height: 18),
          _Tile(
            icon: Icons.pets,
            title: 'Dogs',
            subtitle: 'Dog records, start marks and recorded times',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DogsScreen(profile: profile)),
            ),
          ),
          _Tile(
            icon: Icons.history,
            title: 'All race history',
            subtitle: 'Every saved race and leg',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryScreen(profile: profile),
              ),
            ),
          ),
          _Tile(
            icon: Icons.groups_outlined,
            title: 'Club',
            subtitle: 'Invite code and workspace details',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ClubScreen(profile: profile)),
            ),
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'REV 0.5.4 LIVE MULTI-DEVICE BETA\n\n'
                'Live Ring is now ready for multi-device beta testing alongside '
                'the existing dogs, competitions and records.',
                style: TextStyle(color: AppTheme.textMuted, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BigAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool darkText;
  final VoidCallback onTap;

  const _BigAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.darkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: darkText ? Colors.black : Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.gold),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
