# Flyball Ring Lights — Rev 0.6 Beta

Rev 0.6 builds on the working live-ring system with club management, competition data controls, accessibility, reporting and a flexible centre display.

## Main additions
- Main Display / Viewer can be switched between **Auto, Portrait and Landscape**.
- Blue and Red controller roles remain landscape-first.
- Device-level sound, volume and haptic/vibration controls for the live light sequence.
- Dual-webcam start-line Camera Beta on the hosted web Main Display.
- Real club Teams with active/archive/restore controls.
- Dynamic competition fault types with add, rename, order, disable and restore.
- **Other** fault always supports free-typed detail.
- Competition edit, Move to Bin, Restore and permanent delete of test data.
- Reports & Performance filters for date period, selected competitions, team, organisation and lane.
- KPI reporting for races, legs, wins/losses/draws, clean legs, speeds, faults, reruns, dog runs, crossover quality, lane performance and dog performance.
- Sponsor-ready PDF plus copyable summary and CSV output.
- Club Admin area for members/roles, teams, faults and deleted competitions.

## Important beta note
Camera Beta is a training/coaching aid. Ordinary webcams and browser capture latency are not calibrated judging equipment, so the app does not automatically declare a legal/early start from camera footage.

## Firebase
Rev 0.6 includes **new Firestore rules** for Teams, Fault Types and Admin member access. Publish `firestore.rules` in Firebase Firestore before testing those new areas.

The working Rev 0.5.4 Realtime Database rules are unchanged.
