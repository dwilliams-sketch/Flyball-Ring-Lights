class AppProfile {
  final String uid;
  final String displayName;
  final String email;
  final String clubId;
  final String clubName;
  final String role;

  const AppProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.clubId,
    required this.clubName,
    required this.role,
  });

  factory AppProfile.fromMap(String uid, Map<String, dynamic> data) {
    return AppProfile(
      uid: uid,
      displayName: (data['displayName'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      clubId: (data['clubId'] ?? '').toString(),
      clubName: (data['clubName'] ?? '').toString(),
      role: (data['role'] ?? 'member').toString(),
    );
  }
}
