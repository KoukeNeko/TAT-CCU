import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/ecourse_auth_repository.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      await context.read<EcourseAuthRepository>().signIn();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('登入失敗：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // The four function colors as cookies: the app's mark.
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    for (final (i, t) in tones.cycle.indexed)
                      Positioned(
                        left: [0.0, 120.0, 40.0, 170.0][i],
                        top: [0.0, 20.0, 100.0, 110.0][i],
                        child: Container(
                          width: [130.0, 90.0, 100.0, 70.0][i],
                          height: [130.0, 90.0, 100.0, 70.0][i],
                          decoration: ShapeDecoration(
                            color: t.fill,
                            shape: const [
                              scallop,
                              clover,
                              spikyStar,
                              scallop,
                            ][i],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('TAT CCU', style: Theme.of(context).textTheme.displaySmall),
              const Spacer(),
              // One CAS sign-in covers both: the eCourse2 launch flow signs
              // in to CAS in the system sheet, then returns to the app with
              // the token, and campus systems reuse that CAS session.
              FilledButton(
                onPressed: _busy ? null : _signIn,
                child: const Text('以單一入口登入'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
