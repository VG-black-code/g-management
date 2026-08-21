import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../providers/complaints_provider.dart';
import 'widgets/complaint_details_dialog.dart';

class AllComplaintsScreen extends StatefulWidget {
  final List<Issue> initialIssues;
  final String? statusFilter;
  final String? screenTitle;
  
  const AllComplaintsScreen({
    super.key, 
    required this.initialIssues,
    this.statusFilter,
    this.screenTitle,
  });

  @override
  State<AllComplaintsScreen> createState() => _AllComplaintsScreenState();
}

class _AllComplaintsScreenState extends State<AllComplaintsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _rowsPerPage = 20;
  int? _updatingId;
  String _role = 'Student';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'Student';
    final dept = prefs.getString('department');
    final userId = prefs.getString('user_id');

    if (mounted) {
      setState(() => _role = role);
      context.read<ComplaintsProvider>().fetchComplaints(
        role: role,
        dept: dept,
        userId: userId,
        allInstitution: role == 'Admin' || role == 'Principal',
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.red;
      case 'processing': return Colors.orange;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _handleStatusUpdate(Issue issue, String newStatus) async {
    if (_updatingId != null) return;
    setState(() => _updatingId = issue.id);
    
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('full_name') ?? 'Authority';
    final role = prefs.getString('role') ?? 'Authority';

    final provider = context.read<ComplaintsProvider>();
    final success = await provider.updateStatus(
      issue, 
      newStatus, 
      userName: userName, 
      role: role
    );
    
    if (mounted) {
      setState(() => _updatingId = null);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus successfully!'),
            backgroundColor: _getStatusColor(newStatus),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${provider.error}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ComplaintsProvider>(
      builder: (context, provider, child) {
        var filteredIssues = provider.issues;
        
        if (widget.statusFilter != null) {
          final filter = widget.statusFilter!.toUpperCase();
          if (filter == 'PENDING') {
            filteredIssues = filteredIssues.where((issue) {
              final s = (issue.status ?? '').toUpperCase();
              return s != 'PROCESSING' && s != 'RESOLVED';
            }).toList();
          } else {
            filteredIssues = filteredIssues.where((issue) => 
              (issue.status ?? '').toUpperCase() == filter
            ).toList();
          }
        }
        
        final totalPages = (filteredIssues.length / _rowsPerPage).ceil();
        if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
        
        final startIndex = _currentPage * _rowsPerPage;
        final endIndex = (startIndex + _rowsPerPage < filteredIssues.length) 
            ? startIndex + _rowsPerPage 
            : filteredIssues.length;
        final pagedIssues = filteredIssues.isEmpty ? [] : filteredIssues.sublist(startIndex, endIndex);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(theme),
                _buildSearchBar(provider, theme),
                const SizedBox(height: 12),
                Expanded(
                  child: provider.isLoading && filteredIssues.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filteredIssues.isEmpty
                          ? const Center(child: Text('No complaints found'))
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: 1200,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTableHeader(theme),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: pagedIssues.length,
                                        itemBuilder: (context, index) {
                                          return _buildIssueRow(pagedIssues[index], index, theme);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
                if (totalPages > 1) _buildPaginationFooter(totalPages, filteredIssues.length, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Text(
            widget.screenTitle ?? 'Complaint Management', 
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ComplaintsProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => provider.setSearchQuery(val),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search by ID or Student Name',
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            border: InputBorder.none,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final bool isAuthority = _role.toLowerCase() != 'student';
    
    return Container(
      width: 1200,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          SizedBox(width: 220, child: Text('Student Name', style: _headerStyle(theme))),
          SizedBox(width: 100, child: Text('ID', textAlign: TextAlign.center, style: _headerStyle(theme))),
          SizedBox(width: 200, child: Text('Category', textAlign: TextAlign.center, style: _headerStyle(theme))),
          SizedBox(width: 120, child: Text('Date', textAlign: TextAlign.center, style: _headerStyle(theme))),
          SizedBox(width: 120, child: Text('Current Status', textAlign: TextAlign.center, style: _headerStyle(theme))),
          SizedBox(width: 400, child: Text(isAuthority ? 'Update Status' : 'Actions', textAlign: TextAlign.center, style: _headerStyle(theme))),
        ],
      ),
    );
  }

  TextStyle _headerStyle(ThemeData theme) => theme.textTheme.titleSmall!.copyWith(
    fontWeight: FontWeight.bold,
    color: theme.colorScheme.primary,
  );

  Widget _buildIssueRow(Issue issue, int index, ThemeData theme) {
    final status = (issue.status ?? 'Pending').toUpperCase();
    final date = issue.createdAt != null ? issue.createdAt!.split('T')[0] : 'N/A';
    final isUpdating = _updatingId == issue.id;
    final colorScheme = theme.colorScheme;
    final bool isAuthority = _role.toLowerCase() != 'student';

    return Container(
      width: 1200,
      decoration: BoxDecoration(
        color: index % 2 == 1 ? colorScheme.surfaceVariant.withOpacity(0.1) : Colors.transparent,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Opacity(
        opacity: isUpdating ? 0.6 : 1.0,
        child: Row(
          children: [
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(issue.userName ?? 'N/A', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(issue.usn ?? 'N/A', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            SizedBox(width: 100, child: Text('CMP${issue.id}', textAlign: TextAlign.center, style: theme.textTheme.bodySmall)),
            SizedBox(width: 200, child: Text(issue.problemType ?? issue.category ?? 'N/A', textAlign: TextAlign.center, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 120, child: Text(date, textAlign: TextAlign.center, style: theme.textTheme.bodySmall)),
            SizedBox(
              width: 120,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(status)),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 400,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isAuthority) ...[
                    // PENDING Button: Always looks clicked/faded (0.3 opacity)
                    _buildStatusButton(
                      'Pending', 
                      Colors.red, 
                      status == 'PENDING', 
                      false, 
                      () => {},
                      isDisabled: true
                    ),
                    const SizedBox(width: 8),
                    // PROCESSING Button: Faded if status is Processing or Resolved. Clickable ONLY if Pending.
                    _buildStatusButton(
                      'Processing', 
                      Colors.orange, 
                      status == 'PROCESSING',
                      status == 'PENDING', 
                      () => _handleStatusUpdate(issue, 'Processing'),
                      isDisabled: status == 'PROCESSING' || status == 'RESOLVED'
                    ),
                    const SizedBox(width: 8),
                    // RESOLVED Button: Faded if Resolved. Clickable if Pending or Processing.
                    _buildStatusButton(
                      'Resolved', 
                      Colors.green, 
                      status == 'RESOLVED',
                      status == 'PENDING' || status == 'PROCESSING', 
                      () => _handleStatusUpdate(issue, 'Resolved'),
                      isDisabled: status == 'RESOLVED'
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(Icons.info_outline, size: 24, color: isUpdating ? colorScheme.outline : colorScheme.primary),
                    onPressed: isUpdating ? null : () => showDialog(context: context, builder: (context) => ComplaintDetailsDialog(issue: issue)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String label, Color color, bool isActive, bool isClickable, VoidCallback onTap, {bool isDisabled = false}) {
    final bool shouldLookClicked = isActive || isDisabled;
    
    return SizedBox(
      width: 100,
      child: GestureDetector(
        onTap: (_updatingId != null || !isClickable) ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? color : (shouldLookClicked ? color.withOpacity(0.1) : color.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? color : color.withOpacity(0.3)),
            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Opacity(
            opacity: shouldLookClicked ? 0.3 : 1.0,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                color: isActive ? Colors.white : color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(int totalPages, int totalItems, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: $totalItems complaints', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios, size: 14), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
              Text('${_currentPage + 1} / $totalPages', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 14), onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null),
            ],
          ),
        ],
      ),
    );
  }
}
