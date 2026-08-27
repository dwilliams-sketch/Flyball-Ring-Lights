import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/dog_record.dart';
import '../../services/app_repository.dart';
import 'dog_detail_screen.dart';
import 'edit_dog_screen.dart';

class DogsScreen extends StatelessWidget {
  final AppProfile profile;
  const DogsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Dogs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditDogScreen(profile: profile),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('ADD DOG'),
      ),
      body: StreamBuilder<List<DogRecord>>(
        stream: repo.dogs(profile.clubId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load dogs:\n${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final dogs = snap.data!;
          if (dogs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No dogs yet.\n\nAdd your first dog before using Competition Mode.',
                  textAlign: TextAlign.center,
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
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.pets)),
                  title: Text(dog.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text([
                    if (dog.startDistance.isNotEmpty) 'Start: ${dog.startDistance}',
                    if (dog.releaseCue.isNotEmpty) dog.releaseCue,
                  ].join(' · ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DogDetailScreen(profile: profile, dog: dog),
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
}
