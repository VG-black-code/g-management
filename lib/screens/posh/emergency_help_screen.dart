import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'posh_widgets.dart';

class EmergencyHelpScreen extends StatefulWidget {
  const EmergencyHelpScreen({super.key});

  @override
  State<EmergencyHelpScreen> createState() => _EmergencyHelpScreenState();
}

class _EmergencyHelpScreenState extends State<EmergencyHelpScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _helplines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHelplines();
  }

  Future<void> _fetchHelplines() async {
    try {
      final data = await supabase.from('posh_config').select().order('key');
      if (mounted) {
        setState(() {
          _helplines = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to defaults if table doesn't exist yet
      if (mounted) {
        setState(() {
          _helplines = [
            {
              'label': 'Institutional POSH Contact',
              'value': '+91 98765 43210',
              'icon_name': 'shield',
              'color_hex': '673AB7'
            },
            {
              'label': 'Campus Security',
              'value': '080-1234-5678',
              'icon_name': 'security',
              'color_hex': 'F44336'
            },
            {
              'label': 'Women\'s Helpline',
              'value': '1091',
              'icon_name': 'support_agent',
              'color_hex': '2196F3'
            },
          ];
          _isLoading = false;
        });
      }
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
        title: const Text(
          'Emergency Help',
          style: TextStyle(color: navyText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: poshPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Helplines and Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navyText),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you are in immediate danger or need urgent assistance, please use the contacts below.',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  ..._helplines.map((h) => _buildEmergencyCard(
                        title: h['label'],
                        subtitle: 'Authorized Support Resource',
                        phone: h['value'],
                        icon: _getIconData(h['icon_name']),
                        color: _getColor(h['color_hex']),
                      )),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: poshPurple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.info_outline, color: poshPurple),
                        SizedBox(height: 12),
                        Text(
                          'Your safety is our priority. These contacts are authorized support resources provided by the institution.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'shield': return Icons.shield;
      case 'security': return Icons.security;
      case 'support_agent': return Icons.support_agent;
      case 'local_police': return Icons.local_police;
      default: return Icons.phone;
    }
  }

  Color _getColor(String? hex) {
    if (hex == null) return poshPurple;
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return poshPurple;
    }
  }

  Widget _buildEmergencyCard({
    required String title,
    required String subtitle,
    required String phone,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text(phone, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(phone),
            icon: const Icon(Icons.call),
            style: IconButton.styleFrom(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
