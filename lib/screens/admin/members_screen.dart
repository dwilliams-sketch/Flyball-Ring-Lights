import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../services/app_repository.dart';

class MembersScreen extends StatelessWidget {
  final AppProfile profile;

  const MembersScreen({super.key, required this.profile});

  bool get owner => profile.role == 'owner';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Members & Roles')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AppRepository().members(profile.clubId),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Owner controls ownership and member roles. Admin manages club settings; Trainer can work with dogs, training and results; Member has normal club use.',
                    ),
                  ),
                ),
                for (final doc in snap.data!.docs)
                  _MemberTile(profile: profile, doc: doc, ownerCanEdit: owner),
              ],
            );
          },
        ),
      );
}

class _MemberTile extends StatelessWidget {
  final AppProfile profile;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool ownerCanEdit;

  const _MemberTile({required this.profile, required this.doc, required this.ownerCanEdit});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final role = (data['role'] ?? 'member').toString();
    final isClubOwner = role == 'owner';
    final removed = role == 'removed' || data['status'] == 'removed';

    return Card(
      child: ListTile(
        leading: Icon(removed ? Icons.person_off_outlined : Icons.person_outline),
        title: Text((data['displayName'] ?? 'Member').toString(),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${(data['email'] ?? '').toString()} · ${role.toUpperCase()}'),
        trailing: ownerCanEdit && !isClubOwner
            ? PopupMenuButton<String>(
                onSelected: (value) async {
                  if (['admin', 'trainer', 'member'].contains(value)) {
                    await AppRepository().updateMemberRole(profile.clubId, doc.id, value);
                  } else if (value == 'remove') {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove club access?'),
                        content: Text('Remove ${(data['displayName'] ?? 'this member')} from the club? Their Firebase account is not deleted.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('REMOVE')),
                        ],
                      ),
                    );
                    if (yes == true) {
                      await AppRepository().removeMemberAccess(profile.clubId, doc.id);
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'admin', child: Text('Make Admin')),
                  const PopupMenuItem(value: 'trainer', child: Text('Make Trainer')),
                  const PopupMenuItem(value: 'member', child: Text('Make Member / restore access')),
                  if (!removed)
                    const PopupMenuItem(value: 'remove', child: Text('Remove club access')),
                ],
              )
            : null,
      ),
    );
  }
}
