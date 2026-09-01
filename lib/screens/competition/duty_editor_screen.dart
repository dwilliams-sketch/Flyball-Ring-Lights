import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/race_control.dart';
import '../../services/race_control_service.dart';

class DutyEditorScreen extends StatefulWidget {
  final AppProfile profile;
  final String competitionId;
  final RaceControlSettings settings;
  final CompetitionDuty? existing;

  const DutyEditorScreen({
    super.key,
    required this.profile,
    required this.competitionId,
    required this.settings,
    this.existing,
  });

  @override
  State<DutyEditorScreen> createState() => _DutyEditorScreenState();
}

class _DutyEditorScreenState extends State<DutyEditorScreen> {
  final service = RaceControlService();
  final startRace = TextEditingController();
  final endRace = TextEditingController();
  final customRole = TextEditingController();
  final note = TextEditingController();

  late String group;
  late String role;
  late String lane;
  late int ring;
  final selectedPeople = <String>{};
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    group = e?.group ?? 'team';
    role = e?.role ?? teamDutyRoles.first;
    lane = e?.lane ?? 'N/A';
    ring = e?.ring ?? 1;
    startRace.text = e == null ? '' : '${e.startRace}';
    endRace.text = e == null ? '' : '${e.endRace}';
    note.text = e?.note ?? '';
    selectedPeople.addAll(e?.personIds ?? const []);

    if (!_roleOptions(group).contains(role)) {
      customRole.text = role;
      role = 'Other';
    }
  }

  @override
  void dispose() {
    startRace.dispose();
    endRace.dispose();
    customRole.dispose();
    note.dispose();
    super.dispose();
  }

  List<String> _roleOptions(String value) => switch (value) {
        'ringParty' => ringPartyRoles,
        'official' => officialRoles,
        _ => teamDutyRoles,
      };

  String _groupLabel(String value) => switch (value) {
        'ringParty' => 'Ring Party',
        'official' => 'Judges / Officials',
        _ => 'Team duties',
      };

  Future<void> _save(List<CrewPerson> people) async {
    final start = int.tryParse(startRace.text.trim());
    final end = int.tryParse(endRace.text.trim());
    if (start == null || end == null || start <= 0 || end < start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check the duty race range.')),
      );
      return;
    }
    if (selectedPeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assign at least one person.')),
      );
      return;
    }
    final finalRole = role == 'Other' ? customRole.text.trim() : role;
    if (finalRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the duty name.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await service.saveDuty(
        widget.profile.clubId,
        widget.competitionId,
        dutyId: widget.existing?.id ?? '',
        group: group,
        role: finalRole,
        ring: ring,
        startRace: start,
        endRace: end,
        lane: lane,
        people: people.where((p) => selectedPeople.contains(p.id)).toList(),
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
          title: Text(widget.existing == null ? 'Add competition duty' : 'Edit duty'),
        ),
        body: StreamBuilder<List<CrewPerson>>(
          stream: service.people(widget.profile.clubId, widget.competitionId),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final people = snap.data!;
            final roles = _roleOptions(group);
            if (!roles.contains(role)) role = roles.first;

            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                DropdownButtonFormField<String>(
                  value: group,
                  decoration: const InputDecoration(
                    labelText: 'Duty group',
                    prefixIcon: Icon(Icons.assignment_ind_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'team', child: Text('Team duties')),
                    DropdownMenuItem(value: 'ringParty', child: Text('Ring Party')),
                    DropdownMenuItem(value: 'official', child: Text('Judges / Officials')),
                  ],
                  onChanged: (v) => setState(() {
                    group = v ?? 'team';
                    role = _roleOptions(group).first;
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: InputDecoration(labelText: '${_groupLabel(group)} role'),
                  items: roles
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => role = v ?? roles.first),
                ),
                if (role == 'Other') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: customRole,
                    decoration: const InputDecoration(
                      labelText: 'Custom duty name',
                      hintText: 'e.g. Warm-up steward',
                    ),
                  ),
                ],
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
                      child: DropdownButtonFormField<String>(
                        value: lane,
                        decoration: const InputDecoration(labelText: 'Lane'),
                        items: const ['N/A', 'Blue', 'Red', 'Both']
                            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                            .toList(),
                        onChanged: (v) => setState(() => lane = v ?? 'N/A'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startRace,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'From race'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: endRace,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'To race'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'ASSIGN PEOPLE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                if (people.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Add people from Race Control → Crew first.'),
                    ),
                  ),
                for (final person in people)
                  CheckboxListTile(
                    value: selectedPeople.contains(person.id),
                    title: Text(person.name),
                    subtitle: person.note.isEmpty ? null : Text(person.note),
                    onChanged: (on) => setState(() {
                      if (on == true) {
                        selectedPeople.add(person.id);
                      } else {
                        selectedPeople.remove(person.id);
                      }
                    }),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Duty note (optional)',
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: saving ? null : () => _save(people),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? 'SAVING…' : 'SAVE DUTY'),
                ),
              ],
            );
          },
        ),
      );
}
