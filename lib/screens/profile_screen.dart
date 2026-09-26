import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String _currentRole = 'Student';
  String _userId = '';
  
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  String _selectedGender = 'Male';
  
  final TextEditingController _studentIdCtrl = TextEditingController();
  final TextEditingController _deptCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();
  final TextEditingController _collegeCtrl = TextEditingController();
  final TextEditingController _programCtrl = TextEditingController();
  
  final TextEditingController _adminIdCtrl = TextEditingController();
  final TextEditingController _positionCtrl = TextEditingController();
  
  final TextEditingController _employeeIdCtrl = TextEditingController();
  final TextEditingController _designationCtrl = TextEditingController();
  
  String _encodedImage = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? '';
    _currentRole = prefs.getString('role') ?? 'Student';
    
    try {
      final client = Supabase.instance.client;
      Map<String, dynamic>? data;

      if (_currentRole == 'Student') {
        data = await client.from('profiles').select().eq('id', _userId).maybeSingle();
      } else if (['Teacher', 'HOD', 'Dean', 'Principal'].contains(_currentRole)) {
        data = await client.from('faculty').select().eq('id', _userId).maybeSingle();
      } else if (_currentRole == 'Admin') {
        data = await client.from('admins').select().eq('id', _userId).maybeSingle();
      }

      if (data != null) {
        final profile = UserProfile.fromJson(data);
        setState(() {
          _nameCtrl.text = profile.fullName ?? '';
          _emailCtrl.text = profile.emailId ?? '';
          _phoneCtrl.text = profile.mobileNumber ?? '';
          _dobCtrl.text = profile.dob ?? '';
          _selectedGender = profile.gender ?? 'Male';
          _encodedImage = profile.profileImage ?? '';
          _deptCtrl.text = profile.department ?? '';
          
          if (_currentRole == 'Student') {
            _studentIdCtrl.text = profile.studentId ?? '';
            _yearCtrl.text = profile.year ?? '';
            _collegeCtrl.text = profile.collegeName ?? '';
            _programCtrl.text = profile.program ?? '';
          } else if (_currentRole == 'Admin') {
            _adminIdCtrl.text = profile.adminId ?? '';
            _positionCtrl.text = profile.position ?? '';
          } else { // Faculty Roles
            _employeeIdCtrl.text = profile.facultyId ?? '';
            _designationCtrl.text = profile.designation ?? '';
          }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _encodedImage = base64Encode(bytes);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;
    
    try {
      if (_currentRole == 'Student') {
        final payload = {
          'id': _userId,
          'full_name': _nameCtrl.text.trim(),
          'mobile_number': _phoneCtrl.text.trim(),
          'gender': _selectedGender,
          'dob': _dobCtrl.text.trim(),
          'profile_image': _encodedImage,
          'department': _deptCtrl.text.trim(),
          'student_id': _studentIdCtrl.text.trim(),
          'year': _yearCtrl.text.trim(),
          'college_name': _collegeCtrl.text.trim(),
          'program': _programCtrl.text.trim(),
        };
        await client.from('profiles').upsert(payload);
      } 
      else if (['Teacher', 'HOD', 'Dean', 'Principal'].contains(_currentRole)) {
        final payload = {
          'id': _userId,
          'FullName': _nameCtrl.text.trim(),
          'MobileNumber': _phoneCtrl.text.trim(),
          'EmployeeID': _employeeIdCtrl.text.trim(),
          'Department': _deptCtrl.text.trim(),
          'profile_image': _encodedImage, // Adding common fields for UI sync
          'designation': _designationCtrl.text.trim(),
        };
        await client.from('faculty').upsert(payload);
      } 
      else if (_currentRole == 'Admin') {
        final payload = {
          'id': _userId,
          'full_name': _nameCtrl.text.trim(),
          'mobile_number': _phoneCtrl.text.trim(),
          'admin_id': _adminIdCtrl.text.trim(),
          'position': _positionCtrl.text.trim(),
          'profile_image': _encodedImage,
        };
        await client.from('admins').upsert(payload);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _nameCtrl.text.trim());
      await prefs.setString('profileImage', _encodedImage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = const Color(0xFF673AB7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: primary.withOpacity(0.1),
                        backgroundImage: _encodedImage.isNotEmpty 
                          ? MemoryImage(base64Decode(_encodedImage.split(',').last)) 
                          : null,
                        child: _encodedImage.isEmpty 
                          ? Icon(Icons.person, size: 60, color: primary) 
                          : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: InkWell(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 20, 
                          backgroundColor: primary, 
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildField(_nameCtrl, 'Full Name', Icons.person, primary),
                const SizedBox(height: 16),
                _buildField(_emailCtrl, 'Email Address', Icons.email, primary, enabled: false),
                const SizedBox(height: 16),
                _buildField(_phoneCtrl, 'Mobile Number', Icons.phone, primary, keyboard: TextInputType.phone),
                
                if (_currentRole == 'Student') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildField(_dobCtrl, 'DOB', Icons.cake, primary, readOnly: true, onTap: _pickDate)),
                      const SizedBox(width: 16),
                      Expanded(child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender', 
                          prefixIcon: Icon(Icons.wc, color: primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) => setState(() => _selectedGender = val!),
                      )),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                _buildField(_deptCtrl, 'Department', Icons.business, primary),
                
                if (_currentRole == 'Student') ...[
                  const SizedBox(height: 16),
                  _buildField(_studentIdCtrl, 'Student ID / USN', Icons.badge, primary),
                  const SizedBox(height: 16),
                  _buildField(_programCtrl, 'Program / Course', Icons.school, primary),
                  const SizedBox(height: 16),
                  _buildField(_yearCtrl, 'Academic Year', Icons.calendar_today, primary),
                ] else if (_currentRole == 'Admin') ...[
                  const SizedBox(height: 16),
                  _buildField(_adminIdCtrl, 'Admin ID', Icons.badge, primary),
                  const SizedBox(height: 16),
                  _buildField(_positionCtrl, 'Position', Icons.work, primary),
                ] else ...[ // Faculty roles
                  const SizedBox(height: 16),
                  _buildField(_employeeIdCtrl, 'Employee ID', Icons.badge, primary),
                  const SizedBox(height: 16),
                  _buildField(_designationCtrl, 'Designation', Icons.work, primary),
                ],
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('UPDATE PROFILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, Color color, {bool enabled = true, bool readOnly = false, VoidCallback? onTap, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}
