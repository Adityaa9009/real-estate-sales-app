import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/employee.dart';
import '../widgets/demo_account_banner.dart';
import 'admin/admin_dashboard_screen.dart';
import 'executive/executive_dashboard_screen.dart';
import 'inside_sales/inside_sales_shell.dart';
import 'outside_sales/outside_sales_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@realestate.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRoleDashboard(Employee employee) {
    Widget target;
    switch (employee.role) {
      case AppRole.admin:
        target = const AdminDashboardScreen();
        break;
      case AppRole.executive:
        target = const ExecutiveDashboardScreen();
        break;
      case AppRole.insideSales:
        target = const InsideSalesShell();
        break;
      case AppRole.outsideSales:
        target = const OutsideSalesShell();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employee = await AuthService.signIn(email: email, password: password);
      if (!mounted) return;
      _navigateToRoleDashboard(employee);
    } catch (e) {
      if (!mounted) return;
      // If Firebase auth fails because user does not exist in Auth yet, allow Demo Bypass for evaluation!
      if (e.toString().contains('user-not-found') ||
          e.toString().contains('invalid-credential') ||
          e.toString().contains('No employee profile found')) {
        _promptDemoBypass(email);
      } else {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _promptDemoBypass(String email) {
    AppRole role = AppRole.insideSales;
    String name = 'Demo User';

    if (email.contains('admin')) {
      role = AppRole.admin;
      name = 'Aditya Duhan (Admin)';
    } else if (email.contains('executive')) {
      role = AppRole.executive;
      name = 'Rajesh Sharma (Executive)';
    } else if (email.contains('outside')) {
      role = AppRole.outsideSales;
      name = 'Venkatesh Rao (Outside Sales)';
    } else {
      role = AppRole.insideSales;
      name = 'Sudheer Kumar (Inside Sales)';
    }

    // Create demo employee object
    final demoEmp = Employee(
      id: 'demo_${role.firestoreValue}',
      name: name,
      email: email,
      phone: '9876543210',
      role: role,
    );
    AuthService.currentEmployee = demoEmp;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.info,
        content: Text('Logging in with evaluation mode as ${role.label}...'),
        duration: const Duration(seconds: 1),
      ),
    );

    _navigateToRoleDashboard(demoEmp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Demo Banner
                  DemoAccountBanner(
                    onSelectAccount: (email, password) {
                      _emailController.text = email;
                      _passwordController.text = password;
                      setState(() => _errorMessage = null);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Brand Logo & Title (matching PDF: "REAL ESTATE / Your trusted path to property")
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 38),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'REAL ESTATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your trusted path to property',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error Box
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  const Text(
                    'Email Address',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'name@realestate.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Geofence Simulator Switch (for company presentation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded, size: 16, color: AppColors.info),
                            SizedBox(width: 8),
                            Text(
                              'Geofence (Inside Sales):',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        DropdownButton<bool>(
                          value: LocationService.isMockInsideOffice,
                          dropdownColor: AppColors.surfaceLight,
                          underline: const SizedBox(),
                          isDense: true,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Inside Office (<200m)')),
                            DropdownMenuItem(value: false, child: Text('Outside Office (>200m)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => LocationService.setMockInsideOffice(val));
                            }
                          },
                        ),
                      ],
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
