import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

import '../models/models.dart';

class ComplaintScreen extends StatefulWidget {
  final int categoryIndex;
  const ComplaintScreen({super.key, this.categoryIndex = -1});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  String _selectedCategory = '';
  String _selectedProblemType = '';
  String _selectedLocation = '';
  
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _subLocationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _studentInfoController = TextEditingController();

  String? _dept, _course, _year, _section;
  List<String> _currentProblemTypes = [];
  bool _isLoading = false;
  File? _selectedFile;
  bool _isVideoSelected = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
    
    if (widget.categoryIndex >= 0 && widget.categoryIndex < Constants.categories.length) {
      _selectedCategory = Constants.categories[widget.categoryIndex];
      _updateProblemTypes();
    }
  }

  void _updateProblemTypes() {
    if (_selectedCategory == 'Academic') {
      _currentProblemTypes = Constants.academicProblems['Academic'] ?? [];
    } else {
      _currentProblemTypes = Constants.generalProblems['General'] ?? [];
    }
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (mounted && data != null) {
        final profile = UserProfile.fromJson(data);
        setState(() {
          _dept = profile.department;
          _course = profile.course;
          _year = profile.year;
          _section = profile.section;
          _studentInfoController.text = '${profile.fullName} / ${profile.studentId ?? profile.id}';
        });
      }
    } catch (e) {
      debugPrint('Error loading student profile: $e');
    }
  }

  String _generateComplaintId() {
    final year = DateTime.now().year.toString();
    final dept = _dept ?? 'GEN';
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'CMP-$year-$dept-$random';
  }

  Future<void> _pickFile(bool isVideo, ImageSource source) async {
    try {
      final XFile? pickedFile = isVideo 
          ? await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 1))
          : await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
      
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _isVideoSelected = isVideo;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _submitComplaint() async {
    bool isLocationRequired = _selectedCategory != 'Academic';

    if (_selectedCategory.isEmpty || 
        _selectedProblemType.isEmpty || 
        (isLocationRequired && _selectedLocation.isEmpty) || 
        _descriptionController.text.trim().isEmpty ||
        _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all mandatory fields and provide proof (Image/Video)'),
          backgroundColor: Colors.red,
        )
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fileUrl;
      if (_selectedFile != null) {
        final folder = _isVideoSelected ? 'videos' : 'images';
        final fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}_${path.basename(_selectedFile!.path)}';
        await Supabase.instance.client.storage.from('complaints').upload(fileName, _selectedFile!);
        fileUrl = Supabase.instance.client.storage.from('complaints').getPublicUrl(fileName);
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final now = DateTime.now().toUtc().toIso8601String();
      final generatedId = _generateComplaintId();

      String? targetTeacherId;
      String teacherSearch = _subjectController.text.trim();
      if (_selectedCategory == 'Academic' && teacherSearch.isNotEmpty) {
        try {
          final teacherData = await Supabase.instance.client
              .from('profiles')
              .select('id')
              .ilike('full_name', '%$teacherSearch%')
              .eq('department', _dept ?? '')
              .or('user_role.ilike.Teacher,user_role.ilike.faculty')
              .maybeSingle();
          if (teacherData != null) {
            targetTeacherId = teacherData['id'];
          }
        } catch (e) {
          debugPrint('Teacher lookup failed: $e');
        }
      }

      final issueData = {
        'complaint_id': generatedId,
        'user_id': userId,
        'user_name': _studentInfoController.text,
        'category': _selectedCategory,
        'problem_type': _selectedProblemType + (_subjectController.text.isNotEmpty ? ' (${_subjectController.text})' : ''),
        'location': _selectedCategory == 'Academic' 
            ? 'Academic' 
            : (_selectedLocation + (_subLocationController.text.isNotEmpty ? ' - ${_subLocationController.text}' : '')),
        'description': _descriptionController.text.trim(),
        'photo_url': fileUrl,
        'status': 'PENDING',
        'department': _dept,
        'course': _course,
        'year': _year,
        'section': _section,
        'current_authority_role': 'Teacher',
        'current_authority_id': targetTeacherId,
        'created_at': now,
      };

      // 1. Insert Issue
      final response = await Supabase.instance.client.from('issues').insert(issueData).select().single();
      
      // 2. Try Insert History (Safe-wrapped to prevent UI error if history columns are cached/mismatched)
      try {
        await Supabase.instance.client.from('complaint_history').insert({
          'issue_id': response['id'],
          'performed_by_name': _studentInfoController.text.split(' / ')[0],
          'performed_by_role': 'Student',
          'action': 'SUBMITTED',
          'status': 'PENDING',
          'comment': 'Complaint $generatedId raised. Assigned to: ${teacherSearch.isNotEmpty ? teacherSearch : "Department Teacher"}',
          'created_at': now,
        });
      } catch (hError) {
        debugPrint('Non-critical History Insert Error: $hError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Complaint $generatedId Submitted Successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Submission Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Raise Complaints')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDisabledField(context, _studentInfoController, 'Student Profile', Icons.person),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Grievance Category *', prefixIcon: Icon(Icons.account_tree_outlined)),
                  items: Constants.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val!;
                      _updateProblemTypes();
                      _selectedProblemType = '';
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (_selectedCategory == 'Academic') ...[
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(labelText: 'Subject / Teacher Name (Optional)', prefixIcon: Icon(Icons.book_outlined)),
                  ),
                  const SizedBox(height: 16),
                ],
                
                DropdownButtonFormField<String>(
                  value: _selectedProblemType.isEmpty ? null : _selectedProblemType,
                  decoration: const InputDecoration(labelText: 'Issue Type *', prefixIcon: Icon(Icons.report_problem)),
                  items: _currentProblemTypes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedProblemType = val!),
                ),
                const SizedBox(height: 16),
                
                if (_selectedCategory != 'Academic') ...[
                  DropdownButtonFormField<String>(
                    value: _selectedLocation.isEmpty ? null : _selectedLocation,
                    decoration: const InputDecoration(labelText: 'Location *', prefixIcon: Icon(Icons.location_on)),
                    items: Constants.locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (val) => setState(() => _selectedLocation = val!),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(controller: _subLocationController, decoration: const InputDecoration(hintText: 'Specific Details (e.g. Room No, Floor)', prefixIcon: Icon(Icons.my_location))),
                  const SizedBox(height: 16),
                ],
                
                TextField(controller: _descriptionController, maxLines: 4, decoration: const InputDecoration(hintText: 'Detailed Description *')),
                const SizedBox(height: 24),

                const Text('Proof Evidence (Mandatory) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildEvidenceSection(theme),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitComplaint,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT COMPLAINT'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(ThemeData theme) {
    if (_selectedFile != null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _isVideoSelected
                    ? Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_file, color: Colors.white, size: 50),
                              SizedBox(height: 8),
                              Text('Video Evidence Attached', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    : Image.file(_selectedFile!, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() {
                    _selectedFile = null;
                    _isVideoSelected = false;
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: _buildEvidenceCard(theme, 'Photo', Icons.camera_alt, false)),
        const SizedBox(width: 16),
        Expanded(child: _buildEvidenceCard(theme, 'Video', Icons.videocam, true)),
      ],
    );
  }

  Widget _buildEvidenceCard(ThemeData theme, String label, IconData icon, bool isVideo) {
    return InkWell(
      onTap: () => _showPickerOptions(isVideo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 40),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showPickerOptions(bool isVideo) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(isVideo ? Icons.video_library : Icons.photo_library),
              title: const Text('Select from Gallery'),
              onTap: () { Navigator.pop(ctx); _pickFile(isVideo, ImageSource.gallery); },
            ),
            ListTile(
              leading: Icon(isVideo ? Icons.videocam : Icons.camera_alt),
              title: Text(isVideo ? 'Record Video' : 'Take Photo'),
              onTap: () { Navigator.pop(ctx); _pickFile(isVideo, ImageSource.camera); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledField(BuildContext context, TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      ),
    );
  }
}
