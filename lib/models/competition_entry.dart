class CompetitionEntry {
  final String id;
  String dogId;
  String dogName;
  final int runPosition;
  final bool isRerun;
  final String? sourceEntryId;

  bool fault;
  String faultTypeId;
  String faultReason;
  String faultOtherText;
  String dogTime;
  String startTime;
  String crossover;
  String gapFeet;

  CompetitionEntry({
    required this.id,
    required this.dogId,
    required this.dogName,
    required this.runPosition,
    required this.isRerun,
    this.sourceEntryId,
    this.fault = false,
    this.faultTypeId = '',
    this.faultReason = '',
    this.faultOtherText = '',
    this.dogTime = '',
    this.startTime = '',
    this.crossover = '',
    this.gapFeet = '',
  });
}
