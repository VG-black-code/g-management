import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Global POSH Design Constants ---
const Color poshPurple = Color(0xFF673AB7);
const Color navyText = Color(0xFF1A237E);
const double poshRadius = 20.0;

class PoshSecurityBanner extends StatelessWidget {
  const PoshSecurityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: poshPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(poshRadius),
        border: Border.all(color: poshPurple.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: poshPurple, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your report is confidential.',
                  style: TextStyle(color: navyText, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'It will not be shared with teachers, HODs or regular administrators.',
                  style: TextStyle(color: navyText.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PoshStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const PoshStepIndicator({super.key, required this.currentStep, this.totalSteps = 5});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(totalSteps, (index) {
          bool isActive = index <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
              decoration: BoxDecoration(
                color: isActive ? poshPurple : Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class PoshMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const PoshMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(poshRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(poshRadius),
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
                color: poshPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: poshPurple, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: navyText, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class PoshEvidenceUploader extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const PoshEvidenceUploader({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: poshPurple.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: poshPurple, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navyText)),
          ],
        ),
      ),
    );
  }
}

class PoshStatusBadge extends StatelessWidget {
  final String status;
  const PoshStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Submitted': color = Colors.blue; break;
      case 'Assigned': color = Colors.indigo; break;
      case 'Under Review': color = Colors.orange; break;
      case 'Action Required': color = Colors.red; break;
      case 'Action Taken': color = Colors.green; break;
      case 'Closed': color = Colors.grey; break;
      default: color = poshPurple;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class PoshStatusTimeline extends StatelessWidget {
  final String currentStatus;
  const PoshStatusTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statuses = ['Submitted', 'Assigned', 'Under Review', 'Action Taken', 'Closed'];
    int currentIndex = statuses.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      children: List.generate(statuses.length, (index) {
        bool isCompleted = index <= currentIndex;
        bool isLast = index == statuses.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCompleted ? poshPurple : Colors.grey[200],
                    shape: BoxShape.circle,
                    border: Border.all(color: isCompleted ? poshPurple : Colors.grey[300]!, width: 2),
                  ),
                  child: isCompleted ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                ),
                if (!isLast) Container(width: 2, height: 40, color: isCompleted ? poshPurple : Colors.grey[200]),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statuses[index], style: TextStyle(fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal, color: isCompleted ? Colors.black : Colors.grey)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class PoshReportCard extends StatelessWidget {
  final dynamic report;
  final VoidCallback onTap;

  const PoshReportCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final DateTime createdAt = DateTime.parse(report['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(poshRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
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
                    Text(report['case_number'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: poshPurple, letterSpacing: 1.1)),
                    PoshStatusBadge(status: report['status'] ?? 'Submitted'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(report['category'] ?? 'General', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyText)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Submitted: ${DateFormat('dd MMM yyyy').format(createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: TextButton(
              onPressed: onTap,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Status', style: TextStyle(color: poshPurple, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16, color: poshPurple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PoshConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const PoshConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(poshRadius)),
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: poshPurple),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: navyText, fontWeight: FontWeight.bold))),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: poshPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class PoshCategoryCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const PoshCategoryCard({super.key, required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? poshPurple.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? poshPurple : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: TextStyle(color: isSelected ? poshPurple : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
            if (isSelected) const Icon(Icons.check_circle, color: poshPurple, size: 20),
          ],
        ),
      ),
    );
  }
}
