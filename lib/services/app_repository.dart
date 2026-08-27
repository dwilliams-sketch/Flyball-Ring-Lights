import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_profile.dart';
import '../models/competition_entry.dart';
import '../models/dog_record.dart';

class AppRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore db;

  AppRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : auth = auth ?? FirebaseAuth.instance,
        db = db ?? FirebaseFirestore.instance;

  User? get currentUser => auth.currentUser;

  Future<AppProfile?> loadProfile() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final snap = await db.collection('users').doc(user.uid).get();
    final data = snap.data();
    if (data == null) return null;
    return AppProfile.fromMap(user.uid, data);
  }

  Future<AppProfile> createClubAccount({
    required String displayName,
    required String email,
    required String password,
    required String clubName,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(displayName.trim());

    final clubRef = db.collection('clubs').doc();
    final inviteCode = _inviteCode(clubName);

    final batch = db.batch();
    batch.set(clubRef, {
      'name': clubName.trim(),
      'ownerUid': uid,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(db.collection('users').doc(uid), {
      'displayName': displayName.trim(),
      'email': email.trim().toLowerCase(),
      'clubId': clubRef.id,
      'clubName': clubName.trim(),
      'role': 'owner',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(clubRef.collection('members').doc(uid), {
      'displayName': displayName.trim(),
      'email': email.trim().toLowerCase(),
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return AppProfile(
      uid: uid,
      displayName: displayName.trim(),
      email: email.trim().toLowerCase(),
      clubId: clubRef.id,
      clubName: clubName.trim(),
      role: 'owner',
    );
  }

  Future<AppProfile> joinClubAccount({
    required String displayName,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    final query = await db
        .collection('clubs')
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'That club invite code was not found.',
      );
    }

    final clubDoc = query.docs.first;
    final clubName = (clubDoc.data()['name'] ?? '').toString();

    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(displayName.trim());

    final batch = db.batch();
    batch.set(db.collection('users').doc(uid), {
      'displayName': displayName.trim(),
      'email': email.trim().toLowerCase(),
      'clubId': clubDoc.id,
      'clubName': clubName,
      'role': 'member',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(clubDoc.reference.collection('members').doc(uid), {
      'displayName': displayName.trim(),
      'email': email.trim().toLowerCase(),
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return AppProfile(
      uid: uid,
      displayName: displayName.trim(),
      email: email.trim().toLowerCase(),
      clubId: clubDoc.id,
      clubName: clubName,
      role: 'member',
    );
  }

  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => auth.signOut();

  Stream<List<DogRecord>> dogs(String clubId) {
    return db
        .collection('clubs')
        .doc(clubId)
        .collection('dogs')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DogRecord.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> saveDog(String clubId, DogRecord dog) async {
    final ref = dog.id.isEmpty
        ? db.collection('clubs').doc(clubId).collection('dogs').doc()
        : db.collection('clubs').doc(clubId).collection('dogs').doc(dog.id);

    await ref.set({
      ...dog.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (dog.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDog(String clubId, String dogId) async {
    await db.collection('clubs').doc(clubId).collection('dogs').doc(dogId).delete();
  }

  Future<Map<String, dynamic>?> clubInfo(String clubId) async {
    final snap = await db.collection('clubs').doc(clubId).get();
    return snap.data();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> dogRuns(
    String clubId,
    String dogId,
  ) {
    return db
        .collection('clubs')
        .doc(clubId)
        .collection('dogs')
        .doc(dogId)
        .collection('runs')
        .orderBy('recordedAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> competitionSessions(
    String clubId,
  ) {
    return db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionSessions')
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<String> createCompetitionSession({
    required String clubId,
    required String lane,
  }) async {
    final ref = db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionSessions')
        .doc();

    await ref.set({
      'lane': lane,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'legs': 0,
      'status': 'active',
    });
    return ref.id;
  }

  Future<void> saveCompetitionLeg({
    required String clubId,
    required String sessionId,
    required int legNumber,
    required String lane,
    required List<CompetitionEntry> entries,
    required String comments,
    required String result,
    required String teamTime,
  }) async {
    final sessionRef = db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionSessions')
        .doc(sessionId);
    final legRef = sessionRef.collection('legs').doc('leg_$legNumber');

    final entryMaps = entries.map((e) => {
      'runPosition': e.runPosition,
      'dogId': e.dogId,
      'dogName': e.dogName,
      'isRerun': e.isRerun,
      'dogTime': _numberOrNull(e.dogTime),
      'startTime': _numberOrNull(e.startTime),
      'crossover': e.crossover,
      'gapFeet': _numberOrNull(e.gapFeet),
      'fault': e.fault,
      'faultReason': e.faultReason,
    }).toList();

    final batch = db.batch();
    batch.set(legRef, {
      'legNumber': legNumber,
      'lane': lane,
      'entries': entryMaps,
      'comments': comments.trim(),
      'result': result,
      'teamTime': _numberOrNull(teamTime),
      'recordedAt': FieldValue.serverTimestamp(),
    });

    batch.set(sessionRef, {
      'lane': lane,
      'legs': legNumber,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));

    for (final e in entries) {
      if (e.dogId.isEmpty) continue;
      final runRef = db
          .collection('clubs')
          .doc(clubId)
          .collection('dogs')
          .doc(e.dogId)
          .collection('runs')
          .doc();

      batch.set(runRef, {
        'sessionId': sessionId,
        'legNumber': legNumber,
        'runPosition': e.runPosition,
        'isRerun': e.isRerun,
        'dogTime': _numberOrNull(e.dogTime),
        'startTime': _numberOrNull(e.startTime),
        'crossover': e.crossover,
        'gapFeet': _numberOrNull(e.gapFeet),
        'fault': e.fault,
        'faultReason': e.faultReason,
        'lane': lane,
        'recordedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> finishCompetitionSession(
    String clubId,
    String sessionId,
  ) async {
    await db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionSessions')
        .doc(sessionId)
        .set({
      'status': 'finished',
      'finishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static double? _numberOrNull(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  static String _inviteCode(String clubName) {
    final letters = clubName
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '')
        .padRight(4, 'X')
        .substring(0, 4);
    final n = 1000 + Random.secure().nextInt(9000);
    return '$letters-$n';
  }
}
