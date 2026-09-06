import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../models/employee.dart';
import '../widgets/demo_account_banner.dart';
import 'admin/admin_dashboard_screen.dart';
import 'executive/executive_dashboard_screen.dart';
import 'inside_sales/inside_sales_shell.dart';
import 'outside_sales/outside_sales_shell.dart';

extension on Widget {
  Widget safeAnimate({
    Duration duration = const Duration(milliseconds: 350),
    Duration delay = Duration.zero,
    double slideY = 0.08,
  }) {
    if (WidgetsBinding.instance is! WidgetsFlutterBinding) {
      return this;
    }
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .slideY(begin: slideY, end: 0);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => target));
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
      final employee = await AuthService.signIn(
        email: email,
        password: password,
      );
      if (!mounted) return;
      _navigateToRoleDashboard(employee);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('StateError: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient background glows
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(20),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withAlpha(16),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    decoration: CardStyles.primary(
                      color: AppColors.surfaceLight.withAlpha(220),
                      borderRadius: 24,
                      glowColor: AppColors.primary,
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand Logo & Title (matching PDF: "REAL ESTATE / Your trusted path to property")
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(90),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ).safeAnimate(duration: const Duration(milliseconds: 400)),
                        const SizedBox(height: 14),
                        Text(
                          'REAL ESTATE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.sora(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.textPrimary,
                          ),
                        ).safeAnimate(
                          delay: const Duration(milliseconds: 80),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your trusted path to property',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ).safeAnimate(
                          delay: const Duration(milliseconds: 140),
                        ),
                        const SizedBox(height: 32),

                        // Error Box
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.danger.withAlpha(100),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Field
                        Text(
                          'Email Address',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ).safeAnimate(
                          delay: const Duration(milliseconds: 180),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'name@realestate.com',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ).safeAnimate(
                          delay: const Duration(milliseconds: 200),
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        Text(
                          'Password',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ).safeAnimate(
                          delay: const Duration(milliseconds: 240),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ).safeAnimate(
                          delay: const Duration(milliseconds: 260),
                        ),
                        const SizedBox(height: 28),

                        // Login Button
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(80),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ).safeAnimate(
                          delay: const Duration(milliseconds: 300),
                        ),

                        const SizedBox(height: 24),

                        // Section divider before demo banner
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'QUICK DEMO SIGN-IN',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Demo Accounts Quick Tap Autofill
                        DemoAccountBanner(
                          onSelectAccount: (email, password) {
                            setState(() {
                              _emailController.text = email;
                              if (password.isNotEmpty) {
                                _passwordController.text = password;
                              }
                              _errorMessage = null;
                            });
                          },
                        ).safeAnimate(
                          delay: const Duration(milliseconds: 340),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
