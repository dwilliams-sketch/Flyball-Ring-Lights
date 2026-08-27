import 'package:flutter/material.dart';

import '../../services/app_repository.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final repo = AppRepository();
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final club = TextEditingController();
  final invite = TextEditingController();
  bool saving = false;
  bool hidePassword = true;
  String mode = 'create';

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    club.dispose();
    invite.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      final profile = mode == 'create'
          ? await repo.createClubAccount(
              displayName: name.text,
              email: email.text,
              password: password.text,
              clubName: club.text,
            )
          : await repo.joinClubAccount(
              displayName: name.text,
              email: email.text,
              password: password.text,
              inviteCode: invite.text,
            );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendly(e))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('email-already-in-use')) return 'That email already has an account.';
    if (s.contains('weak-password')) return 'Please use a stronger password (at least 6 characters).';
    if (s.contains('invalid-email')) return 'Please check the email address.';
    return s.replaceFirst('FirebaseException: ', '');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  const Text('Welcome aboard',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your club workspace or join your crew with an invite code.',
                    style: TextStyle(color: AppTheme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                    validator: (v) => !(v ?? '').contains('@') ? 'Please enter a valid email.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hidePassword = !hidePassword),
                        icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: (v) => (v ?? '').length < 6 ? 'Use at least 6 characters.' : null,
                  ),
                  const SizedBox(height: 22),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'create',
                        icon: Icon(Icons.flag_outlined),
                        label: Text('Create Club'),
                      ),
                      ButtonSegment(
                        value: 'join',
                        icon: Icon(Icons.group_add_outlined),
                        label: Text('Join Club'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (v) => setState(() => mode = v.first),
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
                      validator: (v) => mode == 'create' && (v ?? '').trim().isEmpty
                          ? 'Please enter your club name.'
                          : null,
                    )
                  else
                    TextFormField(
                      controller: invite,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Club invite code',
                        hintText: 'e.g. MENA-4827',
                        prefixIcon: Icon(Icons.key_outlined),
                      ),
                      validator: (v) => mode == 'join' && (v ?? '').trim().isEmpty
                          ? 'Please enter the invite code.'
                          : null,
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: saving ? null : _submit,
                    child: Text(saving ? 'SETTING UP…' : 'CONTINUE'),
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
