import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDetailsScreen({super.key, required this.userData});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  bool _isLoading = false;
  late UserProfile _user;

  @override
  void initState() {
    super.initState();
    _user = UserProfile.fromJson(widget.userData);
  }

  Future<void> _updateApprovalStatus(bool approve) async {
    final action = approve ? 'Approve' : 'Reject';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action User?'),
        content: Text('Are you sure you want to ${action.toLowerCase()} this user? This will update the database immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action, style: TextStyle(color: approve ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      
      // 1. Update profiles table
      final List<dynamic> profileResponse = await client.from('profiles').update({
        'is_approved': approve,
        'is_active': approve, 
      }).eq('id', _user.id).select();

      if (profileResponse.isEmpty) {
        throw 'The database rejected the update. Please ensure your Supabase RLS Policies allow the "Admin" role to update rows.';
      }

      // 2. Update faculty table if user is an authority (Teacher, HOD, Dean, Principal)
      if (['Teacher', 'HOD', 'Dean', 'Principal'].contains(_user.userRole)) {
        await client.from('faculty').update({
          'status': approve ? 'approved' : 'rejected',
          'is_approved': approve,
        }).eq('id', _user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'User approved and database updated!' : 'User rejected'), 
            backgroundColor: approve ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pop(context, true); // Send 'true' back to UsersListScreen to trigger a refresh
      }
    } catch (e) {
      debugPrint("Database Update Error: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Database Error'),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStudent = _user.userRole == 'Student';
    // Approval only required for non-students (excluding Admin)
    final isPending = !_user.isApproved && !isStudent && _user.userRole != 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('User Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(theme),
                const SizedBox(height: 24),
                _buildInfoSection(theme),
                const SizedBox(height: 30),
                if (isPending) _buildApprovalButtons(),
                const SizedBox(height: 20),
                _buildAccountStatusSection(),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final isStudent = _user.userRole == 'Student';
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.purple[50],
            backgroundImage: (_user.profileImage != null && _user.profileImage!.isNotEmpty)
                ? MemoryImage(base64Decode(_user.profileImage!.split(',').last))
                : null,
            child: _user.profileImage == null ? const Icon(Icons.person, size: 60, color: Colors.purple) : null,
          ),
          const SizedBox(height: 16),
          Text(_user.fullName ?? 'Unknown', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${_user.userRole} • ${_user.department ?? "No Department"}', 
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
          if (!isStudent && _user.userRole != 'Admin') ...[
            const SizedBox(height: 12),
            _buildStatusBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isApproved = _user.isApproved;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isApproved ? Colors.green[200]! : Colors.orange[200]!),
      ),
      child: Text(
        isApproved ? 'APPROVED' : 'PENDING APPROVAL',
        style: TextStyle(
          color: isApproved ? Colors.green[700] : Colors.orange[700],
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IDENTIFICATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildDetailItem('User ID', _user.studentId ?? _user.facultyId ?? 'N/A'),
          const Divider(height: 30),
          const Text('INSTITUTIONAL DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildDetailItem('Department', _user.department ?? 'N/A'),
          if (_user.userRole == 'Student') ...[
            _buildDetailItem('Course', _user.course ?? 'N/A'),
            _buildDetailItem('Year', _user.year ?? 'N/A'),
            _buildDetailItem('Section', _user.section ?? 'N/A'),
            _buildDetailItem('Semester', _user.semester ?? 'N/A'),
          ],
          if (_user.userRole == 'Teacher') ...[
             _buildDetailItem('Subject/Course', _user.course ?? 'N/A'),
          ],
          const Divider(height: 30),
          const Text('CONTACT INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildDetailItem('Email', _user.emailId ?? 'N/A'),
          _buildDetailItem('Phone', _user.mobileNumber ?? 'N/A'),
          const Divider(height: 30),
          const Text('ACCOUNT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildDetailItem('Registered Date', _user.joiningDate ?? 'N/A'),
          _buildDetailItem('Account Status', _user.isActive ? 'Active' : 'Inactive'),
          if (_user.userRole != 'Student' && _user.userRole != 'Admin')
            _buildDetailItem('Approval Status', _user.isApproved ? 'Approved' : 'Pending'),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildApprovalButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateApprovalStatus(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _updateApprovalStatus(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStatusSection() {
    return Center(
      child: TextButton(
        onPressed: () async {
          setState(() => _isLoading = true);
          try {
            final client = Supabase.instance.client;
            final bool newActiveStatus = !_user.isActive;

            await client.from('profiles').update({
              'is_active': newActiveStatus,
            }).eq('id', _user.id);

            // If it's a faculty member (including Principal), also update their status in faculty table
            if (['Teacher', 'HOD', 'Dean', 'Principal'].contains(_user.userRole)) {
              await client.from('faculty').update({
                'status': newActiveStatus ? 'approved' : 'rejected',
                'is_approved': newActiveStatus,
              }).eq('id', _user.id);
            }

            if (mounted) {
              setState(() {
                _user = UserProfile(
                  id: _user.id,
                  fullName: _user.fullName,
                  emailId: _user.emailId,
                  mobileNumber: _user.mobileNumber,
                  gender: _user.gender,
                  userRole: _user.userRole,
                  studentId: _user.studentId,
                  facultyId: _user.facultyId,
                  department: _user.department,
                  course: _user.course,
                  program: _user.program,
                  year: _user.year,
                  section: _user.section,
                  semester: _user.semester,
                  collegeName: _user.collegeName,
                  dob: _user.dob,
                  adminId: _user.adminId,
                  position: _user.position,
                  designation: _user.designation,
                  profileImage: _user.profileImage,
                  joiningDate: _user.joiningDate,
                  isApproved: _user.isApproved,
                  isActive: newActiveStatus,
                );
                _isLoading = false;
              });
            }
          } catch (e) {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        child: Text(_user.isActive ? 'DEACTIVATE ACCOUNT' : 'ACTIVATE ACCOUNT', 
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
