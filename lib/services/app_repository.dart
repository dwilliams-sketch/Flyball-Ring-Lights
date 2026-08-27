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
    User? createdUser;
    DocumentReference<Map<String, dynamic>>? clubRef;

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      createdUser = cred.user;
      final uid = createdUser!.uid;
      await createdUser.updateDisplayName(displayName.trim());

      clubRef = db.collection('clubs').doc();
      final inviteCode = _inviteCode(clubName);

      // Deliberately write these in a safe order rather than one batch.
      // This means later Firestore rules can see the documents that already exist.
      await clubRef.set({
        'name': clubName.trim(),
        'ownerUid': uid,
        'inviteCode': inviteCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await db.collection('users').doc(uid).set({
        'displayName': displayName.trim(),
        'email': email.trim().toLowerCase(),
        'clubId': clubRef.id,
        'clubName': clubName.trim(),
        'role': 'owner',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await db.collection('clubInvites').doc(inviteCode).set({
        'clubId': clubRef.id,
        'clubName': clubName.trim(),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await clubRef.collection('members').doc(uid).set({
        'displayName': displayName.trim(),
        'email': email.trim().toLowerCase(),
        'role': 'owner',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      return AppProfile(
        uid: uid,
        displayName: displayName.trim(),
        email: email.trim().toLowerCase(),
        clubId: clubRef.id,
        clubName: clubName.trim(),
        role: 'owner',
      );
    } catch (e) {
      // Avoid leaving another half-created account during beta setup.
      try {
        if (clubRef != null) await clubRef.delete();
      } catch (_) {}
      try {
        final u = createdUser ?? auth.currentUser;
        if (u != null) await u.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<AppProfile> joinClubAccount({
    required String displayName,
    required String email,
    required String password,
    required String inviteCode,
  }) async {
    User? createdUser;

    try {
      // Create the Firebase identity first so Firestore can securely validate
      // the invite lookup. A bad code is cleaned up immediately.
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      createdUser = cred.user;
      final uid = createdUser!.uid;
      await createdUser.updateDisplayName(displayName.trim());

      final code = inviteCode.trim().toUpperCase();
      final inviteSnap = await db.collection('clubInvites').doc(code).get();
      final inviteData = inviteSnap.data();

      if (inviteData == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'That club invite code was not found.',
        );
      }

      final clubId = (inviteData['clubId'] ?? '').toString();
      final clubName = (inviteData['clubName'] ?? '').toString();

      if (clubId.isEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          message: 'That club invite is incomplete.',
        );
      }

      await db.collection('users').doc(uid).set({
        'displayName': displayName.trim(),
        'email': email.trim().toLowerCase(),
        'clubId': clubId,
        'clubName': clubName,
        'role': 'member',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await db
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .doc(uid)
          .set({
        'displayName': displayName.trim(),
        'email': email.trim().toLowerCase(),
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      return AppProfile(
        uid: uid,
        displayName: displayName.trim(),
        email: email.trim().toLowerCase(),
        clubId: clubId,
        clubName: clubName,
        role: 'member',
      );
    } catch (e) {
      try {
        final u = createdUser ?? auth.currentUser;
        if (u != null) await u.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  Stream<List<DogRecord>> dogs(
    String clubId, {
    bool includeRetired = false,
    bool retiredOnly = false,
  }) {
    return db
        .collection('clubs')
        .doc(clubId)
        .collection('dogs')
        .orderBy('name')
        .snapshots()
        .map((snap) {
          final all = snap.docs
              .map((d) => DogRecord.fromMap(d.id, d.data()))
              .toList();

          if (retiredOnly) {
            return all.where((dog) => dog.isRetired).toList();
          }
          if (includeRetired) return all;
          return all.where((dog) => !dog.isRetired).toList();
        });
  }

  Future<void> saveDog(String clubId, DogRecord dog) async {
    final ref = dog.id.isEmpty
        ? db.collection('clubs').doc(clubId).collection('dogs').doc()
        : db.collection('clubs').doc(clubId).collection('dogs').doc(dog.id);

    await ref.set({
      ...dog.toMap(),
      if (dog.id.isEmpty) 'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
      if (dog.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> retireDog(
    String clubId,
    String dogId, {
    String reason = '',
  }) async {
    await db
        .collection('clubs')
        .doc(clubId)
        .collection('dogs')
        .doc(dogId)
        .set({
      'status': 'retired',
      'retiredReason': reason.trim(),
      'retiredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> restoreDog(String clubId, String dogId) async {
    await db
        .collection('clubs')
        .doc(clubId)
        .collection('dogs')
        .doc(dogId)
        .set({
      'status': 'active',
      'retiredReason': FieldValue.delete(),
      'retiredAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDogPermanently(
    String clubId,
    String dogId,
  ) async {
    final dogRef = db
        .collection('clubs')
        .doc(clubId)
        .collection('dogs')
        .doc(dogId);

    final runs = await dogRef.collection('runs').limit(1).get();
    if (runs.docs.isNotEmpty) {
      throw StateError(
        'This dog has recorded history. Retire the dog instead so its old '
        'competition records are kept.',
      );
    }

    await dogRef.delete();
  }

  Future<int> importMenaiDogs(String clubId) async {
    final dogsRef =
        db.collection('clubs').doc(clubId).collection('dogs');
    final existing = await dogsRef.get();

    final byName = <String, DocumentReference<Map<String, dynamic>>>{};
    for (final doc in existing.docs) {
      final key =
          (doc.data()['name'] ?? '').toString().trim().toLowerCase();
      if (key.isNotEmpty) byName[key] = doc.reference;
    }

    const menaiDogs = <Map<String, String>>[
      {'name': 'Macs', 'bfaNumber': '13654A', 'breed': 'Huntaway', 'jumpHeight': 'FH'},
      {'name': 'Milo', 'bfaNumber': '13649A', 'breed': 'Golden Retriever', 'jumpHeight': 'FH'},
      {'name': 'Arlo', 'bfaNumber': '13650A', 'breed': 'Cross', 'jumpHeight': 'FH'},
      {'name': 'Nellie', 'bfaNumber': '13462A', 'breed': 'Collie', 'jumpHeight': 'FH'},
      {'name': 'Chip', 'bfaNumber': '11689A', 'breed': 'Labrador Retriever', 'jumpHeight': 'FH'},
      {'name': 'Izzie', 'bfaNumber': '11697B', 'breed': 'Cross', 'jumpHeight': 'FH'},
      {'name': 'Coco', 'bfaNumber': '13017A', 'breed': 'Cross', 'jumpHeight': '6'},
      {'name': 'Rizzo', 'bfaNumber': '13196A', 'breed': 'Labrador Retriever', 'jumpHeight': 'FH'},
      {'name': 'Cheddar', 'bfaNumber': '13196B', 'breed': 'Labrador Retriever', 'jumpHeight': 'FH'},
      {'name': 'Olaf', 'bfaNumber': '13192A', 'breed': 'Cross', 'jumpHeight': '6'},
      {'name': 'Snow', 'bfaNumber': '13193A', 'breed': 'Jack Russell Terrier', 'jumpHeight': '6'},
      {'name': 'Maggie', 'bfaNumber': '13286A', 'breed': 'Labrador Retriever', 'jumpHeight': 'FH'},
      {'name': 'Callie', 'bfaNumber': '13286B', 'breed': 'Cocker Spaniel', 'jumpHeight': '6'},
      {'name': 'Skylar', 'bfaNumber': '11917A', 'breed': 'Border Collie/WSD', 'jumpHeight': 'FH'},
      {'name': 'Star', 'bfaNumber': '11697C', 'breed': 'German Shepherd Dog', 'jumpHeight': 'FH'},
      {'name': 'Ember', 'bfaNumber': '11917B', 'breed': 'Border Collie/WSD', 'jumpHeight': 'FH'},
    ];

    final batch = db.batch();
    var created = 0;

    for (final dog in menaiDogs) {
      final key = dog['name']!.toLowerCase();
      final existingRef = byName[key];

      if (existingRef != null) {
        batch.set(existingRef, {
          'bfaNumber': dog['bfaNumber'],
          'breed': dog['breed'],
          'jumpHeight': dog['jumpHeight'],
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        final ref = dogsRef.doc();
        batch.set(ref, {
          ...dog,
          'ukflNumber': '',
          'startDistance': '',
          'releaseCue': '',
          'notes': '',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        created++;
      }
    }

    await batch.commit();
    return created;
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

  Stream<QuerySnapshot<Map<String, dynamic>>> competitionDays(
    String clubId,
  ) {
    return db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionDays')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<String> createCompetitionDay({
    required String clubId,
    required String name,
    required String venue,
    required DateTime date,
    required String organisation,
    required String teamName,
    required String division,
    required String seedTime,
    required String notes,
  }) async {
    final ref = db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionDays')
        .doc();

    await ref.set({
      'name': name.trim(),
      'venue': venue.trim(),
      'date': Timestamp.fromDate(
        DateTime(date.year, date.month, date.day),
      ),
      'organisation': organisation,
      'teamName': teamName.trim(),
      'division': division.trim(),
      'seedTime': _numberOrNull(seedTime),
      'notes': notes.trim(),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> competitionRaces(
    String clubId,
    String competitionId,
  ) {
    return db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionSessions')
        .where('competitionId', isEqualTo: competitionId)
        .snapshots();
  }

  Future<void> finishCompetitionDay(
    String clubId,
    String competitionId, {
    String finalPlacing = '',
    String dayNotes = '',
  }) async {
    await db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionDays')
        .doc(competitionId)
        .set({
      'status': 'finished',
      'finalPlacing': finalPlacing.trim(),
      'dayNotes': dayNotes.trim(),
      'finishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  Stream<QuerySnapshot<Map<String, dynamic>>> competitionLegs(
    String clubId,
    String sessionId,
  ) {
    return db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionSessions')
        .doc(sessionId)
        .collection('legs')
        .orderBy('legNumber')
        .snapshots();
  }

  Future<String> createCompetitionSession({
    required String clubId,
    required String lane,
    String competitionId = '',
    String competitionName = '',
    int raceNumber = 0,
    String opponent = '',
  }) async {
    final ref = db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionSessions')
        .doc();

    await ref.set({
      'lane': lane,
      'competitionId': competitionId,
      'competitionName': competitionName,
      'raceNumber': raceNumber,
      'opponent': opponent.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'legs': 0,
      'status': 'active',
      'raceResult': 'In progress',
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
    final sessionRef = db
        .collection('clubs')
        .doc(clubId)
        .collection('competitionSessions')
        .doc(sessionId);

    final legs = await sessionRef.collection('legs').get();

    var wins = 0;
    var losses = 0;
    var draws = 0;
    var cleanLegs = 0;
    var faults = 0;
    var reruns = 0;
    double? fastestTeamTime;

    for (final leg in legs.docs) {
      final data = leg.data();
      final result = (data['result'] ?? '').toString();

      if (result == 'Win') wins++;
      if (result == 'Loss') losses++;
      if (result == 'Draw') draws++;

      final teamTime = data['teamTime'];
      if (teamTime is num) {
        final value = teamTime.toDouble();
        if (fastestTeamTime == null || value < fastestTeamTime!) {
          fastestTeamTime = value;
        }
      }

      var legFaulted = false;
      final entries = data['entries'];
      if (entries is List) {
        for (final raw in entries) {
          if (raw is! Map) continue;
          if (raw['fault'] == true) {
            faults++;
            legFaulted = true;
          }
          if (raw['isRerun'] == true) reruns++;
        }
      }
      if (!legFaulted) cleanLegs++;
    }

    final raceResult = wins > losses
        ? 'Win'
        : losses > wins
            ? 'Loss'
            : wins == 0 && losses == 0 && draws == 0
                ? 'Not recorded'
                : 'Draw';

    final current = await sessionRef.get();
    final competitionId =
        (current.data()?['competitionId'] ?? '').toString();

    await sessionRef.set({
      'status': 'finished',
      'raceResult': raceResult,
      'legWins': wins,
      'legLosses': losses,
      'legDraws': draws,
      'cleanLegs': cleanLegs,
      'faults': faults,
      'reruns': reruns,
      'fastestTeamTime': fastestTeamTime,
      'finishedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (competitionId.isNotEmpty) {
      await db
          .collection('clubs')
          .doc(clubId)
          .collection('competitionDays')
          .doc(competitionId)
          .set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
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
