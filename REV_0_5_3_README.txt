FLYBALL RING LIGHTS — REV 0.5.3 FAULT LIGHT FIX

WHAT CHANGED
============
- Fault toggles no longer depend on a Realtime Database transaction.
- A tap now gives instant visual feedback.
- Firebase then writes the requested ON/OFF value directly.
- If Firebase rejects the write, the app restores the real state and shows the
  exact error at the bottom instead of silently doing nothing.
- Applies to Blue and Red lane fault lights.

NO FIREBASE RULE CHANGE SHOULD BE NEEDED
=========================================
If your current corrected Rev 0.5.1 Realtime Database rules are published,
leave them as they are.

A canonical realtime_database.rules.json is included in this patch for the
repository/reference.

Suggested commit:
Fix Rev 0.5.3 live fault lights

Expected APK:
Flyball-Ring-Lights-Rev-0.5.3-Live-Ring.apk

TEST
====
Host:
- Blue faults 1–4 should turn on/off.
- Host can also operate Red faults.

Red device:
- Red faults 1–4 should turn on/off.
- Red must not be able to alter Blue faults.

All connected Display/Viewer devices should update immediately.
