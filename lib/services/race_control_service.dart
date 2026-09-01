import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/race_control.dart';

abstract class RaceFeedAdapter {
  String get id;
  String get label;

  Future<Map<int, int>> fetchCurrentRaces(RaceControlSettings settings);
}

class ManualRaceFeedAdapter implements RaceFeedAdapter {
  @override
  String get id => 'manual';

  @override
  String get label => 'Manual';

  @override
  Future<Map<int, int>> fetchCurrentRaces(RaceControlSettings settings) async {
    return const <int, int>{};
  }
}

class FlyballGeekRaceFeedAdapter implements RaceFeedAdapter {
  @override
  String get id => 'flyballGeek';

  @override
  String get label => 'FlyballGeek API';

  @override
  Future<Map<int, int>> fetchCurrentRaces(RaceControlSettings settings) async {
    throw UnsupportedError(
      'FlyballGeek API mapping is ready to plug in, but the endpoint/schema has not been supplied yet.',
    );
  }
}

class RaceControlService {
  final FirebaseFirestore db;

  RaceControlService({FirebaseFirestore? db})
      : db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _day(
    String clubId,
    String competitionId,
  ) =>
      db
          .collection('clubs')
          .doc(clubId)
          .collection('competitionDays')
          .doc(competitionId);

  DocumentReference<Map<String, dynamic>> _settings(
    String clubId,
    String competitionId,
  ) =>
      _day(clubId, competitionId).collection('raceControl').doc('settings');

  CollectionReference<Map<String, dynamic>> _rings(
    String clubId,
    String competitionId,
  ) =>
      _day(clubId, competitionId).collection('raceControlRings');

  CollectionReference<Map<String, dynamic>> _people(
    String clubId,
    String competitionId,
  ) =>
      _day(clubId, competitionId).collection('raceControlPeople');

  CollectionReference<Map<String, dynamic>> _races(
    String clubId,
    String competitionId,
  ) =>
      _day(clubId, competitionId).collection('raceControlRaces');

  CollectionReference<Map<String, dynamic>> _duties(
    String clubId,
    String competitionId,
  ) =>
      _day(clubId, competitionId).collection('raceControlDuties');

  Stream<RaceControlSettings> settings(
    String clubId,
    String competitionId,
  ) =>
      _settings(clubId, competitionId).snapshots().map(
            (snap) => RaceControlSettings.fromMap(snap.data()),
          );

