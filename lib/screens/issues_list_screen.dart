import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../providers/complaints_provider.dart';
import 'issue_details_screen.dart';

class IssuesListScreen extends StatefulWidget {
  final bool isAdmin;
  const IssuesListScreen({super.key, this.isAdmin = false});

  @override
  State<IssuesListScreen> createState() => _IssuesListScreenState();
}

class _IssuesListScreenState extends State<IssuesListScreen> {
  String _userId = '';
  String _role = 'Student';
  String _dept = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchIssues();
  }

  Future<void> _loadUserAndFetchIssues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id') ?? '';
      _role = prefs.getString('role') ?? 'Student';
      _dept = prefs.getString('department') ?? '';
    });
    
    _fetchIssues();
  }

  Future<void> _fetchIssues() async {
    context.read<ComplaintsProvider>().fetchComplaints(
      role: _role,
      userId: _userId,
      dept: _dept,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('My Issues', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: colorScheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchIssues),
        ],
      ),
      body: Consumer<ComplaintsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          
          final issues = provider.issues;
          
          if (issues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined, size: 80, color: colorScheme.primary.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('No grievances found in your history.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _fetchIssues,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];
                return _buildIssueCard(issue);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildIssueCard(Issue issue) {
    final statusColor = _getStatusColor(issue.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    issue.problemType ?? 'Issue',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    issue.status ?? 'Pending',
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Category: ${issue.category ?? 'General'}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            const SizedBox(height: 4),
            Text('Location: ${issue.location ?? 'Campus'}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            const Divider(height: 30),
            Text(
              issue.description ?? '',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Raised on: ${issue.createdAt?.split('T')[0] ?? ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IssueDetailsScreen(issue: issue)),
                    ).then((_) => _fetchIssues());
                  },
                  child: Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    status = status?.toUpperCase() ?? 'PENDING';
    if (status == 'PROCESSING') return Colors.orange;
    if (status == 'RESOLVED') return Colors.green;
    return Colors.red;
  }
}
