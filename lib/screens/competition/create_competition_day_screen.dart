import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';
import 'competition_day_detail_screen.dart';

class CreateCompetitionDayScreen extends StatefulWidget {
  final AppProfile profile;

  const CreateCompetitionDayScreen({
    super.key,
    required this.profile,
  });

  @override
  State<CreateCompetitionDayScreen> createState() =>
      _CreateCompetitionDayScreenState();
}

class _CreateCompetitionDayScreenState
    extends State<CreateCompetitionDayScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final venue = TextEditingController();
  final teamName = TextEditingController();
  final division = TextEditingController();
  final seedTime = TextEditingController();
  final notes = TextEditingController();

  DateTime date = DateTime.now();
  String organisation = 'BFA';
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    venue.dispose();
    teamName.dispose();
    division.dispose();
    seedTime.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (chosen != null) {
      setState(() => date = chosen);
    }
  }

  Future<void> _create() async {
    if (!(form.currentState?.validate() ?? false)) return;

    setState(() => busy = true);

    try {
      final id = await AppRepository().createCompetitionDay(
        clubId: widget.profile.clubId,
        name: name.text,
        venue: venue.text,
        date: date,
        organisation: organisation,
        teamName: teamName.text,
        division: division.text,
        seedTime: seedTime.text,
        notes: notes.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompetitionDayDetailScreen(
            profile: widget.profile,
            competitionId: id,
            competitionData: {
              'name': name.text.trim(),
              'venue': venue.text.trim(),
              'date': date,
              'organisation': organisation,
              'teamName': teamName.text.trim(),
              'division': division.text.trim(),
              'seedTime': double.tryParse(
                seedTime.text.replaceAll(',', '.'),
              ),
              'notes': notes.text.trim(),
              'status': 'active',
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New competition')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Form(
                key: form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Competition name',
                        hintText: 'e.g. Pooches at Polo Ground',
                        prefixIcon: Icon(Icons.emoji_events_outlined),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter the competition name.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: venue,
                      decoration: const InputDecoration(
                        labelText: 'Venue',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Competition date',
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        child: Text(
                          '${date.day.toString().padLeft(2, '0')}/'
                          '${date.month.toString().padLeft(2, '0')}/'
                          '${date.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: organisation,
                      decoration: const InputDecoration(
                        labelText: 'Organisation',
                      ),
                      items: const ['BFA', 'UKFL', 'Other']
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(v),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => organisation = v ?? 'BFA'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: teamName,
                      decoration: const InputDecoration(
                        labelText: 'Team name',
                        hintText: 'e.g. Menai Muttineers',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: division,
                            decoration: const InputDecoration(
                              labelText: 'Division',
                              hintText: 'Optional',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: seedTime,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Seed / declared time',
                              suffixText: 's',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Day notes',
                        hintText:
                            'Surface, conditions, goals, anything useful…',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy ? null : _create,
                        icon: const Icon(Icons.add),
                        label: Text(
                          busy
                              ? 'CREATING…'
                              : 'CREATE COMPETITION DAY',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
