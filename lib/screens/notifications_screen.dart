import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _userName = '';
  String _userRole = '';
  String _userDept = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('name') ?? '';
    _userRole = prefs.getString('role') ?? 'Student';
    _userDept = prefs.getString('department') ?? '';
    
    if (_userName.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final isAdmin = _userRole == 'Admin';
      
      // Clean name for filtering
      String cleanName = _userName.contains(' / ') ? _userName.split(' / ')[0].trim() : _userName;
      
      // Role-based recipient strings (e.g., "HOD-BCA", "Teacher-MCA")
      String roleTarget = _userRole;
      if (_userDept.isNotEmpty && (_userRole == 'Teacher' || _userRole == 'HOD')) {
        roleTarget = '$_userRole-$_userDept';
      }

      var query = client.from('notifications').select();
      
      String filter = "user_name.eq.$cleanName,user_name.eq.Broadcast";
      if (isAdmin) filter += ",user_name.eq.Admin";
      if (_userRole != 'Student') filter += ",user_name.eq.$roleTarget,user_name.eq.$_userRole";

      final data = await query.or(filter).order('id', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = (data as List).map((j) => AppNotification.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchNotifications,
            child: _notifications.isEmpty
              ? Center(child: Text('No new alerts.', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isBroadcast = notif.userName == 'Broadcast';
                    
                    return Card(
                      color: notif.isRead ? colorScheme.surface : colorScheme.primaryContainer.withOpacity(0.1),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBroadcast ? Colors.orange : colorScheme.primary,
                          child: Icon(isBroadcast ? Icons.campaign : Icons.notifications, color: Colors.white),
                        ),
                        title: Text(notif.title ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(notif.message ?? ''),
                        onTap: () {
                          // Mark as read and potentially navigate to IssueDetails
                        },
                      ),
                    );
                  },
                ),
          ),
    );
  }
}
