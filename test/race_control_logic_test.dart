import 'package:flutter_test/flutter_test.dart';
import 'package:flyball_ring_lights/models/race_control.dart';

void main() {
  test('ring-prefixed race codes are decoded', () {
    expect(RaceRef.parse('105', prefixed: true)?.ring, 1);
    expect(RaceRef.parse('105', prefixed: true)?.race, 5);
    expect(RaceRef.parse('365', prefixed: true)?.ring, 3);
    expect(RaceRef.parse('365', prefixed: true)?.race, 65);
  });

  test('race status understands in hole and on deck', () {
    const progress = RingProgress(ring: 2, currentRace: 20);
    expect(
      RaceControlLogic.raceStatus(progress, const RaceRef(ring: 2, race: 22)),
      'IN THE HOLE',
    );
    expect(
      RaceControlLogic.raceStatus(progress, const RaceRef(ring: 2, race: 21)),
      'ON DECK',
    );
    expect(
      RaceControlLogic.raceStatus(progress, const RaceRef(ring: 2, race: 20)),
      'RACING NOW',
    );
  });

  test('handler clash is detected against duty range', () {
    const person = CrewPerson(id: 'dafz', name: 'Dafz');
    const race = ScheduledClubRace(
      id: 'r8',
      ref: RaceRef(ring: 1, race: 8),
      teamName: 'Menai Muttineers',
      dogs: [
        RaceDogAssignment(
          dogId: 'chip',
          dogName: 'Chip',
          handlers: [
            HandlerAssignment(
              personId: 'dafz',
              personName: 'Dafz',
              role: 'Main handler',
            ),
          ],
        ),
      ],
    );
    const duty = CompetitionDuty(
      id: 'lights',
      group: 'ringParty',
      role: 'Lights',
      ring: 1,
      startRace: 4,
      endRace: 10,
      lane: 'Both',
      personIds: ['dafz'],
      personNames: ['Dafz'],
    );

    final clashes = RaceControlLogic.findClashes(
      people: const [person],
      races: const [race],
      duties: const [duty],
      progressByRing: const {1: RingProgress(ring: 1, currentRace: 1)},
      prepBuffer: 3,
      crossRingBuffer: 4,
    );

    expect(clashes.any((c) => c.level == ClashLevel.clash), isTrue);
    expect(clashes.first.detail, contains('Chip'));
  });

  test('multiple handlers on one dog are all checked', () {
    const race = ScheduledClubRace(
      id: 'izzierace',
      ref: RaceRef(ring: 3, race: 65),
      teamName: 'Black Flags',
      dogs: [
        RaceDogAssignment(
          dogId: 'izzie',
          dogName: 'Izzie',
          handlers: [
            HandlerAssignment(personId: 'brenda', personName: 'Brenda', role: 'Main handler'),
            HandlerAssignment(personId: 'dafz', personName: 'Dafz', role: 'Catcher / helper'),
          ],
        ),
      ],
    );
    const duty = CompetitionDuty(
      id: 'duty',
      group: 'official',
      role: 'Box Judge',
      ring: 3,
      startRace: 60,
      endRace: 70,
      lane: 'Blue',
      personIds: ['dafz'],
      personNames: ['Dafz'],
    );

    final clashes = RaceControlLogic.findClashes(
      people: const [
        CrewPerson(id: 'brenda', name: 'Brenda'),
        CrewPerson(id: 'dafz', name: 'Dafz'),
      ],
      races: const [race],
      duties: const [duty],
      progressByRing: const {3: RingProgress(ring: 3, currentRace: 55)},
      prepBuffer: 3,
      crossRingBuffer: 4,
    );

    expect(clashes.any((c) => c.personName == 'Dafz'), isTrue);
  });
}
