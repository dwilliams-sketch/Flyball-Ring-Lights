FLYBALL RING LIGHTS — REV 0.2B

Fixes the Android error:
Failed to load FirebaseOptions from resource.

Flutter now receives the Firebase settings directly through
lib/firebase_options.dart, so startup no longer depends on Android-generated
values.xml.

Upload the contents of this ZIP to the existing repository and preserve folders.

Commit:
Fix Firebase initialisation Rev 0.2B

Then install the newest APK. The normal welcome screen should open and the ring
should show REV 0.2B.
