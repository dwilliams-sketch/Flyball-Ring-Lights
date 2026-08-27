FLYBALL RING LIGHTS — REV 0.4
WEB + COMPETITION DAYS + DOG MANAGEMENT

DOGS
====
- BFA number field.
- UKFL number field.
- Breed.
- Jump height.
- Start mark / release cue / notes remain.
- Import Menai Muttineers dogs from Dogs -> menu -> Import Menai dogs.
- Import avoids duplicates by dog name.
- Existing matching dogs get BFA/breed/jump details updated.
- Active dogs appear in competition line-ups.
- Retire a dog instead of deleting their history.
- Retired dogs have a separate archive screen.
- Restore a retired dog at any time.
- Permanent delete is only allowed when the dog has no recorded runs.
  This is ideal for test/accidental dog records.

MENAI IMPORT
============
The import contains:
Macs, Milo, Arlo, Nellie, Chip, Izzie, Coco, Rizzo, Cheddar, Olaf,
Snow, Maggie, Callie, Skylar, Star and Ember.

BFA numbers / breed / jump height are pre-filled from the list supplied.
UKFL numbers remain blank until entered.

COMPETITION DAYS
================
The structure is now:

COMPETITION DAY
  -> RACE 1
       -> LEG 1, LEG 2, LEG 3...
  -> RACE 2
       -> LEG 1, LEG 2...
  -> etc.

There are no fixed limits on number of races or legs.

Create a competition with:
- competition name
- venue
- date
- BFA / UKFL / Other
- team name
- division
- seed / declared time
- day notes

Each race records:
- race number
- opponent
- lane
- all the existing leg data
- race result calculated from leg wins/losses
- clean legs
- faults
- reruns
- fastest official team time

The competition page gives a running day summary:
- races completed
- race W-L-D
- leg wins/losses
- fastest team time
- clean legs
- faults
- reruns

WEB
===
Firebase Web is now configured.

GitHub Actions builds TWO artifacts:
1. Flyball-Ring-Lights-Rev-0-4-APK
2. Flyball-Ring-Lights-Rev-0-4-Web

The Web artifact is the actual compiled web app.
It still needs to be placed on a web host before other people can open it
from a public link.

The next small setup after confirming the Web build compiles is Firebase
Hosting, which can give the app a public *.web.app address.

FIRESTORE
=========
No new Firestore rule change is required for these features because the
existing signed-in club rules already cover competitionDays and dog records.

UPLOAD
======
Upload the contents of this ZIP to the existing GitHub repository.

Check:
.github/workflows/build-apps.yml

It should mention:
Flyball-Ring-Lights-Rev-0.4.apk
and
Flyball-Ring-Lights-Rev-0-4-Web

Suggested commit:
Build Rev 0.4 web competition days and dogs
