class FaultType {
  final String id;
  final String label;
  final bool active;
  final int sortOrder;

  const FaultType({
    required this.id,
    required this.label,
    required this.active,
    required this.sortOrder,
  });

  factory FaultType.fromMap(String id, Map<String, dynamic> data) {
    return FaultType(
      id: id,
      label: (data['label'] ?? '').toString(),
      active: data['active'] != false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 999,
    );
  }
}
