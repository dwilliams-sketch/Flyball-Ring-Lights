import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/dog_record.dart';
import '../../services/app_repository.dart';
import 'dog_detail_screen.dart';

class RetiredDogsScreen extends StatelessWidget {
  final AppProfile profile;

  const RetiredDogsScreen({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Retired dogs')),
      body: StreamBuilder<List<DogRecord>>(
        stream: repo.dogs(
          profile.clubId,
          retiredOnly: true,
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final dogs = snap.data!;

          if (dogs.isEmpty) {
            return const Center(
              child: Text(
                'No retired dogs.\n\n'
                'Retired dogs keep all of their historical records.',
                textAlign: TextAlign.center,
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
                  leading: const CircleAvatar(
                    child: Icon(Icons.archive_outlined),
                  ),
                  title: Text(dog.name),
                  subtitle: Text(
                    [
                      if (dog.bfaNumber.isNotEmpty)
                        'BFA ${dog.bfaNumber}',
                      if (dog.ukflNumber.isNotEmpty)
                        'UKFL ${dog.ukflNumber}',
                      'Retired',
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DogDetailScreen(
                        profile: profile,
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
}
