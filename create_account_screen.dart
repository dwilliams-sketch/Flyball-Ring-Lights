import 'package:flutter/material.dart';

import '../../models/local_profile.dart';
import '../../services/local_profile_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final club = TextEditingController();
  final form = GlobalKey<FormState>();

  String mode = 'create';
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    club.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(form.currentState?.validate() ?? false)) return;

    if (mode == 'join') {
      await showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Club invitations arrive in Rev 0.2'),
          content: Text(
            'The final version will let you scan a QR code or enter the Captain’s invitation code. For Rev 0.1, choose Create a Club so we can test the local ring.',
          ),
        ),
      );
      return;
    }

    setState(() => saving = true);

    final profile = LocalProfile(
      displayName: name.text.trim(),
      email: email.text.trim(),
      clubName: club.text.trim(),
    );

    await LocalProfileService().save(profile);
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome aboard',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We’ll keep setup short. A Captain creates the club workspace, then invites the rest of the crew.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Please enter your name.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (value) => !(value ?? '').contains('@')
                          ? 'Please enter a valid email.'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'What are you here to do?',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'create',
                          icon: Icon(Icons.flag_outlined),
                          label: Text('Create a Club'),
                        ),
                        ButtonSegment(
                          value: 'join',
                          icon: Icon(Icons.group_add_outlined),
                          label: Text('Join My Club'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (values) {
                        setState(() => mode = values.first);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (mode == 'create')
                      TextFormField(
                        controller: club,
                        decoration: const InputDecoration(
                          labelText: 'Club name',
                          hintText: 'e.g. Menai Muttineers',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        validator: (value) =>
                            mode == 'create' && (value ?? '').trim().isEmpty
                                ? 'Please enter your club name.'
                                : null,
                      )
                    else
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_2, color: AppTheme.gold),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'In Rev 0.2 this becomes Scan Invite QR / Enter Invite Code.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: saving ? null : _continue,
                      child: Text(saving ? 'SETTING UP…' : 'CONTINUE'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rev 0.1 stores this prototype profile only on this device. No password is stored.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
