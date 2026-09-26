import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../providers/complaints_provider.dart';
import '../main.dart';
import 'main_screen.dart';
import 'complaint_analytics_screen.dart';
import 'notifications_screen.dart';
import 'users_list_screen.dart';
import 'issue_details_screen.dart';
import 'broadcast_screen.dart';
import 'profile_screen.dart';
import 'all_complaints_screen.dart';
import 'widgets/dialog_utils.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  String _adminName = 'Admin';
  String _userId = '';
  String? _profileImageUrl;
  
  late AnimationController _fadeController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadAdminData();
    _searchController.addListener(() {
      context.read<ComplaintsProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminName = prefs.getString('name') ?? 'Admin';
      _userId = prefs.getString('user_id') ?? '';
      _profileImageUrl = prefs.getString('profileImage');
    });
    _fetchData();
  }

  void _fetchData() {
    context.read<ComplaintsProvider>().fetchComplaints(
      role: 'Admin',
      allInstitution: true,
    );
    _fadeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(theme),
      body: Stack(
        children: [
          Container(height: 180, color: colorScheme.primary),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _fetchData(),
              child: CustomScrollView(
                slivers: [
                  _buildHeader(theme),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSearchBar(theme),
                            const SizedBox(height: 24),
                            _buildStatsGrid(),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Recent Complaints', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                                Consumer<ComplaintsProvider>(
                                  builder: (context, provider, _) => TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllComplaintsScreen(initialIssues: provider.issues, screenTitle: 'Admin View'))),
                                    child: const Text('View All', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildComplaintsList(theme),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BroadcastScreen())),
        label: const Text('ANNOUNCE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        icon: const Icon(Icons.campaign),
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                backgroundImage: _profileImageUrl != null ? MemoryImage(base64Decode(_profileImageUrl!)) : null,
                child: _profileImageUrl == null ? const Icon(Icons.shield, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Logged in as $_adminName', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.palette, color: Colors.white),
              onPressed: () => showThemeDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by ID, Name or Category...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, _) {
        final issues = provider.issues;
        final pending = issues.where((e) => e.status == 'PENDING' || e.status == 'FORWARDED').length;
        final processing = issues.where((e) => e.status == 'PROCESSING').length;
        final resolved = issues.where((e) => e.status == 'RESOLVED').length;
        final total = issues.length;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.15,
          children: [
            _buildStatCard('Institutional Grievances', total, const Color(0xFF1E3A8A), Icons.layers, 1.0),
            _buildStatCard('Pending Verification', pending, const Color(0xFFB91C1C), Icons.timer_outlined, total > 0 ? pending / total : 0.0),
            _buildStatCard('In Processing', processing, const Color(0xFFC2410C), Icons.settings_outlined, total > 0 ? processing / total : 0.0),
            _buildStatCard('Resolved Issues', resolved, const Color(0xFF15803D), Icons.check_box_outlined, total > 0 ? resolved / total : 0.0),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon, double progressFraction) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 6, width: double.infinity, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(icon, color: color, size: 22),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progressFraction.clamp(0.01, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsList(ThemeData theme) {
    return Consumer<ComplaintsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        final issues = provider.issues;
        if (issues.isEmpty) return const Center(child: Text('No complaints forwarded to Admin.'));
        
        final displayIssues = issues.length > 5 ? issues.take(5).toList() : issues;
        
        return Column(
          children: displayIssues.map((issue) {
            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${issue.userName ?? 'Anonymous'} / ${issue.usn ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${issue.complaintId ?? ("CMP"+issue.id.toString())} ${issue.problemType ?? ""}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        issue.createdAt != null ? issue.createdAt!.substring(0, 4) : '2024',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IssueDetailsScreen(issue: issue))),
                ),
                const Divider(height: 1),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    final colorScheme = theme.colorScheme;
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
                  _adminName.toUpperCase(),
                  style: TextStyle(color: colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Admin',
                  style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerSection('Admin Section'),
                _buildDrawerItem(Icons.home, 'Dashboard', () => Navigator.pop(context)),
                _buildDrawerItem(Icons.analytics, 'Analytics', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintAnalyticsScreen()))),
                _buildDrawerItem(Icons.calendar_month, 'Users Data', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersListScreen()))),
                _buildDrawerItem(Icons.notifications, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                _buildDrawerItem(Icons.edit, 'Update Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                
                const Divider(),
                _buildDrawerSection('User Section'),
                _buildDrawerItem(Icons.person, 'Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                
                const Divider(),
                _buildDrawerSection('Complaint List'),
                Consumer<ComplaintsProvider>(
                  builder: (context, provider, _) => Column(
                    children: [
                      _buildDrawerItem(Icons.home, 'Total Complaints', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllComplaintsScreen(initialIssues: provider.issues, screenTitle: 'Total Complaints')))),
                      _buildDrawerItem(Icons.access_time, 'Pending Complaints', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllComplaintsScreen(initialIssues: provider.issues, statusFilter: 'Pending', screenTitle: 'Pending Complaints')))),
                      _buildDrawerItem(Icons.build, 'Processing Complaints', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllComplaintsScreen(initialIssues: provider.issues, statusFilter: 'Processing', screenTitle: 'Processing Complaints')))),
                      _buildDrawerItem(Icons.check_box, 'Resolved Complaints', () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllComplaintsScreen(initialIssues: provider.issues, statusFilter: 'Resolved', screenTitle: 'Resolved Complaints')))),
                    ],
                  )
                ),

                const Divider(),
                _buildDrawerSection('Support Section'),
                _buildDrawerItem(Icons.help_outline, 'Help / User Guide', () {}),
                _buildDrawerItem(Icons.phone, 'Contact Support', () => showContactSupportDialog(context)),
                _buildDrawerItem(Icons.info_outline, 'About App', () => showAboutSmartifyDialog(context)),
                _buildDrawerItem(Icons.palette, 'Choose Theme', () => showThemeDialog(context)),
                
                const Divider(),
                _buildDrawerSection('Account Section'),
                _buildDrawerItem(Icons.lock, 'Change Password', () {}),
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

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color ?? Colors.grey[700], size: 20),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500, fontSize: 14)),
      onTap: onTap,
    );
  }
}
