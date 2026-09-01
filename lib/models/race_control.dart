import 'package:cloud_firestore/cloud_firestore.dart';

class RaceRef {
  final int ring;
  final int race;

  const RaceRef({required this.ring, required this.race});

  String displayCode({bool prefixed = true}) {
    if (!prefixed || ring <= 0) return race.toString();
    return '$ring${race.toString().padLeft(2, '0')}';
  }

  String get label => 'Ring $ring · Race $race';

  static RaceRef? parse(
    String raw, {
    int defaultRing = 1,
    bool prefixed = true,
  }) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    if (prefixed && digits.length >= 3) {
      final ring = int.tryParse(digits.substring(0, 1));
      final race = int.tryParse(digits.substring(1));
      if (ring != null && ring > 0 && race != null && race > 0) {
        return RaceRef(ring: ring, race: race);
      }
    }

    final race = int.tryParse(digits);
    if (race == null || race <= 0) return null;
    return RaceRef(ring: defaultRing, race: race);
  }

  Map<String, dynamic> toMap() => {
        'ring': ring,
        'race': race,
      };

  factory RaceRef.fromMap(Map<String, dynamic> data) => RaceRef(
        ring: (data['ring'] as num?)?.toInt() ?? 1,
        race: (data['race'] as num?)?.toInt() ?? 0,
      );
}

class RaceControlSettings {
  final int ringCount;
  final bool prefixedRaceNumbers;
  final int prepBufferRaces;
  final int crossRingBufferRaces;
  final bool alertsEnabled;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final String feedMode;
  final String apiEndpoint;
  final String apiKey;
  final String tournamentId;
  final int pollSeconds;

  const RaceControlSettings({
    this.ringCount = 1,
    this.prefixedRaceNumbers = false,
    this.prepBufferRaces = 3,
    this.crossRingBufferRaces = 4,
    this.alertsEnabled = true,
    this.hapticsEnabled = true,
    this.soundEnabled = false,
    this.feedMode = 'manual',
    this.apiEndpoint = '',
    this.apiKey = '',
    this.tournamentId = '',
    this.pollSeconds = 20,
  });

  factory RaceControlSettings.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    return RaceControlSettings(
      ringCount: ((d['ringCount'] as num?)?.toInt() ?? 1).clamp(1, 9).toInt(),
      prefixedRaceNumbers: d['prefixedRaceNumbers'] == true,
      prepBufferRaces:
          ((d['prepBufferRaces'] as num?)?.toInt() ?? 3).clamp(0, 20).toInt(),
      crossRingBufferRaces:
          ((d['crossRingBufferRaces'] as num?)?.toInt() ?? 4).clamp(0, 20).toInt(),
      alertsEnabled: d['alertsEnabled'] != false,
      hapticsEnabled: d['hapticsEnabled'] != false,
      soundEnabled: d['soundEnabled'] == true,
      feedMode: (d['feedMode'] ?? 'manual').toString(),
      apiEndpoint: (d['apiEndpoint'] ?? '').toString(),
      apiKey: (d['apiKey'] ?? '').toString(),
      tournamentId: (d['tournamentId'] ?? '').toString(),
      pollSeconds: ((d['pollSeconds'] as num?)?.toInt() ?? 20).clamp(5, 300).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ringCount': ringCount,
        'prefixedRaceNumbers': prefixedRaceNumbers,
        'prepBufferRaces': prepBufferRaces,
        'crossRingBufferRaces': crossRingBufferRaces,
        'alertsEnabled': alertsEnabled,
        'hapticsEnabled': hapticsEnabled,
        'soundEnabled': soundEnabled,
        'feedMode': feedMode,
        'apiEndpoint': apiEndpoint.trim(),
        'apiKey': apiKey.trim(),
        'tournamentId': tournamentId.trim(),
        'pollSeconds': pollSeconds,
      };
}

class RingProgress {
  final int ring;
  final int currentRace;
  final DateTime? updatedAt;

  const RingProgress({
    required this.ring,
    required this.currentRace,
    this.updatedAt,
  });

  factory RingProgress.fromMap(String id, Map<String, dynamic> data) {
    final raw = data['updatedAt'];
    return RingProgress(
      ring: (data['ring'] as num?)?.toInt() ?? int.tryParse(id) ?? 1,
      currentRace: (data['currentRace'] as num?)?.toInt() ?? 0,
      updatedAt: raw is Timestamp ? raw.toDate().toLocal() : null,
    );
  }
}

class CrewPerson {
  final String id;
  final String name;
  final String note;

  const CrewPerson({
    required this.id,
    required this.name,
    this.note = '',
  });

  factory CrewPerson.fromMap(String id, Map<String, dynamic> data) => CrewPerson(
        id: id,
        name: (data['name'] ?? '').toString(),
        note: (data['note'] ?? '').toString(),
      );
}

class HandlerAssignment {
  final String personId;
  final String personName;
  final String role;

