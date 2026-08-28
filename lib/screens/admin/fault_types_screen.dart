import 'package:flutter/material.dart';

import '../../models/app_profile.dart';
import '../../models/fault_type.dart';
import '../../services/app_repository.dart';

class FaultTypesScreen extends StatefulWidget {
  final AppProfile profile;

  const FaultTypesScreen({super.key, required this.profile});

  @override
  State<FaultTypesScreen> createState() => _FaultTypesScreenState();
}

class _FaultTypesScreenState extends State<FaultTypesScreen> {
  final repo = AppRepository();

  bool get canEdit => widget.profile.role == 'owner' || widget.profile.role == 'admin';

  @override
  void initState() {
    super.initState();
    repo.ensureDefaultFaultTypes(widget.profile.clubId);
  }

  Future<void> _nameDialog({FaultType? fault}) async {
    final controller = TextEditingController(text: fault?.label ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fault == null ? 'Add fault type' : 'Rename fault type'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Fault label'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    if (fault == null) {
      await repo.addFaultType(widget.profile.clubId, value);
    } else {
      await repo.updateFaultType(widget.profile.clubId, fault.id, label: value);
    }
  }

  Future<void> _move(List<FaultType> values, int index, int direction) async {
    final swap = index + direction;
    if (swap < 0 || swap >= values.length) return;
    final a = values[index];
    final b = values[swap];
    await Future.wait([
      repo.updateFaultType(widget.profile.clubId, a.id, sortOrder: b.sortOrder),
      repo.updateFaultType(widget.profile.clubId, b.id, sortOrder: a.sortOrder),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Fault Types')),
        floatingActionButton: canEdit
            ? FloatingActionButton.extended(
                onPressed: _nameDialog,
                icon: const Icon(Icons.add),
                label: const Text('ADD FAULT'),
              )
            : null,
        body: StreamBuilder<List<FaultType>>(
          stream: repo.faultTypes(widget.profile.clubId, includeInactive: true),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final values = snap.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'OTHER is always available during a race and opens a free-type box. Disabled fault types stay attached to old results so historical reports remain correct.',
                    ),
                  ),
                ),
                for (var i = 0; i < values.length; i++)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(values[i].label, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(values[i].active ? 'ACTIVE' : 'INACTIVE · kept for history'),
                      trailing: canEdit
                          ? Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  tooltip: 'Move up',
                                  onPressed: i == 0 ? null : () => _move(values, i, -1),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: 'Move down',
                                  onPressed: i == values.length - 1 ? null : () => _move(values, i, 1),
                                  icon: const Icon(Icons.arrow_downward),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'rename') await _nameDialog(fault: values[i]);
                                    if (v == 'disable') {
                                      await repo.updateFaultType(widget.profile.clubId, values[i].id, active: false);
                                    }
                                    if (v == 'enable') {
                                      await repo.updateFaultType(widget.profile.clubId, values[i].id, active: true);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                    if (values[i].active)
                                      const PopupMenuItem(value: 'disable', child: Text('Disable')),
                                    if (!values[i].active)
                                      const PopupMenuItem(value: 'enable', child: Text('Restore')),
                                  ],
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_note_rounded),
                    title: const Text('Other', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('ALWAYS AVAILABLE · free-type explanation'),
                  ),
                ),
              ],
            );
          },
        ),
      );
}
