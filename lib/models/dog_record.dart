class DogRecord {
  final String id;
  final String name;
  final String notes;
  final String startDistance;
  final String releaseCue;

  const DogRecord({
    required this.id,
    required this.name,
    required this.notes,
    required this.startDistance,
    required this.releaseCue,
  });

  factory DogRecord.fromMap(String id, Map<String, dynamic> data) {
    return DogRecord(
      id: id,
      name: (data['name'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      startDistance: (data['startDistance'] ?? '').toString(),
      releaseCue: (data['releaseCue'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'notes': notes.trim(),
    'startDistance': startDistance.trim(),
    'releaseCue': releaseCue.trim(),
  };
}
