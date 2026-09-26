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
      _showError('Please enter both Email/ID and Password');
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
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    final str = value.toString().toLowerCase();
    return str == 'true' || str == '1' || str == 'approved' || str == 'active' || str == 'success';
  }

  Future<void> _resolveEmailAndLogin(String id, String password) async {
    try {
      final client = Supabase.instance.client;
      
      // Order of precedence for ID search
      final admin = await client.from('admins').select('email').eq('admin_id', id).maybeSingle();
      if (admin != null) {
        await _loginWithEmail(admin['email'], password);
        return;
      }

      final faculty = await client.from('faculty').select('Email').eq('EmployeeID', id).maybeSingle();
      if (faculty != null) {
        await _loginWithEmail(faculty['Email'], password);
        return;
      }

      final student = await client.from('profiles').select('email_id').eq('student_id', id).maybeSingle();
      if (student != null) {
        await _loginWithEmail(student['email_id'], password);
        return;
      }

      _showError("Account ID '$id' is not registered.");
    } catch (e) {
      _showError("Database lookup failed.");
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
      _showError(error.message);
    } catch (e) {
      _showError("Login failed.");
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
      final normalizedEmail = email.toLowerCase().trim();
      
      // 1. COMPREHENSIVE ADMIN CHECK (Check admins table by ID or Email)
      var adminData = await client.from('admins').select().eq('id', user.id).maybeSingle();
      if (adminData == null) {
        adminData = await client.from('admins').select().eq('email', normalizedEmail).maybeSingle();
      }
      
      if (adminData != null) {
        if (_isTruthy(adminData['is_approved'])) {
          await _saveUserSession(prefs, adminData['full_name'] ?? adminData['FullName'] ?? 'Admin', 'Admin', adminData['department'] ?? '', adminData['profile_image']);
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          return;
        } else {
          _showError("Admin account pending verification.");
          return;
        }
      }

      // 2. COMPREHENSIVE FACULTY CHECK (Check faculty table by ID or Email)
      var facultyData = await client.from('faculty').select().eq('id', user.id).maybeSingle();
      if (facultyData == null) {
        facultyData = await client.from('faculty').select().eq('Email', normalizedEmail).maybeSingle();
      }
      
      if (facultyData != null) {
        final status = facultyData['Status'] ?? facultyData['status'] ?? facultyData['is_approved'];
        if (_isTruthy(status)) {
          final String rawRole = facultyData['role'] ?? facultyData['user_role'] ?? 'Teacher';
          final String name = facultyData['FullName'] ?? facultyData['full_name'] ?? 'Faculty';
          final String dept = facultyData['Department'] ?? facultyData['department'] ?? '';
          
          if (rawRole.toLowerCase() == 'admin') {
            await _saveUserSession(prefs, name, 'Admin', dept, facultyData['profile_image']);
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          } else {
            await _saveUserSession(prefs, name, rawRole, dept, facultyData['profile_image']);
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthorityDashboardScreen()));
          }
          return;
        } else {
          _showError("Institutional account pending approval.");
          return;
        }
      }

      // 3. COMPREHENSIVE PROFILES CHECK (Fallback for Students and others)
      var profileData = await client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profileData == null) {
        profileData = await client.from('profiles').select().eq('email_id', normalizedEmail).maybeSingle();
      }
      
      if (profileData != null) {
        final String rawRole = profileData['user_role'] ?? profileData['role'] ?? 'Student';
        final String normalizedRole = rawRole.trim().toLowerCase();
        final String name = profileData['full_name'] ?? profileData['FullName'] ?? 'User';
        final String dept = profileData['department'] ?? '';
        final String? image = profileData['profile_image'] ?? profileData['ProfileImage'];
        
        await _saveUserSession(prefs, name, rawRole, dept, image);
        
        if (mounted) {
          if (normalizedRole == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
          } else if (['teacher', 'hod', 'dean', 'principal', 'faculty'].contains(normalizedRole)) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthorityDashboardScreen()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          }
        }
        return;
      }

      _showError("Login successful, but no database record found for $normalizedEmail.");
    } catch (e) {
      _showError("Session synchronization error.");
    }
  }

  Future<void> _saveUserSession(SharedPreferences prefs, String? name, String role, String dept, String? image) async {
    await prefs.setString('name', name ?? 'User');
    await prefs.setString('role', role);
    await prefs.setString('department', dept);
    if (image != null) await prefs.setString('profileImage', image);
  }

  @override
  Widget build(BuildContext context) {
    const Color brandNavy = Color(0xFF1A237E);
    const Color brandPurple = Color(0xFF9C27B0);
    const Color brandOrange = Color(0xFFFF6D00);

    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).colorScheme.primary.withOpacity(0.05), Theme.of(context).scaffoldBackgroundColor],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _rotateAnimation,
                  builder: (context, child) => Transform.rotate(
                    angle: _rotateAnimation.value,
                    child: Image.asset('assets/LOGO.png', width: 220, height: 220),
                  ),
                ),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: brandNavy, letterSpacing: 1.2),
                    children: [
                      TextSpan(text: 'SM'),
                      TextSpan(text: 'Λ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'RT'),
                      TextSpan(text: 'i', style: TextStyle(color: brandPurple)),
                      TextSpan(text: 'FY'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text('* YOUR VOICE * OUR ACTION * BETTER CAMPUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 40),
                TextField(
                  controller: _identifierController,
                  decoration: const InputDecoration(
                    hintText: 'Email / ID / USN', 
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot Password?', style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandOrange, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('LOG IN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text("Register Now", style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold)),
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
