import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'user_details_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserProfile> _allUsers = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  String _searchQuery = '';
  String _selectedDept = 'All Departments';
  String _selectedRole = 'All Roles';
  String _authorityRoleChip = 'All';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _departments = [
    'All Departments', 'BCA', 'BBA', 'B.Com', 'MCA', 'MBA', 'BA', 'B.Sc', 'M.Sc'
  ];

  final List<String> _roles = [
    'All Roles', 'Teacher', 'HOD', 'Dean', 'Principal'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); 
      }
    });
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      // Fetch users and ensure fresh data
      final data = await client.from('profiles').select().order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _allUsers = (data as List).map((e) => UserProfile.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<UserProfile> _getFilteredUsers() {
    final currentTabIndex = _tabController.index;
    return _allUsers.where((u) {
      final roleLower = u.userRole?.toLowerCase() ?? '';
      
      // 1. Tab filtering & Approval Logic
      if (currentTabIndex == 0) { // Students Tab
        if (roleLower != 'student') return false;
      } else if (currentTabIndex == 1) { // Authorities Tab
        // Approved non-student authorities
        if (roleLower == 'student' || roleLower == 'admin' || !u.isApproved) return false;
        if (_authorityRoleChip != 'All' && u.userRole != _authorityRoleChip) return false;
      } else if (currentTabIndex == 2) { // Pending Tab
        // Authorities awaiting approval
        if (u.isApproved || roleLower == 'admin' || roleLower == 'student') return false;
      }

      // 2. Department filter
      if (_selectedDept != 'All Departments') {
        if (u.department == null || u.department!.toUpperCase() != _selectedDept.toUpperCase()) return false;
      }

      // 3. Role filter dropdown
      if (currentTabIndex != 0) {
        if (_selectedRole != 'All Roles') {
          if (u.userRole == null || u.userRole!.toUpperCase() != _selectedRole.toUpperCase()) return false;
        }
      }

      // 4. Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = (u.fullName ?? '').toLowerCase().contains(q) ||
            (u.studentId ?? '').toLowerCase().contains(q) ||
            (u.facultyId ?? '').toLowerCase().contains(q) ||
            (u.emailId ?? '').toLowerCase().contains(q) ||
            (u.department ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  Map<String, int> _calculateStats() {
    Iterable<UserProfile> users = _allUsers;

    if (_selectedDept != 'All Departments') {
      users = users.where((u) => u.department?.toUpperCase() == _selectedDept.toUpperCase());
    }

    return {
      'Students': users.where((u) => (u.userRole?.toLowerCase() ?? '') == 'student').length,
      'Teachers': users.where((u) => (u.userRole?.toLowerCase() ?? '') == 'teacher' && u.isApproved).length,
      'HODs': users.where((u) => (u.userRole?.toLowerCase() ?? '') == 'hod' && u.isApproved).length,
      'Deans/Principals': users.where((u) => (u.userRole?.toLowerCase() == 'dean' || u.userRole?.toLowerCase() == 'principal') && u.isApproved).length,
    };
  }

  void _clearFilters() {
    setState(() {
      _selectedDept = 'All Departments';
      _selectedRole = 'All Roles';
      _searchQuery = '';
      _searchController.clear();
      _authorityRoleChip = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final filteredUsers = _getFilteredUsers();
    final currentTab = _tabController.index;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Institutional Users', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple[700],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.purple[700],
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Students'),
            Tab(text: 'Authorities'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? _buildErrorState()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 16),

                      _buildFiltersArea(currentTab),
                      const SizedBox(height: 16),
                      
                      if (currentTab != 2) ...[
                        _buildOverviewHeader(stats),
                        const SizedBox(height: 24),
                      ] else ...[
                        _buildPendingHeader(),
                        const SizedBox(height: 16),
                      ],

                      if (currentTab == 1) ...[
                        _buildAuthorityRoleChips(),
                        const SizedBox(height: 24),
                      ],

                      _buildListTitle(filteredUsers.length),
                      const SizedBox(height: 12),

                      if (filteredUsers.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) => _buildUserCard(filteredUsers[index]),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: 'Search by Name or ID...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildFiltersArea(int currentTab) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDropdownFilter('Department', _selectedDept, _departments, (val) => setState(() => _selectedDept = val!))),
            if (currentTab != 0) ...[
              const SizedBox(width: 12),
              Expanded(child: _buildDropdownFilter('Role', _selectedRole, _roles, (val) => setState(() => _selectedRole = val!))),
            ],
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_list_off, size: 18),
            label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: Colors.purple[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.purple),
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewHeader(Map<String, int> stats) {
    String title = 'College Overview';
    if (_selectedDept != 'All Departments') {
      title = '$_selectedDept Overview';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.3, 
          children: [
            _buildStatCard('Students', stats['Students']!, Colors.indigo[400]!),
            _buildStatCard('Teachers', stats['Teachers']!, Colors.teal[400]!),
            _buildStatCard('HODs', stats['HODs']!, Colors.amber[700]!),
            _buildStatCard('Deans/Principals', stats['Deans/Principals']!, Colors.deepPurple[400]!),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              count.toString(), 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorityRoleChips() {
    final roles = ['All', 'Teacher', 'HOD', 'Dean', 'Principal'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles.map((role) {
          final isSelected = _authorityRoleChip == role;
          return GestureDetector(
            onTap: () => setState(() => _authorityRoleChip = role),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple[700] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.purple[700]! : Colors.grey[200]!),
              ),
              child: Text(role, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPendingHeader() {
    final pendingCount = _allUsers.where((u) => !u.isApproved && u.userRole != 'Admin' && (u.userRole?.toLowerCase() ?? '') != 'student').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pending Approvals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text('$pendingCount authorities waiting for approval', style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  Widget _buildListTitle(int count) {
    String label = '';
    if (_tabController.index == 0) label = 'Students';
    else if (_tabController.index == 1) label = 'Authorities';
    else label = 'Pending Approvals';
    
    return Text('$label ($count)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildUserCard(UserProfile user) {
    final roleLower = user.userRole?.toLowerCase() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.purple[50],
          backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty) 
              ? MemoryImage(base64Decode(user.profileImage!.split(',').last)) 
              : null,
          child: user.profileImage == null ? const Icon(Icons.person, color: Colors.purple, size: 28) : null,
        ),
        title: Text(user.fullName ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('${user.userRole} • ${user.department ?? "No Dept"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('ID: ${user.studentId ?? user.facultyId ?? "N/A"}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (roleLower != 'student') ...[
              if (!user.isApproved)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                  child: const Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Approved', style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserDetailsScreen(userData: user.toJson()))
        ).then((_) => _fetchUsers()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.person_off_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No users found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Try changing your search or filters.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Unable to load users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Please check your connection and try again.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchUsers,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700], foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
