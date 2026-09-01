import 'package:flutter/material.dart';

void main() => runApp(const RealEstateSalesApp());

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
  AppRole _selectedRole = AppRole.admin;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    final email = _emailController.text.trim();
    if (email.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RoleHomePage(role: _selectedRole, email: email),
      ),
    );
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
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<AppRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Test role (temporary)',
                        border: OutlineInputBorder(),
                      ),
                      items: AppRole.values
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.label),
                            ),
                          )
                          .toList(),
                      onChanged: (role) {
                        if (role != null) setState(() => _selectedRole = role);
                      },
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
                      onPressed: _signIn,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Sign in'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'For now, enter any email and password, choose a role, '
                      'and sign in. Firebase will replace this test mode.',
                      style: theme.textTheme.bodySmall,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Estate Sales'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              (route) => false,
            ),
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
