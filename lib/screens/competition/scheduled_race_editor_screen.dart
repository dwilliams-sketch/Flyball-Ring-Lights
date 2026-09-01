import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/dog_record.dart';
import '../../models/race_control.dart';
import '../../services/app_repository.dart';
import '../../services/race_control_service.dart';

class ScheduledRaceEditorScreen extends StatefulWidget {
  final AppProfile profile;
  final String competitionId;
  final RaceControlSettings settings;
  final String defaultTeamName;
  final ScheduledClubRace? existing;

  const ScheduledRaceEditorScreen({
    super.key,
    required this.profile,
    required this.competitionId,
    required this.settings,
    this.defaultTeamName = '',
    this.existing,
  });

  @override
  State<ScheduledRaceEditorScreen> createState() =>
      _ScheduledRaceEditorScreenState();
}

class _ScheduledRaceEditorScreenState extends State<ScheduledRaceEditorScreen> {
  final form = GlobalKey<FormState>();
  final service = RaceControlService();
  final team = TextEditingController();
  final raceCode = TextEditingController();
  final note = TextEditingController();

  late int ring;
  final selectedDogIds = <String?>[null, null, null, null];
  final handlerRoles = <int, Map<String, String>>{
    0: {},
    1: {},
    2: {},
    3: {},
  };
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    team.text = existing?.teamName ?? widget.defaultTeamName;
    note.text = existing?.note ?? '';
    ring = existing?.ref.ring ?? 1;
    raceCode.text = existing == null
        ? ''
        : existing.ref.displayCode(
            prefixed: widget.settings.prefixedRaceNumbers,
          );
    if (existing != null) {
      for (var i = 0; i < existing.dogs.length && i < 4; i++) {
        selectedDogIds[i] = existing.dogs[i].dogId;
        handlerRoles[i] = {
          for (final h in existing.dogs[i].handlers) h.personId: h.role,
        };
      }
    }
  }

  @override
  void dispose() {
    team.dispose();
    raceCode.dispose();
    note.dispose();
    super.dispose();
  }

  RaceRef? _parsedRace() => RaceRef.parse(
        raceCode.text,
        defaultRing: ring,
        prefixed: widget.settings.prefixedRaceNumbers,
      );

  Future<void> _chooseHandlers(int index, List<CrewPerson> people) async {
    var selected = Map<String, String>.from(handlerRoles[index] ?? const {});
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Handlers / helpers'),
          content: SizedBox(
            width: 520,
            child: people.isEmpty
                ? const Text(
                    'Add people from Race Control → Crew first. You can assign more than one person to each dog.',
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      const Text(
                        'Select everyone needed with this dog. The first/main handler and catchers/helpers all count for clash warnings.',
                      ),
                      const SizedBox(height: 8),
                      for (final person in people)
                        Card(
                          child: Column(
                            children: [
                              CheckboxListTile(
                                value: selected.containsKey(person.id),
                                title: Text(person.name),
                                onChanged: (on) => setLocal(() {
                                  if (on == true) {
                                    selected[person.id] = selected.isEmpty
                                        ? 'Main handler'
                                        : 'Catcher / helper';
                                  } else {
                                    selected.remove(person.id);
                                  }
                                }),
                              ),
                              if (selected.containsKey(person.id))
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: DropdownButtonFormField<String>(
                                    value: selected[person.id],
                                    decoration: const InputDecoration(
                                      labelText: 'Role with this dog',
                                    ),
                                    items: handlerRolesList
                                        .map((v) => DropdownMenuItem(
                                              value: v,
                                              child: Text(v),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setLocal(() {
                                      selected[person.id] = v ?? 'Main handler';
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => handlerRoles[index] = result);
  }

  Future<void> _save(List<DogRecord> dogs, List<CrewPerson> people) async {
    if (!(form.currentState?.validate() ?? false)) return;
    final ref = _parsedRace();
    if (ref == null || ref.ring > widget.settings.ringCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check the ring/race number.')),
      );
      return;
    }

    final chosen = selectedDogIds.whereType<String>().toList();
    if (chosen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one dog to this race.')),
      );
      return;
    }
    if (chosen.toSet().length != chosen.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The same dog cannot be entered twice.')),
      );
      return;
    }

    final peopleById = {for (final p in people) p.id: p};
    final raceDogs = <RaceDogAssignment>[];
    for (var i = 0; i < selectedDogIds.length; i++) {
      final dogId = selectedDogIds[i];
      if (dogId == null) continue;
      final dog = dogs.firstWhere((d) => d.id == dogId);
      final roles = handlerRoles[i] ?? const <String, String>{};
      raceDogs.add(RaceDogAssignment(
        dogId: dog.id,
        dogName: dog.name,
        handlers: roles.entries.map((entry) {
          final person = peopleById[entry.key];
          return HandlerAssignment(
            personId: entry.key,
            personName: person?.name ?? entry.key,
            role: entry.value,
          );
        }).toList(),
      ));
    }

    setState(() => saving = true);
    try {
      await service.saveScheduledRace(
        widget.profile.clubId,
        widget.competitionId,
        raceId: widget.existing?.id ?? '',
        ref: ref,
        teamName: team.text,
        dogs: raceDogs,
        note: note.text,
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? 'Add club race' : 'Edit club race'),
        ),
        body: StreamBuilder<List<DogRecord>>(
          stream: AppRepository().dogs(widget.profile.clubId),
          builder: (context, dogSnap) => StreamBuilder<List<CrewPerson>>(
            stream: service.people(widget.profile.clubId, widget.competitionId),
            builder: (context, peopleSnap) {
              if (!dogSnap.hasData || !peopleSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final dogs = dogSnap.data!;
              final people = peopleSnap.data!;
              final parsed = _parsedRace();

              return Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    TextFormField(
                      controller: team,
                      decoration: const InputDecoration(
                        labelText: 'Team',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter the team name.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: ring,
                            decoration: const InputDecoration(labelText: 'Ring'),
                            items: [
                              for (var i = 1; i <= widget.settings.ringCount; i++)
                                DropdownMenuItem(value: i, child: Text('Ring $i')),
                            ],
                            onChanged: (v) => setState(() => ring = v ?? 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: raceCode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: widget.settings.prefixedRaceNumbers
                                  ? 'Race code'
                                  : 'Race number',
                              hintText: widget.settings.prefixedRaceNumbers
                                  ? 'e.g. 365 = Ring 3 Race 65'
                                  : 'e.g. 65',
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (v) => RaceRef.parse(
                                      v ?? '',
                                      defaultRing: ring,
                                      prefixed: widget.settings.prefixedRaceNumbers,
                                    ) ==
                                    null
                                ? 'Enter a race.'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    if (parsed != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Understood as ${parsed.label}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'DOGS & HANDLERS',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add the dogs expected to run and everyone needed with each dog. A dog can have several people attached to it.',
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < 4; i++) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedDogIds[i] ?? '',
                                decoration: InputDecoration(
                                  labelText: 'Dog ${i + 1}',
                                  prefixIcon: const Icon(Icons.pets),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: '',
                                    child: Text('Not running / leave empty'),
                                  ),
                                  ...dogs.map((d) => DropdownMenuItem<String>(
                                        value: d.id,
                                        child: Text(d.name),
                                      )),
                                ],
                                onChanged: (v) => setState(() {
                                  selectedDogIds[i] = (v == null || v.isEmpty) ? null : v;
                                  if (selectedDogIds[i] == null) handlerRoles[i] = {};
                                }),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: selectedDogIds[i] == null
                                      ? null
                                      : () => _chooseHandlers(i, people),
                                  icon: const Icon(Icons.group_add_outlined),
                                  label: Text(
                                    (handlerRoles[i]?.isEmpty ?? true)
                                        ? 'ADD HANDLERS / HELPERS'
                                        : '${handlerRoles[i]!.length} PERSON(S) ASSIGNED',
                                  ),
                                ),
                              ),
                              if (handlerRoles[i]?.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    handlerRoles[i]!.entries.map((e) {
                                      final person = people
                                          .where((p) => p.id == e.key)
                                          .firstOrNull;
                                      return '${person?.name ?? e.key} — ${e.value}';
                                    }).join('\n'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    TextFormField(
                      controller: note,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Race note (optional)',
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: saving ? null : () => _save(dogs, people),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(saving ? 'SAVING…' : 'SAVE RACE & HANDLERS'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}

const handlerRolesList = <String>[
  'Main handler',
  'Catcher / helper',
  'Second handler',
  'Backup',
  'Other',
];

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
