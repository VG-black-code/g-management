import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/complaints_provider.dart';
import 'issue_details_screen.dart';
import 'profile_screen.dart';
import 'main_screen.dart';
import 'notifications_screen.dart';
import 'users_list_screen.dart';
import 'complaint_analytics_screen.dart';
import 'all_complaints_screen.dart';
import 'broadcast_screen.dart';

// --- Dashboard Role Configuration Architecture ---
class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const QuickAction({required this.label, required this.icon, required this.onTap});
}

class RoleMenu {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const RoleMenu({required this.label, required this.icon, required this.onTap});
}

class DashboardConfig {
  final String roleTitle;
  final Color accentColor;
  final List<QuickAction> actions;
  final List<RoleMenu> drawerMenus;
  final List<BottomNavItem> navItems;

  const DashboardConfig({
    required this.roleTitle,
    required this.accentColor,
    required this.actions,
    required this.drawerMenus,
    required this.navItems,
  });
}

class BottomNavItem {
  final String label;
  final IconData icon;
  const BottomNavItem({required this.label, required this.icon});
}

class AuthorityDashboardScreen extends StatefulWidget {
  const AuthorityDashboardScreen({super.key});

  @override
  State<AuthorityDashboardScreen> createState() => _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState extends State<AuthorityDashboardScreen> {
  UserProfile? _profile;
  bool _isLoadingProfile = true;
  int _selectedIndex = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadProfile();
    if (_profile != null) {
      _fetchComplaints();
      _fetchNotificationCount();
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoadingProfile = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _profile = UserProfile.fromJson(data);
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _fetchComplaints() {
    if (_profile == null) return;
    
    // We pass the profile ID as userId to enable specific assignment filtering
    context.read<ComplaintsProvider>().fetchComplaints(
      role: _profile!.userRole!,
      dept: _profile!.department,
      userId: _profile!.id, 
      course: _profile!.course,
      year: _profile!.year,
      section: _profile!.section,
      assignedDepts: _profile!.assignedDepartments,
    );
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final displayName = _profile!.fullName?.split(' / ')[0] ?? '';
      final response = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_name', displayName)
          .eq('is_read', false);
      if (mounted) {
        setState(() {
          _unreadNotifications = (response as List).length;
        });
      }
    } catch (_) {}
  }

  void _goToReports(String filter, String title) {
    final issues = context.read<ComplaintsProvider>().issues;
    Navigator.push(context, MaterialPageRoute(builder: (_) => AllComplaintsScreen(
      initialIssues: issues,
      screenTitle: title,
      statusFilter: filter == 'All' ? null : filter,
    )));
  }

  void _goToUsers() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersListScreen()));
  }

  void _goToAnalytics() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintAnalyticsScreen()));
  }

  void _goToBroadcast() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen()));
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    }
  }

  DashboardConfig _getRoleConfig() {
    final role = _profile?.userRole ?? 'Teacher';
    
    switch (role) {
      case 'HOD':
        return DashboardConfig(
          roleTitle: 'HOD Dashboard',
          accentColor: const Color(0xFF2196F3), 
          actions: [
            QuickAction(label: 'Review Reports', icon: Icons.rate_review, onTap: () => _goToReports('Pending', 'Pending Reports')),
            QuickAction(label: 'Forward Reports', icon: Icons.forward_to_inbox, onTap: () => _goToReports('Forwarded', 'Forwarded Reports')),
            QuickAction(label: 'Dept Overview', icon: Icons.business, onTap: _goToAnalytics),
          ],
          navItems: [
            const BottomNavItem(label: 'Dashboard', icon: Icons.dashboard),
            const BottomNavItem(label: 'Reports', icon: Icons.assignment),
            const BottomNavItem(label: 'Department', icon: Icons.account_balance),
            const BottomNavItem(label: 'Profile', icon: Icons.person),
          ],
          drawerMenus: [
            RoleMenu(label: 'Dashboard', icon: Icons.home, onTap: () {}),
            RoleMenu(label: 'Department Reports', icon: Icons.list_alt, onTap: () => _goToReports('All', 'Department Reports')),
            RoleMenu(label: 'Pending Reports', icon: Icons.timer, onTap: () => _goToReports('Pending', 'Pending Reports')),
            RoleMenu(label: 'Resolved Reports', icon: Icons.check_circle, onTap: () => _goToReports('Resolved', 'Resolved Reports')),
            RoleMenu(label: 'Teachers', icon: Icons.supervisor_account, onTap: _goToUsers),
            RoleMenu(label: 'Students', icon: Icons.group, onTap: _goToUsers),
            RoleMenu(label: 'Department Overview', icon: Icons.analytics, onTap: _goToAnalytics),
          ],
        );
      case 'Dean':
        return DashboardConfig(
          roleTitle: 'Dean Dashboard',
          accentColor: const Color(0xFF4CAF50), 
          actions: [
            QuickAction(label: 'Review Reports', icon: Icons.assignment_turned_in, onTap: () => _goToReports('Pending', 'Pending Reports')),
            QuickAction(label: 'Forward to Principal', icon: Icons.escalator, onTap: () => _goToReports('Forwarded', 'Forwarded Reports')),
            QuickAction(label: 'Faculty Overview', icon: Icons.supervised_user_circle, onTap: _goToUsers),
          ],
          navItems: [
            const BottomNavItem(label: 'Dashboard', icon: Icons.dashboard),
            const BottomNavItem(label: 'Reports', icon: Icons.assignment),
            const BottomNavItem(label: 'Departments', icon: Icons.lan),
            const BottomNavItem(label: 'Profile', icon: Icons.person),
          ],
          drawerMenus: [
            RoleMenu(label: 'Dashboard', icon: Icons.home, onTap: () {}),
            RoleMenu(label: 'All Escalated Reports', icon: Icons.call_made, onTap: () => _goToReports('All', 'Escalated Reports')),
            RoleMenu(label: 'Pending Reports', icon: Icons.timer, onTap: () => _goToReports('Pending', 'Pending Reports')),
            RoleMenu(label: 'Resolved Reports', icon: Icons.check_circle, onTap: () => _goToReports('Resolved', 'Resolved Reports')),
            RoleMenu(label: 'Departments', icon: Icons.business, onTap: _goToUsers),
            RoleMenu(label: 'Faculty', icon: Icons.group, onTap: _goToUsers),
            RoleMenu(label: 'Analytics', icon: Icons.analytics, onTap: _goToAnalytics),
          ],
        );
      case 'Principal':
        return DashboardConfig(
          roleTitle: 'Principal Dashboard',
          accentColor: const Color(0xFFE53935), 
          actions: [
            QuickAction(label: 'Review All Reports', icon: Icons.manage_search, onTap: () => _goToReports('All', 'All Reports')),
            QuickAction(label: 'Broadcast Notice', icon: Icons.campaign, onTap: _goToBroadcast),
            QuickAction(label: 'Campus Overview', icon: Icons.map, onTap: _goToAnalytics),
          ],
          navItems: [
            const BottomNavItem(label: 'Dashboard', icon: Icons.dashboard),
            const BottomNavItem(label: 'Reports', icon: Icons.assignment),
            const BottomNavItem(label: 'Users', icon: Icons.people),
            const BottomNavItem(label: 'Profile', icon: Icons.person),
          ],
          drawerMenus: [
            RoleMenu(label: 'Dashboard', icon: Icons.home, onTap: () {}),
            RoleMenu(label: 'All Reports', icon: Icons.list, onTap: () => _goToReports('All', 'All Reports')),
            RoleMenu(label: 'Pending Reports', icon: Icons.timer, onTap: () => _goToReports('Pending', 'Pending Reports')),
            RoleMenu(label: 'Resolved Reports', icon: Icons.check_circle, onTap: () => _goToReports('Resolved', 'Resolved Reports')),
            RoleMenu(label: 'Departments', icon: Icons.lan, onTap: _goToUsers),
            RoleMenu(label: 'Faculty', icon: Icons.supervisor_account, onTap: _goToUsers),
            RoleMenu(label: 'Students', icon: Icons.school, onTap: _goToUsers),
            RoleMenu(label: 'Analytics', icon: Icons.bar_chart, onTap: _goToAnalytics),
            RoleMenu(label: 'Broadcast Notice', icon: Icons.add_alert, onTap: _goToBroadcast),
            RoleMenu(label: 'Campus Overview', icon: Icons.view_quilt, onTap: _goToAnalytics),
          ],
        );
      default: // Teacher
        return DashboardConfig(
          roleTitle: 'Teacher Dashboard',
          accentColor: const Color(0xFF673AB7), 
          actions: [
            QuickAction(label: 'Review Reports', icon: Icons.fact_check, onTap: () => _goToReports('Pending', 'Pending Reports')),
            QuickAction(label: 'Approve Students', icon: Icons.how_to_reg, onTap: _goToUsers),
            QuickAction(label: 'Campus Map', icon: Icons.explore, onTap: () {}),
          ],
          navItems: [
            const BottomNavItem(label: 'Dashboard', icon: Icons.dashboard),
            const BottomNavItem(label: 'Reports', icon: Icons.assignment),
            const BottomNavItem(label: 'Students', icon: Icons.group),
            const BottomNavItem(label: 'Profile', icon: Icons.person),
          ],
          drawerMenus: [
            RoleMenu(label: 'Dashboard', icon: Icons.home, onTap: () {}),
            RoleMenu(label: 'My Reports', icon: Icons.my_library_books, onTap: () => _goToReports('All', 'My Reports')),
            RoleMenu(label: 'Pending Reports', icon: Icons.timer, onTap: () => _goToReports('Pending', 'Pending Reports')),
            RoleMenu(label: 'Resolved Reports', icon: Icons.check_circle, onTap: () => _goToReports('Resolved', 'Resolved Reports')),
            RoleMenu(label: 'Approve Students', icon: Icons.verified_user, onTap: _goToUsers),
            RoleMenu(label: 'Students', icon: Icons.school, onTap: _goToUsers),
            RoleMenu(label: 'Campus Map', icon: Icons.map, onTap: () {}),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profile == null) return const Scaffold(body: Center(child: Text('Unauthorized Access')));

    final config = _getRoleConfig();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(config.roleTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, size: 28),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 12, top: 12,
                  child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(config),
      body: RefreshIndicator(
        onRefresh: () async => _loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(config),
              _buildStatsSection(config),
              _buildQuickActions(config),
              _buildRecentComplaintsSection(config),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(config),
    );
  }

  Widget _buildWelcomeSection(DashboardConfig config) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello,', style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text('Prof. ${_profile!.fullName?.split(' ').first}!', 
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                Text(_profile!.userRole == 'Teacher' 
                    ? '${_profile!.department} Department'
                    : '${_profile!.department ?? "Institution Administration"}', 
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 32,
            backgroundColor: config.accentColor.withOpacity(0.1),
            backgroundImage: _profile!.profileImage != null && _profile!.profileImage!.isNotEmpty
                ? MemoryImage(base64Decode(_profile!.profileImage!.split(',').last)) 
                : null,
            child: (_profile!.profileImage == null || _profile!.profileImage!.isEmpty)
                ? Icon(Icons.person, size: 35, color: config.accentColor) 
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(DashboardConfig config) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, child) {
        final issues = provider.issues;
        final pending = issues.where((e) => e.status != 'RESOLVED' && e.status != 'REJECTED').length;
        final resolved = issues.where((e) => e.status == 'RESOLVED').length;

        return Container(
          height: 140,
          margin: const EdgeInsets.symmetric(vertical: 20),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildStatCard('Total Reports', issues.length, 'Assigned to you', Colors.indigo.shade600, Icons.assignment),
              _buildStatCard('Pending Solve', pending, 'Needs attention', Colors.orange.shade800, Icons.pending_actions),
              _buildStatCard('Resolved', resolved, 'Successfully solved', Colors.green.shade700, Icons.check_circle_outline),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, String subtitle, Color color, IconData icon) {
    return Container(
      width: 165,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text('$count', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(DashboardConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: config.actions.length,
            itemBuilder: (context, index) {
              final action = config.actions[index];
              return Container(
                width: 115,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: config.accentColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(action.icon, color: config.accentColor, size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(action.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentComplaintsSection(DashboardConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => _goToReports('All', 'All Reports'), child: Text('View All', style: TextStyle(color: config.accentColor, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Consumer<ComplaintsProvider>(
          builder: (context, provider, child) {
            final issues = provider.issues;
            if (issues.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No complaints assigned yet.', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length > 5 ? 5 : issues.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) => _buildComplaintCard(issues[index], config),
            );
          },
        ),
      ],
    );
  }

  Widget _buildComplaintCard(Issue issue, DashboardConfig config) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IssueDetailsScreen(issue: issue))).then((_) => _loadAllData()),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildThumb(issue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(issue.status ?? 'Pending'),
                          if (issue.priority != null)
                            Text(issue.priority!.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _getPriorityColor(issue.priority!))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(issue.problemType ?? 'Grievance', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${issue.category} • #CMP${issue.id}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(Issue issue) {
    return Container(
      width: 65, height: 65,
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: issue.photoUrl != null && issue.photoUrl!.isNotEmpty
            ? (issue.photoUrl!.contains('/videos/') 
                ? const Center(child: Icon(Icons.videocam, color: Colors.grey))
                : Image.network(issue.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image)))
            : const Icon(Icons.description_outlined, color: Colors.grey, size: 28),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PENDING': color = Colors.red; break;
      case 'PROCESSING': 
      case 'IN PROGRESS': color = Colors.orange; break;
      case 'RESOLVED': color = Colors.green; break;
      case 'REJECTED': color = Colors.grey; break;
      case 'FORWARDED': color = Colors.blue; break;
      default: color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Widget _buildBottomNav(DashboardConfig config) {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: config.accentColor,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == config.navItems.length - 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          if (index == 1) _goToReports('All', 'All Reports');
          if (index == 2) _goToUsers();
        },
        items: config.navItems.map((item) => BottomNavigationBarItem(icon: Icon(item.icon), label: item.label)).toList(),
      ),
    );
  }

  Widget _buildDrawer(DashboardConfig config) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: config.accentColor),
            accountName: Text(_profile!.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(_profile!.userRole ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: _profile!.profileImage != null && _profile!.profileImage!.isNotEmpty
                ? MemoryImage(base64Decode(_profile!.profileImage!.split(',').last)) 
                : null,
              child: (_profile!.profileImage == null || _profile!.profileImage!.isEmpty)
                ? Icon(Icons.person, color: config.accentColor) 
                : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.dashboard, 'Dashboard', () => Navigator.pop(context)),
                ...config.drawerMenus.map((menu) => _buildDrawerItem(menu.icon, menu.label, () {
                  Navigator.pop(context);
                  menu.onTap();
                })),
                _buildDrawerItem(Icons.notifications, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                _buildDrawerItem(Icons.person, 'Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _logout(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
