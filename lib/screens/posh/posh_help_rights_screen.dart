import 'package:flutter/material.dart';
import 'emergency_help_screen.dart';
import 'posh_widgets.dart';

class PoshHelpRightsScreen extends StatelessWidget {
  const PoshHelpRightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: navyText),
        title: const Text(
          'POSH Help & Rights',
          style: TextStyle(color: navyText, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              title: 'What is POSH?',
              description: 'Understand the POSH Act and workplace/campus harassment policies.',
              icon: Icons.gavel,
              color: poshPurple,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Your Rights',
              description: 'Understand your rights as a student, teacher or staff member.',
              icon: Icons.shield_outlined,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildProcessSection(),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Important Guidelines',
              description: 'Explain appropriate reporting and evidence preservation.',
              icon: Icons.rule,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Useful Contacts',
              description: 'Provide authorized institutional support contacts.',
              icon: Icons.contact_support_outlined,
              color: Colors.teal,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'POSH Immediate Help?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you are in immediate danger, please contact appropriate emergency/support services.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyHelpScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View Helplines', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String description, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyText)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How the Process Works', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: navyText)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStep('Report', Icons.edit_note),
              _buildArrow(),
              _buildStep('Review', Icons.pageview_outlined),
              _buildArrow(),
              _buildStep('Investigate', Icons.search),
              _buildArrow(),
              _buildStep('Action', Icons.gavel),
              _buildArrow(),
              _buildStep('Closure', Icons.check_circle_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: poshPurple, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildArrow() {
    return const Icon(Icons.chevron_right, size: 16, color: Colors.grey);
  }
}
