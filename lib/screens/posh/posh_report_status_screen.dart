import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'posh_widgets.dart';

class PoshReportStatusScreen extends StatefulWidget {
  final dynamic report;

  const PoshReportStatusScreen({super.key, required this.report});

  @override
  State<PoshReportStatusScreen> createState() => _PoshReportStatusScreenState();
}

class _PoshReportStatusScreenState extends State<PoshReportStatusScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _updates = [];
  List<dynamic> _myEvidence = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCaseDetails();
  }

  Future<void> _fetchCaseDetails() async {
    setState(() => _isLoading = true);
    try {
      final caseId = widget.report['id'];
      
      // 1. Fetch public updates (Safe Messages)
      final updatesData = await supabase
          .from('posh_case_updates')
          .select()
          .eq('case_id', caseId)
          .order('created_at', ascending: false);
      
      // 2. Fetch my own uploaded evidence
      final evidenceData = await supabase
          .from('posh_evidence')
          .select()
          .eq('case_id', caseId)
          .eq('uploaded_by', supabase.auth.currentUser!.id);
      
      if (mounted) {
        setState(() {
          _updates = updatesData;
          _myEvidence = evidenceData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching case details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewMyFile(String filePath) async {
    try {
      final response = await supabase.storage.from('posh-evidence').createSignedUrl(filePath, 60);
      final uri = Uri.parse(response);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final String status = report['status'] ?? 'Submitted';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: navyText),
        title: Text(
          report['case_number'] ?? 'Report Status',
          style: const TextStyle(color: navyText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: poshPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(report),
                  const SizedBox(height: 30),
                  const Text('Case Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyText)),
                  const SizedBox(height: 20),
                  PoshStatusTimeline(currentStatus: status),
                  const SizedBox(height: 30),
                  
                  _buildSectionTitle('My Report Details'),
                  _buildDetailsBox(report['description'] ?? 'No description provided.'),
                  
                  if (_myEvidence.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Submitted Evidence'),
                    ..._myEvidence.map((e) => Card(
                      elevation: 0,
                      color: Colors.grey[50],
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), 
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.file_present, color: poshPurple),
                        title: Text(e['file_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
                        onTap: () => _viewMyFile(e['file_path']),
                      ),
                    )),
                  ],

                  if (_updates.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    _buildSectionTitle('Timeline Updates'),
                    ..._updates.map((update) => _buildUpdateCard(update)),
                  ],
                  
                  const SizedBox(height: 40),
                  const PoshSecurityBanner(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(dynamic report) {
    final DateTime createdAt = DateTime.parse(report['created_at']);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(poshRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(report['category'] ?? 'General', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyText)),
              PoshStatusBadge(status: report['status'] ?? 'Submitted'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Submitted: ${DateFormat('dd MMM yyyy').format(createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyText)),
    );
  }

  Widget _buildDetailsBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
      child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
    );
  }

  Widget _buildUpdateCard(dynamic update) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: poshPurple.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: poshPurple.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(update['status'] ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: poshPurple)),
              Text(DateFormat('dd MMM, hh:mm a').format(DateTime.parse(update['created_at'])), style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          if (update['safe_message'] != null) ...[
            const SizedBox(height: 8),
            Text(update['safe_message'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ],
      ),
    );
  }
}
