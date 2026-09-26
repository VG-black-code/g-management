import 'package:flutter/material.dart';
import 'report_incident_screen.dart';
import 'my_confidential_reports_screen.dart';
import 'posh_help_rights_screen.dart';
import 'emergency_help_screen.dart';
import 'posh_widgets.dart';

class PoshHomeScreen extends StatelessWidget {
  const PoshHomeScreen({super.key});

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
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, color: poshPurple, size: 24),
            const SizedBox(width: 8),
            Column(
              children: [
                const Text(
                  'POSH & Harassment',
                  style: TextStyle(color: navyText, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '(Confidential)',
                  style: TextStyle(color: poshPurple.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report harassment, sexual harassment, abuse or inappropriate behaviour confidentially.',
              style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 30),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 1,
              childAspectRatio: 2.8,
              mainAxisSpacing: 16,
              children: [
                PoshMenuCard(
                  icon: Icons.assignment_outlined,
                  title: 'Report an Incident',
                  subtitle: 'File a confidential report',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIncidentScreen())),
                ),
                PoshMenuCard(
                  icon: Icons.folder_outlined,
                  title: 'My Confidential Reports',
                  subtitle: 'Track your report status',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyConfidentialReportsScreen())),
                ),
                PoshMenuCard(
                  icon: Icons.info_outline,
                  title: 'POSH Help & Rights',
                  subtitle: 'Know your rights & policies',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoshHelpRightsScreen())),
                ),
                PoshMenuCard(
                  icon: Icons.contact_phone,
                  title: 'Emergency Help',
                  subtitle: 'Helplines and support',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyHelpScreen())),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const PoshSecurityBanner(),
          ],
        ),
      ),
    );
  }
}
