FLYBALL RING LIGHTS — REV 0.3.1 ACCOUNT/PERMISSIONS FIX

WHY THIS PATCH EXISTS
=====================
Rev 0.3 could create the Firebase Authentication login and then have Firestore
reject the club/profile write. That left a half-created/orphan account:
- Create Account then reported the email already existed.
- Sign In could authenticate but there was no club profile to load.

FIXED
=====
- Club/account setup now writes Firestore documents in a safe order.
- Failed beta account setup tries to delete the newly-created Firebase login.
- Club joining now uses a secure direct invite-code document.
- Firestore rules updated for the new safe setup order.
- Forgot Password added to Sign In.
- Incomplete old beta accounts now show a clearer message.
- APK renamed Rev 0.3.1 Account Fix.

IMPORTANT: CLEAR THE OLD TEST USER FIRST
========================================
Firebase Console -> Authentication -> Users
Delete the test account/email that was created by the failed Rev 0.3 setup.

If there is no real data yet, it is fine to delete all test users.

THEN PUBLISH THE NEW FIRESTORE RULES
====================================
Firebase -> Firestore Database -> Rules
Replace the rules with this package's firestore.rules and Publish.

THEN BUILD
==========
Upload/commit this patch to GitHub.

Suggested commit:
Fix Rev 0.3.1 account permissions

Test:
1. Create Account
2. Create Club
3. Confirm home screen opens
4. Add a dog
5. Sign out
6. Sign back in
7. Confirm the club and dog are still there
8. Try Forgot Password

The web build is deliberately NOT added in this patch yet because the Firebase
Web app configuration has not been registered/provided. Once Android account
creation is proven, add the Web Firebase app and web build next.
