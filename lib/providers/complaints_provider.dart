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

  /// Fetch complaints with support for institution-wide data (Principal/Admin)
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

      if (allInstitution || normalizedRole == 'admin') {
         // Admin sees everything
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
      debugPrint('Fetch Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Restore the missing search method
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
      final updates = {
        'status': newStatus,
        'updated_at': now,
        if (newStatus == 'PROCESSING') 'processing_at': now,
        if (newStatus == 'RESOLVED') 'resolved_at': now,
        if (newStatus == 'PROCESSING' && userId != null) 'current_authority_id': userId,
      };

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

      _sendNotification(issue.userName ?? 'Student', 'Complaint Update', 'Your complaint (CMP${issue.id}) is now $newStatus.', issue.id!);
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
      
      await Supabase.instance.client.from('issues').update({
        'current_authority_role': nextRole,
        'current_authority_id': null,
        'status': 'FORWARDED',
        'updated_at': now,
      }).eq('id', issue.id!);

      await Supabase.instance.client.from('complaint_history').insert({
        'issue_id': issue.id,
        'performed_by_name': userName,
        'performed_by_role': role,
        'action': 'FORWARDED_TO_$nextRole',
        'status': 'FORWARDED',
        'comment': '$reason: $comment',
        'created_at': now,
      });

      _sendNotification(issue.userName ?? 'Student', 'Grievance Escalated', 'Your complaint CMP${issue.id} has been forwarded to $nextRole.', issue.id!);
      
      String target = nextRole;
      if (nextRole == 'HOD' || nextRole == 'Teacher') target = '$nextRole - ${issue.department}';
      _sendNotification(target, 'New Forwarded Grievance', 'Complaint CMP${issue.id} forwarded from $role for your attention.', issue.id!);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> _sendNotification(String target, String title, String msg, int issueId) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_name': target,
        'title': title,
        'message': msg,
        'issue_id': issueId,
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Notification Fail: $e');
    }
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    super.dispose();
  }
}
