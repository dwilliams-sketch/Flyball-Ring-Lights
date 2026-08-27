class DogRecord {
  final String id;
  final String name;
  final String notes;
  final String startDistance;
  final String releaseCue;
  final String bfaNumber;
  final String ukflNumber;
  final String breed;
  final String jumpHeight;
  final String status;

  const DogRecord({
    required this.id,
    required this.name,
    required this.notes,
    required this.startDistance,
    required this.releaseCue,
    this.bfaNumber = '',
    this.ukflNumber = '',
    this.breed = '',
    this.jumpHeight = '',
    this.status = 'active',
  });

  bool get isRetired => status == 'retired';

  factory DogRecord.fromMap(String id, Map<String, dynamic> data) {
    return DogRecord(
      id: id,
      name: (data['name'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      startDistance: (data['startDistance'] ?? '').toString(),
      releaseCue: (data['releaseCue'] ?? '').toString(),
      bfaNumber: (data['bfaNumber'] ?? '').toString(),
      ukflNumber: (data['ukflNumber'] ?? '').toString(),
      breed: (data['breed'] ?? '').toString(),
      jumpHeight: (data['jumpHeight'] ?? '').toString(),
      status: (data['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'notes': notes.trim(),
        'startDistance': startDistance.trim(),
        'releaseCue': releaseCue.trim(),
        'bfaNumber': bfaNumber.trim(),
        'ukflNumber': ukflNumber.trim(),
        'breed': breed.trim(),
        'jumpHeight': jumpHeight.trim(),
        'status': status,
      };
}
