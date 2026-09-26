import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'posh_home_screen.dart';
import 'my_confidential_reports_screen.dart';

class PoshSubmissionSuccessScreen extends StatelessWidget {
  final String caseNumber;

  const PoshSubmissionSuccessScreen({super.key, required this.caseNumber});

  @override
  Widget build(BuildContext context) {
    const Color poshPurple = Color(0xFF673AB7);
    const Color navyText = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 30),
              const Text(
                'Confidential Report Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: navyText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your report has been securely submitted to the authorized POSH department.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'It will not be routed through the normal complaint system.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: poshPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Report ID', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          caseNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: navyText,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: poshPurple),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: caseNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report ID copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MyConfidentialReportsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: poshPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    'Track My Report',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const PoshHomeScreen()),
                    (route) => route.isFirst,
                  );
                },
                child: const Text(
                  'Return Home',
                  style: TextStyle(color: poshPurple, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
