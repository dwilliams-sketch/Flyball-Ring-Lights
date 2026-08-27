FLYBALL RING LIGHTS — REV 0.3 COMPETITION BETA

THIS IS THE BIG USEFUL BETA BUILD
=================================
Rev 0.3 deliberately leaves the live multi-phone ring until the next revision,
but adds the whole records/competition side in one coherent layer.

ADDED
=====
- Real Firebase email/password Create Account.
- Real Sign In.
- Create a Club workspace.
- Join a Club using the Captain's invite code.
- Club invite-code screen.
- Add/edit dog records.
- Dog start mark, usual release cue and notes.
- Competition Mode.
- Choose Blue or Red lane.
- Four starting dog dropdowns.
- Change the running order between legs.
- Individual dog time for ALL FOUR dogs.
- Start time for Dog 1.
- Crossover rating for every dog after Dog 1:
  Perfect / Good / Long / Very Long / Bus.
- Optional crossover gap in feet.
- Tap a fault immediately.
- Choose the reason after the light has been marked.
- Faulted dog is automatically appended as the next re-run.
- If a re-run faults, the dog can be appended again.
- Each re-run gets its own individual dog time.
- Leg result and optional official team time.
- Free-text leg comments.
- Save Leg & Start Next Leg.
- Save Leg & Finish Race.
- Competition session history.
- Each dog gets a permanent run history.
- Dog page calculates recorded PB, average, clean percentage and best start.

IMPORTANT FIRESTORE STEP
========================
Your Firestore database was created in Production Mode, so it is currently
locked.

Before testing Rev 0.3:
1. Firebase Console
2. Firestore Database
3. Rules
4. Replace the existing rules with the supplied firestore.rules
5. Publish

Those rules keep club data restricted to signed-in members of that club.

UPLOAD
======
Upload the CONTENTS of this ZIP to the existing GitHub repo, preserving folders.

Suggested commit:
Build Rev 0.3 competition beta

The APK artifact is:
Flyball-Ring-Lights-Rev-0-3-Competition-Beta-APK

TEST ORDER
==========
1. Install app.
2. Create a brand-new account and club.
3. Add at least four dogs.
4. Open Competition Mode.
5. Select lane and four dogs.
6. Enter all four dog times + Dog 1 start time.
7. Mark one dog as a fault and confirm it appears as a re-run.
8. Enter the re-run time.
9. Save & start next leg.
10. Change the dog order.
11. Save & finish.
12. Open each dog's record and confirm the times appear.

NOT IN THIS BUILD YET
=====================
- Live Blue/Red/Main Display/Viewer multi-device sync.
- QR room joining.
- Pass Planner combinations.
- Subscription/paywall.
- Certified electronic timing.

Those can come after this records/competition beta is proven.
