FLYBALL RING LIGHTS — REV 0.5.2

Fixes Live Ring hanging on CREATING RING.

The app now connects Realtime Database using the exact Europe-West1 database URL
and adds 12-second timeouts so a failed live-room step gives a readable error.

No Firebase rule changes are needed for this patch.

Suggested commit:
Fix Rev 0.5.2 Realtime Database connection
