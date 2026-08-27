import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/dog_record.dart';
import '../../services/app_repository.dart';

class EditDogScreen extends StatefulWidget {
  final AppProfile profile;
  final DogRecord? dog;

  const EditDogScreen({
    super.key,
    required this.profile,
    this.dog,
  });

  @override
  State<EditDogScreen> createState() => _EditDogScreenState();
}

class _EditDogScreenState extends State<EditDogScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController start;
  late final TextEditingController cue;
  late final TextEditingController notes;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.dog?.name ?? '');
    start = TextEditingController(text: widget.dog?.startDistance ?? '');
    cue = TextEditingController(text: widget.dog?.releaseCue ?? '');
    notes = TextEditingController(text: widget.dog?.notes ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    start.dispose();
    cue.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    try {
      await AppRepository().saveDog(
        widget.profile.clubId,
        DogRecord(
          id: widget.dog?.id ?? '',
          name: name.text,
          notes: notes.text,
          startDistance: start.text,
          releaseCue: cue.text,
        ),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.dog == null ? 'Add dog' : 'Edit ${widget.dog!.name}')),
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
                    labelText: 'Dog name',
                    prefixIcon: Icon(Icons.pets),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the dog name.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: start,
                  decoration: const InputDecoration(
                    labelText: 'Usual start distance',
                    hintText: 'e.g. 15 ft',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cue,
                  decoration: const InputDecoration(
                    labelText: 'Usual release cue',
                    hintText: 'e.g. Second light / Jump 3',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Dog notes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : _save,
                    child: Text(busy ? 'SAVING…' : 'SAVE DOG'),
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
