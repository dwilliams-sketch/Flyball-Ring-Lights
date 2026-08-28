class TeamRecord {
  final String id;
  final String name;
  final String status;

  const TeamRecord({
    required this.id,
    required this.name,
    this.status = 'active',
  });

  bool get isArchived => status == 'archived';

  factory TeamRecord.fromMap(String id, Map<String, dynamic> data) {
    return TeamRecord(
      id: id,
      name: (data['name'] ?? '').toString(),
      status: (data['status'] ?? 'active').toString(),
    );
  }
}
