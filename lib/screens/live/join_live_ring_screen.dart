import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/live_ring_service.dart';
import '../../theme/app_theme.dart';
import 'live_ring_screen.dart';

class JoinLiveRingScreen extends StatefulWidget {
  final String defaultName;

  const JoinLiveRingScreen({
    super.key,
    this.defaultName = '',
  });

  @override
  State<JoinLiveRingScreen> createState() => _JoinLiveRingScreenState();
}

class _JoinLiveRingScreenState extends State<JoinLiveRingScreen> {
  late final TextEditingController name;
  final code = TextEditingController();
  String role = 'viewer';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() => busy = true);

    try {
      final join = await LiveRingService().joinRoom(
        code: code.text,
        role: role,
        displayName: name.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LiveRingScreen(join: join),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Join Live Ring')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Join the ring',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You do not need a paid/full club account to join '
                      'a live ring as Red, Display or Viewer.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: '6-digit room code',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Device / person name',
                        hintText: 'e.g. Hetty / Main Tablet',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'JOIN AS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RoleCard(
                      selected: role == 'red',
                      icon: Icons.circle,
                      title: 'RED LANE',
                      subtitle: 'Red faults + emergency STOP',
                      color: AppTheme.redLane,
                      onTap: () => setState(() => role = 'red'),
                    ),
                    _RoleCard(
                      selected: role == 'display',
                      icon: Icons.tv,
                      title: 'MAIN DISPLAY',
                      subtitle: 'Read-only lights, timer and sound',
                      color: AppTheme.gold,
                      onTap: () => setState(() => role = 'display'),
                    ),
                    _RoleCard(
                      selected: role == 'viewer',
                      icon: Icons.visibility_outlined,
                      title: 'VIEWER',
                      subtitle: 'Read-only phone / camera view',
                      color: Colors.white70,
                      onTap: () => setState(() => role = 'viewer'),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: busy ? null : _join,
                      icon: const Icon(Icons.login),
                      label: Text(
                        busy ? 'JOINING…' : 'JOIN LIVE RING',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? color : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(subtitle),
          trailing: selected
              ? Icon(Icons.check_circle, color: color)
              : const Icon(Icons.circle_outlined),
        ),
      );
}