  const HandlerAssignment({
    required this.personId,
    required this.personName,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'personId': personId,
        'personName': personName,
        'role': role,
      };

  factory HandlerAssignment.fromMap(Map<String, dynamic> data) =>
      HandlerAssignment(
        personId: (data['personId'] ?? '').toString(),
        personName: (data['personName'] ?? '').toString(),
        role: (data['role'] ?? 'Main handler').toString(),
      );
}

class RaceDogAssignment {
  final String dogId;
  final String dogName;
  final List<HandlerAssignment> handlers;

  const RaceDogAssignment({
    required this.dogId,
    required this.dogName,
    required this.handlers,
  });

  Map<String, dynamic> toMap() => {
        'dogId': dogId,
        'dogName': dogName,
        'handlers': handlers.map((h) => h.toMap()).toList(),
      };

  factory RaceDogAssignment.fromMap(Map<String, dynamic> data) {
    final raw = data['handlers'];
    return RaceDogAssignment(
      dogId: (data['dogId'] ?? '').toString(),
      dogName: (data['dogName'] ?? '').toString(),
      handlers: raw is List
          ? raw
              .whereType<Map>()
              .map((m) => HandlerAssignment.fromMap(
                    Map<String, dynamic>.from(m),
                  ))
              .toList()
          : const [],
    );
  }
}

class ScheduledClubRace {
  final String id;
  final RaceRef ref;
  final String teamName;
  final List<RaceDogAssignment> dogs;
  final String note;

  const ScheduledClubRace({
    required this.id,
    required this.ref,
    required this.teamName,
    required this.dogs,
    this.note = '',
  });

