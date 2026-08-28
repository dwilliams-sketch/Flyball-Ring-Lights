FLYBALL RING LIGHTS — REV 0.6 PERFORMANCE · ACCESSIBILITY · DISPLAY BETA

VERSION
0.6.0+15

WHAT IS NEW
- Toggle Main Display / Viewer between AUTO, PORTRAIT and LANDSCAPE.
- Live-ring haptics/vibration can be toggled separately from sound.
- Dual-webcam Camera Beta on the hosted web Main Display.
- Competition edit, Bin, Restore and permanent-delete workflow.
- Dynamic club fault types; Other supports free typing.
- Team records and archive/restore.
- Reports & Performance with competition/set/team/organisation/lane filters.
- Speed, W-L-D, clean-run, fault, rerun, lane, dog and crossover KPIs.
- Sponsor PDF, sponsor-summary copy and CSV copy.
- Club Admin area and member roles.

IMPORTANT FIREBASE STEP
Rev 0.6 has new Firestore permissions. After the GitHub build is green, publish the included `firestore.rules` under Firebase → Firestore Database → Rules before testing Teams, Fault Types or Admin.

DO NOT CHANGE REALTIME DATABASE RULES.
The live-ring Realtime Database rules from the working 0.5.4 setup remain the same.

GITHUB
Suggested commit:
Build Rev 0.6 performance accessibility display beta

Expected artifacts:
Flyball-Ring-Lights-Rev-0-6-Performance-Display-APK
Flyball-Ring-Lights-Rev-0-6-Performance-Display-Web

WEB DEPLOY
The web artifact now contains its own firebase.json and DEPLOY_WEB.txt. After uploading/extracting it in Cloud Shell, the deploy command is:

npx firebase-tools@15.28.2 deploy --only hosting --project flyball-ring-lights

CAMERA BETA
This is a coaching aid, not certified judging. It records the app's capture-request timing, but ordinary webcam/browser shutter latency is not calibrated.
