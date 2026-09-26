import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/complaints_provider.dart';
import '../main.dart';
import 'issue_details_screen.dart';
import 'profile_screen.dart';
import 'main_screen.dart';
import 'notifications_screen.dart';
import 'users_list_screen.dart';
import 'complaint_analytics_screen.dart';
import 'all_complaints_screen.dart';
import 'posh/posh_home_screen.dart';
import 'posh/posh_officer_dashboard.dart';
import 'posh/posh_widgets.dart';
import 'widgets/dialog_utils.dart';

class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const QuickAction({required this.label, required this.icon, required this.onTap});
}

class DashboardConfig {
  final String roleTitle;
  final Color accentColor;
  final List<QuickAction> actions;
  final List<BottomNavItem> navItems;

  const DashboardConfig({
    required this.roleTitle,
    required this.accentColor,
    required this.actions,
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
  bool _isPoshOfficer = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _checkPoshRole();
  }

  Future<void> _loadAllData() async {
    await _loadProfile();
    if (_profile != null) {
      _fetchComplaints();
      _fetchNotificationCount();
    }
  }

  Future<void> _checkPoshRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('posh_authorized_users')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        if (mounted) {
          setState(() {
            _isPoshOfficer = data != null;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoadingProfile = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final savedRole = prefs.getString('role') ?? 'Teacher';

    try {
      final client = Supabase.instance.client;
      
      // Try fetching from faculty table
      var data = await client.from('faculty').select().eq('id', userId).maybeSingle();
      
      // Fallback to profiles table if not found in faculty
      if (data == null) {
        data = await client.from('profiles').select().eq('id', userId).maybeSingle();
      }

      if (mounted) {
        setState(() {
          if (data != null) {
            _profile = UserProfile.fromJson(data);
          } else {
            // Construct a minimal profile from prefs as a safe fallback
            _profile = UserProfile(
              id: userId,
              fullName: prefs.getString('name') ?? 'Faculty',
              userRole: savedRole,
              department: prefs.getString('department') ?? '',
              isApproved: true,
            );
          }
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _fetchComplaints() {
    if (_profile == null) return;
    context.read<ComplaintsProvider>().fetchComplaints(
      role: _profile!.userRole!,
      dept: _profile!.department,
      userId: _profile!.id,
      assignedDepts: _profile!.assignedDepartments,
    );
  }

  Future<void> _fetchNotificationCount() async {
    try {
      if (_profile == null) return;
      final client = Supabase.instance.client;
      String filter = 'user_id.eq.${_profile!.id},target_role.eq.${_profile!.userRole}';
      if (_isPoshOfficer) {
        filter += ',target_role.eq.posh_officer';
      }

      final response = await client
          .from('notifications')
          .select('id')
          .or(filter)
          .eq('is_read', false);
      if (mounted) {
        setState(() {
          _unreadNotifications = (response as List).length;
        });
      }
    } catch (_) {}
  }

  void _goToReports(String? filter, String title) {
    final provider = context.read<ComplaintsProvider>();
    Navigator.push(context, MaterialPageRoute(builder: (_) => AllComplaintsScreen(
      initialIssues: provider.issues,
      screenTitle: title,
      statusFilter: filter,
    )));
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
    final role = _profile?.userRole ?? 'Authority';
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    
    final List<QuickAction> actions = [
      QuickAction(label: 'My Tasks', icon: Icons.fact_check, onTap: () => _goToReports('Pending', 'Assigned Reports')),
      QuickAction(label: 'Students', icon: Icons.group, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersListScreen()))),
      QuickAction(label: 'Analytics', icon: Icons.bar_chart, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintAnalyticsScreen()))),
    ];

    if (_isPoshOfficer) {
      actions.insert(0, QuickAction(
        label: 'POSH Cases', 
        icon: Icons.admin_panel_settings, 
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoshOfficerDashboard()))
      ));
    }
    
    return DashboardConfig(
      roleTitle: '$role Dashboard',
      accentColor: accentColor,
      actions: actions,
      navItems: [
        const BottomNavItem(label: 'Dashboard', icon: Icons.dashboard),
        const BottomNavItem(label: 'Reports', icon: Icons.assignment),
        const BottomNavItem(label: 'Users', icon: Icons.group),
        const BottomNavItem(label: 'Profile', icon: Icons.person),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final config = _getRoleConfig();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(config.roleTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showThemeDialog(context),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, size: 28),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _fetchNotificationCount()),
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
      drawer: _buildHamburgerMenu(),
      body: RefreshIndicator(
        onRefresh: () async => _loadAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(config),
              _buildStatsGrid(config),
              _buildQuickActionsGrid(config),
              _buildRecentComplaintsList(config),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(config),
    );
  }

  Widget _buildWelcomeBanner(DashboardConfig config) {
    String? profileImg = _profile?.profileImage;
    return Container(
      padding: const EdgeInsets.all(20),
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
                const Text('Hello Prof,', style: TextStyle(color: Colors.grey)),
                Text(_profile?.fullName ?? 'Faculty', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('${_profile?.department ?? "All"} Dept', style: TextStyle(color: config.accentColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 30,
            backgroundColor: config.accentColor.withOpacity(0.1),
            backgroundImage: profileImg != null && profileImg.isNotEmpty
              ? MemoryImage(base64Decode(profileImg.split(',').last)) 
              : null,
            child: (profileImg == null || profileImg.isEmpty) 
              ? Icon(Icons.person, color: config.accentColor) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardConfig config) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, _) {
        final issues = provider.issues;
        final pending = issues.where((e) => e.status != 'RESOLVED').length;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _buildStatCard('Active Cases', pending, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard('Total Assigned', issues.length, config.accentColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(DashboardConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: config.actions.length,
            itemBuilder: (context, index) {
              final action = config.actions[index];
              return InkWell(
                onTap: action.onTap,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(backgroundColor: config.accentColor.withOpacity(0.1), child: Icon(action.icon, color: config.accentColor)),
                      const SizedBox(height: 8),
                      Text(action.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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

  Widget _buildRecentComplaintsList(DashboardConfig config) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, _) {
        final issues = provider.issues;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.all(20), child: Text('Recent Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            if (issues.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No grievances assigned.')))
            else ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length > 5 ? 5 : issues.length,
              itemBuilder: (context, index) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.description_outlined)),
                title: Text(issues[index].problemType ?? 'Issue'),
                subtitle: Text('#CMP${issues[index].id} • ${issues[index].status}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IssueDetailsScreen(issue: issues[index]))).then((_) => _loadAllData()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav(DashboardConfig config) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: config.accentColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        setState(() => _selectedIndex = i);
        if (i == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        if (i == 1) _goToReports(null, 'All Reports');
        if (i == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersListScreen()));
      },
      items: config.navItems.map((n) => BottomNavigationBarItem(icon: Icon(n.icon), label: n.label)).toList(),
    );
  }

  Widget _buildHamburgerMenu() {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    
    return Drawer(
      child: Column(
        children: [
          // Custom Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, bottom: 24, right: 24),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(50)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: _profile?.profileImage != null && _profile!.profileImage!.isNotEmpty
                    ? MemoryImage(base64Decode(_profile!.profileImage!.split(',').last)) 
                    : null,
                  child: (_profile?.profileImage == null || _profile!.profileImage!.isEmpty) 
                    ? Icon(Icons.person, size: 35, color: accentColor) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile?.fullName?.split(' ').first ?? 'Faculty', 
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                      ),
                      Text(
                        _profile?.userRole ?? 'Authority', 
                        style: const TextStyle(color: Colors.white70, fontSize: 14)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSectionHeader('USER SECTION', accentColor),
                _buildMenuItem(Icons.person_outline, 'Update Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), accentColor),
                _buildMenuItem(Icons.assignment_outlined, 'Complaint Status', () => _goToReports(null, 'Complaint Status'), accentColor),
                _buildMenuItem(Icons.description_outlined, 'My Reports', () => _goToReports(null, 'My Reports'), accentColor),
                
                const Divider(indent: 20, endIndent: 20, height: 32),
                
                _buildSectionHeader('CONFIDENTIAL', accentColor),
                _buildMenuItem(Icons.shield, '🔐 POSH & Harassment', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoshHomeScreen())), accentColor, subtitle: 'Report harassment or abuse confidentially and securely'),

                if (_isPoshOfficer) ...[
                  const Divider(indent: 20, endIndent: 20, height: 32),
                  _buildSectionHeader('POSH MANAGEMENT', accentColor),
                  _buildMenuItem(Icons.admin_panel_settings, 'POSH Dashboard', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoshOfficerDashboard())), accentColor),
                ],

                const Divider(indent: 20, endIndent: 20, height: 32),
                
                _buildSectionHeader('SUPPORT SECTION', accentColor),
                _buildMenuItem(Icons.help_outline, 'Help / User Guide', () {}, accentColor),
                _buildMenuItem(Icons.headset_mic_outlined, 'Contact Support', () => showContactSupportDialog(context), accentColor),
                _buildMenuItem(Icons.info_outline, 'About App', () => showAboutSmartifyDialog(context), accentColor),
                _buildMenuItem(Icons.palette_outlined, 'Choose Theme', () => showThemeDialog(context), accentColor),

                const Divider(indent: 20, endIndent: 20, height: 32),

                _buildSectionHeader('REPORT MANAGEMENT', accentColor),
                _buildMenuItem(Icons.timer_outlined, 'Pending Reports', () => _goToReports('Pending', 'Pending Reports'), accentColor),
                _buildMenuItem(Icons.check_circle_outline, 'Resolved Reports', () => _goToReports('Resolved', 'Resolved Reports'), accentColor),
                _buildMenuItem(Icons.shield_outlined, 'Approve Reports', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersListScreen())), accentColor),

                const Divider(indent: 20, endIndent: 20, height: 32),

                _buildSectionHeader('ACCOUNT SECTION', accentColor),
                _buildMenuItem(Icons.lock_outline, 'Change Password', () {}, accentColor),
                _buildMenuItem(Icons.logout_outlined, 'Logout', _logout, Colors.red, isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 10, bottom: 8),
      child: Text(
        title, 
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, Color iconColor, {bool isDestructive = false, String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title, 
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87, 
          fontSize: 14, 
          fontWeight: FontWeight.w500
        )
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
      onTap: () {
        Navigator.pop(context); // Close drawer first
        onTap();
      },
      dense: subtitle == null,
      visualDensity: subtitle == null ? VisualDensity.compact : null,
    );
  }
}