  Future<void> saveSettings(
    String clubId,
    String competitionId,
    RaceControlSettings value,
  ) async {
    await _settings(clubId, competitionId).set({
      ...value.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (var ring = 1; ring <= value.ringCount; ring++) {
      await _rings(clubId, competitionId).doc('$ring').set({
        'ring': ring,
        'currentRace': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Stream<List<RingProgress>> rings(
    String clubId,
    String competitionId,
  ) =>
      _rings(clubId, competitionId).snapshots().map((snap) {
        final values = snap.docs
            .map((d) => RingProgress.fromMap(d.id, d.data()))
            .toList();
        values.sort((a, b) => a.ring.compareTo(b.ring));
        return values;
      });

  Future<void> setCurrentRace(
    String clubId,
    String competitionId,
    int ring,
    int currentRace,
  ) async {
    await _rings(clubId, competitionId).doc('$ring').set({
      'ring': ring,
      'currentRace': currentRace < 0 ? 0 : currentRace,
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'manual',
    }, SetOptions(merge: true));
  }

  Stream<List<CrewPerson>> people(
    String clubId,
    String competitionId,
  ) =>
      _people(clubId, competitionId).snapshots().map((snap) {
        final values = snap.docs
            .map((d) => CrewPerson.fromMap(d.id, d.data()))
            .toList();
        values.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return values;
      });

  Future<String> savePerson(
    String clubId,
    String competitionId, {
    String personId = '',
    required String name,
    String note = '',
  }) async {
    final ref = personId.isEmpty
        ? _people(clubId, competitionId).doc()
        : _people(clubId, competitionId).doc(personId);
    await ref.set({
      'name': name.trim(),
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (personId.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deletePerson(
    String clubId,
    String competitionId,
    String personId,
  ) async {
    final races = await _races(clubId, competitionId).get();
    final duties = await _duties(clubId, competitionId).get();
    final usedInRace = races.docs.any((doc) {
      final race = ScheduledClubRace.fromMap(doc.id, doc.data());
      return race.personIds.contains(personId);
    });
    final usedInDuty = duties.docs.any((doc) {
      final duty = CompetitionDuty.fromMap(doc.id, doc.data());
      return duty.personIds.contains(personId);
    });
    if (usedInRace || usedInDuty) {
      throw StateError('This person is still assigned to a race or duty. Remove those assignments first.');
    }
    await _people(clubId, competitionId).doc(personId).delete();
  }

  Stream<List<ScheduledClubRace>> scheduledRaces(
    String clubId,
    String competitionId,
  ) =>
      _races(clubId, competitionId).snapshots().map((snap) {
        final values = snap.docs
            .map((d) => ScheduledClubRace.fromMap(d.id, d.data()))
            .toList();
        values.sort((a, b) {
          final ring = a.ref.ring.compareTo(b.ref.ring);
          return ring != 0 ? ring : a.ref.race.compareTo(b.ref.race);
        });
        return values;
      });

  Future<String> saveScheduledRace(
    String clubId,
    String competitionId, {
    String raceId = '',
    required RaceRef ref,
    required String teamName,
    required List<RaceDogAssignment> dogs,
    String note = '',
  }) async {
    final target = raceId.isEmpty
        ? _races(clubId, competitionId).doc()
        : _races(clubId, competitionId).doc(raceId);
    await target.set({
      'ring': ref.ring,
      'race': ref.race,
      'teamName': teamName.trim(),
      'dogs': dogs.map((d) => d.toMap()).toList(),
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (raceId.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return target.id;
  }

  Future<void> deleteScheduledRace(
    String clubId,
    String competitionId,
    String raceId,
  ) =>
      _races(clubId, competitionId).doc(raceId).delete();

  Stream<List<CompetitionDuty>> duties(
    String clubId,
    String competitionId,
  ) =>
      _duties(clubId, competitionId).snapshots().map((snap) {
        final values = snap.docs
            .map((d) => CompetitionDuty.fromMap(d.id, d.data()))
            .toList();
        values.sort((a, b) {
          final ring = a.ring.compareTo(b.ring);
          return ring != 0 ? ring : a.startRace.compareTo(b.startRace);
        });
        return values;
      });

  Future<String> saveDuty(
    String clubId,
    String competitionId, {
    String dutyId = '',
    required String group,
    required String role,
    required int ring,
    required int startRace,
    required int endRace,
    required String lane,
    required List<CrewPerson> people,
    String note = '',
  }) async {
    final target = dutyId.isEmpty
        ? _duties(clubId, competitionId).doc()
        : _duties(clubId, competitionId).doc(dutyId);
    await target.set({
      'group': group,
      'role': role.trim(),
      'ring': ring,
      'startRace': startRace,
      'endRace': endRace,
      'lane': lane,
      'personIds': people.map((p) => p.id).toList(),
      'personNames': people.map((p) => p.name).toList(),
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (dutyId.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return target.id;
  }

  Future<void> deleteDuty(
    String clubId,
    String competitionId,
    String dutyId,
  ) =>
      _duties(clubId, competitionId).doc(dutyId).delete();

  String apiStatus(RaceControlSettings settings) {
    if (settings.feedMode != 'flyballGeek') return 'Manual race control active';
    if (settings.apiEndpoint.trim().isEmpty) {
      return 'FlyballGeek selected · waiting for API endpoint/schema';
    }
    return 'FlyballGeek details saved · connector mapping still required';
  }
}
