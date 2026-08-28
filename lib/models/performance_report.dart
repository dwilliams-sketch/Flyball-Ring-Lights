class TrendPoint {
  final String competitionId;
  final String label;
  final DateTime? date;
  final double? averageTime;
  final double? fastestTime;
  final int faults;
  final int legs;

  const TrendPoint({
    required this.competitionId,
    required this.label,
    required this.date,
    required this.averageTime,
    required this.fastestTime,
    required this.faults,
    required this.legs,
  });
}

class LaneKpi {
  final String lane;
  final int legs;
  final int wins;
  final int losses;
  final int draws;
  final int faults;
  final int cleanLegs;
  final double? averageTime;
  final double? fastestTime;

  const LaneKpi({
    required this.lane,
    required this.legs,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.faults,
    required this.cleanLegs,
    required this.averageTime,
    required this.fastestTime,
  });

  double get cleanPercent => legs == 0 ? 0 : cleanLegs * 100 / legs;
}

class DogKpi {
  final String dogId;
  final String dogName;
  final int runs;
  final int faults;
  final int reruns;
  final double? fastestTime;
  final double? averageTime;
  final double? averageStart;
  final Map<String, int> crossovers;

  const DogKpi({
    required this.dogId,
    required this.dogName,
    required this.runs,
    required this.faults,
    required this.reruns,
    required this.fastestTime,
    required this.averageTime,
    required this.averageStart,
    required this.crossovers,
  });

  double get faultRate => runs == 0 ? 0 : faults * 100 / runs;
}

class PerformanceReport {
  final String title;
  final int competitionCount;
  final int raceCount;
  final int raceWins;
  final int raceLosses;
  final int raceDraws;
  final int legCount;
  final int legWins;
  final int legLosses;
  final int legDraws;
  final int cleanLegs;
  final int faults;
  final int reruns;
  final int dogRuns;
  final double? fastestTeamTime;
  final double? averageTeamTime;
  final double? medianTeamTime;
  final Map<String, int> faultBreakdown;
  final Map<String, int> crossoverBreakdown;
  final Map<String, LaneKpi> lanes;
  final List<DogKpi> dogs;
  final List<TrendPoint> trend;

  const PerformanceReport({
    required this.title,
    required this.competitionCount,
    required this.raceCount,
    required this.raceWins,
    required this.raceLosses,
    required this.raceDraws,
    required this.legCount,
    required this.legWins,
    required this.legLosses,
    required this.legDraws,
    required this.cleanLegs,
    required this.faults,
    required this.reruns,
    required this.dogRuns,
    required this.fastestTeamTime,
    required this.averageTeamTime,
    required this.medianTeamTime,
    required this.faultBreakdown,
    required this.crossoverBreakdown,
    required this.lanes,
    required this.dogs,
    required this.trend,
  });

  double get cleanLegPercent => legCount == 0 ? 0 : cleanLegs * 100 / legCount;

  double get raceWinPercent {
    final recorded = raceWins + raceLosses + raceDraws;
    return recorded == 0 ? 0 : raceWins * 100 / recorded;
  }

  double get faultsPerLeg => legCount == 0 ? 0 : faults / legCount;
}

class ReportFilter {
  final Set<String> competitionIds;
  final DateTime? from;
  final DateTime? to;
  final String teamName;
  final String organisation;
  final String lane;

  const ReportFilter({
    this.competitionIds = const {},
    this.from,
    this.to,
    this.teamName = '',
    this.organisation = '',
    this.lane = '',
  });
}
