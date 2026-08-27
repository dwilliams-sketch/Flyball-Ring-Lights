FLYBALL RING LIGHTS — REV 0.5.1 FIREBASE STARTUP FIX

ERROR FIXED
===========
[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists

WHY IT HAPPENED
===============
The Android Google Services configuration is now working properly and creates/
configures the native DEFAULT Firebase app.

Rev 0.5 then tried to initialise the same DEFAULT app again using explicit Dart
FirebaseOptions, which caused the duplicate-app error.

THE FIX
=======
Android now uses:
Firebase.initializeApp()

This attaches FlutterFire to the Android DEFAULT Firebase configuration created
from google-services.json.

Web still uses the explicit Firebase Web options, because browsers do not have
Android google-services resources.

NO DATABASE CHANGES
===================
Do NOT change Firestore rules.
Do NOT change Realtime Database rules.
Your published Rev 0.5 Realtime rules remain correct.

UPLOAD
======
Upload/commit the contents to the existing GitHub repo.

Suggested commit:
Fix Rev 0.5.1 Firebase duplicate app

Expected artifacts:
Flyball-Ring-Lights-Rev-0-5-1-Live-Ring-APK
Flyball-Ring-Lights-Rev-0-5-1-Live-Ring-Web

FIRST TEST
==========
Install the APK.
The Firebase Connection Failed screen should be gone.

Then:
1. Sign in.
2. START LIVE RING.
3. CREATE LIVE RING.
4. Confirm a token and 6-digit code appear.
5. Join from a second device as Red Lane.
