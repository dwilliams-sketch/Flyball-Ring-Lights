FLYBALL RING LIGHTS — REV 0.3.2 RACE HISTORY DETAIL

WHAT THIS FIXES
===============
Rev 0.3.1 saved competition sessions and legs correctly, but the Competition
History page only displayed a summary list. The saved races could not be opened.

REV 0.3.2
=========
Tap any race in Competition History to open it.

The race detail shows:
- every saved leg
- Win / Loss / Draw / Not recorded
- official team time
- all original dogs in running order
- every individual dog time
- Dog 1 start time
- crossover rating
- crossover gap in feet
- faults and fault reasons
- re-runs as separate positions (Dog 5, 6, 7 etc.)
- leg comments

No database migration is required. Existing Rev 0.3/0.3.1 saved races should
open automatically because the detail screen reads the data already stored.

UPLOAD
======
Upload/commit the contents to the existing repository.

Suggested commit:
Add Rev 0.3.2 race history detail

APK:
Flyball-Ring-Lights-Rev-0.3.2-Race-History.apk
