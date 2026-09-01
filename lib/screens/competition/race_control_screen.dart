import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_profile.dart';
import '../../models/race_control.dart';
import '../../services/race_control_service.dart';
import '../../services/ring_audio_service.dart';
import '../../theme/app_theme.dart';
import 'duty_editor_screen.dart';
import 'scheduled_race_editor_screen.dart';

class RaceControlScreen extends StatefulWidget {
  final AppProfile profile;
  final String competitionId;
  final String competitionName;
  final String defaultTeamName;

  const RaceControlScreen({
    super.key,
    required this.profile,
    required this.competitionId,
    required this.competitionName,
    this.defaultTeamName = '',
  });

  @override
  State<RaceControlScreen> createState() => _RaceControlScreenState();
}

class _RaceControlScreenState extends State<RaceControlScreen>
    with SingleTickerProviderStateMixin {
  final service = RaceControlService();
  final audio = RingAudioService();
  late final TabController tabs;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    audio.dispose();
    super.dispose();
  }

  Future<void> _settingsDialog(RaceControlSettings current) async {
    var ringCount = current.ringCount;
    var prefixed = current.prefixedRaceNumbers;
    var prep = current.prepBufferRaces;
    var cross = current.crossRingBufferRaces;
    var alerts = current.alertsEnabled;
    var haptics = current.hapticsEnabled;
    var sound = current.soundEnabled;
    var feedMode = current.feedMode;
    final endpoint = TextEditingController(text: current.apiEndpoint);
    final apiKey = TextEditingController(text: current.apiKey);
    final tournament = TextEditingController(text: current.tournamentId);
    final poll = TextEditingController(text: '${current.pollSeconds}');

    final result = await showDialog<RaceControlSettings>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Race Control settings'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: ringCount,
                    decoration: const InputDecoration(labelText: 'Number of rings'),
                    items: [
                      for (var i = 1; i <= 9; i++)
                        DropdownMenuItem(value: i, child: Text('$i ring${i == 1 ? '' : 's'}')),
                    ],
                    onChanged: (v) => setLocal(() => ringCount = v ?? 1),
                  ),
                  SwitchListTile(
                    value: prefixed,
                    title: const Text('Ring-prefixed race codes'),
                    subtitle: const Text('Examples: 105 = Ring 1 Race 5 · 365 = Ring 3 Race 65'),
                    onChanged: (v) => setLocal(() => prefixed = v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: prep,
                          decoration: const InputDecoration(labelText: 'Handler prep buffer'),
                          items: [
                            for (var i = 0; i <= 10; i++)
                              DropdownMenuItem(value: i, child: Text('$i races')),
                          ],
                          onChanged: (v) => setLocal(() => prep = v ?? 3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: cross,
                          decoration: const InputDecoration(labelText: 'Cross-ring warning'),
                          items: [
                            for (var i = 0; i <= 10; i++)
                              DropdownMenuItem(value: i, child: Text('$i races')),
                          ],
                          onChanged: (v) => setLocal(() => cross = v ?? 4),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    value: alerts,
                    title: const Text('Race & duty alerts'),
                    onChanged: (v) => setLocal(() => alerts = v),
                  ),
                  SwitchListTile(
                    value: haptics,
                    title: const Text('Vibration / haptics'),
                    onChanged: (v) => setLocal(() => haptics = v),
                  ),
                  SwitchListTile(
                    value: sound,
                    title: const Text('Alert sound'),
                    subtitle: const Text('Uses the existing ring cue sound while Race Control is open.'),
                    onChanged: (v) => setLocal(() => sound = v),
                  ),
                  const Divider(height: 28),
                  DropdownButtonFormField<String>(
                    value: feedMode,
                    decoration: const InputDecoration(labelText: 'Race data source'),
                    items: const [
                      DropdownMenuItem(value: 'manual', child: Text('Manual race control')),
                      DropdownMenuItem(value: 'flyballGeek', child: Text('FlyballGeek API (ready for access details)')),
                    ],
                    onChanged: (v) => setLocal(() => feedMode = v ?? 'manual'),
                  ),
                  if (feedMode == 'flyballGeek') ...[
                    const SizedBox(height: 10),
                    const Text(
                      'These fields are deliberately editable. Once FlyballGeek supplies the endpoint/schema, the connector can be mapped without redesigning Race Control.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: endpoint,
                      decoration: const InputDecoration(labelText: 'API endpoint'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: apiKey,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'API key / token'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tournament,
                      decoration: const InputDecoration(labelText: 'Tournament ID / code'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: poll,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Poll every (seconds)'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                RaceControlSettings(
                  ringCount: ringCount,
                  prefixedRaceNumbers: prefixed,
                  prepBufferRaces: prep,
                  crossRingBufferRaces: cross,
                  alertsEnabled: alerts,
                  hapticsEnabled: haptics,
                  soundEnabled: sound,
                  feedMode: feedMode,
                  apiEndpoint: endpoint.text,
                  apiKey: apiKey.text,
                  tournamentId: tournament.text,
                  pollSeconds: int.tryParse(poll.text) ?? 20,
                ),
              ),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );

    endpoint.dispose();
    apiKey.dispose();
    tournament.dispose();
    poll.dispose();

    if (result != null) {
      await service.saveSettings(
        widget.profile.clubId,
        widget.competitionId,
        result,
      );
    }
  }

  Future<void> _personDialog({CrewPerson? person}) async {
    final name = TextEditingController(text: person?.name ?? '');
    final note = TextEditingController(text: person?.note ?? '');
    final value = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(person == null ? 'Add crew person' : 'Edit person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: note,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. usually handles Chip',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(context, [name.text.trim(), note.text.trim()]),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    name.dispose();
    note.dispose();
    if (value == null || value.first.isEmpty) return;
    await service.savePerson(
      widget.profile.clubId,
      widget.competitionId,
      personId: person?.id ?? '',
      name: value[0],
      note: value[1],
    );
  }

  Future<void> _setRace(
    RaceControlSettings settings,
    int ring,
    int current,
    List<ScheduledClubRace> races,
    List<CompetitionDuty> duties,
  ) async {
    final controller = TextEditingController(text: '$current');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Ring $ring current race'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Race currently racing'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('SET'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await _changeCurrentRace(settings, ring, value, races, duties);
  }

  Future<void> _changeCurrentRace(
    RaceControlSettings settings,
    int ring,
    int value,
    List<ScheduledClubRace> races,
    List<CompetitionDuty> duties,
  ) async {
    await service.setCurrentRace(
      widget.profile.clubId,
      widget.competitionId,
      ring,
      value,
    );
    if (!settings.alertsEnabled || !mounted) return;
    await _pingForRace(settings, ring, value, races, duties);
  }

  Future<void> _pingForRace(
    RaceControlSettings settings,
    int ring,
    int current,
    List<ScheduledClubRace> races,
    List<CompetitionDuty> duties,
  ) async {
    final messages = <String>[];

    for (final race in races.where((r) => r.ref.ring == ring)) {
      final away = race.ref.race - current;
      if ([10, 5, 4, 2, 1, 0].contains(away)) {
        final status = RaceControlLogic.raceStatus(
          RingProgress(ring: ring, currentRace: current),
          race.ref,
        );
        messages.add('${race.teamName}: $status');
      }
    }

    for (final duty in duties.where((d) => d.ring == ring)) {
      final away = duty.startRace - current;
      if ([5, 4, 2, 1, 0].contains(away)) {
        messages.add(
          away == 0
              ? '${duty.role} duty starts NOW'
              : '${duty.role} duty in $away race${away == 1 ? '' : 's'}',
        );
      }
    }

    if (messages.isEmpty) return;
    if (settings.hapticsEnabled) {
      unawaited(HapticFeedback.mediumImpact());
    }
    if (settings.soundEnabled) {
      audio.enabled = true;
      audio.volume = .7;
      unawaited(audio.redCue());
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(messages.join('\n')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<RaceControlSettings>(
        stream: service.settings(widget.profile.clubId, widget.competitionId),
        builder: (context, settingsSnap) {
          final settings = settingsSnap.data ?? const RaceControlSettings();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Race Control'),
              actions: [
                IconButton(
                  tooltip: 'Race Control settings',
                  onPressed: () => _settingsDialog(settings),
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
              bottom: TabBar(
                controller: tabs,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.radar_rounded), text: 'LIVE'),
                  Tab(icon: Icon(Icons.flag_outlined), text: 'RACES'),
                  Tab(icon: Icon(Icons.assignment_ind_outlined), text: 'DUTIES'),
                  Tab(icon: Icon(Icons.groups_outlined), text: 'CREW'),
                ],
              ),
            ),
            body: StreamBuilder<List<RingProgress>>(
              stream: service.rings(widget.profile.clubId, widget.competitionId),
              builder: (context, ringSnap) => StreamBuilder<List<CrewPerson>>(
                stream: service.people(widget.profile.clubId, widget.competitionId),
                builder: (context, peopleSnap) => StreamBuilder<List<ScheduledClubRace>>(
                  stream: service.scheduledRaces(widget.profile.clubId, widget.competitionId),
                  builder: (context, raceSnap) => StreamBuilder<List<CompetitionDuty>>(
                    stream: service.duties(widget.profile.clubId, widget.competitionId),
                    builder: (context, dutySnap) {
                      final rings = ringSnap.data ?? const <RingProgress>[];
                      final people = peopleSnap.data ?? const <CrewPerson>[];
                      final races = raceSnap.data ?? const <ScheduledClubRace>[];
                      final duties = dutySnap.data ?? const <CompetitionDuty>[];

                      return TabBarView(
                        controller: tabs,
                        children: [
                          _liveTab(settings, rings, races, duties),
                          _racesTab(settings, races),
                          _dutiesTab(settings, duties),
                          _crewTab(settings, rings, people, races, duties),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _liveTab(
    RaceControlSettings settings,
    List<RingProgress> rings,
    List<ScheduledClubRace> races,
    List<CompetitionDuty> duties,
  ) {
    final progress = {for (final r in rings) r.ring: r};
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: ListTile(
            leading: Icon(
              settings.feedMode == 'manual' ? Icons.touch_app_outlined : Icons.cloud_sync_outlined,
              color: AppTheme.gold,
            ),
            title: Text(service.apiStatus(settings), style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              settings.feedMode == 'manual'
                  ? 'Use + / − or Set Race. All countdowns and clash checks still work without internet.'
                  : 'API settings are stored, but the FlyballGeek payload mapping will be added when access details arrive.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var ring = 1; ring <= settings.ringCount; ring++)
          _ringCard(
            settings,
            progress[ring] ?? RingProgress(ring: ring, currentRace: 0),
            races,
            duties,
          ),
      ],
    );
  }

  Widget _ringCard(
    RaceControlSettings settings,
    RingProgress progress,
    List<ScheduledClubRace> races,
    List<CompetitionDuty> duties,
  ) {
    final upcomingRaces = races
        .where((r) => r.ref.ring == progress.ring && r.ref.race >= progress.currentRace)
        .toList()
      ..sort((a, b) => a.ref.race.compareTo(b.ref.race));
    final upcomingDuties = duties
        .where((d) => d.ring == progress.ring && d.endRace >= progress.currentRace)
        .toList()
      ..sort((a, b) => a.startRace.compareTo(b.startRace));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'RING ${progress.ring}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  progress.currentRace == 0 ? 'NOT STARTED' : 'RACE ${progress.currentRace}',
                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _changeCurrentRace(
                      settings,
                      progress.ring,
                      (progress.currentRace - 1).clamp(0, 9999).toInt(),
                      races,
                      duties,
                    ),
                    icon: const Icon(Icons.remove),
                    label: const Text('1 RACE'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _setRace(
                      settings,
                      progress.ring,
                      progress.currentRace,
                      races,
                      duties,
                    ),
                    child: Text('SET ${progress.currentRace}'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _changeCurrentRace(
                      settings,
                      progress.ring,
                      progress.currentRace + 1,
                      races,
                      duties,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('1 RACE'),
                  ),
                ),
              ],
            ),
            if (upcomingRaces.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('NEXT CLUB RACES', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              for (final race in upcomingRaces.take(3))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(race.teamName),
                  subtitle: Text(
                    '${race.ref.label} · ${RaceControlLogic.raceStatus(progress, race.ref)}',
                  ),
                ),
            ],
            if (upcomingDuties.isNotEmpty) ...[
              const Divider(height: 20),
              const Text('UPCOMING DUTIES', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              for (final duty in upcomingDuties.take(4))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.assignment_ind_outlined),
                  title: Text('${duty.role}${duty.lane == 'N/A' ? '' : ' · ${duty.lane}'}'),
                  subtitle: Text(
                    duty.containsRace(progress.currentRace)
                        ? 'DUTY NOW · races ${duty.startRace}-${duty.endRace}'
                        : '${(duty.startRace - progress.currentRace).clamp(0, 999)} races away · ${duty.personNames.join(', ')}',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _racesTab(
    RaceControlSettings settings,
    List<ScheduledClubRace> races,
  ) =>
      Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScheduledRaceEditorScreen(
                profile: widget.profile,
                competitionId: widget.competitionId,
                settings: settings,
                defaultTeamName: widget.defaultTeamName,
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('ADD CLUB RACE'),
        ),
        body: races.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No club races added yet.\n\nAdd the races your teams are due to run, then attach one or more handlers/helpers to each dog.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                children: [
                  for (final race in races)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${race.ref.ring}')),
                        title: Text(
                          '${race.teamName} · ${race.ref.label}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          race.dogs.map((dog) {
                            final handlers = dog.handlers.map((h) => h.personName).join(' + ');
                            return handlers.isEmpty ? dog.dogName : '${dog.dogName}: $handlers';
                          }).join('\n'),
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ScheduledRaceEditorScreen(
                                    profile: widget.profile,
                                    competitionId: widget.competitionId,
                                    settings: settings,
                                    defaultTeamName: widget.defaultTeamName,
                                    existing: race,
                                  ),
                                ),
                              );
                            }
                            if (v == 'delete') {
                              await service.deleteScheduledRace(
                                widget.profile.clubId,
                                widget.competitionId,
                                race.id,
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      );

  Widget _dutiesTab(
    RaceControlSettings settings,
    List<CompetitionDuty> duties,
  ) =>
      Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DutyEditorScreen(
                profile: widget.profile,
                competitionId: widget.competitionId,
                settings: settings,
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('ADD DUTY'),
        ),
        body: duties.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No duties added yet.\n\nTeam duties: Box Loader, Ball Collector, Line Watch, Lane Captain, Dog Handler.\n\nRing Party / officials: Lights, Scribe, Box Judge, judges and custom roles.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                children: [
                  for (final duty in duties)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment_ind_outlined),
                        title: Text(
                          '${duty.role}${duty.lane == 'N/A' ? '' : ' · ${duty.lane}'}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          'Ring ${duty.ring} · races ${duty.startRace}-${duty.endRace}\n${duty.personNames.join(', ')}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DutyEditorScreen(
                                    profile: widget.profile,
                                    competitionId: widget.competitionId,
                                    settings: settings,
                                    existing: duty,
                                  ),
                                ),
                              );
                            }
                            if (v == 'delete') {
                              await service.deleteDuty(
                                widget.profile.clubId,
                                widget.competitionId,
                                duty.id,
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      );

  Widget _crewTab(
    RaceControlSettings settings,
    List<RingProgress> rings,
    List<CrewPerson> people,
    List<ScheduledClubRace> races,
    List<CompetitionDuty> duties,
  ) {
    final progress = {for (final r in rings) r.ring: r};
    final clashes = RaceControlLogic.findClashes(
      people: people,
      races: races,
      duties: duties,
      progressByRing: progress,
      prepBuffer: settings.prepBufferRaces,
      crossRingBuffer: settings.crossRingBufferRaces,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _personDialog(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('ADD PERSON'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        children: [
          if (clashes.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle_outline, color: AppTheme.green),
                title: Text('No known clashes', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('Based on the races, handlers, duties and live ring positions entered so far.'),
              ),
            )
          else ...[
            const Text('CLASH WARNINGS', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            for (final clash in clashes)
              Card(
                child: ListTile(
                  leading: Icon(
                    clash.level == ClashLevel.clash
                        ? Icons.error_outline
                        : Icons.warning_amber_rounded,
                    color: clash.level == ClashLevel.clash
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                  ),
                  title: Text('${clash.personName} · ${clash.title}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(clash.detail),
                ),
              ),
            const SizedBox(height: 12),
          ],
          const Text('COMPETITION CREW', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          if (people.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add the people who may handle dogs or take competition duties.'),
              ),
            ),
          for (final person in people)
            _personCard(person, races, duties, progress),
        ],
      ),
    );
  }

  Widget _personCard(
    CrewPerson person,
    List<ScheduledClubRace> races,
    List<CompetitionDuty> duties,
    Map<int, RingProgress> progress,
  ) {
    final raceCommitments = <String>[];
    for (final race in races) {
      for (final dog in race.dogs) {
        for (final handler in dog.handlers.where((h) => h.personId == person.id)) {
          final status = RaceControlLogic.raceStatus(progress[race.ref.ring], race.ref);
          raceCommitments.add('${dog.dogName} · ${race.ref.label} · ${handler.role} · $status');
        }
      }
    }
    final dutyCommitments = duties
        .where((d) => d.personIds.contains(person.id))
        .map((d) => '${d.role} · Ring ${d.ring} · ${d.startRace}-${d.endRace}${d.lane == 'N/A' ? '' : ' · ${d.lane}'}')
        .toList();

    return Card(
      child: ExpansionTile(
        title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          '${raceCommitments.length} dog/race commitment(s) · ${dutyCommitments.length} duty assignment(s)',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') await _personDialog(person: person);
            if (v == 'delete') {
              try {
                await service.deletePerson(
                  widget.profile.clubId,
                  widget.competitionId,
                  person.id,
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
                );
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          if (person.note.isNotEmpty)
            Align(alignment: Alignment.centerLeft, child: Text(person.note)),
          if (raceCommitments.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('DOG / RACE', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            for (final text in raceCommitments)
              Align(alignment: Alignment.centerLeft, child: Text('• $text')),
          ],
          if (dutyCommitments.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('DUTIES', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            for (final text in dutyCommitments)
              Align(alignment: Alignment.centerLeft, child: Text('• $text')),
          ],
        ],
      ),
    );
  }
}
