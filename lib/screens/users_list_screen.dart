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

  String _searchQuery = '';
  String _selectedDept = 'All Departments';
  String _selectedRole = 'All Roles';
  String _authorityRoleChip = 'All';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _departments = [
    'All Departments', 'BCA', 'BBA', 'BA', 'BCOM', 'MCA', 'MCOM', 'BHM'
  ];

  final List<String> _roles = [
    'All Roles', 'Teacher', 'HOD', 'Dean', 'Principal', 'Admin'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {}); 
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
      
      // 1. Fetch from Profiles (Students)
      final studentData = await client.from('profiles').select().order('full_name');
      
      // 2. Fetch from Faculty (Teachers, etc.)
      final facultyData = await client.from('faculty').select().order('FullName');
      
      // 3. Fetch from Admins
      final adminData = await client.from('admins').select().order('full_name');
      
      final List<UserProfile> mergedUsers = [];
      
      // Map Students
      mergedUsers.addAll((studentData as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        map['user_role'] = 'Student';
        return UserProfile.fromJson(map);
      }));
      
      // Map Faculty
      mergedUsers.addAll((facultyData as List).map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e))));
      
      // Map Admins
      mergedUsers.addAll((adminData as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        map['user_role'] = 'Admin';
        return UserProfile.fromJson(map);
      }));

      if (mounted) {
        setState(() {
          _allUsers = mergedUsers;
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
      
      if (currentTabIndex == 0) { // Students Tab
        if (roleLower != 'student') return false;
      } else if (currentTabIndex == 1) { // Authorities Tab
        // Approved Faculty or Approved Admins
        if (roleLower == 'student' || !u.isApproved) return false;
        if (_authorityRoleChip != 'All' && u.userRole != _authorityRoleChip) return false;
      } else if (currentTabIndex == 2) { // Pending Tab
        // Unapproved Faculty OR Unapproved Admins
        if (u.isApproved || roleLower == 'student') return false;
      }

      if (_selectedDept != 'All Departments' && roleLower != 'admin') {
        if (u.department == null || u.department!.toUpperCase() != _selectedDept.toUpperCase()) return false;
      }

      if (currentTabIndex != 0 && _selectedRole != 'All Roles') {
        if (u.userRole != _selectedRole) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return (u.fullName ?? '').toLowerCase().contains(q) ||
               (u.emailId ?? '').toLowerCase().contains(q) ||
               (u.studentId ?? u.facultyId ?? u.adminId ?? '').toLowerCase().contains(q);
      }

      return true;
    }).toList();
  }

  Map<String, int> _calculateStats() {
    return {
      'Students': _allUsers.where((u) => u.userRole == 'Student').length,
      'Teachers': _allUsers.where((u) => u.userRole == 'Teacher' && u.isApproved).length,
      'HODs': _allUsers.where((u) => u.userRole == 'HOD' && u.isApproved).length,
      'Admins': _allUsers.where((u) => u.userRole == 'Admin' && u.isApproved).length,
    };
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('User Management', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          tabs: const [Tab(text: 'Students'), Tab(text: 'Authorities'), Tab(text: 'Pending')],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchUsers,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSearchField(),
                const SizedBox(height: 16),
                _buildFiltersArea(currentTab),
                const SizedBox(height: 24),
                if (currentTab != 2) _buildOverviewHeader(stats),
                const SizedBox(height: 12),
                Text('Records Found: ${filteredUsers.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                ...filteredUsers.map((u) => _buildUserCard(u)).toList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Search by Name, Email or ID...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFiltersArea(int tab) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDept,
            decoration: const InputDecoration(labelText: 'Dept', contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (v) => setState(() => _selectedDept = v!),
          ),
        ),
        const SizedBox(width: 8),
        if (tab != 0) 
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role', contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
          ),
      ],
    );
  }

  Widget _buildOverviewHeader(Map<String, int> stats) {
    return Row(
      children: [
        _statItem('Students', stats['Students']!, Colors.blue),
        _statItem('Teachers', stats['Teachers']!, Colors.green),
        _statItem('HODs', stats['HODs']!, Colors.orange),
        _statItem('Admins', stats['Admins']!, Colors.purple),
      ],
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.profileImage != null ? MemoryImage(base64Decode(user.profileImage!.split(',').last)) : null,
          child: user.profileImage == null ? const Icon(Icons.person) : null,
        ),
        title: Text(user.fullName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${user.userRole} • ${user.department ?? "N/A"}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsScreen(userData: user.toJson()))).then((_) => _fetchUsers()),
      ),
    );
  }
}
