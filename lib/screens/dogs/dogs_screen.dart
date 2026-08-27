import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/dog_record.dart';
import '../../services/app_repository.dart';
import 'dog_detail_screen.dart';
import 'edit_dog_screen.dart';
import 'retired_dogs_screen.dart';

class DogsScreen extends StatefulWidget {
  final AppProfile profile;

  const DogsScreen({
    super.key,
    required this.profile,
  });

  @override
  State<DogsScreen> createState() => _DogsScreenState();
}

class _DogsScreenState extends State<DogsScreen> {
  final repo = AppRepository();
  bool importing = false;

  Future<void> _importMenai() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Menai Muttineers dogs?'),
        content: const Text(
          'This will add the 16 known Menai dogs and fill/update their '
          'BFA number, breed and jump height. It will not duplicate a dog '
          'if a dog with the same name already exists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('IMPORT'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => importing = true);
    try {
      final created = await repo.importMenaiDogs(widget.profile.clubId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created == 0
                ? 'Menai dog records updated.'
                : '$created Menai dog records added.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Dogs'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'import') _importMenai();
                if (value == 'retired') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RetiredDogsScreen(profile: widget.profile),
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.download_rounded),
                    title: Text('Import Menai dogs'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'retired',
                  child: ListTile(
                    leading: Icon(Icons.archive_outlined),
                    title: Text('Retired dogs'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: importing
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EditDogScreen(profile: widget.profile),
                    ),
                  ),
          icon: const Icon(Icons.add),
          label: const Text('ADD DOG'),
        ),
        body: StreamBuilder<List<DogRecord>>(
          stream: repo.dogs(widget.profile.clubId),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text('Could not load dogs:\n${snap.error}'),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final dogs = snap.data!;

            if (dogs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'No active dogs yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Add a dog manually or import the Menai Muttineers '
                        'dog list from the menu.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: importing ? null : _importMenai,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('IMPORT MENAI DOGS'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: dogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final dog = dogs[i];
                final info = <String>[
                  if (dog.bfaNumber.isNotEmpty) 'BFA ${dog.bfaNumber}',
                  if (dog.ukflNumber.isNotEmpty) 'UKFL ${dog.ukflNumber}',
                  if (dog.breed.isNotEmpty) dog.breed,
                  if (dog.jumpHeight.isNotEmpty)
                    'Jump ${dog.jumpHeight}',
                ];

                return Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(child: Icon(Icons.pets)),
                    title: Text(
                      dog.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: info.isEmpty
                        ? null
                        : Text(info.join(' · ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DogDetailScreen(
                          profile: widget.profile,
                          dog: dog,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
