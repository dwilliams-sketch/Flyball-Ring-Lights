import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/performance_report.dart';

class ReportingService {
  final FirebaseFirestore db;

  ReportingService({FirebaseFirestore? db}) : db = db ?? FirebaseFirestore.instance;

  Future<PerformanceReport> buildReport({
    required String clubId,
    required ReportFilter filter,
    String title = 'Club performance report',
  }) async {
    final club = db.collection('clubs').doc(clubId);
    final daySnap = await club.collection('competitionDays').get();

    final selectedDays = <String, Map<String, dynamic>>{};
    final dayDates = <String, DateTime?>{};

    for (final doc in daySnap.docs) {
      final data = doc.data();
      if ((data['status'] ?? '').toString() == 'deleted') continue;
      if (filter.competitionIds.isNotEmpty &&
          !filter.competitionIds.contains(doc.id)) {
        continue;
      }

      DateTime? date;
      final rawDate = data['date'];
      if (rawDate is Timestamp) date = rawDate.toDate().toLocal();

      if (filter.from != null && date != null && date.isBefore(_dayStart(filter.from!))) {
        continue;
      }
      if (filter.to != null && date != null && date.isAfter(_dayEnd(filter.to!))) {
        continue;
      }
      if (filter.teamName.isNotEmpty &&
          (data['teamName'] ?? '').toString() != filter.teamName) {
        continue;
      }
      if (filter.organisation.isNotEmpty &&
          (data['organisation'] ?? '').toString() != filter.organisation) {
        continue;
      }

      selectedDays[doc.id] = data;
      dayDates[doc.id] = date;
    }

    if (selectedDays.isEmpty) {
      return _empty(title);
    }

    final sessionSnap = await club.collection('competitionSessions').get();
    final sessions = sessionSnap.docs.where((doc) {
      final competitionId = (doc.data()['competitionId'] ?? '').toString();
      return selectedDays.containsKey(competitionId);
    }).toList();

    var raceCount = 0;
    var raceWins = 0;
    var raceLosses = 0;
    var raceDraws = 0;
    var legCount = 0;
    var legWins = 0;
    var legLosses = 0;
    var legDraws = 0;
    var cleanLegs = 0;
    var faults = 0;
    var reruns = 0;
    var dogRuns = 0;

    final teamTimes = <double>[];
    final faultBreakdown = <String, int>{};
    final crossoverBreakdown = <String, int>{};
    final laneBuilders = <String, _LaneBuilder>{
      'Blue': _LaneBuilder('Blue'),
      'Red': _LaneBuilder('Red'),
    };
    final dogBuilders = <String, _DogBuilder>{};
    final trendBuilders = <String, _TrendBuilder>{};

    for (final day in selectedDays.entries) {
      trendBuilders[day.key] = _TrendBuilder(
        competitionId: day.key,
        label: (day.value['name'] ?? 'Competition').toString(),
        date: dayDates[day.key],
      );
    }

    for (final session in sessions) {
      final sessionData = session.data();
      final sessionLane = (sessionData['lane'] ?? '').toString();
      if (filter.lane.isNotEmpty && sessionLane != filter.lane) continue;

      final legs = await session.reference.collection('legs').orderBy('legNumber').get();
      final includedLegs = legs.docs.where((leg) {
        final lane = (leg.data()['lane'] ?? sessionLane).toString();
        return filter.lane.isEmpty || lane == filter.lane;
      }).toList();

      if (includedLegs.isEmpty) continue;
      raceCount++;
      final raceResult = (sessionData['raceResult'] ?? '').toString();
      if (raceResult == 'Win') raceWins++;
      if (raceResult == 'Loss') raceLosses++;
      if (raceResult == 'Draw') raceDraws++;

      final competitionId = (sessionData['competitionId'] ?? '').toString();
      final trend = trendBuilders[competitionId];

      for (final leg in includedLegs) {
        final data = leg.data();
        final lane = (data['lane'] ?? sessionLane).toString();
        final laneBuilder = laneBuilders.putIfAbsent(lane, () => _LaneBuilder(lane));

        legCount++;
        laneBuilder.legs++;
        trend?.legs++;

        final result = (data['result'] ?? '').toString();
        if (result == 'Win') {
          legWins++;
          laneBuilder.wins++;
        } else if (result == 'Loss') {
          legLosses++;
          laneBuilder.losses++;
        } else if (result == 'Draw') {
          legDraws++;
          laneBuilder.draws++;
        }

        final teamTime = _num(data['teamTime']);
        if (teamTime != null && teamTime > 0) {
          teamTimes.add(teamTime);
          laneBuilder.times.add(teamTime);
          trend?.times.add(teamTime);
        }

        var legFaulted = false;
        final entries = data['entries'];
        if (entries is List) {
          for (final raw in entries) {
            if (raw is! Map) continue;
            dogRuns++;
            final dogId = (raw['dogId'] ?? '').toString();
            final dogName = (raw['dogName'] ?? 'Unknown').toString();
            final dogKey = dogId.isEmpty ? 'name:$dogName' : dogId;
            final dog = dogBuilders.putIfAbsent(
              dogKey,
              () => _DogBuilder(dogId: dogId, dogName: dogName),
            );
            dog.runs++;

            final dogTime = _num(raw['dogTime']);
            if (dogTime != null && dogTime > 0) dog.times.add(dogTime);
            final startTime = _num(raw['startTime']);
            if (startTime != null) dog.starts.add(startTime);

            final crossover = (raw['crossover'] ?? '').toString().trim();
            if (crossover.isNotEmpty) {
              crossoverBreakdown[crossover] =
                  (crossoverBreakdown[crossover] ?? 0) + 1;
              dog.crossovers[crossover] = (dog.crossovers[crossover] ?? 0) + 1;
            }

            if (raw['isRerun'] == true) {
              reruns++;
              dog.reruns++;
            }

            if (raw['fault'] == true) {
              faults++;
              laneBuilder.faults++;
              trend?.faults++;
              dog.faults++;
              legFaulted = true;

              var label = (raw['faultLabelSnapshot'] ?? raw['faultReason'] ?? 'Unspecified')
                  .toString()
                  .trim();
              if (label.isEmpty) label = 'Unspecified';
              faultBreakdown[label] = (faultBreakdown[label] ?? 0) + 1;
            }
          }
        }

        if (!legFaulted) {
          cleanLegs++;
          laneBuilder.cleanLegs++;
        }
      }
    }

    final dogs = dogBuilders.values.map((d) => d.build()).toList()
      ..sort((a, b) => b.runs.compareTo(a.runs));

    final trend = trendBuilders.values.map((t) => t.build()).toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) return a.label.compareTo(b.label);
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });

    return PerformanceReport(
      title: title,
      competitionCount: selectedDays.length,
      raceCount: raceCount,
      raceWins: raceWins,
      raceLosses: raceLosses,
      raceDraws: raceDraws,
      legCount: legCount,
      legWins: legWins,
      legLosses: legLosses,
      legDraws: legDraws,
      cleanLegs: cleanLegs,
      faults: faults,
      reruns: reruns,
      dogRuns: dogRuns,
      fastestTeamTime: teamTimes.isEmpty ? null : teamTimes.reduce((a, b) => a < b ? a : b),
      averageTeamTime: _average(teamTimes),
      medianTeamTime: _median(teamTimes),
      faultBreakdown: faultBreakdown,
      crossoverBreakdown: crossoverBreakdown,
      lanes: laneBuilders.map((key, value) => MapEntry(key, value.build())),
      dogs: dogs,
      trend: trend,
    );
  }

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static double? _num(dynamic value) => value is num ? value.toDouble() : null;

  static double? _average(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double? _median(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static PerformanceReport _empty(String title) => PerformanceReport(
        title: title,
        competitionCount: 0,
        raceCount: 0,
        raceWins: 0,
        raceLosses: 0,
        raceDraws: 0,
        legCount: 0,
        legWins: 0,
        legLosses: 0,
        legDraws: 0,
        cleanLegs: 0,
        faults: 0,
        reruns: 0,
        dogRuns: 0,
        fastestTeamTime: null,
        averageTeamTime: null,
        medianTeamTime: null,
        faultBreakdown: const {},
        crossoverBreakdown: const {},
        lanes: const {},
        dogs: const [],
        trend: const [],
      );
}

class _LaneBuilder {
  final String lane;
  int legs = 0;
  int wins = 0;
  int losses = 0;
  int draws = 0;
  int faults = 0;
  int cleanLegs = 0;
  final List<double> times = [];

  _LaneBuilder(this.lane);

  LaneKpi build() => LaneKpi(
        lane: lane,
        legs: legs,
        wins: wins,
        losses: losses,
        draws: draws,
        faults: faults,
        cleanLegs: cleanLegs,
        averageTime: ReportingService._average(times),
        fastestTime: times.isEmpty ? null : times.reduce((a, b) => a < b ? a : b),
      );
}

class _DogBuilder {
  final String dogId;
  final String dogName;
  int runs = 0;
  int faults = 0;
  int reruns = 0;
  final List<double> times = [];
  final List<double> starts = [];
  final Map<String, int> crossovers = {};

  _DogBuilder({required this.dogId, required this.dogName});

  DogKpi build() => DogKpi(
        dogId: dogId,
        dogName: dogName,
        runs: runs,
        faults: faults,
        reruns: reruns,
        fastestTime: times.isEmpty ? null : times.reduce((a, b) => a < b ? a : b),
        averageTime: ReportingService._average(times),
        averageStart: ReportingService._average(starts),
        crossovers: Map.unmodifiable(crossovers),
      );
}

class _TrendBuilder {
  final String competitionId;
  final String label;
  final DateTime? date;
  final List<double> times = [];
  int faults = 0;
  int legs = 0;

  _TrendBuilder({
    required this.competitionId,
    required this.label,
    required this.date,
  });

  TrendPoint build() => TrendPoint(
        competitionId: competitionId,
        label: label,
        date: date,
        averageTime: ReportingService._average(times),
        fastestTime: times.isEmpty ? null : times.reduce((a, b) => a < b ? a : b),
        faults: faults,
        legs: legs,
      );
}
