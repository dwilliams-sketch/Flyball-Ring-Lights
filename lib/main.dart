import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  Object? firebaseError;

  // Rev 0.2A connects Android first. Web remains the local prototype until
  // a separate Firebase Web app is registered later.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp().timeout(
        const Duration(seconds: 20),
      );
    } catch (error) {
      firebaseError = error;
    }
  }

  runApp(RingLightsApp(firebaseError: firebaseError));
}

class RingLightsApp extends StatelessWidget {
  final Object? firebaseError;

  const RingLightsApp({
    super.key,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flyball Ring Lights',
        theme: AppTheme.dark,
        home: firebaseError == null
            ? const WelcomeScreen()
            : FirebaseConnectionError(error: firebaseError!),
      );
}

class FirebaseConnectionError extends StatelessWidget {
  final Object error;

  const FirebaseConnectionError({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 72,
                    color: Colors.orangeAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'FIREBASE CONNECTION FAILED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The ring itself is safe — this screen only means the new '
                    'online connection did not start correctly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SelectableText(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
