import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/team_record.dart';
import '../../services/app_repository.dart';

class EditCompetitionDayScreen extends StatefulWidget {
  final AppProfile profile;
  final String competitionId;
  final Map<String, dynamic> data;

  const EditCompetitionDayScreen({
    super.key,
    required this.profile,
    required this.competitionId,
    required this.data,
  });

  @override
  State<EditCompetitionDayScreen> createState() => _EditCompetitionDayScreenState();
}

class _EditCompetitionDayScreenState extends State<EditCompetitionDayScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController venue;
  late final TextEditingController customTeam;
  late final TextEditingController division;
  late final TextEditingController seedTime;
  late final TextEditingController notes;
  late DateTime date;
  late String organisation;
  String selectedTeamId = '';
  bool custom = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: (widget.data['name'] ?? '').toString());
    venue = TextEditingController(text: (widget.data['venue'] ?? '').toString());
    customTeam = TextEditingController(text: (widget.data['teamName'] ?? '').toString());
    division = TextEditingController(text: (widget.data['division'] ?? '').toString());
    final seed = widget.data['seedTime'];
    seedTime = TextEditingController(text: seed is num ? seed.toString() : '');
    notes = TextEditingController(text: (widget.data['notes'] ?? '').toString());
    final rawDate = widget.data['date'];
    date = rawDate is Timestamp ? rawDate.toDate().toLocal() : DateTime.now();
    organisation = (widget.data['organisation'] ?? 'BFA').toString();
    selectedTeamId = (widget.data['teamId'] ?? '').toString();
    custom = selectedTeamId.isEmpty;
  }

  @override
  void dispose() {
    name.dispose(); venue.dispose(); customTeam.dispose(); division.dispose(); seedTime.dispose(); notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final next = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2040));
    if (next != null) setState(() => date = next);
  }

  Future<void> _save(List<TeamRecord> teams) async {
    if (!(form.currentState?.validate() ?? false)) return;
    final savedTeam = custom ? null : teams.where((t) => t.id == selectedTeamId).firstOrNull;
    final teamName = custom ? customTeam.text.trim() : (savedTeam?.name ?? customTeam.text.trim());
    setState(() => busy = true);
    try {
      await AppRepository().editCompetitionDay(
        clubId: widget.profile.clubId,
        competitionId: widget.competitionId,
        name: name.text,
        venue: venue.text,
        date: date,
        organisation: organisation,
        teamId: custom ? '' : selectedTeamId,
        teamName: teamName,
        division: division.text,
        seedTime: seedTime.text,
        notes: notes.text,
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit Competition')),
        body: StreamBuilder<List<TeamRecord>>(
          stream: AppRepository().teams(widget.profile.clubId),
          builder: (context, snap) {
            final teams = snap.data ?? const <TeamRecord>[];
            return Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Competition name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name.' : null),
                  const SizedBox(height: 10),
                  TextFormField(controller: venue, decoration: const InputDecoration(labelText: 'Venue')),
                  const SizedBox(height: 10),
                  InkWell(onTap: _pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Date'), child: Text('${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}'))),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(value: organisation, decoration: const InputDecoration(labelText: 'Organisation'), items: const ['BFA','UKFL','Other'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(), onChanged:(v)=>setState(()=>organisation=v??'BFA')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: custom ? '__custom__' : (teams.any((t)=>t.id==selectedTeamId) ? selectedTeamId : '__custom__'),
                    decoration: const InputDecoration(labelText: 'Team'),
                    items: [
                      ...teams.map((t)=>DropdownMenuItem(value:t.id, child:Text(t.name))),
                      const DropdownMenuItem(value:'__custom__', child:Text('Custom / one-off team name')),
                    ],
                    onChanged:(v)=>setState(() { custom = v == '__custom__'; if (!custom) selectedTeamId=v??''; }),
                  ),
                  if (custom) ...[
                    const SizedBox(height: 10),
                    TextFormField(controller: customTeam, decoration: const InputDecoration(labelText:'Team name')),
                  ],
                  const SizedBox(height: 10),
                  Row(children:[
                    Expanded(child:TextFormField(controller:division, decoration:const InputDecoration(labelText:'Division'))),
                    const SizedBox(width:8),
                    Expanded(child:TextFormField(controller:seedTime, keyboardType:const TextInputType.numberWithOptions(decimal:true), decoration:const InputDecoration(labelText:'Seed / declared', suffixText:'s'))),
                  ]),
                  const SizedBox(height: 10),
                  TextFormField(controller:notes,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Notes')),
                  const SizedBox(height: 18),
                  FilledButton.icon(onPressed:busy?null:()=>_save(teams), icon:const Icon(Icons.save_outlined), label:Text(busy?'SAVING…':'SAVE CHANGES')),
                ],
              ),
            );
          },
        ),
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
