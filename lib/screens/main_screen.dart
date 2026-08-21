import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'authority_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotateController);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final input = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter all fields')));
      return;
    }

    setState(() { _isLoading = true; });

    if (input.contains('@')) {
      await _loginWithEmail(input.toLowerCase(), password);
    } else {
      await _resolveEmailAndLogin(input, password);
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _resolveEmailAndLogin(String id, String password) async {
    try {
      final client = Supabase.instance.client;
      final profileById = await client
          .from('profiles')
          .select('email_id')
          .or('student_id.eq.$id,faculty_id.eq.$id,email_id.eq.$id')
          .maybeSingle();

      if (profileById != null && profileById['email_id'] != null) {
        await _loginWithEmail(profileById['email_id'], password);
        return;
      }

      final adminById = await client
          .from('admins')
          .select('email')
          .eq('admin_id', id)
          .maybeSingle();

      if (adminById != null && adminById['email'] != null) {
        await _loginWithEmail(adminById['email'], password);
        return;
      }

      _showError("Account not found. Please register first.");
    } catch (e) {
      _showError("Connection error. Please check your internet and try again.");
    }
  }

  Future<void> _loginWithEmail(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (response.session != null) {
        await _handleLoginSuccess(email, response.session!.accessToken, response.user!);
      }
    } on AuthException catch (error) {
      _showError("Login failed: ${error.message}");
    } catch (e) {
      _showError("Unexpected error during login. Check your connection.");
    }
  }

  Future<void> _handleLoginSuccess(String email, String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_id', user.id);
    await prefs.setString('email', email);
    await prefs.setBool('is_logged_in', true);

    try {
      final client = Supabase.instance.client;
      Map<String, dynamic>? userData;
      bool isFromAdminTable = false;

      var adminResponse = await client.from('admins').select().eq('id', user.id).maybeSingle();
      if (adminResponse == null) {
        adminResponse = await client.from('admins').select().eq('email', email).maybeSingle();
      }

      if (adminResponse != null) {
        userData = adminResponse;
        isFromAdminTable = true;
      } else {
        final profileResponse = await client.from('profiles').select().eq('id', user.id).maybeSingle();
        if (profileResponse != null) {
          userData = profileResponse;
          isFromAdminTable = false;
        }
      }

      if (userData != null) {
        final String role = isFromAdminTable ? 'Admin' : (userData['user_role'] ?? 'Student').toString();
        final bool isActive = isFromAdminTable ? true : (userData['is_active'] != false);

        if (!isActive) {
          _showError("Your account has been deactivated.");
          return;
        }

        await prefs.setString('name', userData['full_name'] ?? 'User');
        await prefs.setString('role', role);
        await prefs.setString('department', userData['department'] ?? '');
        
        if (role != 'Student' && role != 'Admin') {
          if (userData['is_approved'] != true) {
            _showError("Your authority account is pending Admin approval.");
            return;
          }
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthorityDashboardScreen()));
          return;
        }

        if (mounted) {
          if (role == 'Admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          }
        }
      } else {
        _showError("Profile not found. Please contact support.");
      }
    } catch (e) {
      _showError("Sync error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    const double logoLogicalSize = 250.0;
    const Color brandingNavy = Color(0xFF1A237E);
    const Color brandingPurple = Color(0xFF9C27B0);
    const Color brandingOrange = Color(0xFFFF6D00);

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) => Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: Image.asset('assets/LOGO.png', width: logoLogicalSize, height: logoLogicalSize, fit: BoxFit.contain),
                      ),
                    ),
                    ClipOval(
                      child: Container(
                        width: logoLogicalSize * 0.49,
                        height: logoLogicalSize * 0.49,
                        color: theme.scaffoldBackgroundColor,
                        child: OverflowBox(
                          minWidth: logoLogicalSize,
                          maxWidth: logoLogicalSize,
                          minHeight: logoLogicalSize,
                          maxHeight: logoLogicalSize,
                          child: Image.asset('assets/LOGO.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: brandingNavy,
                      letterSpacing: 1.2,
                      fontFamily: textTheme.displayLarge?.fontFamily,
                    ),
                    children: [
                      const TextSpan(text: 'SM'),
                      const TextSpan(text: 'Λ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: 'RT'),
                      const TextSpan(text: 'i', style: TextStyle(color: brandingPurple)),
                      const TextSpan(text: 'FY'),
                    ],
                  ),
                ),
                Text(
                  '· YOUR VOICE · OUR ACTION · BETTER CAMPUS ·',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    hintText: 'College Email / ID / USN',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: brandingOrange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandingOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('LOG IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        "Register Now",
                        style: TextStyle(color: brandingOrange, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
