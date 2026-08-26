import 'package:flutter/material.dart';

import '../services/local_profile_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'onboarding/create_account_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final profile = await LocalProfileService().load();
    if (!mounted) return;

    if (profile != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
      );
      return;
    }

    setState(() => checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.gold, width: 2),
                    ),
                    child: const Icon(
                      Icons.traffic_rounded,
                      size: 48,
                      color: AppTheme.gold,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'FLYBALL\nRING LIGHTS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      height: .98,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'by Menai Muttineers',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 42),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('NEW HERE?  CREATE ACCOUNT'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateAccountScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('ALREADY REGISTERED?  SIGN IN'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('Online sign-in comes in Rev 0.2'),
                          content: Text(
                            'Rev 0.1 keeps the timing engine local while we prove the lights, timer and sound. Firebase club login and invitations are the next layer.',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'REV 0.1 · LOCAL RING PROTOTYPE',
                    style: TextStyle(
                      color: Colors.white30,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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
