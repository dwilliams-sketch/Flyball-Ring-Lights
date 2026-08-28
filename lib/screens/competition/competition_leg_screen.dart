import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/competition_entry.dart';
import '../../models/dog_record.dart';
import '../../models/fault_type.dart';
import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';

class CompetitionLegScreen extends StatefulWidget {
  final AppProfile profile;
  final List<DogRecord> dogs;
  final String sessionId;
  final String initialLane;
  final List<String> initialLineupIds;

  const CompetitionLegScreen({
    super.key,
    required this.profile,
    required this.dogs,
    required this.sessionId,
    required this.initialLane,
    required this.initialLineupIds,
  });

  @override
  State<CompetitionLegScreen> createState() => _CompetitionLegScreenState();
}

class _CompetitionLegScreenState extends State<CompetitionLegScreen> {
  final repo = AppRepository();
  final comments = TextEditingController();
  final teamTime = TextEditingController();

  late String lane;
  late List<String> lineup;
  late List<CompetitionEntry> entries;
  int leg = 1;
  bool saving = false;
  String result = 'Not recorded';

  static const crossoverOptions = [
    '',
    'Perfect',
    'Good',
    'Long',
    'Very Long',
    'Bus',
  ];



  @override
  void initState() {
    super.initState();
    lane = widget.initialLane;
    lineup = List<String>.from(widget.initialLineupIds);
    entries = _startingEntries();
  }

  @override
  void dispose() {
    comments.dispose();
    teamTime.dispose();
    super.dispose();
  }

  DogRecord dogById(String id) =>
      widget.dogs.firstWhere((dog) => dog.id == id);

  List<CompetitionEntry> _startingEntries() {
    return List.generate(4, (i) {
      final dog = dogById(lineup[i]);
      return CompetitionEntry(
        id: _id(),
        dogId: dog.id,
        dogName: dog.name,
        runPosition: i + 1,
        isRerun: false,
      );
    });
  }

  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  void _changeStartingDog(int index, String dogId) {
    if (lineup.asMap().entries.any((e) => e.key != index && e.value == dogId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That dog is already in another position.')),
      );
      return;
    }
    final dog = dogById(dogId);
    setState(() {
      lineup[index] = dogId;
      entries[index].dogId = dog.id;
      entries[index].dogName = dog.name;
    });
  }

