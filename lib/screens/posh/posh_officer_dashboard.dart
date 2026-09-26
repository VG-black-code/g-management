import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'posh_case_details_screen.dart';
import 'posh_widgets.dart';
import 'posh_helpline_editor_screen.dart';

class PoshOfficerDashboard extends StatefulWidget {
  const PoshOfficerDashboard({super.key});

  @override
  State<PoshOfficerDashboard> createState() => _PoshOfficerDashboardState();
}

class _PoshOfficerDashboardState extends State<PoshOfficerDashboard> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _cases = [];
  Map<String, int> _stats = {
    'New Cases': 0,
    'Under Review': 0,
    'Action Required': 0,
    'Closed': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('posh_cases')
          .select()
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _cases = data;
          _stats['New Cases'] = _cases.where((c) => c['status'] == 'Submitted').length;
          _stats['Under Review'] = _cases.where((c) => c['status'] == 'Under Review' || c['status'] == 'Assigned').length;
          _stats['Action Required'] = _cases.where((c) => c['status'] == 'Action Required').length;
          _stats['Closed'] = _cases.where((c) => c['status'] == 'Closed' || c['status'] == 'Action Taken').length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching POSH dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: navyText),
        title: const Text(
          'POSH Officer Dashboard',
          style: TextStyle(color: navyText, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: navyText),
            tooltip: 'Helpline Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PoshHelplineEditorScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: navyText),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: poshPurple))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Confidential Cases',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyText),
                        ),
                        Text(
                          'Total: ${_cases.length}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_cases.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No POSH cases found.')))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cases.length,
                        itemBuilder: (context, index) => _buildOfficerCaseCard(_cases[index]),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOfficerCaseCard(dynamic caseData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      caseData['case_number'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: poshPurple, letterSpacing: 1.1),
                    ),
                    PoshStatusBadge(status: caseData['status'] ?? 'Submitted'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  caseData['category'] ?? 'General',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyText),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Submitted: ${caseData['created_at'].toString().split('T')[0]}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PoshCaseDetailsScreen(caseData: caseData)),
              ).then((_) => _fetchDashboardData()),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_open, size: 16, color: poshPurple),
                  SizedBox(width: 8),
                  Text('Open Secure Case', style: TextStyle(color: poshPurple, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('New Cases', _stats['New Cases']!, Colors.blue),
        _buildStatCard('Under Review', _stats['Under Review']!, Colors.orange),
        _buildStatCard('Action Required', _stats['Action Required']!, Colors.red),
        _buildStatCard('Closed', _stats['Closed']!, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
