FLYBALL RING LIGHTS — REV 0.1.1 RESPONSIVE LAYOUT FIX

WHAT THIS FIXES
===============
On smaller phones in landscape, Rev 0.1 could show:
- "BOTTOM OVERFLOWED BY 27 PIXELS" on the Blue/Red lane columns;
- a small overflow in the centre;
- the race timer hidden behind GO / STOP / RESET.

CAUSE
=====
Rev 0.1 used fixed heights for four fault buttons and fixed light sizes.
Some phone screens have much less usable landscape height after Android's
status/navigation areas are removed.

REV 0.1.1
=========
The ring screen now sizes itself from the ACTUAL usable screen height.

- Fault buttons automatically scale down on shallow phone screens.
- The central flyball lamps automatically scale to fit.
- The timer gets guaranteed reserved space above the controls.
- GO / STOP / RESET get their own fixed responsive control strip.
- Larger tablets still receive much larger lamps.
- Very short phones use a compact top bar to save space.
- No change to timing, sound or GO / STOP / RESET logic.

VERSION
=======
0.1.1+2

EASY GITHUB UPDATE
==================
This patch deliberately does NOT contain .github, so you can upload it in one go.

1. Extract this ZIP.
2. GitHub -> Flyball-Ring-Lights -> Add file -> Upload files.
3. Upload the CONTENTS:
     lib
     pubspec.yaml
     REV_0_1_1_README.txt
4. Commit:
     Fix Rev 0.1 landscape overflow
5. Wait for the newest Actions build.
6. Download the same Rev-0-1 APK artifact from the newest run.
   (The installed app version will show 0.1.1.)

TEST
====
- No yellow/black overflow banners.
- All 4 Blue fault buttons visible.
- All 4 Red fault buttons visible.
- All 4 centre lamps visible.
- Timer fully visible above GO/STOP/RESET.
- GO -> red sequence -> green -> timer works normally.
