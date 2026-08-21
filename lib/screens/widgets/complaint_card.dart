import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import 'status_badge.dart';
import 'priority_badge.dart';
import 'complaint_details_dialog.dart';

class ComplaintCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback onTap;

  const ComplaintCard({
    super.key,
    required this.issue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = issue.createdAt != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(issue.createdAt!))
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => ComplaintDetailsDialog(issue: issue),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            issue.userName ?? 'Unknown Student',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'USN: ${issue.usn ?? "N/A"}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: issue.status ?? 'Pending'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildIconLabel(Icons.tag, 'CMP${issue.id}'),
                    const SizedBox(width: 16),
                    _buildIconLabel(Icons.category_outlined, issue.category ?? 'General'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildIconLabel(Icons.calendar_today_outlined, dateStr),
                    const SizedBox(width: 16),
                    _buildIconLabel(Icons.person_pin_outlined, issue.assignedTo ?? 'Unassigned'),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PriorityBadge(priority: issue.priority ?? 'Low'),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => ComplaintDetailsDialog(issue: issue),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
