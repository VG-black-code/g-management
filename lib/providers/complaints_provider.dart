import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class ComplaintsProvider extends ChangeNotifier {
  List<Issue> _allIssues = [];
  List<Issue> _filteredIssues = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _complaintsSubscription;

  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedStatus;

  List<Issue> get issues => _filteredIssues;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get error => _error;

  Future<void> fetchComplaints({
    required String role,
    String? dept,
    String? userId,
    String? course,
    String? year,
    String? section,
    List<String>? assignedDepts,
    bool allInstitution = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      var query = client.from('issues').select();
      final normalizedRole = role.toLowerCase();

      if (normalizedRole == 'admin') {
         query = query.eq('category', 'General').eq('current_authority_role', 'Admin');
      } else if (normalizedRole == 'student') {
        if (userId != null) query = query.eq('user_id', userId);
      } 
      else if (normalizedRole == 'teacher' || normalizedRole == 'faculty') {
        if (dept != null && dept.isNotEmpty) query = query.eq('department', dept);
        query = query.eq('current_authority_role', 'Teacher');
        if (userId != null) query = query.or('current_authority_id.is.null,current_authority_id.eq.$userId');
      } 
      else if (normalizedRole == 'hod') {
        if (dept != null && dept.isNotEmpty) query = query.eq('department', dept);
        query = query.eq('current_authority_role', 'HOD');
      } 
      else if (normalizedRole == 'dean') {
        if (assignedDepts != null && assignedDepts.isNotEmpty) query = query.inFilter('department', assignedDepts);
        query = query.eq('current_authority_role', 'Dean');
      } 
      else if (normalizedRole == 'principal') {
        query = query.eq('current_authority_role', 'Principal');
      }

      final data = await query.order('id', ascending: false);
      _allIssues = (data as List).map((e) => Issue.fromJson(e)).toList();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    _filteredIssues = _allIssues.where((issue) {
      final idMatch = (issue.complaintId ?? '').toLowerCase().contains(_searchQuery) ||
                      'CMP${issue.id}'.toLowerCase().contains(_searchQuery);
      final nameMatch = (issue.userName ?? '').toLowerCase().contains(_searchQuery);
      final categoryMatch = _selectedCategory == null || issue.category == _selectedCategory;
      final statusMatch = _selectedStatus == null || (issue.status ?? '').toUpperCase() == _selectedStatus?.toUpperCase();
      return (idMatch || nameMatch) && categoryMatch && statusMatch;
    }).toList();
    _filteredIssues.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    notifyListeners();
  }

  Future<bool> updateStatus(Issue issue, String newStatus, {String? comment, String? userName, String? role, String? userId}) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final Map<String, dynamic> updates = {
        'status': newStatus,
      };
      
      if (newStatus == 'PROCESSING') updates['processing_at'] = now;
      if (newStatus == 'RESOLVED') updates['resolved_at'] = now;
      if (newStatus == 'PROCESSING' && userId != null) updates['current_authority_id'] = userId;

      await Supabase.instance.client.from('issues').update(updates).eq('id', issue.id!);

      await Supabase.instance.client.from('complaint_history').insert({
        'issue_id': issue.id,
        'performed_by_name': userName,
        'performed_by_role': role,
        'action': 'MARKED_$newStatus',
        'status': newStatus,
        'comment': comment ?? 'Status updated to $newStatus',
        'created_at': now,
      });

      // Update local state to reflect changes immediately
      final index = _allIssues.indexWhere((e) => e.id == issue.id);
      if (index != -1) {
        final existing = _allIssues[index];
        _allIssues[index] = Issue(
          id: existing.id,
          complaintId: existing.complaintId,
          userId: existing.userId,
          userName: existing.userName,
          usn: existing.usn,
          department: existing.department,
          course: existing.course,
          year: existing.year,
          section: existing.section,
          category: existing.category,
          problemType: existing.problemType,
          description: existing.description,
          location: existing.location,
          photoUrl: existing.photoUrl,
          status: newStatus,
          priority: existing.priority,
          currentAuthorityId: newStatus == 'PROCESSING' ? (userId ?? existing.currentAuthorityId) : existing.currentAuthorityId,
          currentAuthorityRole: existing.currentAuthorityRole,
          assignedTo: existing.assignedTo,
          createdAt: existing.createdAt,
          processingAt: newStatus == 'PROCESSING' ? now : existing.processingAt,
          resolvedAt: newStatus == 'RESOLVED' ? now : existing.resolvedAt,
        );
        _applyFilters();
      }

      if (issue.userId != null) {
        await sendNotificationToUser(issue.userId!, 'Complaint Update', 'Your complaint (CMP${issue.id}) is now $newStatus.', issue.id!);
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> forwardComplaint(Issue issue, String nextRole, String reason, String comment, {String? userName, String? role}) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      
      final Map<String, dynamic> updates = {
        'current_authority_role': nextRole,
        'current_authority_id': null,
        'status': 'FORWARDED',
      };

      await Supabase.instance.client.from('issues').update(updates).eq('id', issue.id!);

      await Supabase.instance.client.from('complaint_history').insert({
        'issue_id': issue.id,
        'performed_by_name': userName,
        'performed_by_role': role,
        'action': 'FORWARDED_TO_$nextRole',
        'status': 'FORWARDED',
        'comment': '$reason: $comment',
        'created_at': now,
      });

      // Update local state
      final index = _allIssues.indexWhere((e) => e.id == issue.id);
      if (index != -1) {
         final existing = _allIssues[index];
        _allIssues[index] = Issue(
          id: existing.id,
          complaintId: existing.complaintId,
          userId: existing.userId,
          userName: existing.userName,
          usn: existing.usn,
          department: existing.department,
          course: existing.course,
          year: existing.year,
          section: existing.section,
          category: existing.category,
          problemType: existing.problemType,
          description: existing.description,
          location: existing.location,
          photoUrl: existing.photoUrl,
          status: 'FORWARDED',
          priority: existing.priority,
          currentAuthorityId: null,
          currentAuthorityRole: nextRole,
          assignedTo: existing.assignedTo,
          createdAt: existing.createdAt,
          processingAt: existing.processingAt,
          resolvedAt: existing.resolvedAt,
        );
        _applyFilters();
      }

      if (issue.userId != null) {
        await sendNotificationToUser(issue.userId!, 'Grievance Escalated', 'Your complaint CMP${issue.id} has been forwarded to $nextRole.', issue.id!);
      }
      
      await sendNotificationByRole(nextRole, 'New Forwarded Grievance', 'Complaint CMP${issue.id} forwarded from $role for your attention.', issue.id!, dept: issue.department);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> sendNotificationToUser(String targetUserId, String title, String msg, int? issueId) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': targetUserId,
        'title': title,
        'message': msg,
        'issue_id': issueId,
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      try {
         await Supabase.instance.client.from('notifications').insert({
          'user_name': targetUserId,
          'title': title,
          'message': msg,
          'issue_id': issueId,
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  Future<void> sendNotificationByRole(String role, String title, String msg, int? issueId, {String? dept}) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'target_role': role,
        'department': dept,
        'title': title,
        'message': msg,
        'issue_id': issueId,
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }
}
