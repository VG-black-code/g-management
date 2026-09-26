import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'dashboard_screen.dart';
import 'posh/posh_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _idController = TextEditingController(); 
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Student';
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isPoshMode = false;
  String _emailUsedForOtp = '';
  
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _mobileController.dispose();
    _idController.dispose();
    _deptController.dispose();
    _yearController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() { _secondsLeft = 60; });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() { _secondsLeft--; });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkEmailAndSendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Email! Please include a domain like ".com"'),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Check in all tables if email exists
      final client = Supabase.instance.client;
      final student = await client.from('profiles').select('id').eq('email_id', email).maybeSingle();
      final faculty = await client.from('faculty').select('id').eq('Email', email).maybeSingle();
      final admin = await client.from('admins').select('id').eq('email', email).maybeSingle();

      if (student != null || faculty != null || admin != null) {
        _stopProcess('Email already registered.');
        return;
      }
      await _sendEmailOtpInternal(email);
    } catch (e) {
      await _sendEmailOtpInternal(email); 
    }
  }

  void _stopProcess(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 6),
    ));
  }

  Future<void> _sendEmailOtpInternal(String email) async {
    _emailUsedForOtp = email;
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
      _startTimer();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP sent to $email')));
    } catch (e) {
      _stopProcess('Failed to send OTP: ${e.toString()}');
    }
  }

  bool _validateForm() {
    if (_fullNameController.text.trim().isEmpty) return false;
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('.')) return false;
    if (_otpController.text.trim().isEmpty) return false;
    if (_passwordController.text.trim().length < 6) return false;
    if (_passwordController.text != _confirmPasswordController.text) return false;
    if (_idController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _verifyAndRegister() async {
    setState(() => _isLoading = true);
    final String email = _emailController.text.trim().toLowerCase();
    final String token = _otpController.text.trim();
    final types = [OtpType.signup, OtpType.email, OtpType.magiclink];
    
    for (var type in types) {
      try {
        final response = await Supabase.instance.client.auth.verifyOTP(
          email: email,
          token: token,
          type: type,
        );
        if (response.session != null) {
          await _finalizeAccount(response.user!.id, response.session!.accessToken);
          return;
        }
      } catch (e) {
        debugPrint("Verification failed for type $type: $e");
      }
    }
    _stopProcess('Verification failed. Token may be expired or invalid.');
  }

  Future<void> _finalizeAccount(String userId, String token) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
      
      final String name = _fullNameController.text.trim();
      final String email = _emailController.text.trim().toLowerCase();
      final String phone = _mobileController.text.trim();
      final String inputId = _idController.text.trim();
      final String department = _deptController.text.trim();
      
      final client = Supabase.instance.client;

      if (_selectedRole == 'Student') {
        // 1. Save to profiles table (STUDENTS ONLY)
        final studentPayload = {
          'id': userId,
          'full_name': name,
          'email_id': email,
          'mobile_number': phone,
          'user_role': 'Student',
          'department': department,
          'student_id': inputId,
          'year': _yearController.text.trim(),
          'is_approved': true,
          'is_active': true,
        };
        await client.from('profiles').upsert(studentPayload);
      } 
      else if (['Teacher', 'HOD', 'Dean', 'Principal', 'POSH Officer', 'POSH Head'].contains(_selectedRole)) {
        if (['POSH Officer', 'POSH Head'].contains(_selectedRole)) {
          // Save to posh_authorized_users table
          await client.from('posh_authorized_users').upsert({
            'user_id': userId,
            'full_name': name,
            'email': email,
            'mobile_number': phone,
            'employee_id': inputId,
            'department': department,
            'role': _selectedRole,
            'is_approved': false,
          });
        } else {
          // Save to faculty table (AUTHORITIES ONLY)
          final facultyData = FacultyProfile(
            id: userId,
            fullName: name,
            email: email,
            mobileNumber: phone,
            employeeId: inputId,
            department: department,
            role: _selectedRole,
            status: 'pending',
          ).toJson();
          await client.from('faculty').upsert(facultyData);
        }
        
        // Notify Admin
        await _sendAdminNotification('New Authority Access Request', '$name registered as $_selectedRole and is waiting for approval.');
      } 
      else if (_selectedRole == 'Admin') {
        // 3. Save to admins table (ADMINS ONLY)
        await client.from('admins').upsert({
          'id': userId,
          'full_name': name,
          'email': email,
          'mobile_number': phone,
          'admin_id': inputId,
          'is_approved': false, // Needs Super Admin approval
        });

        // Notify Super Admin
        await _sendAdminNotification('New Admin Registration', '$name has registered as an Admin and needs your approval.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('user_id', userId);
      await prefs.setString('email', email);
      await prefs.setString('name', name);
      await prefs.setString('role', _selectedRole);
      await prefs.setBool('is_logged_in', true);

      setState(() => _isLoading = false);
      if (mounted) {
        if (_selectedRole == 'Student') {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (r) => false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Registration Successful! Please wait for approval before accessing your dashboard.'),
            duration: Duration(seconds: 5),
          ));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _stopProcess('Registration failed: ${e.toString()}');
    }
  }

  Future<void> _sendAdminNotification(String title, String message) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'title': title,
        'message': message,
        'target_role': 'Admin',
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        actions: [
          IconButton(
            icon: Icon(Icons.shield, color: _isPoshMode ? poshPurple : null),
            onPressed: () {
              setState(() {
                _isPoshMode = !_isPoshMode;
                _selectedRole = _isPoshMode ? 'POSH Officer' : 'Student';
              });
            },
            tooltip: 'POSH Authority Registration',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Select Role', 
                    prefixIcon: Icon(_isPoshMode ? Icons.shield : Icons.person_pin),
                    prefixIconColor: _isPoshMode ? poshPurple : null,
                  ),
                  items: (_isPoshMode 
                      ? ['POSH Officer', 'POSH Head'] 
                      : Constants.roles
                  ).map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
                const SizedBox(height: 24),
                _buildField('Full Name', _fullNameController, Icons.person),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField('Email (include .com)', _emailController, Icons.email, type: TextInputType.emailAddress)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _secondsLeft > 0 ? null : _checkEmailAndSendOtp,
                      child: Text(_secondsLeft > 0 ? '${_secondsLeft}s' : 'Get OTP'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('OTP', _otpController, Icons.lock_clock, type: TextInputType.number),
                const SizedBox(height: 16),
                _buildField('Mobile Number', _mobileController, Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 16),
                _buildField(_selectedRole == 'Student' ? 'Student ID / USN' : (_selectedRole == 'Admin' ? 'Admin ID' : 'Employee ID'), _idController, Icons.badge),
                
                if (_selectedRole != 'Principal' && _selectedRole != 'Admin' && _selectedRole != 'POSH Head') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business)),
                    items: Constants.departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) => _deptController.text = val!,
                  ),
                ],

                if (_selectedRole == 'Student') ...[
                  const SizedBox(height: 16),
                  _buildField('Academic Year (e.g. 1st Year)', _yearController, Icons.calendar_today),
                ],

                const SizedBox(height: 16),
                _buildField('Password', _passwordController, Icons.lock, obscure: true),
                const SizedBox(height: 16),
                _buildField('Confirm Password', _confirmPasswordController, Icons.lock_outline, obscure: true),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    if (_validateForm()) _verifyAndRegister();
                    else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields correctly')));
                  },
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTER'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, IconData icon, {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
    );
  }
}
