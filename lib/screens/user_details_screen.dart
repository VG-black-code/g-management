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
        content: Text('Confirming this will update the user status and send them a notification.'),
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
      final role = _user.userRole;

      if (role == 'Student') {
        await client.from('profiles').update({
          'is_approved': approve,
          'is_active': approve,
        }).eq('id', _user.id);
      } else if (['Teacher', 'HOD', 'Dean', 'Principal'].contains(role)) {
        await client.from('faculty').update({
          'Status': approve ? 'approved' : 'rejected',
        }).eq('id', _user.id);
      } else if (role == 'Admin') {
        await client.from('admins').update({
          'is_approved': approve,
        }).eq('id', _user.id);
      }

      // Send Notification to User
      await client.from('notifications').insert({
        'user_id': _user.id,
        'title': approve ? 'Account Approved' : 'Account Status Update',
        'message': approve 
            ? 'Your $role account has been approved. You can now access the full dashboard.'
            : 'Your registration request has been processed. Status: $action',
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User $action Successfully'), backgroundColor: approve ? Colors.green : Colors.red));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Approval Error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStudent = _user.userRole == 'Student';
    // Students are auto-approved in your system usually, so we check for others
    final isPending = !_user.isApproved && _user.userRole != 'Admin' || (_user.userRole == 'Admin' && !_user.isApproved);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FB),
      appBar: AppBar(
        title: const Text('User Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildInfoSection(),
                const SizedBox(height: 30),
                if (isPending) _buildApprovalButtons(),
                const SizedBox(height: 20),
                _buildDeactivateButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.purple[50],
            backgroundImage: (_user.profileImage != null && _user.profileImage!.isNotEmpty)
                ? MemoryImage(base64Decode(_user.profileImage!.split(',').last))
                : null,
            child: _user.profileImage == null ? const Icon(Icons.person, size: 50, color: Colors.purple) : null,
          ),
          const SizedBox(height: 16),
          Text(_user.fullName ?? 'Unknown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('${_user.userRole} • ${_user.department ?? "No Dept"}', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _buildDetailItem('User ID', _user.studentId ?? _user.facultyId ?? _user.adminId ?? 'N/A'),
          _buildDetailItem('Email', _user.emailId ?? 'N/A'),
          _buildDetailItem('Phone', _user.mobileNumber ?? 'N/A'),
          _buildDetailItem('Approval', _user.isApproved ? 'Approved' : 'Pending'),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildApprovalButtons() {
    return Row(
      children: [
        Expanded(child: OutlinedButton(onPressed: () => _updateApprovalStatus(false), child: const Text('REJECT', style: TextStyle(color: Colors.red)))),
        const SizedBox(width: 16),
        Expanded(child: ElevatedButton(onPressed: () => _updateApprovalStatus(true), child: const Text('APPROVE'))),
      ],
    );
  }

  Widget _buildDeactivateButton() {
    return TextButton(
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          await Supabase.instance.client.from('profiles').update({'is_active': !_user.isActive}).eq('id', _user.id);
          if (mounted) Navigator.pop(context, true);
        } catch (_) {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      child: Text(_user.isActive ? 'DEACTIVATE ACCOUNT' : 'ACTIVATE ACCOUNT', style: const TextStyle(color: Colors.red)),
    );
  }
}
