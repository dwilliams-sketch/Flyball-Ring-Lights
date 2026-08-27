FLYBALL RING LIGHTS — REV 0.5 LIVE MULTI-DEVICE BETA

THIS IS THE MULTI-DEVICE TEST BUILD
===================================
Rev 0.5 keeps the working Rev 0.4 dog, competition, APK and web features and
adds the first real Live Ring.

LIVE RING
=========
Signed-in club member:
Home -> START LIVE RING

The Blue/Host creates a temporary room.

The room displays:
- a fun token such as ANCHOR / PARROT / COMPASS
- a unique 6-digit room code

Other devices can join as:
- RED LANE
- MAIN DISPLAY
- VIEWER

Guests do not need a full club account.
The welcome screen now has:
JOIN A LIVE RING AS A GUEST

ROLES
=====
BLUE / HOST
- GO
- STOP
- RESET
- Blue fault lights
- can also operate Red faults if needed
- can end the room for everybody

RED LANE
- Red fault lights
- emergency STOP
- cannot GO or RESET

MAIN DISPLAY
- read only
- sound ON by default

VIEWER
- read only
- sound OFF by default

SYNC
====
The host does NOT transmit every timer tick.

GO writes one authoritative future zero-time into Firebase Realtime Database.
Each device reads Firebase's server clock offset and calculates:
-3.000 -> 0.000 -> +60.000 locally.

This greatly reduces network traffic and timer jitter.

The first three red lights and green light are calculated from the same
zero-time on every connected device.

Fault lights sync through Realtime Database.

PRESENCE
========
The top bar shows:
B = Blue Host
R = Red Lane
D = Main Display
V = number of online viewers

A cloud icon shows whether this device is currently connected to Firebase.

Room role presence uses Firebase onDisconnect so a device that crashes or loses
connection should eventually show offline.

ROOM LIFE
=========
Rooms are created with a 3-hour expiry.

This beta prevents new joins after expiry. It does not yet run a server cleanup
function to physically delete old expired room records.

IMPORTANT FIREBASE STEP
========================
Before using Live Ring you MUST publish the supplied Realtime Database rules.

Firebase Console:
Build -> Realtime Database -> Rules

Replace the rules with:
realtime_database.rules.json

Click Publish.

DO NOT replace your Firestore rules with this file.
Firestore rules and Realtime Database rules are separate.

BUILD
=====
Upload/commit Rev 0.5 to GitHub.

Check:
.github/workflows/build-apps.yml

It should build:
Flyball-Ring-Lights-Rev-0.5-Live-Ring.apk
Flyball-Ring-Lights-Rev-0-5-Live-Ring-Web

Suggested commit:
Build Rev 0.5 live multi-device ring

FIRST TEST
==========
Use at least 3 devices:

DEVICE 1
Sign in -> Start Live Ring -> Create Live Ring
This is BLUE/HOST.

DEVICE 2
Welcome -> Join Live Ring as Guest
Enter room code -> RED LANE.

DEVICE 3
Welcome -> Join Live Ring as Guest
Enter room code -> MAIN DISPLAY.

Optional extra phones:
Join as VIEWER.

Confirm:
1. B / R / D status dots become active.
2. Press GO on Blue.
3. All devices show the same red sequence and timer.
4. Main Display makes the sound cues.
5. Press Blue fault 1. It appears everywhere.
6. Press Red fault 3 on Red device. It appears everywhere.
7. STOP on Blue freezes all devices.
8. RESET on Blue resets all devices and clears faults.
9. GO again.
10. Emergency STOP on Red freezes all devices.
11. Join a Viewer while a room is already active.
12. Disconnect one device and check presence updates.
13. End Room from Blue and confirm other devices see that it ended.

TRAINING WARNING
================
This is a training beta, not certified electronic judging/timing equipment.
Manual/network timing should not be treated as official competition timing.

NOT YET IN LIVE RING
====================
- QR join
- live dog line-ups on the display
- automatic live-ring fault reasons/history
- Pass Planner live prompts
- offline LAN-only mode
- server-side expired-room cleanup

Those should be added after the first real multi-device test proves the sync
layer itself.
