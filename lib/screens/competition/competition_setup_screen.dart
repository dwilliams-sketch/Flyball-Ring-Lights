import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/dog_record.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';
import 'competition_leg_screen.dart';

class CompetitionSetupScreen extends StatefulWidget {
  final AppProfile profile;
  const CompetitionSetupScreen({super.key, required this.profile});

  @override
  State<CompetitionSetupScreen> createState() => _CompetitionSetupScreenState();
}

class _CompetitionSetupScreenState extends State<CompetitionSetupScreen> {
  String lane = 'Blue';
  final selected = <String?>[null, null, null, null];
  bool starting = false;

  Future<void> _start(List<DogRecord> dogs) async {
    if (selected.any((id) => id == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose all four dogs first.')),
      );
      return;
    }
    if (selected.toSet().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each starting position needs a different dog.')),
      );
      return;
    }
    setState(() => starting = true);
    try {
      final sessionId = await AppRepository().createCompetitionSession(
        clubId: widget.profile.clubId,
        lane: lane,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompetitionLegScreen(
            profile: widget.profile,
            dogs: dogs,
            sessionId: sessionId,
            initialLane: lane,
            initialLineupIds: selected.cast<String>(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Competition Mode')),
    body: StreamBuilder<List<DogRecord>>(
      stream: AppRepository().dogs(widget.profile.clubId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final dogs = snap.data!;
        if (dogs.length < 4) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Competition Mode needs at least 4 dogs in the club.\n\n'
                'You currently have ${dogs.length}. Add dogs from the Dogs page first.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Set up this race',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text(
              'Choose your lane and the four dogs in their starting order.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 22),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Blue', label: Text('BLUE LANE'), icon: Icon(Icons.circle)),
                ButtonSegment(value: 'Red', label: Text('RED LANE'), icon: Icon(Icons.circle)),
              ],
              selected: {lane},
              onSelectionChanged: (v) => setState(() => lane = v.first),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < 4; i++) ...[
              DropdownButtonFormField<String>(
                value: selected[i],
                decoration: InputDecoration(
                  labelText: 'Position ${i + 1}',
                  prefixIcon: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                ),
                items: dogs.map((d) => DropdownMenuItem(
                  value: d.id,
                  child: Text(d.name),
                )).toList(),
                onChanged: (v) => setState(() => selected[i] = v),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: starting ? null : () => _start(dogs),
              icon: const Icon(Icons.emoji_events_outlined),
              label: Text(starting ? 'STARTING…' : 'START COMPETITION'),
            ),
          ],
        );
      },
    ),
  );
}
