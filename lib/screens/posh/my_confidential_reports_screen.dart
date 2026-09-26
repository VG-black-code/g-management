import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'posh_report_status_screen.dart';
import 'posh_widgets.dart';

class MyConfidentialReportsScreen extends StatefulWidget {
  const MyConfidentialReportsScreen({super.key});

  @override
  State<MyConfidentialReportsScreen> createState() => _MyConfidentialReportsScreenState();
}

class _MyConfidentialReportsScreenState extends State<MyConfidentialReportsScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('posh_cases')
            .select()
            .eq('reporter_id', user.id)
            .order('created_at', ascending: false);
        
        if (mounted) {
          setState(() {
            _reports = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Confidential Reports',
              style: TextStyle(color: navyText, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Track the status of your confidential reports',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: poshPurple))
          : _reports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      return PoshReportCard(
                        report: _reports[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PoshReportStatusScreen(report: _reports[index]),
                            ),
                          ).then((_) => _fetchReports());
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            'No reports found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'You haven\'t filed any confidential reports yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
