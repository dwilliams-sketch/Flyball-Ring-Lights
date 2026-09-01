FLYBALL RING LIGHTS — REV 0.6 RACE CONTROL ADDITION

Build: 0.6.0+16

ADDED
- Competition Race Control screen per competition day
- 1–9 independent rings
- Optional ring-prefixed race codes (105 = Ring 1 Race 5, 365 = Ring 3 Race 65)
- Manual current-race fallback with +1 / -1 / Set Race controls
- Current / On Deck / In the Hole / Racing Now status
- Races-away countdowns for club races
- Competition crew list
- Multiple handlers/helpers per dog
- Handler roles: Main handler, Catcher/helper, Second handler, Backup, Other
- Team duties: Box Loader, Ball Collector, Line Watch, Lane Captain, Dog Handler, Other
- Ring Party duties: Lights, Scribe, Box Judge, Other
- Judges/Officials: Head Judge, Box Judge, Line Judge, Lights, Scribe, Other
- Blue / Red / Both / N/A lane duty assignment
- Same-ring direct clash warnings
- Handler preparation-buffer warnings
- Cross-ring possible-clash warnings using live/manual ring progress
- Crew Board showing each person’s race and duty commitments
- Foreground sound/haptic alerts for race and duty countdowns
- FlyballGeek-ready API settings and adapter boundary (actual payload mapping awaits API details)
- Card-machine-style Dog Time and Start Time input (425 -> 4.25)
- +/- start-time control

IMPORTANT
The FlyballGeek connector is intentionally a safe placeholder until FlyballGeek supplies its API endpoint/schema/access details. Manual Race Control is fully usable in the meantime.

The existing Rev 0.5.4 Live Ring timing engine is not rewritten by this patch.
