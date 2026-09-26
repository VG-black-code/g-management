import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'posh_submission_success_screen.dart';
import 'posh_widgets.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  Map<String, dynamic>? _userProfile;

  // Form State
  String? _selectedCategory;
  final TextEditingController _otherCategoryController = TextEditingController();
  String? _personType;
  final TextEditingController _personNameController = TextEditingController();
  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _witnessesController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();
  
  // Evidence Map grouped by label
  final Map<String, List<PlatformFile>> _evidenceMap = {
    'Photos': [],
    'Videos': [],
    'Documents': [],
    'Screenshots': [],
    'Audio / Voice': [],
    'Other Files': [],
  };

  String _submissionMode = 'confidential';

  final List<String> _categories = [
    'Sexual harassment',
    'Verbal harassment / abuse',
    'Physical harassment',
    'Bullying / intimidation',
    'Unwanted messages or communication',
    'Inappropriate behaviour',
    'Discrimination',
    'Stalking / unwanted attention',
    'Other'
  ];

  final List<String> _personTypes = [
    'Student', 'Teacher', 'Faculty Member', 'Staff Member', 'Unknown', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        var data = await Supabase.instance.client.from('profiles').select().eq('id', user.id).maybeSingle();
        if (data == null) {
          data = await Supabase.instance.client.from('faculty').select().eq('id', user.id).maybeSingle();
        }
        if (mounted) setState(() => _userProfile = data);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _otherCategoryController.dispose();
    _personNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _witnessesController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles(String label, FileType type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: type);
    if (result != null) {
      setState(() => _evidenceMap[label]!.addAll(result.files));
    }
  }

  void _submitReport() {
    showDialog(
      context: context,
      builder: (context) => PoshConfirmationDialog(
        title: 'Submit Confidential Report?',
        message: 'Once submitted, this report will be securely transferred to the authorized POSH department. It will not enter the normal complaint workflow.',
        confirmLabel: 'Submit Securely',
        onConfirm: _processSubmission,
      ),
    );
  }

  Future<void> _processSubmission() async {
    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final caseData = {
        'reporter_id': user.id,
        'category': _selectedCategory == 'Other' ? 'Other: ${_otherCategoryController.text}' : _selectedCategory,
        'person_type': _personType,
        'person_identifier': _personNameController.text,
        'incident_date': _incidentDate?.toIso8601String().split('T')[0],
        'incident_time': _incidentTime != null ? '${_incidentTime!.hour.toString().padLeft(2, '0')}:${_incidentTime!.minute.toString().padLeft(2, '0')}' : null,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'witnesses': _witnessesController.text,
        'additional_information': _additionalInfoController.text,
        'submission_mode': _submissionMode,
        'status': 'Submitted',
      };

      final response = await supabase.from('posh_cases').insert(caseData).select().single();
      final caseId = response['id'];
      final caseNumber = response['case_number'];

      // Evidence Upload with secure owner-based path
      for (var entry in _evidenceMap.entries) {
        for (var file in entry.value) {
          if (file.path != null) {
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final filePath = '${user.id}/$caseId/$fileName';
            await supabase.storage.from('posh-evidence').upload(filePath, File(file.path!));
            await supabase.from('posh_evidence').insert({
              'case_id': caseId,
              'uploaded_by': user.id,
              'file_path': filePath,
              'file_name': file.name,
              'file_type': entry.key, // Grouped by category
              'file_size': file.size,
            });
          }
        }
      }

      await supabase.from('posh_audit_logs').insert({
        'case_id': caseId, 'user_id': user.id, 'action': 'REPORT_SUBMITTED', 'metadata': {'mode': _submissionMode},
      });

      await supabase.from('notifications').insert({
        'user_id': user.id, 'title': 'POSH Report Submitted', 'message': 'Your report $caseNumber has been securely submitted.', 'type': 'POSH',
      });

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PoshSubmissionSuccessScreen(caseNumber: caseNumber)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: navyText), onPressed: () => _currentStep > 0 ? setState(() => _currentStep--) : Navigator.pop(context)),
        title: const Text('Report an Incident', style: TextStyle(color: navyText, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          PoshStepIndicator(currentStep: _currentStep),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildCurrentStepView())),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      case 3: return _buildStep4();
      case 4: return _buildStep5();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. What happened?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyText)),
        const SizedBox(height: 20),
        ..._categories.map((cat) => PoshCategoryCard(title: cat, isSelected: _selectedCategory == cat, onTap: () => setState(() => _selectedCategory = cat))),
        if (_selectedCategory == 'Other') Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: TextField(controller: _otherCategoryController, decoration: const InputDecoration(labelText: 'Please specify', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))))),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2. Who was involved?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyText)),
        const SizedBox(height: 10),
        const Text('Person involved', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 10, children: _personTypes.map((type) => ChoiceChip(label: Text(type), selected: _personType == type, onSelected: (val) => setState(() => _personType = val ? type : null), selectedColor: poshPurple.withOpacity(0.2), labelStyle: TextStyle(color: _personType == type ? poshPurple : Colors.black), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))).toList()),
        const SizedBox(height: 30),
        const Text('Name / Identification (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _personNameController, decoration: const InputDecoration(hintText: 'Enter name or identification (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
        const SizedBox(height: 8),
        const Text('You can skip this if you don\'t want to share.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3. Incident Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyText)),
        const SizedBox(height: 20),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(_incidentDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_incidentDate!)), trailing: const Icon(Icons.calendar_today, color: poshPurple), onTap: () async { final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now()); if (date != null) setState(() => _incidentDate = date); }),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Approximate Time', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(_incidentTime == null ? 'Select Time' : _incidentTime!.format(context)), trailing: const Icon(Icons.access_time, color: poshPurple), onTap: () async { final time = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (time != null) setState(() => _incidentTime = time); }),
        const SizedBox(height: 16),
        const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _locationController, decoration: const InputDecoration(hintText: 'Where did this happen?', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
        const SizedBox(height: 16),
        const Text('What happened?', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _descriptionController, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(hintText: 'Write in detail what happened...', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))), counterText: '')),
        Align(alignment: Alignment.centerRight, child: Text('${_descriptionController.text.length}/1000', style: const TextStyle(fontSize: 10, color: Colors.grey))),
        const SizedBox(height: 16),
        const Text('Was anyone else present? (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _witnessesController, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))))),
        const SizedBox(height: 16),
        const Text('Additional Information (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: _additionalInfoController, maxLines: 2, maxLength: 500, decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))), counterText: '')),
        Align(alignment: Alignment.centerRight, child: Text('${_additionalInfoController.text.length}/500', style: const TextStyle(fontSize: 10, color: Colors.grey))),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('4. Evidence (Optional)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyText)),
        const SizedBox(height: 8),
        const Text('Upload any evidence that can support your report.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        _buildUploadGroup('Photos', Icons.photo, FileType.image),
        _buildUploadGroup('Videos', Icons.videocam, FileType.video),
        _buildUploadGroup('Documents', Icons.description, FileType.any),
        _buildUploadGroup('Screenshots', Icons.screenshot, FileType.image),
        _buildUploadGroup('Audio / Voice', Icons.mic, FileType.audio),
        _buildUploadGroup('Other Files', Icons.attach_file, FileType.any),
        const SizedBox(height: 30),
        const PoshSecurityBanner(),
      ],
    );
  }

  Widget _buildUploadGroup(String label, IconData icon, FileType type) {
    final files = _evidenceMap[label]!;
    return Column(
      children: [
        PoshEvidenceUploader(label: label, icon: icon, onTap: () => _pickFiles(label, type)),
        if (files.isNotEmpty) ...files.map((file) => ListTile(
          dense: true,
          leading: const Icon(Icons.file_present, size: 20, color: poshPurple),
          title: Text(file.name, style: const TextStyle(fontSize: 12)),
          subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB • Ready', style: const TextStyle(fontSize: 10)),
          trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red), onPressed: () => setState(() => files.remove(file))),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('5. Reporter Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyText)),
        const SizedBox(height: 20),
        const Text('How would you like to submit this report?', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        _buildOptionTile('I want to identify myself', 'Provide your details to help in the investigation process.', 'identified'),
        if (_submissionMode == 'identified' && _userProfile != null)
          Container(margin: const EdgeInsets.only(top: 10, left: 10, right: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Profile Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(_userProfile!['full_name'] ?? _userProfile!['FullName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_userProfile!['email_id'] ?? _userProfile!['Email'] ?? '', style: const TextStyle(fontSize: 13)),
            Text(_userProfile!['department'] ?? _userProfile!['Department'] ?? '', style: const TextStyle(fontSize: 13)),
          ])),
        const SizedBox(height: 16),
        _buildOptionTile('I want to submit confidentially', 'Your identity will be kept confidential within the authorized POSH process.', 'confidential'),
        const SizedBox(height: 30),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withOpacity(0.3))), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Note', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          SizedBox(height: 4),
          Text('Complete anonymity cannot be guaranteed where disclosure is required for legal, safety or institutional processes.', style: TextStyle(fontSize: 12)),
        ])),
      ],
    );
  }

  Widget _buildOptionTile(String title, String desc, String mode) {
    bool isSelected = _submissionMode == mode;
    return InkWell(onTap: () => setState(() => _submissionMode = mode), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: Border.all(color: isSelected ? poshPurple : Colors.grey[300]!, width: 2), borderRadius: BorderRadius.circular(12), color: isSelected ? poshPurple.withOpacity(0.02) : Colors.white), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: navyText)), const SizedBox(height: 4), Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600]))])),
      Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? poshPurple : Colors.grey),
    ])));
  }

  Widget _buildBottomNavigation() {
    bool canGoNext = true;
    if (_currentStep == 0 && _selectedCategory == null) canGoNext = false;
    if (_currentStep == 0 && _selectedCategory == 'Other' && _otherCategoryController.text.isEmpty) canGoNext = false;
    if (_currentStep == 2 && (_incidentDate == null || _locationController.text.isEmpty || _descriptionController.text.isEmpty)) canGoNext = false;

    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]), child: Row(children: [
      if (_currentStep > 0) Expanded(child: OutlinedButton(onPressed: () => setState(() => _currentStep--), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Colors.grey)), child: const Text('Back', style: TextStyle(color: Colors.black)))),
      if (_currentStep > 0) const SizedBox(width: 16),
      Expanded(flex: 2, child: ElevatedButton(onPressed: _isSubmitting || !canGoNext ? null : (_currentStep == 4 ? _submitReport : () => setState(() => _currentStep++)), style: ElevatedButton.styleFrom(backgroundColor: poshPurple, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_currentStep == 4 ? '🔒 Submit Report' : 'Next →', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
    ]));
  }
}
