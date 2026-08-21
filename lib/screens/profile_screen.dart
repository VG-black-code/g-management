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
  final TextEditingController _studentDeptCtrl = TextEditingController();
  final TextEditingController _studentYearCtrl = TextEditingController();
  final TextEditingController _studentCollegeCtrl = TextEditingController();
  final TextEditingController _studentProgramCtrl = TextEditingController();
  
  final TextEditingController _adminIdCtrl = TextEditingController();
  final TextEditingController _positionCtrl = TextEditingController();
  
  final TextEditingController _facultyIdCtrl = TextEditingController();
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
    
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _userId)
          .maybeSingle();

      if (data != null) {
        final profile = UserProfile.fromJson(data);
        setState(() {
          _currentRole = profile.userRole ?? 'Student';
          _nameCtrl.text = profile.fullName ?? '';
          _emailCtrl.text = profile.emailId ?? '';
          _phoneCtrl.text = profile.mobileNumber ?? '';
          _dobCtrl.text = profile.dob ?? '';
          _selectedGender = profile.gender ?? 'Male';
          _encodedImage = profile.profileImage ?? '';
          
          if (_currentRole == 'Student') {
            _studentIdCtrl.text = profile.studentId ?? '';
            _studentDeptCtrl.text = profile.department ?? '';
            _studentYearCtrl.text = profile.year ?? '';
            _studentCollegeCtrl.text = profile.collegeName ?? '';
            _studentProgramCtrl.text = profile.program ?? '';
          } else if (_currentRole == 'Admin') {
            _adminIdCtrl.text = profile.adminId ?? '';
            _studentDeptCtrl.text = profile.department ?? '';
            _positionCtrl.text = profile.position ?? '';
          } else if (_currentRole == 'Faculty') {
            _facultyIdCtrl.text = profile.facultyId ?? '';
            _studentDeptCtrl.text = profile.department ?? '';
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
    
    final profile = UserProfile(
      id: _userId,
      fullName: _nameCtrl.text.trim(),
      emailId: _emailCtrl.text.trim(),
      mobileNumber: _phoneCtrl.text.trim(),
      gender: _selectedGender,
      userRole: _currentRole,
      dob: _dobCtrl.text.trim(),
      profileImage: _encodedImage,
      department: _studentDeptCtrl.text.trim(),
      studentId: _currentRole == 'Student' ? _studentIdCtrl.text.trim() : null,
      year: _currentRole == 'Student' ? _studentYearCtrl.text.trim() : null,
      collegeName: _currentRole == 'Student' ? _studentCollegeCtrl.text.trim() : null,
      program: _currentRole == 'Student' ? _studentProgramCtrl.text.trim() : null,
      adminId: _currentRole == 'Admin' ? _adminIdCtrl.text.trim() : null,
      position: _currentRole == 'Admin' ? _positionCtrl.text.trim() : null,
      facultyId: _currentRole == 'Faculty' ? _facultyIdCtrl.text.trim() : null,
      designation: _currentRole == 'Faculty' ? _designationCtrl.text.trim() : null,
    );

    try {
      await Supabase.instance.client.from('profiles').upsert(profile.toJson());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', profile.fullName ?? '');
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

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
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
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        backgroundImage: _encodedImage.isNotEmpty 
                          ? MemoryImage(base64Decode(_encodedImage)) 
                          : null,
                        child: _encodedImage.isEmpty 
                          ? Icon(Icons.person, size: 60, color: colorScheme.primary) 
                          : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: InkWell(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 20, 
                          backgroundColor: colorScheme.primary, 
                          child: Icon(Icons.camera_alt, color: colorScheme.onPrimary, size: 20)
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildField(_nameCtrl, 'Full Name', Icons.person),
                const SizedBox(height: 16),
                _buildField(_emailCtrl, 'Email', Icons.email, enabled: false),
                const SizedBox(height: 16),
                _buildField(_phoneCtrl, 'Mobile Number', Icons.phone, keyboard: TextInputType.phone),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField(_dobCtrl, 'DOB', Icons.cake, readOnly: true, onTap: _pickDate)),
                    const SizedBox(width: 16),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
                      items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) => setState(() => _selectedGender = val!),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(_studentDeptCtrl, 'Department', Icons.business),
                const SizedBox(height: 16),
                
                if (_currentRole == 'Student') ...[
                  _buildField(_studentIdCtrl, 'Student ID', Icons.badge),
                  const SizedBox(height: 16),
                  _buildField(_studentProgramCtrl, 'Program', Icons.school),
                  const SizedBox(height: 16),
                  _buildField(_studentYearCtrl, 'Year', Icons.calendar_today),
                  const SizedBox(height: 16),
                  _buildField(_studentCollegeCtrl, 'College Name', Icons.account_balance),
                ] else if (_currentRole == 'Admin') ...[
                  _buildField(_adminIdCtrl, 'Admin ID', Icons.badge),
                  const SizedBox(height: 16),
                  _buildField(_positionCtrl, 'Position', Icons.work),
                ] else if (_currentRole == 'Faculty') ...[
                  _buildField(_facultyIdCtrl, 'Faculty ID', Icons.badge),
                  const SizedBox(height: 16),
                  _buildField(_designationCtrl, 'Designation', Icons.work),
                ],
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('UPDATE PROFILE'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool enabled = true, bool readOnly = false, VoidCallback? onTap, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
