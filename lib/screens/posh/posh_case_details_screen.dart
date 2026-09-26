import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'posh_widgets.dart';

class PoshCaseDetailsScreen extends StatefulWidget {
  final dynamic caseData;

  const PoshCaseDetailsScreen({super.key, required this.caseData});

  @override
  State<PoshCaseDetailsScreen> createState() => _PoshCaseDetailsScreenState();
}

class _PoshCaseDetailsScreenState extends State<PoshCaseDetailsScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _safeMessageController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _evidence = [];
  List<dynamic> _internalNotes = [];
  Map<String, dynamic>? _reporterProfile;
  List<dynamic> _availableOfficers = [];
  String? _assignedOfficerName;

  @override
  void initState() {
    super.initState();
    _fetchCaseDetails();
    _fetchOfficers();
    _logAccess('CASE_VIEWED_BY_OFFICER');
  }

  Future<void> _logAccess(String action, {Map<String, dynamic>? metadata}) async {
    try {
      await supabase.from('posh_audit_logs').insert({
        'case_id': widget.caseData['id'],
        'user_id': supabase.auth.currentUser!.id,
        'action': action,
        'metadata': metadata,
      });
    } catch (_) {}
  }

  Future<void> _fetchOfficers() async {
    try {
      final officersData = await supabase.from('posh_authorized_users').select('user_id');
      List<String> userIds = (officersData as List).map((o) => o['user_id'] as String).toList();
      
      if (userIds.isNotEmpty) {
        final faculty = await supabase.from('faculty').select('id, FullName').inFilter('id', userIds);
        final profiles = await supabase.from('profiles').select('id, full_name').inFilter('id', userIds);
        
        if (mounted) {
          setState(() {
            _availableOfficers = [...faculty, ...profiles];
            _updateAssignedOfficerName();
          });
        }
      }
    } catch (_) {}
  }

  void _updateAssignedOfficerName() {
    if (widget.caseData['assigned_officer_id'] != null) {
      final officer = _availableOfficers.firstWhere(
        (o) => o['id'] == widget.caseData['assigned_officer_id'],
        orElse: () => null,
      );
      if (officer != null) {
        _assignedOfficerName = officer['FullName'] ?? officer['full_name'];
      }
    }
  }

  Future<void> _fetchCaseDetails() async {
    setState(() => _isLoading = true);
    try {
      final caseId = widget.caseData['id'];
      final evidenceData = await supabase.from('posh_evidence').select().eq('case_id', caseId);
      final notesData = await supabase.from('posh_internal_notes').select().eq('case_id', caseId).order('created_at', ascending: false);

      if (widget.caseData['submission_mode'] == 'identified') {
        final reporterId = widget.caseData['reporter_id'];
        var profile = await supabase.from('profiles').select().eq('id', reporterId).maybeSingle();
        if (profile == null) {
          profile = await supabase.from('faculty').select().eq('id', reporterId).maybeSingle();
        }
        _reporterProfile = profile;
      }

      if (mounted) {
        setState(() {
          _evidence = evidenceData;
          _internalNotes = notesData;
          _updateAssignedOfficerName();
        });
      }
    } catch (e) {
      debugPrint('Error fetching case details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignOfficer(String officerId) async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('posh_cases').update({'assigned_officer_id': officerId}).eq('id', widget.caseData['id']);
      await _logAccess('CASE_ASSIGNED', metadata: {'assigned_to': officerId});
      
      // Notify the assigned officer
      await supabase.from('notifications').insert({
        'user_id': officerId,
        'title': 'New POSH Case Assigned',
        'message': 'You have been assigned to case ${widget.caseData['case_number']}.',
        'type': 'POSH_ASSIGNMENT',
      });

      widget.caseData['assigned_officer_id'] = officerId;
      await _fetchCaseDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning officer: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('posh_cases').update({'status': newStatus}).eq('id', widget.caseData['id']);
      final safeMsg = _safeMessageController.text.trim().isEmpty ? 'Status updated to $newStatus' : _safeMessageController.text.trim();
      
      await supabase.from('posh_case_updates').insert({
        'case_id': widget.caseData['id'],
        'updated_by': supabase.auth.currentUser!.id,
        'status': newStatus,
        'safe_message': safeMsg,
      });

      // Notify the reporter
      await supabase.from('notifications').insert({
        'user_id': widget.caseData['reporter_id'],
        'title': 'POSH Report Update',
        'message': 'The status of your report ${widget.caseData['case_number']} has been updated to $newStatus.',
        'type': 'POSH_UPDATE',
      });

      await _logAccess('STATUS_UPDATED', metadata: {'new_status': newStatus, 'reporter_msg': safeMsg});

      _safeMessageController.clear();
      Navigator.pop(context);
      await _fetchCaseDetails();
      setState(() => widget.caseData['status'] = newStatus);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseData = widget.caseData;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const BackButton(color: navyText),
        title: Text(caseData['case_number'], style: const TextStyle(color: navyText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt_1_outlined, color: poshPurple), onPressed: _showAssignDialog),
          IconButton(icon: const Icon(Icons.edit_note, color: poshPurple), onPressed: _showStatusUpdateDialog),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: poshPurple)) : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildSectionHeader('Case Overview'), PoshStatusBadge(status: caseData['status'])]),
        _buildInfoItem('Incident Type', caseData['category']),
        _buildInfoItem('Location', caseData['location'] ?? 'Not specified'),
        _buildInfoItem('Date & Time', '${caseData['incident_date'] ?? 'N/A'} at ${caseData['incident_time'] ?? 'N/A'}'),
        _buildInfoItem('Assigned Officer', _assignedOfficerName ?? 'Unassigned'),
        const SizedBox(height: 24),
        _buildSectionHeader('Reporter Information'),
        if (caseData['submission_mode'] == 'identified' && _reporterProfile != null) ...[
          _buildInfoItem('Identity', 'IDENTIFIED'),
          _buildInfoItem('Name', _reporterProfile!['full_name'] ?? _reporterProfile!['FullName'] ?? 'N/A'),
          _buildInfoItem('Dept/Email', '${_reporterProfile!['department'] ?? ''} • ${_reporterProfile!['email_id'] ?? ''}'),
        ] else ...[
          const Text('Reporter identity is CONFIDENTIAL.', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        _buildSectionHeader('Full Description'),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)), child: Text(caseData['description'] ?? 'No description.', style: const TextStyle(height: 1.5, fontSize: 14))),
        const SizedBox(height: 20),
        _buildSectionHeader('Witnesses & Extra Info'),
        _buildInfoItem('Witnesses', caseData['witnesses'] ?? 'None mentioned'),
        _buildInfoItem('Additional Info', caseData['additional_information'] ?? 'None provided'),
        const SizedBox(height: 24),
        _buildSectionHeader('Secure Evidence'),
        if (_evidence.isEmpty) const Text('No evidence files.', style: TextStyle(color: Colors.grey)) else ..._evidence.map((e) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: const Icon(Icons.file_present, color: poshPurple), title: Text(e['file_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), subtitle: Text(e['file_type'] ?? 'Attachment', style: const TextStyle(fontSize: 11)), trailing: IconButton(icon: const Icon(Icons.open_in_new, size: 20), onPressed: () => _viewFile(e['file_path']))))),
        const SizedBox(height: 30),
        const Divider(thickness: 2),
        _buildSectionHeader('Officer Investigation Notes'),
        const Text('VISIBLE ONLY TO POSH OFFICERS', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: TextField(controller: _noteController, decoration: const InputDecoration(hintText: 'Add a private note...', border: OutlineInputBorder()))), const SizedBox(width: 8), IconButton(onPressed: _addInternalNote, icon: const Icon(Icons.send, color: poshPurple))]),
        const SizedBox(height: 16),
        ..._internalNotes.map((n) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: poshPurple.withOpacity(0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: poshPurple.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n['note'], style: const TextStyle(fontSize: 14)), const SizedBox(height: 4), Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(n['created_at'])), style: const TextStyle(fontSize: 10, color: Colors.grey))]))),
      ])),
    );
  }

  void _showStatusUpdateDialog() {
    showDialog(context: context, builder: (context) {
      String? selectedStatus = widget.caseData['status'];
      return StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Update Case Status'), content: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField<String>(value: selectedStatus, decoration: const InputDecoration(border: OutlineInputBorder()), items: ['Submitted', 'Assigned', 'Under Review', 'Action Required', 'Action Taken', 'Closed'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (val) => setDialogState(() => selectedStatus = val)), const SizedBox(height: 16), TextField(controller: _safeMessageController, maxLines: 2, decoration: const InputDecoration(labelText: 'Safe Message for Reporter', border: OutlineInputBorder()))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () => _updateStatus(selectedStatus!), style: ElevatedButton.styleFrom(backgroundColor: poshPurple), child: const Text('Update Status', style: TextStyle(color: Colors.white)))]);
      });
    });
  }

  void _showAssignDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Assign Case'), content: SizedBox(width: double.maxFinite, child: _availableOfficers.isEmpty ? const Text('No officers found.') : ListView.builder(shrinkWrap: true, itemCount: _availableOfficers.length, itemBuilder: (context, index) { final officer = _availableOfficers[index]; final name = officer['FullName'] ?? officer['full_name']; return ListTile(title: Text(name), onTap: () { Navigator.pop(context); _assignOfficer(officer['id']); }); })), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  Future<void> _viewFile(String filePath) async {
    try {
      final response = await supabase.storage.from('posh-evidence').createSignedUrl(filePath, 60);
      if (await canLaunchUrl(Uri.parse(response))) await launchUrl(Uri.parse(response), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addInternalNote() async {
    if (_noteController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await supabase.from('posh_internal_notes').insert({'case_id': widget.caseData['id'], 'officer_id': supabase.auth.currentUser!.id, 'note': _noteController.text.trim()});
      _noteController.clear();
      await _fetchCaseDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyText)));

  Widget _buildInfoItem(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 6), child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 14), children: [TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)), TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold))])));
}
