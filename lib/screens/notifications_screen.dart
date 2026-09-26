import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'issue_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Stream<List<Map<String, dynamic>>>? _notificationStream;
  String _userId = '';
  String _userRole = '';
  String _userDept = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _setupRealtimeNotifications();
  }

  Future<void> _setupRealtimeNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _userId = user.id;
    }

    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('name') ?? '';
    _userRole = prefs.getString('role') ?? 'Student';
    _userDept = prefs.getString('department') ?? '';

    // Logic for realtime stream
    // We want to hear about notifications targeted to:
    // 1. Specific User ID (Student who raised the complaint)
    // 2. Specific User Name (legacy/fallback)
    // 3. User's Role (Teacher, HOD, etc.)
    // 4. Broadcasts
    
    final client = Supabase.instance.client;
    
    // Using a simple stream and filtering in-app for complex OR conditions 
    // because Supabase realtime stream filtering is limited.
    _notificationStream = client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('id', ascending: false)
        .limit(50);

    if (mounted) setState(() {});
  }

  bool _shouldShowNotification(Map<String, dynamic> data) {
    final notifUserId = data['user_id']?.toString();
    final notifUserName = data['user_name']?.toString();
    final targetRole = data['target_role']?.toString();
    final dept = data['department']?.toString();

    // 1. Direct match for User ID
    if (_userId.isNotEmpty && notifUserId == _userId) return true;

    // 2. Match for User Name
    if (_userName.isNotEmpty && notifUserName == _userName) return true;

    // 3. Match for Broadcast
    if (notifUserName == 'Broadcast') return true;

    // 4. Match for Admin
    if (_userRole == 'Admin' && (notifUserName == 'Admin' || targetRole == 'Admin')) return true;

    // 5. Match for Role & Dept
    if (targetRole == _userRole) {
      if (dept == null || dept.isEmpty || dept == _userDept) return true;
    }

    return false;
  }

  Future<void> _markAsRead(int id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error marking read: $e');
    }
  }

  Future<void> _navigateToIssue(int issueId) async {
    try {
      final data = await Supabase.instance.client
          .from('issues')
          .select()
          .eq('id', issueId)
          .single();
      
      if (mounted) {
        final issue = Issue.fromJson(data);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => IssueDetailsScreen(issue: issue)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load complaint details')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              // Mark all as read logic could go here
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: _notificationStream == null
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notificationStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredList = snapshot.data!
                  .where((data) => _shouldShowNotification(data))
                  .map((data) => AppNotification.fromJson(data))
                  .toList();

              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No notifications yet', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final notif = filteredList[index];
                  final isRead = notif.isRead;
                  final isBroadcast = notif.userName == 'Broadcast';
                  
                  return Card(
                    elevation: isRead ? 0 : 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: isRead ? Colors.grey.shade200 : colorScheme.primary.withOpacity(0.5),
                        width: isRead ? 1 : 2,
                      ),
                    ),
                    color: isRead ? Colors.white : colorScheme.primaryContainer.withOpacity(0.05),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isRead ? Colors.grey.shade200 : (isBroadcast ? Colors.orange : colorScheme.primary),
                        child: Icon(
                          isBroadcast ? Icons.campaign : Icons.notifications, 
                          color: isRead ? Colors.grey : Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notif.title ?? 'Update', 
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          color: isRead ? Colors.grey.shade700 : Colors.black,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notif.message ?? '', style: TextStyle(color: isRead ? Colors.grey : Colors.black87)),
                          const SizedBox(height: 8),
                          Text(
                            notif.createdAt != null 
                              ? _formatTimestamp(notif.createdAt!) 
                              : '', 
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (notif.id != null) _markAsRead(notif.id!);
                        if (notif.issueId != null) {
                          _navigateToIssue(notif.issueId!);
                        }
                      },
                      trailing: !isRead ? Container(width: 8, height: 8, decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)) : null,
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