  Future<void> _toggleFault(CompetitionEntry entry) async {
    if (entry.fault) {
      setState(() => _clearFault(entry));
      return;
    }

    // Light the fault instantly and queue the rerun before asking why.
    setState(() {
      entry.fault = true;
      entries.add(
        CompetitionEntry(
          id: _id(),
          dogId: entry.dogId,
          dogName: entry.dogName,
          runPosition: entries.length + 1,
          isRerun: true,
          sourceEntryId: entry.id,
        ),
      );
    });

    List<FaultType> faultTypes;
    try {
      faultTypes = await repo.loadActiveFaultTypes(widget.profile.clubId);
    } catch (_) {
      faultTypes = const [];
    }

    if (!mounted) return;
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                '${entry.dogName} — what was the fault?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            for (final fault in faultTypes)
              ListTile(
                title: Text(fault.label),
                onTap: () => Navigator.pop(context, fault.id),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Other'),
              subtitle: const Text('Type exactly what happened'),
              onTap: () => Navigator.pop(context, '__other__'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (selectedId == null) {
      setState(() => _clearFault(entry));
      return;
    }

    if (selectedId == '__other__') {
      final other = await _askOtherReason();
      if (!mounted) return;
      if (other == null || other.trim().isEmpty) {
        setState(() => _clearFault(entry));
        return;
      }
      setState(() {
        entry.faultTypeId = 'other';
        entry.faultReason = 'Other';
        entry.faultOtherText = other.trim();
      });
      return;
    }

    final selected = faultTypes.where((f) => f.id == selectedId).firstOrNull;
    if (selected == null) {
      setState(() => _clearFault(entry));
      return;
    }

    setState(() {
      entry.faultTypeId = selected.id;
      entry.faultReason = selected.label;
      entry.faultOtherText = '';
    });
  }

  void _clearFault(CompetitionEntry entry) {
    entry.fault = false;
    entry.faultTypeId = '';
    entry.faultReason = '';
    entry.faultOtherText = '';

    // Remove the newest still-empty rerun that was created from this entry.
    for (var i = entries.length - 1; i >= 4; i--) {
      final r = entries[i];
      if (r.sourceEntryId == entry.id &&
          r.dogTime.trim().isEmpty &&
          !r.fault) {
        entries.removeAt(i);
        break;
      }
    }
  }

  Future<String?> _askOtherReason() async {
    final c = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Other fault'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'What happened?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('SAVE')),
        ],
      ),
    );
    c.dispose();
    return result;
  }

  Future<void> _saveAndNext() async {
    await _saveLeg(startNext: true);
  }

  Future<void> _finish() async {
    final ok = await _saveLeg(startNext: false);
    if (!ok || !mounted) return;
    await repo.finishCompetitionSession(widget.profile.clubId, widget.sessionId);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _saveLeg({required bool startNext}) async {
    setState(() => saving = true);
    try {
      await repo.saveCompetitionLeg(
        clubId: widget.profile.clubId,
        sessionId: widget.sessionId,
        legNumber: leg,
        lane: lane,
        entries: entries,
        comments: comments.text,
        result: result,
        teamTime: teamTime.text,
      );

      if (startNext && mounted) {
        setState(() {
          leg += 1;
          comments.clear();
          teamTime.clear();
          result = 'Not recorded';
          entries = _startingEntries();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leg ${leg - 1} saved. Ready for Leg $leg.')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save leg: $e')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final laneColor = lane == 'Blue' ? AppTheme.blueLane : AppTheme.redLane;

    return Scaffold(
      appBar: AppBar(
        title: Text('Competition · Leg $leg'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '$lane LANE',
                style: TextStyle(color: laneColor, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: ExpansionTile(
                initiallyExpanded: leg == 1,
                title: const Text('LINE-UP THIS LEG',
                  style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(entries.take(4).map((e) => e.dogName).join(' → ')),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    DropdownButtonFormField<String>(
                      value: lineup[i],
                      decoration: InputDecoration(labelText: 'Position ${i + 1}'),
                      items: widget.dogs.map((d) => DropdownMenuItem(
                        value: d.id,
                        child: Text(d.name),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) _changeStartingDog(i, v);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < entries.length; i++)
              _EntryCard(
                key: ValueKey(entries[i].id),
                entry: entries[i],
                isFirstOriginal: i == 0,
                crossoverOptions: crossoverOptions,
                onChanged: () => setState(() {}),
                onFault: () => _toggleFault(entries[i]),
              ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: result,
              decoration: const InputDecoration(
                labelText: 'Leg result',
                prefixIcon: Icon(Icons.emoji_events_outlined),
              ),
              items: const ['Not recorded', 'Win', 'Loss', 'Draw']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => result = v ?? 'Not recorded'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: teamTime,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Official team time (optional)',
                hintText: 'e.g. 19.428',
                suffixText: 's',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: comments,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Leg comments',
                hintText: 'Box turns, passes, handling, anything worth remembering…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : _saveAndNext,
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(saving ? 'SAVING…' : 'SAVE LEG & START NEXT LEG'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: saving ? null : _finish,
              icon: const Icon(Icons.flag),
              label: const Text('SAVE LEG & FINISH RACE'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatefulWidget {
  final CompetitionEntry entry;
  final bool isFirstOriginal;
  final List<String> crossoverOptions;
  final VoidCallback onChanged;
  final VoidCallback onFault;

  const _EntryCard({
    super.key,
    required this.entry,
    required this.isFirstOriginal,
    required this.crossoverOptions,
    required this.onChanged,
    required this.onFault,
  });

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  late final TextEditingController time;
  late final TextEditingController start;
  late final TextEditingController feet;

  @override
  void initState() {
    super.initState();
    time = TextEditingController(text: widget.entry.dogTime);
    start = TextEditingController(text: widget.entry.startTime);
    feet = TextEditingController(text: widget.entry.gapFeet);
  }

  @override
  void dispose() {
    time.dispose();
    start.dispose();
    feet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final faultColor = e.fault ? Colors.redAccent : Colors.white24;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: faultColor, width: e.fault ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text('${e.runPosition}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${e.dogName}${e.isRerun ? ' · RE-RUN' : ''}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: widget.onFault,
                  icon: Icon(e.fault ? Icons.warning_rounded : Icons.lightbulb_outline),
                  label: Text(e.fault ? 'FAULT ON' : 'FAULT'),
                ),
              ],
            ),
            if (e.fault && e.faultReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fault: ${e.faultReason}'
                  '${e.faultOtherText.isEmpty ? '' : ' — ${e.faultOtherText}'}',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: time,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Dog time',
                      hintText: '4.123',
                      suffixText: 's',
                    ),
                    onChanged: (v) {
                      e.dogTime = v;
                      widget.onChanged();
                    },
                  ),
                ),
                if (widget.isFirstOriginal) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: start,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Start time',
                        hintText: '+0.042',
                        suffixText: 's',
                      ),
                      onChanged: (v) {
                        e.startTime = v;
                        widget.onChanged();
                      },
                    ),
                  ),
                ],
              ],
            ),
            if (!widget.isFirstOriginal) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: e.crossover,
                      decoration: const InputDecoration(labelText: 'Crossover'),
                      items: widget.crossoverOptions
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v.isEmpty ? 'Not recorded' : v),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => e.crossover = v ?? '');
                        widget.onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: feet,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Gap',
                        suffixText: 'ft',
                      ),
                      onChanged: (v) {
                        e.gapFeet = v;
                        widget.onChanged();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}


extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
