FLYBALL RING LIGHTS — REV 0.5.4 FAULT STATE SYNC FIX

No: Red Lane does NOT have to join before Blue fault lights work.

The Rev 0.5.3 issue was local state timing:
- tap gave immediate local feedback
- after only 120 ms the local override was removed
- on slower connections the Firebase room stream could still contain the old
  value
- the next tap could therefore calculate the wrong ON/OFF state

Rev 0.5.4:
- keeps the requested fault state visible until Firebase ACTUALLY confirms it
- supports repeated toggles even while a previous update is still travelling
- RESET clears all local pending fault state before resetting Firebase
- still shows a visible error if Firebase rejects a write

Expected:
Blue Host can use Blue faults with no Red device connected.
Blue Host can also operate Red faults.
Red Lane, once joined, can operate Red faults.
Display and Viewers are read-only.

No Firebase rules changes are required.

Suggested commit:
Fix Rev 0.5.4 fault state sync
