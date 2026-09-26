import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/models.dart';
import '../providers/complaints_provider.dart';

class IssueDetailsScreen extends StatefulWidget {
  final Issue issue;

  const IssueDetailsScreen({super.key, required this.issue});

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideo = false;
  List<ComplaintHistory> _history = [];
  bool _isLoadingHistory = true;
  String _userRole = '';
  String _userName = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkMediaType();
    _fetchHistory();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _userId = user.id;
      try {
        final client = Supabase.instance.client;
        
        // 1. Check Profiles (Students)
        final profileData = await client.from('profiles').select().eq('id', user.id).maybeSingle();
        if (profileData != null) {
          if (mounted) {
            setState(() {
              _userRole = profileData['user_role'] ?? 'Student';
              _userName = profileData['full_name'] ?? 'User';
            });
          }
          return;
        }

        // 2. Check Faculty (Teachers, etc.)
        final facultyData = await client.from('faculty').select().eq('id', user.id).maybeSingle();
        if (facultyData != null) {
          if (mounted) {
            setState(() {
              _userRole = facultyData['role'] ?? 'Teacher';
              _userName = facultyData['FullName'] ?? 'User';
            });
          }
          return;
        }

        // 3. Check Admin
        final adminData = await client.from('admins').select().eq('id', user.id).maybeSingle();
        if (adminData != null) {
          if (mounted) {
            setState(() {
              _userRole = 'Admin';
              _userName = adminData['full_name'] ?? 'Admin';
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  void _checkMediaType() {
    final url = widget.issue.photoUrl;
    if (url != null && url.contains('/videos/')) {
      setState(() => _isVideo = true);
      _initializeVideoPlayer(url);
    }
  }

  Future<void> _initializeVideoPlayer(String url) async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
    );
    if (mounted) setState(() {});
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await Supabase.instance.client
          .from('complaint_history')
          .select()
          .eq('issue_id', widget.issue.id!)
          .order('created_at', ascending: true);
      if (mounted) {
        setState(() {
          _history = (data as List).map((e) => ComplaintHistory.fromJson(e)).toList();
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateStr).toLocal());
    } catch (_) { return dateStr; }
  }

  Future<void> _handleAction(String action) async {
    final provider = context.read<ComplaintsProvider>();
    final TextEditingController remarkController = TextEditingController();
    String? nextRole;
    List<String> forwardOptions = [];

    final normalizedRole = _userRole.toLowerCase();
    final isAcademic = widget.issue.category == 'Academic';

    if (action == 'FORWARD') {
      if (normalizedRole == 'teacher' || normalizedRole == 'faculty') {
        forwardOptions.add('HOD');
        if (!isAcademic) forwardOptions.add('Admin');
      } else if (normalizedRole == 'hod') {
        forwardOptions.add('Dean');
      } else if (normalizedRole == 'dean') {
        forwardOptions.add(isAcademic ? 'Principal' : 'Admin');
      }

      if (forwardOptions.length == 1) {
        nextRole = forwardOptions.first;
      } else if (forwardOptions.length > 1) {
        nextRole = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Forward to:'),
            children: forwardOptions.map((role) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(role, style: const TextStyle(fontSize: 16)),
              ),
            )).toList(),
          ),
        );
        if (nextRole == null) return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          action == 'PROCESS' ? 'Start Processing?' : 
          action == 'RESOLVE' ? 'Mark as Resolved?' : 
          'Forward to ${nextRole ?? "Authority"}?'
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter a reply or action taken for the student:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: remarkController,
              decoration: InputDecoration(
                hintText: 'e.g. Discussed with class teacher / Replaced broken bench',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'RESOLVE' ? Colors.green : (action == 'PROCESS' ? Colors.orange : Colors.blue),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    bool success = false;
    final comment = remarkController.text.trim();
    if (action == 'PROCESS') {
      success = await provider.updateStatus(widget.issue, 'PROCESSING', comment: comment, userName: _userName, role: _userRole, userId: _userId);
    } else if (action == 'RESOLVE') {
      success = await provider.updateStatus(widget.issue, 'RESOLVED', comment: comment, userName: _userName, role: _userRole, userId: _userId);
    } else if (action == 'FORWARD' && nextRole != null) {
      success = await provider.forwardComplaint(widget.issue, nextRole, 'Institutional Escalation', comment, userName: _userName, role: _userRole);
    }

    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action recorded successfully!'), backgroundColor: Colors.green),
      );
      _fetchHistory(); // Refresh history immediately
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedRole = _userRole.toLowerCase();
    final isFaculty = ['teacher', 'faculty', 'hod', 'dean', 'principal', 'admin'].contains(normalizedRole);
    
    bool isAuthorized = widget.issue.currentAuthorityRole?.toLowerCase() == normalizedRole;
    if (!isAuthorized && normalizedRole == 'admin' && widget.issue.category == 'General') {
      isAuthorized = true;
    }
    
    final status = widget.issue.status?.toUpperCase() ?? 'PENDING';
    final isResolved = status == 'RESOLVED';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complaint Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.issue.photoUrl != null && widget.issue.photoUrl!.isNotEmpty)
              _isVideo ? _buildVideoPlayer() : _buildImage(widget.issue.photoUrl!)
            else
              _buildPlaceholder(),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 20),
                  _buildLatestReplySection(), // NEW SECTION
                  const Divider(height: 40),
                  _buildInfoGrid(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
                  const SizedBox(height: 32),
                  _buildTimelineSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: (isFaculty && isAuthorized && !isResolved) ? _buildActionButtons() : null,
    );
  }

  Widget _buildLatestReplySection() {
    // Find the latest history entry with a comment from an authority
    final latestReply = _history.reversed.firstWhere(
      (h) => h.comment != null && h.comment!.trim().isNotEmpty && h.performedByRole != 'Student',
      orElse: () => ComplaintHistory(),
    );

    if (latestReply.comment == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.reply_all, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'RESPONSE FROM ${latestReply.performedByRole?.toUpperCase()}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            latestReply.comment!,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Replied by ${latestReply.performedByName} on ${_formatDate(latestReply.createdAt)}',
            style: TextStyle(fontSize: 11, color: Colors.green.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = widget.issue.status?.toUpperCase() ?? 'PENDING';
    final isPending = status == 'PENDING' || status == 'FORWARDED';
    final isProcessing = status == 'PROCESSING';
    final normalizedRole = _userRole.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
      ),
      child: Row(
        children: [
          if (isPending) ...[
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAction('PROCESS'), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), 
                child: const Text('PROCESS')
              )
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAction('RESOLVE'), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
                child: const Text('RESOLVE')
              )
            ),
          ],
          if (isProcessing)
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAction('RESOLVE'), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), 
                child: const Text('MARK RESOLVED')
              )
            ),
          const SizedBox(width: 12),
          if (normalizedRole != 'principal' && normalizedRole != 'admin')
            Expanded(
              child: OutlinedButton(
                onPressed: () => _handleAction('FORWARD'), 
                child: const Text('FORWARD')
              )
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('#CMP${widget.issue.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ),
            _buildStatusBadge(widget.issue.status ?? 'Pending'),
          ],
        ),
        const SizedBox(height: 16),
        Text(widget.issue.problemType ?? 'Grievance', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Raised by: ${widget.issue.userName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(_formatDate(widget.issue.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      children: [
        _buildInfoItem('Category', widget.issue.category ?? 'General'),
        _buildInfoItem('Department', widget.issue.department ?? 'All'),
        _buildInfoItem('Location', widget.issue.location ?? 'Campus'),
        _buildInfoItem('Priority', widget.issue.priority ?? 'Medium'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.issue.description ?? 'No details provided.', style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.5)),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        if (_isLoadingHistory) const Center(child: CircularProgressIndicator())
        else if (_history.isEmpty) const Text('No history available.')
        else ..._history.reversed.map((h) => _buildTimelineItem(h)).toList(),
      ],
    );
  }

  Widget _buildTimelineItem(ComplaintHistory h) {
    bool isAuthority = h.performedByRole != 'Student';
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: isAuthority ? Colors.green : Colors.blue, shape: BoxShape.circle)),
              Container(width: 2, height: 50, color: Colors.grey.shade200),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.action?.replaceAll('_', ' ') ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text('By ${h.performedByName} (${h.performedByRole})', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (h.comment != null && h.comment!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAuthority ? Colors.green.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: isAuthority ? Border.all(color: Colors.green.shade100) : null,
                    ),
                    child: Text(h.comment!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  ),
                ],
                const SizedBox(height: 4),
                Text(_formatDate(h.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.red;
    if (status.toUpperCase() == 'RESOLVED') color = Colors.green;
    else if (status.toUpperCase() == 'PROCESSING') color = Colors.orange;
    else if (status.toUpperCase() == 'FORWARDED') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(height: 250, width: double.infinity, color: Colors.black, child: _chewieController != null ? Chewie(controller: _chewieController!) : const Center(child: CircularProgressIndicator()));
  }

  Widget _buildImage(String url) {
    return Image.network(url, height: 250, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder());
  }

  Widget _buildPlaceholder() {
    return Container(height: 250, width: double.infinity, color: Colors.grey.shade200, child: const Icon(Icons.image, size: 64, color: Colors.grey));
  }
}
