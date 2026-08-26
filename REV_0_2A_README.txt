FLYBALL RING LIGHTS — REV 0.2A FIREBASE CONNECTION

PURPOSE
=======
This is deliberately only the first small part of Rev 0.2.

It connects the Android app to the new Flyball Ring Lights Firebase project.
It does NOT add live rooms yet.

WHAT IT ADDS
============
- Firebase Core connection.
- Firebase Authentication package.
- Android google-services configuration.
- A clear on-screen error if Firebase cannot initialise.
- Version bump to 0.2.0+4.
- Ring label changed to REV 0.2A.
- GitHub workflow simplified to Android APK only for now.

WHY THE WORKFLOW CHANGED
========================
The old workflow was building the APK successfully and then showing a red X
because GitHub Pages failed afterwards.

For this stage we only need the Android APK, so Rev 0.2A removes the Pages
deployment. A successful Android build should now finish green.

IMPORTANT
=========
The file firebase/google-services.json is Firebase's Android client
configuration. It is not a Firebase Admin/service-account private key.

UPLOAD TO GITHUB
================
Upload the CONTENTS of this ZIP to the existing Flyball-Ring-Lights repository,
preserving the folders:

.github/workflows/build-apps.yml
firebase/google-services.json
lib/main.dart
lib/screens/ring/ring_screen.dart
lib/widgets/fault_button.dart
pubspec.yaml
REV_0_2A_README.txt

Suggested commit:
Connect Rev 0.2A to Firebase

TEST
====
After GitHub Actions finishes:
1. The workflow should ideally show a green tick.
2. Download Flyball-Ring-Lights-Rev-0-2A-APK.
3. Install it.
4. The normal welcome screen should open.
5. Open a ring and check the top-left says REV 0.2A.
6. If Firebase fails, the app will show a readable Firebase Connection Failed
   screen instead of hanging.

NEXT
====
Once this connection build works, the next patch will replace the prototype
account screen with real Firebase email/password sign-up and sign-in.
