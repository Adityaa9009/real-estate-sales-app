import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/dashboard_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RealEstateSalesApp());
}

enum AppRole { admin, executive, insideSales, outsideSales }

extension AppRoleDetails on AppRole {
  String get label => switch (this) {
    AppRole.admin => 'Admin',
    AppRole.executive => 'Executive',
    AppRole.insideSales => 'Inside Sales',
    AppRole.outsideSales => 'Outside Sales',
  };

  IconData get icon => switch (this) {
    AppRole.admin => Icons.admin_panel_settings_outlined,
    AppRole.executive => Icons.manage_accounts_outlined,
    AppRole.insideSales => Icons.support_agent_outlined,
    AppRole.outsideSales => Icons.location_on_outlined,
  };

  /// Maps the exact Firestore `role` string (per docs/DATABASE_SCHEMA.md)
  /// to an [AppRole]. Returns null for any unrecognized value.
  static AppRole? fromFirestoreValue(String? value) => switch (value) {
    'admin' => AppRole.admin,
    'executive' => AppRole.executive,
    'inside_sales' => AppRole.insideSales,
    'outside_sales' => AppRole.outsideSales,
    _ => null,
  };
}

class RealEstateSalesApp extends StatelessWidget {
  const RealEstateSalesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Real Estate Sales',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      useMaterial3: true,
    ),
    home: const LoginPage(),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = credential.user?.uid;
      if (uid == null) {
        throw StateError('Sign in succeeded but no user was returned.');
      }

      final employeeDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(uid)
          .get();

      if (!employeeDoc.exists) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _error =
              'No employee record found for this account. Contact your administrator.';
        });
        return;
      }

      final data = employeeDoc.data()!;
      final active = data['active'] as bool? ?? false;
      if (!active) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _error =
              'This employee account is inactive. Contact your administrator.';
        });
        return;
      }

      final role = AppRoleDetails.fromFirestoreValue(data['role'] as String?);
      if (role == null) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _error = 'This account does not have an authorized role.';
        });
        return;
      }

      if (!mounted) return;

      if (role == AppRole.insideSales) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const DashboardShell(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RoleHomePage(role: role, email: email),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _messageForAuthError(e));
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.home_work_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Welcome back', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to the Real Estate Sales App.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
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

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({super.key, required this.role, required this.email});

  final AppRole role;
  final String email;

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Estate Sales'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(role.icon, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    '${role.label} Dashboard',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(email, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  const Text(
                    'Role routing is working. This temporary page will be '
                    'replaced by the assigned team member’s module.',
                    textAlign: TextAlign.center,
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