import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/complaints_provider.dart';
import '../main.dart';
import 'complaint_screen.dart';
import 'main_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'issue_details_screen.dart';
import 'issues_list_screen.dart';
import 'posh/posh_home_screen.dart';
import 'posh/posh_officer_dashboard.dart';
import 'posh/posh_widgets.dart';
import 'widgets/dialog_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _userName = 'User';
  String _userId = '';
  String? _profileImageUrl;
  bool _hasUnread = false;
  int _selectedIndex = 0;
  bool _isPoshOfficer = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkPoshRole();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('name') ?? 'User';
      _userId = prefs.getString('user_id') ?? '';
      _profileImageUrl = prefs.getString('profileImage');
    });
    
    if (_userId.isNotEmpty) {
      context.read<ComplaintsProvider>().fetchComplaints(role: 'Student', userId: _userId);
      _checkNotifications();
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

  Future<void> _checkNotifications() async {
    try {
      final displayName = _userName.contains(' / ') ? _userName.split(' / ')[0] : _userName;
      final client = Supabase.instance.client;
      
      var query = client.from('notifications').select().eq('is_read', false);
      if (_isPoshOfficer) {
        query = query.or('user_name.eq.$displayName,target_role.eq.posh_officer');
      } else {
        query = query.eq('user_name', displayName);
      }

      final data = await query;
      if (mounted) setState(() => _hasUnread = (data as List).isNotEmpty);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(theme),
      body: Consumer<ComplaintsProvider>(
        builder: (context, provider, child) {
          final issues = provider.issues;

          return Stack(
            children: [
              Container(height: 160, color: colorScheme.primary),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(theme),
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 16),
                              _buildCategoryGrid(),
                              const SizedBox(height: 32),
                              const Text('Recent History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 16),
                              _buildRecentIssues(issues),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen())),
        label: const Text('RAISE COMPLAINT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        icon: const Icon(Icons.add),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const IssuesListScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Issues'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    final displayName = _userName.contains(' / ') ? _userName.split(' / ')[0] : _userName;
    final role = _userName.contains(' / ') ? _userName.split(' / ')[1] : 'Student';
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                backgroundImage: _profileImageUrl != null ? MemoryImage(base64Decode(_profileImageUrl!)) : null,
                child: _profileImageUrl == null ? const Icon(Icons.person, color: Colors.white, size: 32) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5)),
                  Text(role, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.palette, color: Colors.white, size: 28),
              onPressed: () => showThemeDialog(context),
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: _hasUnread ? Colors.orangeAccent : Colors.white, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildCatCard('Classroom', Icons.edit),
        _buildCatCard('Facilities', Icons.photo_library),
        _buildCatCard('Hostel', Icons.flag),
        _buildCatCard('Lab / IT', Icons.calendar_month),
      ],
    );
  }

  Widget _buildCatCard(String title, IconData icon) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () {
         int catIdx = title == 'Classroom' || title == 'Lab / IT' ? 0 : 1;
         Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintScreen(categoryIndex: catIdx)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color.withOpacity(0.8), size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentIssues(List<Issue> issues) {
    if (issues.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No complaints raised.')));
    
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: issues.length > 5 ? 5 : issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IssueDetailsScreen(issue: issue))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: issue.photoUrl != null && issue.photoUrl!.isNotEmpty
                        ? _buildImage(issue.photoUrl!)
                        : _buildPlaceholderImage(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.problemType ?? 'Complaint',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Location: ${issue.location ?? 'Campus'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        _buildProgressBar(issue.status),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text('Comment', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(String photoUrl) {
    final String trimmed = photoUrl.trim();
    if (trimmed.startsWith('http')) {
      return Image.network(
        trimmed,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      );
    } else {
      try {
        return Image.memory(
          base64Decode(trimmed),
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[100],
      child: const Icon(Icons.image, color: Colors.grey, size: 40),
    );
  }

  Widget _buildProgressBar(String? status) {
    double progress = 0.3;
    if (status == 'PROCESSING') progress = 0.6;
    if (status == 'RESOLVED') progress = 1.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return Container(
          height: 16,
          alignment: Alignment.centerLeft,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                height: 4,
                width: totalWidth * progress,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Positioned(
                left: (totalWidth * progress) - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final displayName = _userName.contains(' / ') ? _userName.split(' / ')[0] : _userName;
    final displaySub = _userName.contains(' / ') ? _userName.split(' / ')[1] : 'Student';

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 20, bottom: 20),
            color: colorScheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                  backgroundImage: _profileImageUrl != null ? MemoryImage(base64Decode(_profileImageUrl!)) : null,
                  child: _profileImageUrl == null ? Icon(Icons.person, size: 35, color: colorScheme.onPrimary) : null,
                ),
                const SizedBox(height: 12),
                Text(
                  displayName.toUpperCase(),
                  style: TextStyle(color: colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  displaySub,
                  style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerSection('USER SECTION'),
                _buildDrawerItem(Icons.edit, 'Update Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                _buildDrawerItem(Icons.info_outline, 'Complaint Status', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssuesListScreen()))),
                _buildDrawerItem(Icons.edit, 'Raise Complaint', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen()))),
                _buildDrawerItem(Icons.menu, 'My Complaints', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IssuesListScreen()))),
                
                const Divider(),
                _buildDrawerSection('CONFIDENTIAL'),
                _buildDrawerItem(Icons.shield, '🔐 POSH & Harassment', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoshHomeScreen())), subtitle: 'Report harassment or abuse confidentially and securely'),
                
                if (_isPoshOfficer) ...[
                  const Divider(),
                  _buildDrawerSection('POSH MANAGEMENT'),
                  _buildDrawerItem(Icons.admin_panel_settings, 'POSH Dashboard', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoshOfficerDashboard()))),
                ],

                const Divider(),
                _buildDrawerSection('SUPPORT SECTION'),
                _buildDrawerItem(Icons.help_outline, 'Help / User Guide', () {}),
                _buildDrawerItem(Icons.phone, 'Contact Support', () => showContactSupportDialog(context)),
                _buildDrawerItem(Icons.info_outline, 'About App', () => showAboutSmartifyDialog(context)),
                
                const Divider(),
                _buildDrawerSection('APP SETTINGS'),
                _buildDrawerItem(Icons.palette, 'Choose Theme', () => showThemeDialog(context)),
                
                const Divider(),
                _buildDrawerSection('ACCOUNT SECTION'),
                _buildDrawerItem(Icons.logout, 'Logout', () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false);
                }, color: Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color, String? subtitle}) {
    return ListTile(
      dense: subtitle == null,
      leading: Icon(icon, color: color ?? Colors.grey[700], size: 22),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
      onTap: onTap,
    );
  }
}