  factory ScheduledClubRace.fromMap(String id, Map<String, dynamic> data) {
    final rawDogs = data['dogs'];
    return ScheduledClubRace(
      id: id,
      ref: RaceRef(
        ring: (data['ring'] as num?)?.toInt() ?? 1,
        race: (data['race'] as num?)?.toInt() ?? 0,
      ),
      teamName: (data['teamName'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      dogs: rawDogs is List
          ? rawDogs
              .whereType<Map>()
              .map((m) => RaceDogAssignment.fromMap(
                    Map<String, dynamic>.from(m),
                  ))
              .toList()
          : const [],
    );
  }

  Set<String> get personIds => dogs
      .expand((d) => d.handlers)
      .map((h) => h.personId)
      .where((id) => id.isNotEmpty)
      .toSet();
}

class CompetitionDuty {
  final String id;
  final String group;
  final String role;
  final int ring;
  final int startRace;
  final int endRace;
  final String lane;
  final List<String> personIds;
  final List<String> personNames;
  final String note;

  const CompetitionDuty({
    required this.id,
    required this.group,
    required this.role,
    required this.ring,
    required this.startRace,
    required this.endRace,
    required this.lane,
    required this.personIds,
    required this.personNames,
    this.note = '',
  });

  factory CompetitionDuty.fromMap(String id, Map<String, dynamic> data) =>
      CompetitionDuty(
        id: id,
        group: (data['group'] ?? 'team').toString(),
        role: (data['role'] ?? 'Other').toString(),
        ring: (data['ring'] as num?)?.toInt() ?? 1,
        startRace: (data['startRace'] as num?)?.toInt() ?? 0,
        endRace: (data['endRace'] as num?)?.toInt() ?? 0,
        lane: (data['lane'] ?? 'N/A').toString(),
        personIds: (data['personIds'] is List)
            ? List<String>.from(data['personIds'])
            : const [],
        personNames: (data['personNames'] is List)
            ? List<String>.from(data['personNames'])
            : const [],
        note: (data['note'] ?? '').toString(),
      );

  bool containsRace(int race) => race >= startRace && race <= endRace;
}

enum ClashLevel { clear, tight, clash, crossRing }

class CrewClash {
  final ClashLevel level;
  final String personId;
  final String personName;
  final String title;
  final String detail;

  const CrewClash({
    required this.level,
    required this.personId,
    required this.personName,
    required this.title,
    required this.detail,
  });
}

class RaceControlLogic {
  static int racesAway(RingProgress? progress, RaceRef target) {
    if (progress == null || progress.ring != target.ring) return 999999;
    return target.race - progress.currentRace;
  }

  static String raceStatus(RingProgress? progress, RaceRef target) {
    final away = racesAway(progress, target);
    if (away == 999999) return 'Waiting for ring update';
    if (away < 0) return 'Race passed';
    if (away == 0) return 'RACING NOW';
    if (away == 1) return 'ON DECK';
    if (away == 2) return 'IN THE HOLE';
    return '$away races away';
  }

  static List<CrewClash> findClashes({
    required List<CrewPerson> people,
    required List<ScheduledClubRace> races,
    required List<CompetitionDuty> duties,
    required Map<int, RingProgress> progressByRing,
    required int prepBuffer,
    required int crossRingBuffer,
  }) {
    final byId = {for (final p in people) p.id: p};
    final out = <CrewClash>[];

    String nameOf(String id, String fallback) => byId[id]?.name ?? fallback;

    for (final race in races) {
      for (final dog in race.dogs) {
        for (final handler in dog.handlers) {
          for (final duty in duties.where(
            (d) => d.personIds.contains(handler.personId),
          )) {
            final personName = nameOf(handler.personId, handler.personName);

            if (duty.ring == race.ref.ring) {
              if (duty.containsRace(race.ref.race)) {
                out.add(CrewClash(
                  level: ClashLevel.clash,
                  personId: handler.personId,
                  personName: personName,
                  title: 'Direct duty clash',
                  detail:
                      '$personName is needed with ${dog.dogName} in Ring ${race.ref.ring}, Race ${race.ref.race}, but is also ${duty.role} for races ${duty.startRace}-${duty.endRace}.',
                ));
                continue;
              }

              final dutyEndsBefore = duty.endRace < race.ref.race;
              final gap = dutyEndsBefore
                  ? race.ref.race - duty.endRace
                  : duty.startRace - race.ref.race;
              if (gap >= 0 && gap <= prepBuffer) {
                out.add(CrewClash(
                  level: ClashLevel.tight,
                  personId: handler.personId,
                  personName: personName,
                  title: 'Tight turnaround',
                  detail:
                      '$personName is needed with ${dog.dogName} in Race ${race.ref.race}. ${duty.role} is only $gap race${gap == 1 ? '' : 's'} away from that commitment.',
                ));
              }
              continue;
            }

            final raceProgress = progressByRing[race.ref.ring];
            final dutyProgress = progressByRing[duty.ring];
            if (raceProgress == null || dutyProgress == null) continue;

            final raceAway = race.ref.race - raceProgress.currentRace;
            final dutyStartsAway = duty.startRace - dutyProgress.currentRace;
            final dutyEndsAway = duty.endRace - dutyProgress.currentRace;
            final dutyActiveOrSoon = dutyEndsAway >= 0 &&
                dutyStartsAway <= crossRingBuffer;
            final raceSoon = raceAway >= 0 && raceAway <= crossRingBuffer;

            if (dutyActiveOrSoon && raceSoon) {
              out.add(CrewClash(
                level: ClashLevel.crossRing,
                personId: handler.personId,
                personName: personName,
                title: 'Possible cross-ring clash',
                detail:
                    '$personName is needed with ${dog.dogName} in Ring ${race.ref.ring} in ${raceAway.clamp(0, 999)} race(s), while ${duty.role} in Ring ${duty.ring} is active or about to start.',
              ));
            }
          }
        }
      }
    }

    for (var i = 0; i < duties.length; i++) {
      for (var j = i + 1; j < duties.length; j++) {
        final a = duties[i];
        final b = duties[j];
        final common = a.personIds.toSet().intersection(b.personIds.toSet());
        if (common.isEmpty) continue;

        if (a.ring == b.ring) {
          final overlap = a.startRace <= b.endRace && b.startRace <= a.endRace;
          if (!overlap) continue;
          for (final personId in common) {
            final personName = nameOf(personId, personId);
            out.add(CrewClash(
              level: ClashLevel.clash,
              personId: personId,
              personName: personName,
              title: 'Two duties overlap',
              detail:
                  '$personName is assigned to ${a.role} and ${b.role} in Ring ${a.ring} during overlapping race ranges.',
            ));
          }
        } else {
          final pa = progressByRing[a.ring];
          final pb = progressByRing[b.ring];
          if (pa == null || pb == null) continue;
          final aSoon = a.endRace >= pa.currentRace &&
              a.startRace - pa.currentRace <= crossRingBuffer;
          final bSoon = b.endRace >= pb.currentRace &&
              b.startRace - pb.currentRace <= crossRingBuffer;
          if (!aSoon || !bSoon) continue;
          for (final personId in common) {
            final personName = nameOf(personId, personId);
            out.add(CrewClash(
              level: ClashLevel.crossRing,
              personId: personId,
              personName: personName,
              title: 'Possible cross-ring duty clash',
              detail:
                  '$personName has ${a.role} in Ring ${a.ring} and ${b.role} in Ring ${b.ring} around the same time.',
            ));
          }
        }
      }
    }

    return out;
  }
}

const teamDutyRoles = <String>[
  'Box Loader',
  'Ball Collector',
  'Line Watch',
  'Lane Captain',
  'Dog Handler',
  'Other',
];

const ringPartyRoles = <String>[
  'Lights',
  'Scribe',
  'Box Judge',
  'Other',
];

const officialRoles = <String>[
  'Head Judge',
  'Box Judge',
  'Line Judge',
  'Lights',
  'Scribe',
  'Other',
];

const handlerRoles = <String>[
  'Main handler',
  'Catcher / helper',
  'Second handler',
  'Backup',
  'Other',
];
