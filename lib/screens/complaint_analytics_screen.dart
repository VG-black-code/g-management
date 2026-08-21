import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';

class ComplaintAnalyticsScreen extends StatefulWidget {
  const ComplaintAnalyticsScreen({super.key});

  @override
  State<ComplaintAnalyticsScreen> createState() => _ComplaintAnalyticsScreenState();
}

class _ComplaintAnalyticsScreenState extends State<ComplaintAnalyticsScreen> with TickerProviderStateMixin {
  List<Issue> _allIssues = [];
  bool _isLoading = true;
  String _userRole = 'Admin';

  int _pendingCount = 0;
  int _processingCount = 0;
  int _resolvedCount = 0;
  
  Map<String, Map<String, int>> _categoryBreakdown = {
    'Academic': {'Pending': 0, 'Processing': 0, 'Resolved': 0},
    'General': {'Pending': 0, 'Processing': 0, 'Resolved': 0},
  };

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fetchIssues();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchIssues() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('role') ?? 'Admin';
    final dept = prefs.getString('department') ?? '';
    final userId = prefs.getString('user_id') ?? '';

    try {
      final client = Supabase.instance.client;
      var query = client.from('issues').select();
      
      if (_userRole == 'Student') {
        query = query.eq('user_id', userId);
      } else if (_userRole == 'HOD' || _userRole == 'Teacher') {
        query = query.eq('department', dept);
      }
      
      final data = await query.order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _allIssues = (data as List).map((json) => Issue.fromJson(json)).toList();
          _processData();
          _isLoading = false;
        });
        _fadeController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData() {
    int pending = 0, processing = 0, resolved = 0;
    Map<String, Map<String, int>> breakdown = {
      'Academic': {'Pending': 0, 'Processing': 0, 'Resolved': 0},
      'General': {'Pending': 0, 'Processing': 0, 'Resolved': 0},
    };

    for (var issue in _allIssues) {
      final s = issue.status?.toUpperCase() ?? '';
      String statusKey = '';
      if (s == 'PENDING' || s == 'FORWARDED') {
        pending++;
        statusKey = 'Pending';
      } else if (s == 'PROCESSING') {
        processing++;
        statusKey = 'Processing';
      } else if (s == 'RESOLVED') {
        resolved++;
        statusKey = 'Resolved';
      }

      if (statusKey.isNotEmpty) {
        final c = (issue.category ?? 'General').trim();
        String categoryKey = 'General';
        if (c.toLowerCase() == 'academic') {
          categoryKey = 'Academic';
        }
        
        breakdown[categoryKey]![statusKey] = (breakdown[categoryKey]![statusKey] ?? 0) + 1;
      }
    }

    setState(() {
      _pendingCount = pending;
      _processingCount = processing;
      _resolvedCount = resolved;
      _categoryBreakdown = breakdown;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Analytics Portal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _fetchIssues)],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : FadeTransition(
            opacity: _fadeController,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Institutional Grievance Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      _buildMiniStat('Pending', _pendingCount, Colors.red),
                      const SizedBox(width: 12),
                      _buildMiniStat('Processing', _processingCount, Colors.orange),
                      const SizedBox(width: 12),
                      _buildMiniStat('Resolved', _resolvedCount, Colors.green),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Overall Status Distribution', theme),
                  const SizedBox(height: 16),
                  _buildChartCard(
                    child: Column(
                      children: [
                        SizedBox(height: 200, child: _buildDonutChart(_pendingCount, _processingCount, _resolvedCount)),
                        const SizedBox(height: 24),
                        _buildLegend(theme),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('Workflow Breakdown', theme),
                  const SizedBox(height: 16),
                  
                  _buildCategoryBarChartCard('Academic Analysis', _categoryBreakdown['Academic']!, Colors.blue),
                  const SizedBox(height: 20),
                  _buildCategoryBarChartCard('General Analysis', _categoryBreakdown['General']!, Colors.deepPurple),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCategoryBarChartCard(String title, Map<String, int> data, Color accentColor) {
    int total = data.values.fold(0, (sum, item) => sum + item);
    int maxVal = data.values.fold(0, (curr, val) => max(curr, val));
    
    // Dynamic maxY ensures bars never overflow their container box.
    double chartMaxY = maxVal == 0 ? 5 : (maxVal * 1.5).ceilToDouble();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.05),
              border: Border(left: BorderSide(color: accentColor, width: 4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Total: $total', style: TextStyle(color: accentColor, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMaxY,
                  barGroups: [
                    _makeBarGroup(0, data['Pending']!.toDouble(), Colors.red),
                    _makeBarGroup(1, data['Processing']!.toDouble(), Colors.orange),
                    _makeBarGroup(2, data['Resolved']!.toDouble(), Colors.green),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          String text = '';
                          switch (value.toInt()) {
                            case 0: text = 'Pending'; break;
                            case 1: text = 'Processing'; break;
                            case 2: text = 'Resolved'; break;
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 10,
                            child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.05), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.round().toString(),
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      showingTooltipIndicators: [0], // Always show count on top
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          border: Border(top: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildChartCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildDonutChart(int pending, int processing, int resolved) {
    int total = pending + processing + resolved;
    if (total == 0) return const Center(child: Text('No data', style: TextStyle(fontSize: 10, color: Colors.grey)));

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(color: Colors.red, value: pending.toDouble(), radius: 30, title: '', showTitle: false),
          PieChartSectionData(color: Colors.orange, value: processing.toDouble(), radius: 30, title: '', showTitle: false),
          PieChartSectionData(color: Colors.green, value: resolved.toDouble(), radius: 30, title: '', showTitle: false),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(Colors.red, 'Pending'),
        const SizedBox(width: 16),
        _legendDot(Colors.orange, 'Processing'),
        const SizedBox(width: 16),
        _legendDot(Colors.green, 'Resolved'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
