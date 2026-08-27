import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/live_ring_service.dart';
import '../../theme/app_theme.dart';
import 'join_live_ring_screen.dart';
import 'live_ring_screen.dart';

class LiveRingLobbyScreen extends StatefulWidget {
  final AppProfile profile;

  const LiveRingLobbyScreen({
    super.key,
    required this.profile,
  });

  @override
  State<LiveRingLobbyScreen> createState() => _LiveRingLobbyScreenState();
}

class _LiveRingLobbyScreenState extends State<LiveRingLobbyScreen> {
  bool creating = false;

  Future<void> _create() async {
    setState(() => creating = true);

    try {
      final join = await LiveRingService().createRoom(
        displayName: widget.profile.displayName,
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
        SnackBar(content: Text(_message(e))),
      );
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  String _message(Object e) =>
      e.toString().replaceFirst('Bad state: ', '');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Live Ring')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.wifi_tethering_rounded,
                      size: 64,
                      color: AppTheme.gold,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'LIVE MULTI-DEVICE RING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create the ring on the Blue/Host device, then let '
                      'Red Lane, the Main Display and viewers join using '
                      'the 6-digit room code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: creating ? null : _create,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(
                        creating ? 'CREATING RING…' : 'CREATE LIVE RING',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: creating
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => JoinLiveRingScreen(
                                    defaultName:
                                        widget.profile.displayName,
                                  ),
                                ),
                              ),
                      icon: const Icon(Icons.login),
                      label: const Text('JOIN AN EXISTING RING'),
                    ),
                    const SizedBox(height: 20),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Blue / Host controls GO, STOP, RESET and Blue '
                          'faults. Red controls Red faults and STOP. Main '
                          'Display and Viewers are read-only.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
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
